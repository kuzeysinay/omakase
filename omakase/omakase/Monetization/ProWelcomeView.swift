//
//  ProWelcomeView.swift
//  omakase
//
//  Post-buy celebration & success screen displayed right after subscribing to
//  Omakase Pro, visualizing newly unlocked benefits with crisp monochrome
//  animations matching Omakase's editorial aesthetic.
//

import SwiftUI

struct ProWelcomeView: View {

    let planName: String
    let isTrial: Bool
    let trialDays: Int
    let onStartReading: () -> Void

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var medallionVisible = false
    @State private var headerVisible = false
    @State private var cardVisible = false
    @State private var visibleBenefitCount = 0
    @State private var ctaVisible = false
    @State private var pulseRings = false

    private var l10n: L10n { L10n(lang: appLanguage) }

    private var subtitleText: String {
        isTrial ? l10n.proWelcomeSubtitleTrial(trialDays) : l10n.proWelcomeSubtitlePaid
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            OmakaseASCIIBackdrop(reduceMotion: reduceMotion, opacityMultiplier: 0.92)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 16)

                heroSection

                Spacer(minLength: 20)

                benefitsCard
                    .padding(.horizontal, 20)

                Spacer(minLength: 20)

                bottomCTA
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .task {
            await runCelebrationSequence()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Concentric monochrome celebration medallion
            ZStack {
                Circle()
                    .strokeBorder(
                        OmakaseTheme.ink.opacity(pulseRings ? 0.05 : 0.22),
                        lineWidth: 1.5
                    )
                    .frame(width: 144, height: 144)
                    .scaleEffect(pulseRings ? 1.14 : 0.92)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                        value: pulseRings
                    )

                Circle()
                    .strokeBorder(
                        OmakaseTheme.ink.opacity(pulseRings ? 0.14 : 0.30),
                        lineWidth: 1.5
                    )
                    .frame(width: 114, height: 114)
                    .scaleEffect(pulseRings ? 1.06 : 0.96)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: pulseRings
                    )

                // Minimal monochrome confetti accents
                Group {
                    Text("✦")
                        .font(.system(size: 13, weight: .bold))
                        .offset(x: -58, y: -40)
                    Text("✦")
                        .font(.system(size: 10, weight: .bold))
                        .offset(x: 60, y: -32)
                    Text("∘")
                        .font(.system(size: 16, weight: .bold))
                        .offset(x: -52, y: 42)
                    Text("✦")
                        .font(.system(size: 11, weight: .bold))
                        .offset(x: 54, y: 44)
                }
                .foregroundStyle(OmakaseTheme.ink.opacity(0.65))
                .scaleEffect(medallionVisible ? 1 : 0.4)
                .opacity(medallionVisible ? 1 : 0)

                Circle()
                    .fill(OmakaseTheme.chipActiveFill)
                    .frame(width: 84, height: 84)
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.18),
                        radius: 16,
                        y: 6
                    )
                    .overlay(
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(OmakaseTheme.chipActiveText)
                    )
            }
            .scaleEffect(medallionVisible ? 1 : 0.6)
            .opacity(medallionVisible ? 1 : 0)

            // PRO + Active Plan Pills
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(OmakaseTheme.chipActiveText)
                        .frame(width: 5, height: 5)
                    Text("OMAKASE PRO")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .tracking(1.0)
                }
                .foregroundStyle(OmakaseTheme.chipActiveText)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(OmakaseTheme.chipActiveFill, in: Capsule())

                Text("\(planName) · \(l10n.proWelcomeBadgeActive)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
                    )
            }
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 10)

            VStack(spacing: 8) {
                Text(l10n.proWelcomeTitle)
                    .font(.system(size: 30, weight: .heavy, design: .default))
                    .tracking(-0.6)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 18)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)
        }
    }

    // MARK: - Unlocked Benefits Card

    private var benefitsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text(l10n.proWelcomeUnlockedHeader)
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(OmakaseTheme.ink)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .overlay(OmakaseTheme.stroke)

            benefitRow(
                index: 1,
                icon: "doc.text.fill",
                title: l10n.proComparePostsLabel,
                previousValue: l10n.proComparePostsFree,
                unlockedValue: l10n.proCompareUnlimited
            )

            Divider()
                .overlay(OmakaseTheme.stroke.opacity(0.6))
                .padding(.leading, 44)

            benefitRow(
                index: 2,
                icon: "fish.fill",
                title: l10n.proCompareDeepDiveLabel,
                previousValue: l10n.proCompareDeepDiveFree,
                unlockedValue: l10n.proCompareUnlimited
            )

            Divider()
                .overlay(OmakaseTheme.stroke.opacity(0.6))
                .padding(.leading, 44)

            benefitRow(
                index: 3,
                icon: "film.fill",
                title: l10n.proCompareLetterboxdLabel,
                previousValue: l10n.proCompareLetterboxdFree,
                unlockedValue: l10n.proCompareUnlimited
            )

            Divider()
                .overlay(OmakaseTheme.stroke.opacity(0.6))
                .padding(.leading, 44)

            benefitRow(
                index: 4,
                icon: "checkmark.seal.fill",
                title: l10n.proFeatureProBadge,
                previousValue: nil,
                unlockedValue: "PRO"
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(OmakaseTheme.cardSurface.opacity(colorScheme == .dark ? 0.55 : 0.45))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
        )
        .opacity(cardVisible ? 1 : 0)
        .offset(y: cardVisible ? 0 : 18)
    }

    private func benefitRow(
        index: Int,
        icon: String,
        title: String,
        previousValue: String?,
        unlockedValue: String
    ) -> some View {
        let isShown = visibleBenefitCount >= index

        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(OmakaseTheme.ink)
                .frame(width: 24, height: 24)
                .background(OmakaseTheme.wash, in: Circle())

            Text(title)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.84)

            Spacer(minLength: 6)

            HStack(spacing: 6) {
                if let previousValue {
                    Text(previousValue)
                        .font(.system(size: 11, weight: .medium))
                        .strikethrough(true, color: .secondary.opacity(0.65))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(unlockedValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(OmakaseTheme.chipActiveText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(OmakaseTheme.chipActiveFill, in: Capsule())
                    .lineLimit(1)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(OmakaseTheme.ink)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12.5)
        .opacity(isShown ? 1 : 0)
        .offset(y: isShown ? 0 : 8)
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 10) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onStartReading()
            } label: {
                HStack(spacing: 8) {
                    Text(l10n.proWelcomeStartCTA)
                        .font(.system(size: 17, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(OmakaseTheme.chipActiveText)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(OmakaseTheme.chipActiveFill)
                )
            }
            .buttonStyle(OmakaseChipButtonStyle())
            .accessibilityIdentifier("proWelcome.startButton")

            Text(l10n.proWelcomeManageNote)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(ctaVisible ? 1 : 0)
        .offset(y: ctaVisible ? 0 : 12)
    }

    // MARK: - Animation Sequence

    @MainActor
    private func runCelebrationSequence() async {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        if reduceMotion {
            medallionVisible = true
            headerVisible = true
            cardVisible = true
            visibleBenefitCount = 4
            ctaVisible = true
            return
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            medallionVisible = true
        }
        try? await Task.sleep(for: .milliseconds(90))
        pulseRings = true

        withAnimation(.easeOut(duration: 0.3)) {
            headerVisible = true
        }
        try? await Task.sleep(for: .milliseconds(110))

        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            cardVisible = true
        }

        for step in 1...4 {
            try? await Task.sleep(for: .milliseconds(90))
            withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                visibleBenefitCount = step
            }
        }

        try? await Task.sleep(for: .milliseconds(100))
        withAnimation(.easeOut(duration: 0.28)) {
            ctaVisible = true
        }
    }
}
