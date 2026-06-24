//
//  Post.swift
//  omakase
//

import Foundation
import Observation

/// A single AI-generated post in the feed. `text` grows over time as SSE
/// tokens stream in, and `isComplete` flips to true when the `done` event
/// arrives.
///
/// Uses `@Observable` so SwiftUI can track per-property mutations without
/// needing to copy the entire `posts` array on every SSE token — the key fix
/// for scroll-stuttering during streaming.
@Observable
final class Post: Identifiable, @unchecked Sendable {
    let id: UUID
    /// Short headline from the model (`TITLE:` line); may be empty until the first SSE `title` event.
    var title: String
    var text: String
    var isComplete: Bool
    /// User interests this post relates to, parsed from the model's `TAGS:` line.
    var tags: [String]
    /// The format template used to generate this post (e.g. "DEBATE", "TIMELINE").
    var postFormat: String?
    /// Deep dive expansion text, if requested.
    var deepDiveText: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        text: String = "",
        isComplete: Bool = false,
        tags: [String] = [],
        postFormat: String? = nil,
        deepDiveText: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.isComplete = isComplete
        self.tags = tags
        self.postFormat = postFormat
        self.deepDiveText = deepDiveText
        self.createdAt = createdAt
    }
}

extension Post: Equatable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
}
