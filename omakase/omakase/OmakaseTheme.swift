//
//  OmakaseTheme.swift
//  omakase
//
//  Monochrome palette inspired by Hidden Folks — ink on paper, no accent colors.
//

import SwiftUI

enum OmakaseTheme {

    /// Primary ink color (black in light mode, white in dark mode).
    static let ink = Color.primary

    /// Paper-like background wash for cards and sections.
    static let wash = Color.primary.opacity(0.06)

    /// Sketch-style stroke for borders and outlines.
    static let stroke = Color.primary.opacity(0.15)

    /// Active taste-chip fill — always reads as solid black ink on paper.
    static var chipActiveFill: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : .black
        })
    }

    /// Text on active chips — high contrast against chipActiveFill.
    static var chipActiveText: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? .black : .white
        })
    }

    /// Inactive chip outline.
    static let chipInactiveStroke = Color.primary.opacity(0.28)
}

/// Prevents the default Button highlight flash on long-press / context-menu release.
struct OmakaseChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.92 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Shared deep-dive reader sheet — consistent across feed, timeline, and bookmarks.
struct DeepDiveReaderSheet: View {

    let text: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Decorative header band
                    HStack(spacing: 10) {
                        Image(systemName: "fish.fill")
                            .font(.title2)
                            .foregroundStyle(OmakaseTheme.ink)
                        Text(title)
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(OmakaseTheme.wash)

                    Divider()

                    let clean = String(text.drop(while: { $0.isWhitespace || $0.isNewline }))
                    Text(clean)
                        .font(.body)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(l10n.lang == .turkish ? "Kapat" : "Close")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
