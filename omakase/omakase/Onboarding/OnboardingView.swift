//
//  OnboardingView.swift
//  omakase
//
//  Zero-friction 3-slide introduction over swaying ASCII sushi.
//  Completing or skipping seeds sensible default categories and drops
//  the user straight into the main feed (HIG Rule 2 & Rule 6 + MPTV).
//

import SwiftUI

struct OnboardingView: View {

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("omakase.interests") private var storedInterests: String = ""
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false

    var authService: AuthService? = nil

    @State private var introPage: Int = 0

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            OmakaseASCIIBackdrop(
                reduceMotion: reduceMotion,
                opacityMultiplier: 0.95
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top brand & skip bar
                HStack {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                        Text(l10n.appTitle)
                            .font(.system(size: 19, weight: .bold))
                            .tracking(-0.3)
                    }

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        completeOnboarding()
                    } label: {
                        Text(l10n.introSkip)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)

                // Paged intro slides
                TabView(selection: $introPage) {
                    introSlide1.tag(0)
                    introSlide2.tag(1)
                    introSlide3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: introPage)

                // Page indicators + primary CTA
                VStack(spacing: 18) {
                    HStack(spacing: 7) {
                        ForEach(0..<3, id: \.self) { index in
                            Capsule()
                                .fill(index == introPage ? OmakaseTheme.ink : Color.primary.opacity(0.18))
                                .frame(width: index == introPage ? 26 : 8, height: 6)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: introPage)
                        }
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if introPage < 2 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                introPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(introPage < 2 ? l10n.introNext : l10n.onboardingStartFeed)
                                .font(.system(size: 16.5, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(OmakaseTheme.chipActiveFill)
                        )
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                    }
                    .buttonStyle(OmakaseChipButtonStyle())
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
            }
        }
    }

    // MARK: - Slides

    private var introSlide1: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(OmakaseTheme.ink)
                        .frame(width: 6, height: 6)
                    Text(l10n.introSlide1SampleTag)
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .tracking(0.9)
                        .foregroundStyle(.secondary)
                }

                Text(l10n.introSlide1SampleText)
                    .font(.system(size: 15.5, weight: .medium))
                    .lineSpacing(4)
                    .foregroundStyle(.primary)

                Divider()
                    .overlay(OmakaseTheme.stroke)

                HStack(spacing: 6) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 11, weight: .semibold))
                    Text(l10n.introSlide1SampleSource)
                        .font(.system(size: 11.5, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
            )

            slideCopy(
                eyebrow: l10n.introSlide1Eyebrow,
                title: l10n.introSlide1Title,
                body: l10n.introSlide1Body
            )

            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private var introSlide2: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(OmakaseTheme.wash, in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.introSlide2Metric1)
                            .font(.system(size: 14, weight: .bold))
                        GeometryReader { barGeo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.primary.opacity(0.12))
                                Capsule()
                                    .fill(OmakaseTheme.ink)
                                    .frame(width: barGeo.size.width * 0.68)
                            }
                        }
                        .frame(height: 5)
                    }
                }

                Divider()
                    .overlay(OmakaseTheme.stroke)

                HStack(spacing: 10) {
                    Image(systemName: "fish.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(OmakaseTheme.chipActiveFill, in: Circle())
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                    Text(l10n.introSlide2Metric2)
                        .font(.system(size: 14, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
            )

            slideCopy(
                eyebrow: l10n.introSlide2Eyebrow,
                title: l10n.introSlide2Title,
                body: l10n.introSlide2Body
            )

            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private var introSlide3: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    featurePill(icon: "paperplane.fill", text: l10n.introSlide3Pill1)
                    featurePill(icon: "bookmark.fill", text: l10n.introSlide3Pill2)
                }

                HStack(spacing: 10) {
                    Image(systemName: "film")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(OmakaseTheme.chipActiveFill, in: Circle())
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                    Text(l10n.introSlide3Pill3)
                        .font(.system(size: 14.5, weight: .bold))
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.primary.opacity(0.35)).frame(width: 8, height: 8)
                        Circle().fill(Color.primary.opacity(0.65)).frame(width: 8, height: 8)
                        Circle().fill(OmakaseTheme.ink).frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
            )

            slideCopy(
                eyebrow: l10n.introSlide3Eyebrow,
                title: l10n.introSlide3Title,
                body: l10n.introSlide3Body
            )

            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 12.5, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func slideCopy(eyebrow: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.1)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(size: 30, weight: .heavy))
                .tracking(-0.5)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(body)
                .font(.system(size: 15.5))
                .lineSpacing(3.5)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        let existing = FeedView.parse(interests: storedInterests)
        let finalInterests: [String]
        if existing.isEmpty {
            finalInterests = InterestCategory.presets.prefix(3).map { $0.localizedName(for: appLanguage) }
            storedInterests = finalInterests.joined(separator: ", ")
        } else {
            finalInterests = existing
        }

        hasOnboarded = true

        if let uid = authService?.uid {
            Task {
                try? await FirestoreService.shared.updateInterests(finalInterests, uid: uid)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
