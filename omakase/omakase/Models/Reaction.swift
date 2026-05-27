//
//  Reaction.swift
//  omakase
//

import Foundation
import FirebaseFirestore

struct Reaction: Codable, Identifiable, Sendable {
    @DocumentID var id: String?   // The UID of the reactor
    let emoji: String
    let reactedAt: Date
}

enum ReactionEmoji: String, CaseIterable, Sendable {
    case mindBlown = "🤯"
    case fire = "🔥"
    case lightbulb = "💡"
    case laugh = "😂"
    case bullseye = "🎯"
}
