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
    var collectionName: String = "All"

    init(from post: Post, collectionName: String = "All") {
        id = post.id
        title = post.title
        text = post.text
        tags = post.tags
        postCreatedAt = post.createdAt
        savedAt = Date()
        self.collectionName = collectionName
    }

    /// Backward-compatible decoding: bookmarks saved before the `tags` or
    /// `collectionName` fields existed will decode with sensible defaults.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        text = try c.decode(String.self, forKey: .text)
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
        postCreatedAt = try c.decode(Date.self, forKey: .postCreatedAt)
        savedAt = try c.decode(Date.self, forKey: .savedAt)
        collectionName = (try? c.decode(String.self, forKey: .collectionName)) ?? "All"
    }
}

@Observable
@MainActor
final class BookmarkStore {

    private(set) var entries: [BookmarkEntry] = []
    private let defaultsKey = "omakase.bookmarks.v1"
    private let collectionsKey = "omakase.collections.v1"

    init() {
        load()
    }

    var count: Int { entries.count }

    func contains(postId: UUID) -> Bool {
        entries.contains { $0.id == postId }
    }

    func toggle(_ post: Post) {
        if let i = entries.firstIndex(where: { $0.id == post.id }) {
            entries.remove(at: i)
        } else {
            var entry = BookmarkEntry(from: post)
            entry.collectionName = "All"
            entries.insert(entry, at: 0)
        }
        save()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func removeAll(in collection: String? = nil) {
        if let collection {
            if collection == "All" {
                entries = []
            } else {
                entries.removeAll { $0.collectionName == collection }
            }
        } else {
            entries = []
        }
        save()
    }

    // MARK: - Collections

    /// All unique collection names, always starting with "All".
    var collectionNames: [String] {
        var names = ["All"]
        let custom = customCollections
        names.append(contentsOf: custom)
        return names
    }

    private var customCollections: [String] {
        get {
            guard let data = UserDefaults.standard.data(forKey: collectionsKey),
                  let names = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return names
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: collectionsKey)
            }
        }
    }

    func entries(in collection: String) -> [BookmarkEntry] {
        if collection == "All" {
            return entries
        }
        return entries.filter { $0.collectionName == collection }
    }

    func entryCount(in collection: String) -> Int {
        entries(in: collection).count
    }

    func createCollection(name: String) {
        guard !name.isEmpty, name != "All", !customCollections.contains(name) else { return }
        var cols = customCollections
        cols.append(name)
        customCollections = cols
    }

    func renameCollection(old: String, new: String) {
        guard old != "All", !new.isEmpty else { return }
        var cols = customCollections
        if let idx = cols.firstIndex(of: old) {
            cols[idx] = new
            customCollections = cols
            // Update all entries in old collection
            for i in entries.indices where entries[i].collectionName == old {
                entries[i].collectionName = new
            }
            save()
        }
    }

    func deleteCollection(name: String, deleteEntries: Bool = false) {
        guard name != "All" else { return }
        var cols = customCollections
        cols.removeAll { $0 == name }
        customCollections = cols
        if deleteEntries {
            entries.removeAll { $0.collectionName == name }
        } else {
            // Move entries back to "All"
            for i in entries.indices where entries[i].collectionName == name {
                entries[i].collectionName = "All"
            }
        }
        save()
    }

    func moveToCollection(entryId: UUID, collection: String) {
        if let idx = entries.firstIndex(where: { $0.id == entryId }) {
            entries[idx].collectionName = collection
            save()
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([BookmarkEntry].self, from: data) {
            entries = decoded
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
