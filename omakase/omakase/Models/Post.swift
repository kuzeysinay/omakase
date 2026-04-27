//
//  Post.swift
//  omakase
//

import Foundation

/// A single AI-generated post in the feed. `text` grows over time as SSE
/// tokens stream in, and `isComplete` flips to true when the `done` event
/// arrives.
struct Post: Identifiable, Equatable, Sendable {
    let id: UUID
    /// Short headline from the model (`TITLE:` line); may be empty until the first SSE `title` event.
    var title: String
    var text: String
    var isComplete: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        text: String = "",
        isComplete: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.isComplete = isComplete
        self.createdAt = createdAt
    }
}
