//
//  AppLanguage.swift
//  omakase
//

import SwiftUI

/// User-selected UI and API content language (BCP-47 tag sent to the backend).
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case turkish = "tr"

    var id: String { rawValue }

    /// Name shown in the language picker (each option in its own language).
    var pickerLabel: String {
        switch self {
        case .english: "English"
        case .turkish: "Türkçe"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english: "en_US"
        case .turkish: "tr_TR"
        }
    }
}

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .english
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}

// MARK: - Date Localization Helper

extension Date {
    /// Formats the date using the specified AppLanguage's locale so date & time strings
    /// (e.g. month names, 24h clock) correctly respect the in-app language setting.
    func localizedFormatted(
        for language: AppLanguage,
        date: Date.FormatStyle.DateStyle = .abbreviated,
        time: Date.FormatStyle.TimeStyle = .shortened
    ) -> String {
        formatted(
            Date.FormatStyle(
                date: date,
                time: time,
                locale: Locale(identifier: language.localeIdentifier)
            )
        )
    }
}
