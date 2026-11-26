//
//  OmakaseWidget.swift
//  omakaseWidget
//
//  Minimal monochrome Omakase home-screen widget displaying monthly read count
//  (without streaks) and size-adaptive random subtopics that open directly
//  into post generation.
//

import SwiftUI
import WidgetKit

struct OmakaseWidgetEntry: TimelineEntry {
    let date: Date
    let monthlyReadCount: Int
    let language: WidgetLanguage
    let topics: [WidgetTopicItem]
}

struct OmakaseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> OmakaseWidgetEntry {
        let language = WidgetLanguage.resolved(from: WidgetSharedStore.defaults)
        return OmakaseWidgetEntry(
            date: Date(),
            monthlyReadCount: 12,
            language: language,
            topics: WidgetTopicCatalog.previewTopics(count: 6, language: language)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (OmakaseWidgetEntry) -> Void) {
        let defaults = WidgetSharedStore.defaults
        let language = WidgetLanguage.resolved(from: defaults)
        if context.isPreview {
            completion(
                OmakaseWidgetEntry(
                    date: Date(),
                    monthlyReadCount: 14,
                    language: language,
                    topics: WidgetTopicCatalog.previewTopics(count: 6, language: language)
                )
            )
            return
        }

        let count = WidgetSharedStore.monthlyReadCount()
        let synced = WidgetSharedStore.syncedSubtopics()
        let topics = WidgetTopicCatalog.sampleTopics(
            count: 6,
            language: language,
            syncedByCategory: synced
        )
        completion(
            OmakaseWidgetEntry(
                date: Date(),
                monthlyReadCount: count,
                language: language,
                topics: topics
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OmakaseWidgetEntry>) -> Void) {
        let defaults = WidgetSharedStore.defaults
        let language = WidgetLanguage.resolved(from: defaults)
        let count = WidgetSharedStore.monthlyReadCount()
        let synced = WidgetSharedStore.syncedSubtopics()
        let now = Date()

        // Generate 6 future-dated entries (every 2 hours) so random subtopics refresh smoothly.
        var entries: [OmakaseWidgetEntry] = []
        for step in 0..<6 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: step * 2, to: now) ?? now
            let stepCount = WidgetSharedStore.monthlyReadCount(for: entryDate)
            let topics = WidgetTopicCatalog.sampleTopics(
                count: 6,
                language: language,
                syncedByCategory: synced
            )
            entries.append(
                OmakaseWidgetEntry(
                    date: entryDate,
                    monthlyReadCount: step == 0 ? count : stepCount,
                    language: language,
                    topics: topics
                )
            )
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct OmakaseWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: OmakaseWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallLayout
                    .widgetURL(entry.topics.first?.deepLinkURL ?? URL(string: "omakase://feed")!)
            case .systemMedium:
                mediumLayout
                    .widgetURL(URL(string: "omakase://feed")!)
            case .systemLarge:
                largeLayout
                    .widgetURL(URL(string: "omakase://feed")!)
            @unknown default:
                mediumLayout
                    .widgetURL(URL(string: "omakase://feed")!)
            }
        }
        .containerBackground(for: .widget) {
            Color(uiColor: .systemBackground)
        }
    }

    // MARK: - Small (1 featured subtopic + compact monthly read count)

    private var smallLayout: some View {
        let featured = entry.topics.first

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 4) {
                Text("omakase")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(-0.2)
                    .foregroundStyle(.primary)

                Spacer(minLength: 4)

                Text(entry.language.monthlyReadLabel(count: entry.monthlyReadCount, compact: true))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            if let item = featured {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: item.symbolName)
                            .font(.system(size: 10, weight: .semibold))
                        Text(item.categoryName.uppercased())
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .tracking(0.6)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)

                    Text(item.topic)
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.8)
                )
            }
        }
        .padding(2)
    }

    // MARK: - Medium (3 random subtopics across 3 categories)

    private var mediumLayout: some View {
        let items = Array(entry.topics.prefix(3))

        return VStack(alignment: .leading, spacing: 7) {
            headerRow

            VStack(spacing: 5) {
                ForEach(items) { item in
                    Link(destination: item.deepLinkURL) {
                        HStack(spacing: 8) {
                            Image(systemName: item.symbolName)
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 22, height: 22)
                                .background(Color.primary.opacity(0.08), in: Circle())

                            Text(item.topic)
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer(minLength: 4)

                            Text(item.categoryName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.09), lineWidth: 0.7)
                        )
                    }
                }
            }
        }
        .padding(2)
    }

    // MARK: - Large (6 random subtopics in a 2×3 Bento grid)

    private var largeLayout: some View {
        let items = Array(entry.topics.prefix(6))
        let rows = stride(from: 0, to: items.count, by: 2).map { index in
            Array(items[index..<min(index + 2, items.count)])
        }

        return VStack(alignment: .leading, spacing: 10) {
            headerRow

            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, rowItems in
                    HStack(spacing: 8) {
                        ForEach(rowItems) { item in
                            Link(destination: item.deepLinkURL) {
                                bentoTile(item)
                            }
                        }
                        if rowItems.count == 1 {
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(2)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 6) {
            Text("omakase")
                .font(.system(size: 14.5, weight: .bold))
                .tracking(-0.2)
                .foregroundStyle(.primary)

            Spacer()

            Text(entry.language.monthlyReadLabel(count: entry.monthlyReadCount))
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.06), in: Capsule())
        }
    }

    private func bentoTile(_ item: WidgetTopicItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: item.symbolName)
                    .font(.system(size: 11, weight: .semibold))
                Text(item.categoryName.uppercased())
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .tracking(0.5)
                    .lineLimit(1)
                Spacer(minLength: 2)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(item.topic)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.8)
        )
    }
}

struct OmakaseDailyTastesWidget: Widget {
    let kind: String = "kuzeysinay.omakase.daily-tastes"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OmakaseWidgetProvider()) { entry in
            OmakaseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Omakase")
        .description("Tap any subtopic to read a primary-sourced micro-story.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
