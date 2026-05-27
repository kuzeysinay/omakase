//
//  Comment.swift
//  omakase
//

import Foundation
import FirebaseFirestore

struct Comment: Codable, Identifiable, Equatable, Sendable {
    @DocumentID var id: String?
    let authorId: String
    let authorName: String
    let authorPhotoURL: String?
    let text: String
    let createdAt: Date
    var reportedBy: [String]?
}
