//
//  ShareCardView.swift
//  omakase
//
//  Deterministic monochrome editorial card rendered via ImageRenderer for sharing.
//

import SwiftUI

enum ShareCardTheme: String, CaseIterable, Identifiable, Equatable {
    case paper
    case ink
    case editorial
    case midnight

    var id: String { rawValue }

    static func defaultTheme(for colorScheme: ColorScheme) -> ShareCardTheme {
        colorScheme == .dark ? .ink : .paper
    }

    var isFramed: Bool {
        self == .editorial || self == .midnight
    }

    var isDark: Bool {
        self == .ink || self == .midnight
    }

    var outerBackground: Color {
        switch self {
        case .paper:     return Color(hex: 0xFFFFFF)
        case .ink:       return Color(hex: 0x0B0B0D)
        case .editorial: return Color(hex: 0xEFEFF2)
        case .midnight:  return Color(hex: 0x000000)
        }
    }

    var cardBackground: Color {
        switch self {
        case .paper:     return Color(hex: 0xFFFFFF)
        case .ink:       return Color(hex: 0x0B0B0D)
        case .editorial: return Color(hex: 0xFFFFFF)
        case .midnight:  return Color(hex: 0x141417)
        }
    }

    var ink: Color {
        isDark ? Color(hex: 0xFAFAFC) : Color(hex: 0x0D0D0F)
    }

    var secondaryInk: Color {
        ink.opacity(0.58)
    }

    var wash: Color {
        isDark ? Color.white.opacity(0.06) : Color(hex: 0x0D0D0F).opacity(0.045)
    }

    var stroke: Color {
        isDark ? Color.white.opacity(0.12) : Color(hex: 0x0D0D0F).opacity(0.10)
    }

    var swatchPrimary: Color {
        outerBackground
    }

    var swatchAccent: Color {
        cardBackground
    }

    var swatchBorder: Color {
        isDark ? Color.white.opacity(0.28) : Color(hex: 0x0D0D0F).opacity(0.22)
    }

    func localizedTitle(l10n: L10n) -> String {
        switch self {
        case .paper:     return l10n.exportThemePaper
        case .ink:       return l10n.exportThemeInk
        case .editorial: return l10n.exportThemeEditorial
        case .midnight:  return l10n.exportThemeMidnight
        }
    }
}

enum ShareCardAspectRatio: String, CaseIterable, Identifiable, Equatable {
    case story
    case post
    case square

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .story:  return CGSize(width: 1080, height: 1920)
        case .post:   return CGSize(width: 1080, height: 1350)
        case .square: return CGSize(width: 1080, height: 1080)
        }
    }

    var ratio: CGFloat {
        size.width / size.height
    }

    var iconName: String {
        switch self {
        case .story:  return "rectangle.ratio.9.to.16"
        case .post:   return "rectangle.portrait"
        case .square: return "square"
        }
    }

    func localizedTitle(l10n: L10n) -> String {
        switch self {
        case .story:  return l10n.exportRatioStory
        case .post:   return l10n.exportRatioPost
        case .square: return l10n.exportRatioSquare
        }
    }
}

struct ShareCardConfig: Equatable {
    var theme: ShareCardTheme
    var aspectRatio: ShareCardAspectRatio = .post
    var showSource: Bool = true
    var showTags: Bool = true
    var showMotif: Bool = true
}

/// A deterministic SwiftUI view rendered as an image for sharing.
struct ShareCardView: View {
    let post: Post
    var config: ShareCardConfig = ShareCardConfig(theme: .paper)
    var language: AppLanguage = .english

    private var l10n: L10n { L10n(lang: language) }
    private var theme: ShareCardTheme { config.theme }
    private var aspect: ShareCardAspectRatio { config.aspectRatio }

    private var resolvedCategory: InterestCategory {
        InterestCategory.resolveMainCategory(
            categoryId: post.categoryId,
            tags: post.tags,
            title: post.title,
            text: post.cleanDisplayBody
        )
    }

    private var outerPadding: CGFloat {
        theme.isFramed ? (aspect == .square ? 52 : 60) : 0
    }

    private var contentHorizontalPadding: CGFloat {
        switch aspect {
        case .story:  return theme.isFramed ? 60 : 72
        case .post:   return theme.isFramed ? 58 : 68
        case .square: return theme.isFramed ? 52 : 64
        }
    }

    private var contentVerticalPadding: CGFloat {
        switch aspect {
        case .story:  return theme.isFramed ? 72 : 96
        case .post:   return theme.isFramed ? 56 : 68
        case .square: return theme.isFramed ? 46 : 56
        }
    }

    private var titleFontSize: CGFloat {
        let len = post.title.count
        switch aspect {
        case .story:
            return len > 70 ? 50 : 56
        case .post:
            return len > 70 ? 50 : 58
        case .square:
            return len > 70 ? 42 : 48
        }
    }

    private var bodyFontSize: CGFloat {
        let len = post.cleanDisplayBody.count
        switch aspect {
        case .story:
            if len > 420 { return 34 }
            if len > 280 { return 38 }
            return 42
        case .post:
            if len > 420 { return 30 }
            if len > 280 { return 34 }
            return 37
        case .square:
            if len > 420 { return 26 }
            if len > 280 { return 29 }
            return 32
        }
    }

    private var formattedBodyAttributed: AttributedString {
        let raw = post.cleanDisplayBody
        return (try? AttributedString(
            markdown: raw,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(raw)
    }

    private func formattedSourceLine(_ raw: String) -> AttributedString {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var prefix = AttributedString("\(l10n.postSourceLabel): ")
        prefix.foregroundColor = theme.ink.opacity(0.52)

        var citation = (try? AttributedString(
            markdown: trimmed,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(trimmed)
        citation.foregroundColor = theme.ink.opacity(0.80)
        return prefix + citation
    }

    var body: some View {
        ZStack {
            // Outer mat background
            outerCanvasBackground

            if theme.isFramed {
                cardInterior
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 44, style: .continuous)
                            .strokeBorder(theme.stroke, lineWidth: 2)
                    )
                    .shadow(
                        color: theme.isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.08),
                        radius: 28,
                        x: 0,
                        y: 12
                    )
                    .padding(outerPadding)
            } else {
                cardInterior
            }
        }
        .frame(width: aspect.size.width, height: aspect.size.height)
    }

    @ViewBuilder
    private var outerCanvasBackground: some View {
        if theme == .ink {
            ZStack {
                theme.outerBackground
                RadialGradient(
                    colors: [
                        Color(hex: 0x16161A),
                        Color(hex: 0x0B0B0D)
                    ],
                    center: .top,
                    startRadius: 80,
                    endRadius: aspect.size.height * 0.85
                )
            }
        } else {
            theme.outerBackground
        }
    }

    private var cardInterior: some View {
        ZStack {
            if config.showMotif {
                staticMotifLayer
            }

            VStack(alignment: .leading, spacing: 0) {
                headerBar
                    .padding(.bottom, aspect == .square ? 26 : 32)

                Rectangle()
                    .fill(theme.stroke)
                    .frame(height: 1.5)

                Spacer(minLength: aspect == .square ? 20 : 32)

                contentBlock

                Spacer(minLength: aspect == .square ? 20 : 32)

                Rectangle()
                    .fill(theme.stroke)
                    .frame(height: 1.5)

                footerBar
                    .padding(.top, aspect == .square ? 24 : 30)
            }
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.vertical, contentVerticalPadding)
        }
    }

    // MARK: - Subtle Static ASCII Sushi Motifs

    private var staticMotifLayer: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Text("""
                     _____
                    (~~~~~)
                    [=====]
                    """)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .lineSpacing(2)
                    .foregroundStyle(theme.ink.opacity(0.055))
                    .rotationEffect(.degrees(7))
                    .padding(.top, aspect == .story ? 210 : 150)
                    .padding(.trailing, 54)
                }
                Spacer()
                HStack {
                    Text("""
                      /\\
                     /  \\
                    /_[]_\\
                    """)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .lineSpacing(2)
                    .foregroundStyle(theme.ink.opacity(0.055))
                    .rotationEffect(.degrees(-6))
                    .padding(.bottom, aspect == .story ? 210 : 150)
                    .padding(.leading, 54)
                    Spacer()
                }
            }

            if aspect == .story {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("""
                        .---.
                        |(o)|
                        '---'
                        """)
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .lineSpacing(2)
                        .foregroundStyle(theme.ink.opacity(0.045))
                        .rotationEffect(.degrees(4))
                        .padding(.trailing, 72)
                        .padding(.bottom, 420)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 14) {
                Image("AppLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(theme.ink)

                Text("omakase")
                    .font(.system(size: 36, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(theme.ink)
            }

            Spacer(minLength: 16)

            HStack(spacing: 10) {
                Image(systemName: resolvedCategory.iconName)
                    .font(.system(size: 21, weight: .semibold))
                Text(resolvedCategory.localizedName(for: language))
                    .font(.system(size: 22, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(theme.ink.opacity(0.84))
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(theme.wash, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(theme.stroke, lineWidth: 1.5)
            )
        }
    }

    // MARK: - Content

    private var contentBlock: some View {
        VStack(alignment: .leading, spacing: aspect == .square ? 22 : 28) {
            Text(post.title)
                .font(.system(size: titleFontSize, weight: .bold))
                .tracking(-0.6)
                .lineSpacing(4)
                .minimumScaleFactor(0.65)
                .foregroundStyle(theme.ink)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(formattedBodyAttributed)
                .font(.system(size: bodyFontSize, weight: .regular))
                .lineSpacing(aspect == .square ? 9 : 12)
                .minimumScaleFactor(0.65)
                .foregroundStyle(theme.ink.opacity(0.88))
                .lineLimit(aspect == .story ? 26 : (aspect == .square ? 14 : 18))
                .fixedSize(horizontal: false, vertical: true)

            if config.showSource, let source = post.sourceCitation {
                HStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(theme.ink.opacity(0.55))

                    Text(formattedSourceLine(source))
                        .font(.system(size: 22, weight: .regular))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 13)
                .background(theme.wash, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(theme.stroke, lineWidth: 1.5)
                )
                .padding(.top, 4)
            }

            if config.showTags, !post.tags.isEmpty {
                tagChips
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tagChips: some View {
        HStack(spacing: 12) {
            ForEach(post.tags.prefix(4), id: \.self) { rawTag in
                let cleanTag = rawTag.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).capitalized
                if !cleanTag.isEmpty {
                    Text(cleanTag)
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(theme.ink.opacity(0.75))
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(theme.wash, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(theme.stroke, lineWidth: 1.5)
                        )
                }
            }
        }
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack(spacing: 16) {
            Text(post.createdAt.localizedFormatted(for: language, date: .abbreviated, time: .omitted))
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(theme.secondaryInk)

            Spacer(minLength: 16)

            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 20, weight: .semibold))
                Text(ShareService.omakaseDisplayURL)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
            }
            .foregroundStyle(theme.ink)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(theme.wash, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(theme.stroke, lineWidth: 1.5)
            )
        }
    }
}
