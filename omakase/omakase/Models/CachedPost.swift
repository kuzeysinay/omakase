//
//  CachedPost.swift
//  omakase
//

import Foundation
import SwiftData

@Model
final class CachedPost {
    @Attribute(.unique) var postId: UUID
    var title: String
    var text: String
    var tags: [String]
    var postFormat: String?
    var deepDiveText: String?
    var createdAt: Date
    var cachedAt: Date

    init(from post: Post) {
        self.postId = post.id
        self.title = post.title
        self.text = post.text
        self.tags = post.tags
        self.postFormat = post.postFormat
        self.deepDiveText = post.deepDiveText
        self.createdAt = post.createdAt
        self.cachedAt = Date()
    }

    func toPost() -> Post {
        Post(
            title: title,
            text: text,
            isComplete: true,
            tags: tags,
            postFormat: postFormat,
            deepDiveText: deepDiveText,
            createdAt: createdAt
        )
    }
}
