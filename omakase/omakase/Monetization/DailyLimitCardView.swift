//
//  DailyLimitCardView.swift
//  omakase
//

import SwiftUI

struct DailyLimitCardView: View {

    let resetsAt: Date
    let hasExistingPosts: Bool
    var onScrollToLastPost: (() -> Void)? = nil
    let onUpgrade: () -> Void
    let onRemind: () -> Void

    @Environment(\.appLanguage) private var appLanguage

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        VStack(spacing: 24) {
            if hasExistingPosts, let onScrollToLastPost {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onScrollToLastPost()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.up")
                            .font(.caption.weight(.bold))
                        Text(l10n.limitCardBackToPlates)
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemBackground), in: Capsule())
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }

            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(width: 72, height: 72)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(OmakaseTheme.ink)
                }

                Text(l10n.limitCardTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("dailyLimit.title")

                Text(l10n.limitCardSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .fixedSize(horizontal: false, vertical: true)

                SwiftUI.TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let remaining = max(0, Int(resetsAt.timeIntervalSince(context.date)))
                    let formatted = Self.formatCountdown(remaining)
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption.weight(.bold))
                        Text(l10n.limitCardNextMenuIn(formatted))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .secondarySystemBackground), in: Capsule())
                    .foregroundStyle(.primary)
                }
            }

            VStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onUpgrade()
                } label: {
                    Text(l10n.limitCardUpgradeCTA)
                        .font(.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(OmakaseTheme.chipActiveFill)
                        )
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("dailyLimit.upgradeButton")

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onRemind()
                } label: {
                    Label(l10n.limitCardRemindCTA, systemImage: "bell")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("dailyLimit.remindButton")
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    private static func formatCountdown(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
