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

/// Single like reaction (Instagram-style). Legacy emoji reactions are still counted.
enum ReactionEmoji: String, CaseIterable, Sendable {
    case like = "like"
}
