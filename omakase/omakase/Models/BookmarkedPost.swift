//
//  BookmarkedPost.swift
//  omakase
//

import Foundation

/// A post snapshot saved locally (feed `Post` is not persisted).
struct BookmarkedPost: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var text: String
    let createdAt: Date
    let savedAt: Date

    init(from post: Post) {
        id = post.id
        title = post.title
        text = post.text
        createdAt = post.createdAt
        savedAt = Date.now
    }
}
