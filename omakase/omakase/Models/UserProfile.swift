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
    /// Last timestamp when `@username` was updated (enforces 14-day cooldown).
    var usernameUpdatedAt: Date?
    /// True once the user has explicitly confirmed their display name & unique @username.
    var profileSetupCompleted: Bool?

    static let usernameCooldownDays: Int = 14

    /// Days remaining before the user can change their `@username` again (0 if allowed now).
    var daysUntilNextUsernameChange: Int {
        guard let lastChanged = usernameUpdatedAt else { return 0 }
        guard let nextAllowed = Calendar.current.date(byAdding: .day, value: Self.usernameCooldownDays, to: lastChanged) else {
            return 0
        }
        let remaining = nextAllowed.timeIntervalSinceNow
        guard remaining > 0 else { return 0 }
        return max(1, Int(ceil(remaining / 86_400.0)))
    }

    var canChangeUsernameNow: Bool {
        daysUntilNextUsernameChange == 0
    }

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
        createdAt: Date = .now,
        usernameUpdatedAt: Date? = nil,
        profileSetupCompleted: Bool? = nil
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
        self.usernameUpdatedAt = usernameUpdatedAt
        self.profileSetupCompleted = profileSetupCompleted
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case username
        case email
        case photoURL
        case interests
        case createdAt
        case searchableName
        case searchableUsername
        case usernameUpdatedAt
        case profileSetupCompleted
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
        usernameUpdatedAt = try? c.decodeIfPresent(Date.self, forKey: .usernameUpdatedAt)
        profileSetupCompleted = try? c.decodeIfPresent(Bool.self, forKey: .profileSetupCompleted)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(displayName, forKey: .displayName)
        try c.encodeIfPresent(username, forKey: .username)
        // `email` is intentionally omitted from Firestore writes (S-04 / S-19).
        try c.encodeIfPresent(photoURL, forKey: .photoURL)
        try c.encode(interests, forKey: .interests)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(searchableName, forKey: .searchableName)
        try c.encodeIfPresent(searchableUsername, forKey: .searchableUsername)
        try c.encodeIfPresent(usernameUpdatedAt, forKey: .usernameUpdatedAt)
        try c.encodeIfPresent(profileSetupCompleted, forKey: .profileSetupCompleted)
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
