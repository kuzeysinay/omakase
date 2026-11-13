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
    /// Public visible name (e.g. "Kuzey Sınay").
    var displayName: String
    /// Unique @handle without the leading "@" (e.g. "kuzeysinay").
    var username: String?
    var email: String
    var photoURL: String?
    var interests: [String]
    var createdAt: Date
    /// Lowercase version of displayName for case-insensitive search.
    var searchableName: String
    /// Lowercase version of username for case-insensitive handle search.
    var searchableUsername: String?

    /// Returns the `@username` handle (falls back to email prefix if legacy profile lacks username).
    var formattedHandle: String {
        if let u = username?.trimmingCharacters(in: .whitespacesAndNewlines), !u.isEmpty {
            return u.hasPrefix("@") ? u : "@\(u)"
        }
        if let prefix = email.split(separator: "@").first, !prefix.isEmpty {
            return "@\(Self.sanitizeUsername(String(prefix)))"
        }
        return "@\(Self.sanitizeUsername(displayName))"
    }

    init(
        id: String,
        displayName: String,
        username: String? = nil,
        email: String,
        photoURL: String? = nil,
        interests: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        let cleanUsername = username.map { Self.sanitizeUsername($0) }
        self.username = (cleanUsername?.isEmpty == false) ? cleanUsername : nil
        self.email = email
        self.photoURL = photoURL
        self.interests = interests
        self.createdAt = createdAt
        self.searchableName = displayName.lowercased()
        self.searchableUsername = self.username?.lowercased()
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        displayName = try c.decode(String.self, forKey: .displayName)
        username = try c.decodeIfPresent(String.self, forKey: .username)
        // `email` is omitted from public Firestore documents to prevent PII harvesting (S-04).
        email = (try? c.decodeIfPresent(String.self, forKey: .email)) ?? ""
        photoURL = try c.decodeIfPresent(String.self, forKey: .photoURL)
        interests = (try? c.decodeIfPresent([String].self, forKey: .interests)) ?? []
        createdAt = (try? c.decodeIfPresent(Date.self, forKey: .createdAt)) ?? .now
        searchableName = (try? c.decodeIfPresent(String.self, forKey: .searchableName)) ?? displayName.lowercased()
        searchableUsername = try c.decodeIfPresent(String.self, forKey: .searchableUsername) ?? username?.lowercased()
    }

    /// Normalizes a raw string into a valid Twitter-style handle (lowercase a-z, 0-9, underscore, dot).
    static func sanitizeUsername(_ raw: String) -> String {
        let transliterated = raw
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i")
            .lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_.")
        let filtered = transliterated.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered).prefix(20))
    }
}
