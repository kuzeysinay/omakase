//
//  PostSourceView.swift
//  omakase
//

import SwiftUI

/// Subtle, tappable footnote pill below a post that reveals the full citation
/// and a button to search the source name in the user's default browser.
struct PostSourceView: View {
    let source: String

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.openURL) private var openURL

    @State private var showSourcePopover = false

    private var l10n: L10n { L10n(lang: appLanguage) }

    private var uppercaseLabel: String {
        l10n.postSourceLabel.uppercased(with: Locale(identifier: appLanguage.localeIdentifier))
    }

    private var formattedSource: AttributedString {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        return (try? AttributedString(
            markdown: trimmed,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(trimmed)
    }

    private var plainAccessibilitySource: String {
        String(formattedSource.characters).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var inlinePillText: AttributedString {
        var prefix = AttributedString("\(l10n.postSourceLabel): ")
        prefix.foregroundColor = Color.secondary.opacity(0.75)
        var citation = formattedSource
        citation.foregroundColor = Color.secondary
        return prefix + citation
    }

    private var browserSearchURL: URL? {
        let query = plainAccessibilitySource
        guard !query.isEmpty, var components = URLComponents(string: "https://www.google.com/search") else {
            return nil
        }
        // Exclude Google iOS app Universal Links so iOS always opens the user's default browser (e.g. Chrome).
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "noiga", value: "1"),
            URLQueryItem(name: "iga", value: "0")
        ]
        return components.url
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            TelemetryService.shared.track("source_tapped")
            showSourcePopover = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "book.closed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)

                Text(inlinePillText)
                    .font(.system(size: 12, weight: .regular))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.035))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.6)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(l10n.postSourceLabel): \(plainAccessibilitySource)")
        .accessibilityHint(l10n.searchSourceInBrowser)
        .accessibilityIdentifier("post.source.button")
        .popover(isPresented: $showSourcePopover, arrowEdge: .top) {
            sourcePopoverContent
        }
    }

    @ViewBuilder
    private var sourcePopoverContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "book.closed")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(uppercaseLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
            }

            Text(formattedSource)
                .font(.system(size: 13.5, weight: .medium))
                .lineSpacing(3)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("post.source.popover.citation")

            if let url = browserSearchURL {
                Button {
                    showSourcePopover = false
                    TelemetryService.shared.track("source_opened_browser")
                    openURL(url)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12, weight: .semibold))
                        Text(l10n.searchSourceInBrowser)
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10.5, weight: .semibold))
                            .opacity(0.75)
                    }
                    .foregroundStyle(OmakaseTheme.chipActiveText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(OmakaseTheme.chipActiveFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("post.source.popover.searchButton")
            }
        }
        .padding(16)
        .frame(width: 280, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .environment(\.appLanguage, appLanguage)
        .presentationCompactAdaptation(.popover)
    }
}
