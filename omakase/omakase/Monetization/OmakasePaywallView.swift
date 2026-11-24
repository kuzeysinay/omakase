//
//  OmakasePaywallView.swift
//  omakase
//
//  Immersive monochrome paywall with gently swaying ASCII backdrop,
//  context-aware trigger copy, Free vs. Pro comparison, and StoreKit 2 /
//  RevenueCat yearly-first plan presentation.
//

import RevenueCat
import SwiftUI

enum PaywallSource: String, Identifiable, Sendable {
    case firstPlateSoft
    case plateLimit
    case deepDiveLimit
    case profile

    var id: String { rawValue }
}

private enum PaywallPlanSelection: Equatable {
    case yearly
    case monthly
}

struct OmakasePaywallView: View {

    let source: PaywallSource
    var onToast: ((String) -> Void)? = nil

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var accessManager = AccessManager.shared
    @State private var selectedPlan: PaywallPlanSelection = .yearly
    @State private var localToastMessage: String?

    private var l10n: L10n { L10n(lang: appLanguage) }

    // MARK: - Packages & Pricing

    private var annualPackage: Package? { accessManager.annualPackage }
    private var monthlyPackage: Package? { accessManager.monthlyPackage }

    private var selectedPackage: Package? {
        switch selectedPlan {
        case .yearly: return annualPackage ?? monthlyPackage
        case .monthly: return monthlyPackage ?? annualPackage
        }
    }

    private var annualPriceString: String {
        annualPackage?.localizedPriceString ?? "₺499,99"
    }

    private var monthlyPriceString: String {
        monthlyPackage?.localizedPriceString ?? "₺49,99"
    }

    private var annualPerMonthString: String? {
        annualPackage?.storeProduct.localizedPricePerMonth
    }

    private var yearlySavingsPercent: Int? {
        guard
            let annualPrice = annualPackage?.storeProduct.price,
            let monthlyPrice = monthlyPackage?.storeProduct.price,
            monthlyPrice > 0
        else { return nil }
        let annualizedMonthly = NSDecimalNumber(decimal: monthlyPrice * 12).doubleValue
        let yearlyDouble = NSDecimalNumber(decimal: annualPrice).doubleValue
        guard annualizedMonthly > yearlyDouble, annualizedMonthly > 0 else { return nil }
        let pct = Int(((annualizedMonthly - yearlyDouble) / annualizedMonthly * 100.0).rounded())
        return pct >= 5 ? pct : nil
    }

    private var yearlyHasFreeTrial: Bool {
        if let intro = annualPackage?.storeProduct.introductoryDiscount {
            return intro.paymentMode == .freeTrial
        }
        return true
    }

    private var yearlyTrialDays: Int {
        guard let intro = annualPackage?.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else { return 7 }
        let period = intro.subscriptionPeriod
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        @unknown default: return 7
        }
    }

    // MARK: - Context-Aware Copy

    private var eyebrowText: String {
        switch source {
        case .plateLimit: return l10n.proEyebrowPlateLimit
        case .deepDiveLimit: return l10n.proEyebrowDeepDiveLimit
        case .firstPlateSoft, .profile: return "OMAKASE PRO"
        }
    }

    private var headlineText: String {
        switch source {
        case .plateLimit: return l10n.proHeadlinePlateLimit
        case .deepDiveLimit: return l10n.proHeadlineDeepDiveLimit
        case .firstPlateSoft, .profile: return l10n.proHeadline
        }
    }

    private var ctaTitle: String {
        if selectedPlan == .yearly && yearlyHasFreeTrial {
            return l10n.proStartTrialCTA
        }
        return l10n.proSubscribeCTA
    }

    private var reassuranceText: String {
        if selectedPlan == .yearly && yearlyHasFreeTrial {
            return l10n.proTrialReassurance
        }
        return l10n.proMonthlyReassurance
    }

    private var disclosureText: String {
        if selectedPlan == .yearly {
            return l10n.proYearlyDisclosure(annualPriceString)
        }
        return l10n.proMonthlyDisclosure(monthlyPriceString)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            // Gently swaying monochrome ASCII ocean / omakase counter backdrop
            OmakaseASCIIBackdrop(reduceMotion: reduceMotion)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        heroSection
                            .padding(.top, 26)
                        comparisonCard
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 20)
                }

                bottomDock
            }
        }
        .task {
            if accessManager.currentOffering == nil {
                await accessManager.loadOfferings()
            }
        }
        .toast(message: $localToastMessage)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Circle()
                    .fill(OmakaseTheme.ink)
                    .frame(width: 6, height: 6)
                Text(eyebrowText)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
            )

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary.opacity(0.75))
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.closeLabel)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(headlineText)
                .font(.system(size: 32, weight: .heavy, design: .default))
                .tracking(-0.6)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(l10n.proSubtitle)
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(3.5)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Free vs. Pro Comparison Card

    private var comparisonCard: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack(spacing: 8) {
                Text("OMAKASE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(l10n.proCompareFreeHeader)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 64, alignment: .center)

                Text(l10n.proCompareProHeader)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(OmakaseTheme.chipActiveText)
                    .frame(width: 74, height: 22)
                    .background(OmakaseTheme.chipActiveFill, in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .overlay(OmakaseTheme.stroke)

            comparisonRow(
                icon: "doc.text",
                title: l10n.proComparePostsLabel,
                freeValue: l10n.proComparePostsFree,
                proValue: l10n.proCompareUnlimited
            )
            Divider()
                .overlay(OmakaseTheme.stroke.opacity(0.6))
                .padding(.leading, 44)

            comparisonRow(
                icon: "fish",
                title: l10n.proCompareDeepDiveLabel,
                freeValue: l10n.proCompareDeepDiveFree,
                proValue: l10n.proCompareUnlimited
            )
            Divider()
                .overlay(OmakaseTheme.stroke.opacity(0.6))
                .padding(.leading, 44)

            comparisonRow(
                icon: "sparkles",
                title: l10n.proCompareSubtopicsLabel,
                freeValue: l10n.proCompareSubtopicsFree,
                proValue: l10n.proCompareFull
            )
            Divider()
                .overlay(OmakaseTheme.stroke.opacity(0.6))
                .padding(.leading, 44)

            comparisonRow(
                icon: "checkmark.seal",
                title: l10n.proFeatureProBadge,
                freeValue: "—",
                proValue: "✓"
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
        )
    }

    private func comparisonRow(
        icon: String,
        title: String,
        freeValue: String,
        proValue: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(OmakaseTheme.ink)
                .frame(width: 22, alignment: .center)

            Text(title)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)

            Text(freeValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(proValue)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 74, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Sticky Bottom Pricing & CTA Dock

    private var bottomDock: some View {
        VStack(spacing: 12) {
            VStack(spacing: 10) {
                yearlyPlanCard
                monthlyPlanCard
            }

            HStack(spacing: 6) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 11, weight: .semibold))
                Text(reassuranceText)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.top, 2)

            Button {
                Task { await handlePurchaseTap() }
            } label: {
                ZStack {
                    if accessManager.isPurchasing {
                        ProgressView()
                            .tint(OmakaseTheme.chipActiveText)
                    } else {
                        HStack(spacing: 8) {
                            Text(ctaTitle)
                                .font(.system(size: 16.5, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
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
            .disabled(accessManager.isPurchasing || accessManager.isRestoring)

            Text(disclosureText)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)

            footerLinks
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(
            Color(uiColor: .systemBackground)
                .shadow(color: Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.06), radius: 14, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var yearlyPlanCard: some View {
        let isSelected = selectedPlan == .yearly
        let badgeLabel: String = {
            if let pct = yearlySavingsPercent {
                return "\(l10n.proBestValueBadge.uppercased()) · \(l10n.proSavePercentBadge(pct))"
            }
            return l10n.proBestValueBadge.uppercased()
        }()

        let subtitleParts: [String] = {
            var parts: [String] = []
            if yearlyHasFreeTrial {
                parts.append(l10n.proFreeTrialDaysLabel(yearlyTrialDays))
            }
            if let perMonth = annualPerMonthString {
                parts.append(l10n.proPerMonthEquivalent(perMonth))
            }
            return parts
        }()

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                selectedPlan = .yearly
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 12) {
                    selectionIndicator(isSelected: isSelected)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.proPlanYearly)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)

                        if !subtitleParts.isEmpty {
                            Text(subtitleParts.joined(separator: " · "))
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 1) {
                        Text(annualPriceString)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(l10n.proPerYearSuffix)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? OmakaseTheme.wash : Color(uiColor: .secondarySystemBackground).opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            isSelected ? OmakaseTheme.ink : OmakaseTheme.stroke,
                            lineWidth: isSelected ? 2 : 1
                        )
                )

                Text(badgeLabel)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(OmakaseTheme.chipActiveText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(OmakaseTheme.chipActiveFill, in: Capsule())
                    .offset(x: -12, y: -10)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    private var monthlyPlanCard: some View {
        let isSelected = selectedPlan == .monthly

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                selectedPlan = .monthly
            }
        } label: {
            HStack(spacing: 12) {
                selectionIndicator(isSelected: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.proPlanMonthly)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(l10n.proBilledMonthly)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(monthlyPriceString)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(l10n.proPerMonthSuffix)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? OmakaseTheme.wash : Color(uiColor: .secondarySystemBackground).opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? OmakaseTheme.ink : OmakaseTheme.stroke,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? OmakaseTheme.ink : Color.primary.opacity(0.28), lineWidth: 1.8)
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(OmakaseTheme.ink)
                    .frame(width: 12, height: 12)
            }
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 10) {
            Button {
                Task { await handleRestoreTap() }
            } label: {
                if accessManager.isRestoring {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Text(l10n.proRestorePurchases)
                }
            }
            .disabled(accessManager.isPurchasing || accessManager.isRestoring)

            Text("·")
                .foregroundStyle(.tertiary)

            if let termsURL = URL(string: "https://getomakase.app/terms.html") {
                Link(l10n.termsOfUse, destination: termsURL)
            }

            Text("·")
                .foregroundStyle(.tertiary)

            if let privacyURL = URL(string: "https://getomakase.app/privacy.html") {
                Link(l10n.privacyPolicy, destination: privacyURL)
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    // MARK: - Actions

    private func handlePurchaseTap() async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if selectedPackage == nil {
            await accessManager.loadOfferings()
        }
        guard let pkg = selectedPackage else {
            localToastMessage = l10n.proProductsUnavailable
            return
        }

        let outcome = await accessManager.purchase(package: pkg)
        switch outcome {
        case .purchased:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onToast?(l10n.proPurchaseSuccess)
            dismiss()
        case .pending:
            localToastMessage = l10n.proPaymentPending
        case .cancelled:
            break
        case .failed(let err):
            localToastMessage = err.message(l10n: l10n)
        }
    }

    private func handleRestoreTap() async {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let outcome = await accessManager.restorePurchases()
        switch outcome {
        case .restored:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onToast?(l10n.proRestoreSuccess)
            dismiss()
        case .nothingToRestore:
            localToastMessage = l10n.proRestoreEmpty
        case .failed(let err):
            localToastMessage = err.message(l10n: l10n)
        }
    }
}

// MARK: - Gently Swaying Monochrome ASCII Sushi Backdrop

/// Calm, Hidden-Folks-inspired monochrome ASCII sushi sprites (nigiri, maki,
/// onigiri, temaki, ocha) drifting and swaying gently behind the paywall.
private struct OmakaseASCIIBackdrop: View {

    let reduceMotion: Bool
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
        // Top-left Nigiri
        SushiSprite(
            id: 0,
            art: """
             _____
            (~~~~~)
            [=====]
            """,
            xFraction: 0.16, yFraction: 0.09,
            speed: 0.55, swayX: 12, swayY: 5, maxDegrees: 3.5, phase: 0.0, fontSize: 12
        ),
        // Top-center Maki roll
        SushiSprite(
            id: 1,
            art: """
            .---.
            |(o)|
            '---'
            """,
            xFraction: 0.52, yFraction: 0.07,
            speed: -0.48, swayX: 10, swayY: 6, maxDegrees: 4.0, phase: 1.4, fontSize: 12
        ),
        // Top-right Onigiri
        SushiSprite(
            id: 2,
            art: """
              /\\
             /  \\
            /_[]_\\
            """,
            xFraction: 0.84, yFraction: 0.11,
            speed: 0.44, swayX: 11, swayY: 5, maxDegrees: 3.0, phase: 2.6, fontSize: 12
        ),
        // Upper-mid Chopsticks + Nigiri
        SushiSprite(
            id: 3,
            art: """
            ====\\  ____
            ====/ (~~~~)
                  [====]
            """,
            xFraction: 0.78, yFraction: 0.25,
            speed: -0.52, swayX: 14, swayY: 6, maxDegrees: 2.8, phase: 0.9, fontSize: 11.5
        ),
        // Upper-mid Ocha teacup
        SushiSprite(
            id: 4,
            art: """
             ( )
            |___|
            '---'
            """,
            xFraction: 0.14, yFraction: 0.26,
            speed: 0.46, swayX: 9, swayY: 5, maxDegrees: 2.5, phase: 3.1, fontSize: 11.5
        ),
        // Mid-center Maki duo
        SushiSprite(
            id: 5,
            art: """
            .---. .---.
            |(o)| |(o)|
            '---' '---'
            """,
            xFraction: 0.48, yFraction: 0.36,
            speed: 0.40, swayX: 15, swayY: 5, maxDegrees: 2.5, phase: 4.2, fontSize: 11.5
        ),
        // Lower-mid Temaki hand roll
        SushiSprite(
            id: 6,
            art: """
            \\o~o/
             \\ /
              V
            """,
            xFraction: 0.18, yFraction: 0.48,
            speed: -0.50, swayX: 11, swayY: 6, maxDegrees: 4.2, phase: 2.1, fontSize: 12
        ),
        // Lower-mid Nigiri
        SushiSprite(
            id: 7,
            art: """
             _____
            (~~~~~)
            [=====]
            """,
            xFraction: 0.84, yFraction: 0.47,
            speed: 0.58, swayX: 13, swayY: 5, maxDegrees: 3.2, phase: 5.0, fontSize: 12
        ),
        // Mid-bottom Onigiri
        SushiSprite(
            id: 8,
            art: """
              /\\
             /  \\
            /_[]_\\
            """,
            xFraction: 0.46, yFraction: 0.58,
            speed: -0.42, swayX: 12, swayY: 5, maxDegrees: 3.0, phase: 1.7, fontSize: 12
        ),
        // Gentle sparkle accents
        SushiSprite(
            id: 9,
            art: "·  ✦  ·",
            xFraction: 0.34, yFraction: 0.17,
            speed: 0.65, swayX: 8, swayY: 4, maxDegrees: 0, phase: 0.5, fontSize: 12
        ),
        SushiSprite(
            id: 10,
            art: "~  ∘  ~",
            xFraction: 0.66, yFraction: 0.42,
            speed: -0.60, swayX: 9, swayY: 4, maxDegrees: 0, phase: 3.7, fontSize: 12
        )
    ]

    var body: some View {
        SwiftUI.TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0.0 : context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let baseOpacity = colorScheme == .dark ? 0.25 : 0.20

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
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black.opacity(0.9), location: 0.48),
                            .init(color: .black.opacity(0.35), location: 0.68),
                            .init(color: .clear, location: 0.82)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
