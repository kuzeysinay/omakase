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

    /// High-contrast monochrome tint for Toggles and Pickers (avoids white-on-white in Dark Mode).
    static var controlTint: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(white: 0.46, alpha: 1.0) : .black
        })
    }

    /// Elevated paper surface (white in Light Mode, secondary dark gray in Dark Mode).
    static var cardSurface: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? .secondarySystemBackground : .systemBackground
        })
    }
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

    private var parsedContent: ParsedPostContent {
        Post.splitBodyAndSource(from: text)
    }

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

                    Text(parsedContent.body)
                        .font(.body)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, parsedContent.source == nil ? 48 : 16)
                        .accessibilityIdentifier("deepdive.sheet.body")

                    if let source = parsedContent.source {
                        PostSourceView(source: source)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 48)
                    }
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
                    .accessibilityLabel(l10n.closeLabel)
                    .accessibilityIdentifier("deepdive.sheet.closeButton")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Gently Swaying Monochrome ASCII Sushi Backdrop

/// Calm, Hidden-Folks-inspired monochrome ASCII sushi sprites (nigiri, maki,
/// onigiri, temaki, ocha) drifting and swaying gently behind key screens.
struct OmakaseASCIIBackdrop: View {

    var reduceMotion: Bool = false
    var opacityMultiplier: Double = 1.0
    @Environment(\.colorScheme) private var colorScheme

    private struct SushiSprite: Identifiable {
        let id: Int
        let art: String
        let xFraction: CGFloat
        let yFraction: CGFloat
        let speed: Double
        let swayX: CGFloat
        let swayY: CGFloat
        let maxDegrees: Double
        let phase: Double
        let fontSize: CGFloat
    }

    private let sprites: [SushiSprite] = [
        SushiSprite(
            id: 0,
            art: """
             _____
            (~~~~~)
            [=====]
            """,
            xFraction: 0.14, yFraction: 0.08,
            speed: 0.55, swayX: 12, swayY: 5, maxDegrees: 3.5, phase: 0.0, fontSize: 12
        ),
        SushiSprite(
            id: 1,
            art: """
            .---.
            |(o)|
            '---'
            """,
            xFraction: 0.52, yFraction: 0.06,
            speed: -0.48, swayX: 10, swayY: 6, maxDegrees: 4.0, phase: 1.4, fontSize: 12
        ),
        SushiSprite(
            id: 2,
            art: """
              /\\
             /  \\
            /_[]_\\
            """,
            xFraction: 0.85, yFraction: 0.10,
            speed: 0.44, swayX: 11, swayY: 5, maxDegrees: 3.0, phase: 2.6, fontSize: 12
        ),
        SushiSprite(
            id: 3,
            art: """
            ====\\  ____
            ====/ (~~~~)
                  [====]
            """,
            xFraction: 0.80, yFraction: 0.24,
            speed: -0.52, swayX: 14, swayY: 6, maxDegrees: 2.8, phase: 0.9, fontSize: 11.5
        ),
        SushiSprite(
            id: 4,
            art: """
             ( )
            |___|
            '---'
            """,
            xFraction: 0.12, yFraction: 0.25,
            speed: 0.46, swayX: 9, swayY: 5, maxDegrees: 2.5, phase: 3.1, fontSize: 11.5
        ),
        SushiSprite(
            id: 5,
            art: """
            \\o~o/
             \\ /
              V
            """,
            xFraction: 0.10, yFraction: 0.45,
            speed: -0.50, swayX: 11, swayY: 6, maxDegrees: 4.2, phase: 2.1, fontSize: 12
        ),
        SushiSprite(
            id: 6,
            art: """
            .---. .---.
            |(o)| |(o)|
            '---' '---'
            """,
            xFraction: 0.86, yFraction: 0.43,
            speed: 0.40, swayX: 13, swayY: 5, maxDegrees: 2.5, phase: 4.2, fontSize: 11.5
        ),
        SushiSprite(
            id: 7,
            art: """
             _____
            (~~~~~)
            [=====]
            """,
            xFraction: 0.22, yFraction: 0.60,
            speed: 0.54, swayX: 14, swayY: 5, maxDegrees: 3.2, phase: 5.0, fontSize: 12
        ),
        SushiSprite(
            id: 8,
            art: """
              /\\
             /  \\
            /_[]_\\
            """,
            xFraction: 0.84, yFraction: 0.64,
            speed: -0.45, swayX: 12, swayY: 5, maxDegrees: 3.5, phase: 1.7, fontSize: 12
        ),
        SushiSprite(
            id: 9,
            art: """
            .---.
            |(o)|
            '---'
            """,
            xFraction: 0.14, yFraction: 0.77,
            speed: 0.48, swayX: 11, swayY: 5, maxDegrees: 3.8, phase: 3.3, fontSize: 12
        ),
        SushiSprite(
            id: 10,
            art: """
            ====\\  ____
            ====/ (~~~~)
                  [====]
            """,
            xFraction: 0.78, yFraction: 0.80,
            speed: -0.42, swayX: 13, swayY: 5, maxDegrees: 2.6, phase: 0.4, fontSize: 11.5
        ),
        SushiSprite(
            id: 11,
            art: """
             ( )
            |___|
            '---'
            """,
            xFraction: 0.20, yFraction: 0.92,
            speed: -0.52, swayX: 10, swayY: 4, maxDegrees: 2.4, phase: 2.8, fontSize: 11.5
        ),
        SushiSprite(
            id: 12,
            art: """
            \\o~o/
             \\ /
              V
            """,
            xFraction: 0.82, yFraction: 0.93,
            speed: 0.50, swayX: 10, swayY: 4, maxDegrees: 3.6, phase: 4.6, fontSize: 12
        ),
        SushiSprite(
            id: 13,
            art: "·  ✦  ·",
            xFraction: 0.36, yFraction: 0.16,
            speed: 0.65, swayX: 8, swayY: 4, maxDegrees: 0, phase: 0.5, fontSize: 12
        ),
        SushiSprite(
            id: 14,
            art: "~  ∘  ~",
            xFraction: 0.52, yFraction: 0.70,
            speed: -0.60, swayX: 9, swayY: 4, maxDegrees: 0, phase: 3.7, fontSize: 12
        )
    ]

    var body: some View {
        SwiftUI.TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0.0 : context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let baseOpacity = (colorScheme == .dark ? 0.26 : 0.21) * opacityMultiplier

                ZStack {
                    ForEach(sprites) { sprite in
                        let dx = CGFloat(sin(t * sprite.speed + sprite.phase)) * sprite.swayX
                        let dy = CGFloat(cos(t * abs(sprite.speed) * 0.85 + sprite.phase)) * sprite.swayY
                        let angle = sin(t * sprite.speed * 0.7 + sprite.phase) * sprite.maxDegrees
                        let pulse = 0.82 + 0.18 * sin(t * 0.6 + sprite.phase)

                        Text(sprite.art)
                            .font(.system(size: sprite.fontSize, weight: .semibold, design: .monospaced))
                            .lineSpacing(1)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(OmakaseTheme.ink.opacity(baseOpacity * pulse))
                            .rotationEffect(.degrees(angle))
                            .position(
                                x: geo.size.width * sprite.xFraction + dx,
                                y: geo.size.height * sprite.yFraction + dy
                            )
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
