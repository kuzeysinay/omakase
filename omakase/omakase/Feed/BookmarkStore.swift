//
//  BookmarkStore.swift
//  omakase
//

import Foundation
import Observation

struct BookmarkEntry: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var text: String
    /// User interests this post relates to.
    var tags: [String]
    var postCreatedAt: Date
    var savedAt: Date
    /// Canonical Main Subject ID (`InterestCategory.id`, e.g. "food", "science", "film").
    var collectionName: String = "science"
    /// Deep dive expansion text, if available when bookmarked.
    var deepDiveText: String?
    /// The format template used to generate this post.
    var postFormat: String?

    init(from post: Post, collectionName: String? = nil) {
        id = post.id
        title = post.title
        text = post.text
        tags = post.tags
        postCreatedAt = post.createdAt
        savedAt = Date()
        let resolvedMain = InterestCategory.resolveMainCategory(
            categoryId: collectionName ?? post.categoryId,
            tags: post.tags,
            title: post.title,
            text: post.text
        )
        self.collectionName = resolvedMain.id
        self.deepDiveText = post.deepDiveText
        self.postFormat = post.postFormat
    }

    /// Backward-compatible decoding: bookmarks saved before `collectionName` was normalized
    /// to a main category ID are automatically mapped to their canonical `InterestCategory.id`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        text = try c.decode(String.self, forKey: .text)
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
        postCreatedAt = try c.decode(Date.self, forKey: .postCreatedAt)
        savedAt = try c.decode(Date.self, forKey: .savedAt)
        let rawCollection = (try? c.decode(String.self, forKey: .collectionName)) ?? ""
        let resolvedMain = InterestCategory.resolveMainCategory(
            categoryId: rawCollection,
            tags: tags,
            title: title,
            text: text,
            legacyCollectionName: rawCollection
        )
        collectionName = resolvedMain.id
        deepDiveText = try? c.decode(String.self, forKey: .deepDiveText)
        postFormat = try? c.decode(String.self, forKey: .postFormat)
    }

    /// Reconstruct a `Post` from this bookmark entry.
    func toPost() -> Post {
        Post(
            id: id,
            title: title,
            text: text,
            isComplete: true,
            tags: tags,
            categoryId: collectionName,
            postFormat: postFormat,
            deepDiveText: deepDiveText,
            createdAt: postCreatedAt
        )
    }
}

@Observable
@MainActor
final class BookmarkStore {

    static let shared = BookmarkStore()

    private(set) var entries: [BookmarkEntry] = []
    private let defaultsKey = "omakase.bookmarks.v1"

    init() {
        load()
    }

    var count: Int { entries.count }

    func contains(postId: UUID) -> Bool {
        entries.contains { $0.id == postId }
    }

    func toggle(_ post: Post) {
        if entries.contains(where: { $0.id == post.id }) {
            entries.removeAll(where: { $0.id == post.id })
        } else {
            let mainCat = InterestCategory.resolveMainCategory(
                categoryId: post.categoryId,
                tags: post.tags,
                title: post.title,
                text: post.text
            )
            let entry = BookmarkEntry(from: post, collectionName: mainCat.id)
            entries.insert(entry, at: 0)
        }
        save()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func removeAll(in collectionId: String? = nil) {
        if let collectionId {
            if collectionId == "All" {
                entries = []
            } else {
                entries.removeAll { $0.collectionName == collectionId }
            }
        } else {
            entries = []
        }
        save()
    }

    // MARK: - Main Subject Folders

    /// Canonical folder IDs: always starts with `"All"`, followed by Main Subject IDs (`InterestCategory.id`)
    /// that currently contain saved posts (preserving `InterestCategory.presets` order).
    var collectionNames: [String] {
        var ids = ["All"]
        let populatedMainIds = Set(entries.map(\.collectionName))
        for cat in InterestCategory.presets where populatedMainIds.contains(cat.id) {
            ids.append(cat.id)
        }
        return ids
    }

    /// Returns the localized display title for a folder ID (`"All"` or an `InterestCategory.id`).
    func displayTitle(for collectionId: String, language: AppLanguage) -> String {
        if collectionId == "All" {
            return L10n(lang: language).bookmarkAllCategory
        }
        if let cat = InterestCategory.category(forId: collectionId) {
            return cat.localizedName(for: language)
        }
        return collectionId
    }

    /// Returns the SF Symbol icon name for a folder ID (`"All"` or an `InterestCategory.id`).
    func iconName(for collectionId: String) -> String {
        if collectionId == "All" {
            return "tray.full.fill"
        }
        if let cat = InterestCategory.category(forId: collectionId) {
            return cat.iconName
        }
        return "folder.fill"
    }

    func entries(in collectionId: String) -> [BookmarkEntry] {
        if collectionId == "All" {
            var seen = Set<UUID>()
            return entries.filter { seen.insert($0.id).inserted }
        }
        return entries.filter { $0.collectionName == collectionId }
    }

    func entryCount(in collectionId: String) -> Int {
        entries(in: collectionId).count
    }

    func moveToCollection(entryId: UUID, collectionId: String) {
        guard InterestCategory.category(forId: collectionId) != nil else { return }
        if let idx = entries.firstIndex(where: { $0.id == entryId }) {
            entries[idx].collectionName = collectionId
            save()
        }
    }

    // MARK: - Persistence & Automatic Migration

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([BookmarkEntry].self, from: data)
        else { return }

        // Deduplicate by post UUID (legacy versions created multiple entries per post, one per tag)
        // and ensure every entry's `collectionName` is a canonical Main Subject ID.
        var seen = Set<UUID>()
        var migrated: [BookmarkEntry] = []
        for var entry in decoded {
            guard seen.insert(entry.id).inserted else { continue }
            let mainCat = InterestCategory.resolveMainCategory(
                categoryId: entry.collectionName,
                tags: entry.tags,
                title: entry.title,
                text: entry.text,
                legacyCollectionName: entry.collectionName
            )
            entry.collectionName = mainCat.id
            migrated.append(entry)
        }
        entries = migrated
        save()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
