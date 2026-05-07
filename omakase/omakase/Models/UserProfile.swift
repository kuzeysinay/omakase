//
//  UserProfile.swift
//  omakase
//

import Foundation
import FirebaseFirestore

/// Firestore document model for a user profile (`users/{uid}`).
struct UserProfile: Codable, Identifiable, Equatable, Sendable {
    /// Firebase Auth UID — also the Firestore document ID.
    var id: String
    var displayName: String
    var email: String
    var photoURL: String?
    var interests: [String]
    var createdAt: Date
    /// Lowercase version of displayName for case-insensitive search.
    var searchableName: String

    init(
        id: String,
        displayName: String,
        email: String,
        photoURL: String? = nil,
        interests: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.interests = interests
        self.createdAt = createdAt
        self.searchableName = displayName.lowercased()
    }
}
