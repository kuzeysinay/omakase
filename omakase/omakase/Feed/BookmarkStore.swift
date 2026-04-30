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

    init(from post: Post) {
        id = post.id
        title = post.title
        text = post.text
        tags = post.tags
        postCreatedAt = post.createdAt
        savedAt = Date()
    }

    /// Backward-compatible decoding: bookmarks saved before the `tags` field
    /// existed will simply decode with an empty array.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        text = try c.decode(String.self, forKey: .text)
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
        postCreatedAt = try c.decode(Date.self, forKey: .postCreatedAt)
        savedAt = try c.decode(Date.self, forKey: .savedAt)
    }
}

@Observable
@MainActor
final class BookmarkStore {

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
        if let i = entries.firstIndex(where: { $0.id == post.id }) {
            entries.remove(at: i)
        } else {
            entries.insert(BookmarkEntry(from: post), at: 0)
        }
        save()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func removeAll() {
        entries = []
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([BookmarkEntry].self, from: data) {
            entries = decoded
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
