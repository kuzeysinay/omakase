//
//  SharedPost.swift
//  omakase
//

import Foundation
import FirebaseFirestore

/// A post that a user chose to share to the communal timeline.
/// Stored in Firestore at `shared_posts/{autoId}`.
struct SharedPost: Codable, Identifiable, Equatable, Sendable {
    /// Firestore auto-generated document ID (set after reading back).
    @DocumentID var id: String?
    var authorId: String
    var authorName: String
    var authorPhotoURL: String?
    var title: String
    var text: String
    var tags: [String]
    var originalCreatedAt: Date
    var sharedAt: Date
    /// Deep dive expansion text, included when the original post had one at share time.
    var deepDiveText: String?
    var reactionCounts: [String: Int]?
    var totalReactions: Int?
    var commentCount: Int?

    init(
        authorId: String,
        authorName: String,
        authorPhotoURL: String? = nil,
        title: String,
        text: String,
        tags: [String],
        originalCreatedAt: Date,
        sharedAt: Date = .now,
        deepDiveText: String? = nil,
        reactionCounts: [String: Int]? = nil,
        totalReactions: Int? = nil,
        commentCount: Int? = nil
    ) {
        self.authorId = authorId
        self.authorName = authorName
        self.authorPhotoURL = authorPhotoURL
        self.title = title
        self.text = text
        self.tags = tags
        self.originalCreatedAt = originalCreatedAt
        self.sharedAt = sharedAt
        self.deepDiveText = deepDiveText
        self.reactionCounts = reactionCounts
        self.totalReactions = totalReactions
        self.commentCount = commentCount
    }
}
