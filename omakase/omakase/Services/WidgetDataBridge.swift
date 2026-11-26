//
//  WidgetDataBridge.swift
//  omakase
//
//  App Group bridge sharing monthly read count (no streaks), active UI language,
//  and live AI-discovered subtopics between the main app and omakaseWidget.
//

import Foundation
import WidgetKit

@MainActor
enum WidgetDataBridge {
    nonisolated static let appGroupID = "group.kuzeysinay.omakase"
    nonisolated static let widgetKind = "kuzeysinay.omakase.daily-tastes"

    private enum Keys {
        static let monthKey = "omakase.widget.monthKey"
        static let monthlyReadCount = "omakase.widget.monthlyReadCount"
        static let language = "omakase.widget.language"
        static let subtopicsByCategory = "omakase.widget.subtopicsByCategory"
    }

    private static var lastSubtopicReloadDate: Date = .distantPast

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func currentMonthKey(for date: Date = Date()) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        return String(format: "%04d-%02d", year, month)
    }

    static func monthlyReadCount(for date: Date = Date()) -> Int {
        let defaults = sharedDefaults
        let activeKey = currentMonthKey(for: date)
        guard defaults.string(forKey: Keys.monthKey) == activeKey else {
            return 0
        }
        return max(0, defaults.integer(forKey: Keys.monthlyReadCount))
    }

    static func incrementMonthlyReadCount() {
        let defaults = sharedDefaults
        let activeKey = currentMonthKey()
        let current = (defaults.string(forKey: Keys.monthKey) == activeKey)
            ? max(0, defaults.integer(forKey: Keys.monthlyReadCount))
            : 0
        defaults.set(activeKey, forKey: Keys.monthKey)
        defaults.set(current + 1, forKey: Keys.monthlyReadCount)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func syncLanguage(_ language: AppLanguage) {
        let defaults = sharedDefaults
        let previous = defaults.string(forKey: Keys.language)
        if previous != language.rawValue {
            defaults.set(language.rawValue, forKey: Keys.language)
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        }
    }

    static func syncSubtopics(categoryId: String, topics: [String], language: AppLanguage) {
        guard language == AppLanguage.resolved() else { return }
        let clean = topics
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !clean.isEmpty else { return }

        let defaults = sharedDefaults
        var map: [String: [String]] = [:]
        if let data = defaults.data(forKey: Keys.subtopicsByCategory),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            map = decoded
        }
        map[categoryId] = Array(clean.prefix(12))

        if let encoded = try? JSONEncoder().encode(map) {
            defaults.set(encoded, forKey: Keys.subtopicsByCategory)
        }

        let now = Date()
        if now.timeIntervalSince(lastSubtopicReloadDate) >= 15 {
            lastSubtopicReloadDate = now
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        }
    }
}
