//
//  BookmarksStore.swift
//  omakase
//

import Foundation
import Observation

@Observable
final class BookmarksStore {

    static let shared = BookmarksStore()

    private(set) var items: [BookmarkedPost] = []

    private let defaultsKey = "omakase.bookmarks.v1"

    private init() {
        load()
    }

    func contains(postID: UUID) -> Bool {
        items.contains { $0.id == postID }
    }

    func toggle(_ post: Post) {
        let trimmed = post.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard post.isComplete, !trimmed.isEmpty else { return }
        if let index = items.firstIndex(where: { $0.id == post.id }) {
            items.remove(at: index)
        } else {
            items.insert(BookmarkedPost(from: post), at: 0)
        }
        save()
    }

    func remove(at offsets: IndexSet) {
        items = items.enumerated().filter { !offsets.contains($0.offset) }.map(\.element)
        save()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode([BookmarkedPost].self, from: data)
        else {
            items = []
            return
        }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
