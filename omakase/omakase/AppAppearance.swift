//
//  AppAppearance.swift
//  omakase
//

import SwiftUI

/// User-selected appearance mode: system default, light, or dark.
enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var id: String { rawValue }

    /// The SwiftUI `ColorScheme` to apply, or `nil` for system default.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }

    /// SF Symbol name for display in the picker row.
    var iconName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max.fill"
        case .dark:   "moon.fill"
        }
    }

    /// Icon tint color.
    var iconColor: Color {
        switch self {
        case .system: .purple
        case .light:  .orange
        case .dark:   .indigo
        }
    }
}
