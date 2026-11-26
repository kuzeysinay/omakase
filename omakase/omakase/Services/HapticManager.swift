//
//  HapticManager.swift
//  omakase
//
//  Subtle, tactile feedback helpers for key navigation, paging, and action moments.
//

import UIKit

@MainActor
enum HapticManager {

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
    }

    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.65)
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
