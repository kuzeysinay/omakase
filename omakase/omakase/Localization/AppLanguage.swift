//
//  AppLanguage.swift
//  omakase
//

import SwiftUI

/// User-selected UI and API content language (BCP-47 tag sent to the backend).
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case turkish = "tr"
    case japanese = "ja"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case korean = "ko"

    var id: String { rawValue }

    /// Name shown in the language picker (each option in its own language).
    var pickerLabel: String {
        switch self {
        case .english: "English"
        case .turkish: "Türkçe"
        case .japanese: "日本語"
        case .german: "Deutsch"
        case .french: "Français"
        case .spanish: "Español"
        case .korean: "한국어"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english: "en_US"
        case .turkish: "tr_TR"
        case .japanese: "ja_JP"
        case .german: "de_DE"
        case .french: "fr_FR"
        case .spanish: "es_ES"
        case .korean: "ko_KR"
        }
    }

    /// Resolves the best matching supported language from the device's preferred languages.
    static var systemDefault: AppLanguage {
        for preferred in Locale.preferredLanguages {
            let lower = preferred.lowercased()
            let base = lower.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? lower
            if let match = AppLanguage(rawValue: base) {
                return match
            }
        }
        return .english
    }

    /// Returns the persisted language if present, otherwise falls back to `systemDefault`.
    static func resolved(from defaults: UserDefaults = .standard) -> AppLanguage {
        if let code = defaults.string(forKey: "omakase.language"),
           let stored = AppLanguage(rawValue: code) {
            return stored
        }
        return systemDefault
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
