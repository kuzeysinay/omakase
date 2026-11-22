//
//  OmakasePaywallView.swift
//  omakase
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

struct OmakasePaywallView: View {

    let source: PaywallSource
    var onToast: ((String) -> Void)? = nil

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var accessManager = AccessManager.shared
    @State private var selectedPlan: PlanChoice = .yearly
    @State private var localToastMessage: String?

    private enum PlanChoice {
        case yearly
        case monthly
    }

    private var l10n: L10n { L10n(lang: appLanguage) }

    private var selectedPackage: Package? {
        switch selectedPlan {
        case .yearly:
            return accessManager.annualPackage ?? accessManager.monthlyPackage
        case .monthly:
            return accessManager.monthlyPackage ?? accessManager.annualPackage
        }
    }

    private var isBusy: Bool {
        accessManager.isPurchasing || accessManager.isRestoring
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection

                    featuresCard

                    if source == .deepDiveLimit && accessManager.canClaimShareBonus {
                        shareHintBanner
                    }

                    plansSection

                    ctaSection

                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(l10n.dismissLabel)
                }
            }
            .toast(message: $localToastMessage)
        }
        .task {
            if accessManager.currentOffering == nil {
                await accessManager.loadOfferings()
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(OmakaseTheme.ink)
                Text("PRO")
                    .font(.caption2.weight(.bold).monospaced())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(OmakaseTheme.chipActiveFill, in: Capsule())
                    .foregroundStyle(OmakaseTheme.chipActiveText)
            }

            Text(l10n.proHeadline)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(l10n.proSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(icon: "fork.knife", text: l10n.proFeatureUnlimitedPlates)
            featureRow(icon: "fish.fill", text: l10n.proFeatureUnlimitedDeepDive)
            featureRow(icon: "sparkles", text: l10n.proFeatureUnlimitedSubtopics)
            featureRow(icon: "checkmark.seal.fill", text: l10n.proFeatureProBadge)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OmakaseTheme.ink)
                .frame(width: 24)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var shareHintBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OmakaseTheme.ink)
            Text(l10n.proShareForDeepDiveCTA)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var plansSection: some View {
        if accessManager.isLoadingOfferings && accessManager.currentOffering == nil {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 24)
        } else if accessManager.annualPackage == nil && accessManager.monthlyPackage == nil {
            VStack(spacing: 12) {
                Text(l10n.proProductsUnavailable)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(l10n.tryAgain) {
                    Task { await accessManager.loadOfferings() }
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        } else {
            VStack(spacing: 12) {
                if let yearly = accessManager.annualPackage {
                    planCard(
                        choice: .yearly,
                        title: l10n.proPlanYearly,
                        priceText: "\(yearly.localizedPriceString) \(l10n.proPerYearSuffix)",
                        badge: l10n.proBestValueBadge,
                        sublabel: l10n.proFreeTrialBadge
                    )
                }

                if let monthly = accessManager.monthlyPackage {
                    planCard(
                        choice: .monthly,
                        title: l10n.proPlanMonthly,
                        priceText: "\(monthly.localizedPriceString) \(l10n.proPerMonthSuffix)",
                        badge: nil,
                        sublabel: nil
                    )
                }
            }
        }
    }

    private func planCard(
        choice: PlanChoice,
        title: String,
        priceText: String,
        badge: String?,
        sublabel: String?
    ) -> some View {
        let isSelected = (selectedPlan == choice)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedPlan = choice
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? OmakaseTheme.ink : .secondary)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(OmakaseTheme.chipActiveFill, in: Capsule())
                                .foregroundStyle(OmakaseTheme.chipActiveText)
                        }
                    }

                    if let sublabel {
                        Text(sublabel)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(priceText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color(uiColor: .secondarySystemBackground) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? OmakaseTheme.ink : Color.primary.opacity(0.14),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var ctaSection: some View {
        Button {
            guard let pkg = selectedPackage else { return }
            Task { await handlePurchase(pkg) }
        } label: {
            HStack(spacing: 8) {
                if accessManager.isPurchasing {
                    ProgressView()
                        .tint(OmakaseTheme.chipActiveText)
                } else {
                    Text(selectedPlan == .yearly ? l10n.proStartTrialCTA : l10n.proSubscribeCTA)
                        .font(.body.weight(.bold))
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
        .buttonStyle(.plain)
        .disabled(selectedPackage == nil || isBusy)
        .opacity((selectedPackage == nil || isBusy) ? 0.55 : 1.0)
    }

    private var footerSection: some View {
        VStack(spacing: 14) {
            Button {
                Task { await handleRestore() }
            } label: {
                if accessManager.isRestoring {
                    ProgressView().controlSize(.small)
                } else {
                    Text(l10n.proRestorePurchases)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
            .disabled(isBusy)

            Text(l10n.proSubscriptionDisclosure)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                if let termsURL = URL(string: "https://getomakase.app/terms.html") {
                    Link(l10n.termsOfUse, destination: termsURL)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                if let privacyURL = URL(string: "https://getomakase.app/privacy.html") {
                    Link(l10n.privacyPolicy, destination: privacyURL)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // MARK: - Actions

    private func handlePurchase(_ package: Package) async {
        let outcome = await accessManager.purchase(package: package)
        switch outcome {
        case .purchased:
            onToast?(l10n.proPurchaseSuccess)
            dismiss()
        case .cancelled:
            break
        case .pending:
            localToastMessage = l10n.proPaymentPending
        case .failed(let error):
            localToastMessage = error.message(l10n: l10n)
        }
    }

    private func handleRestore() async {
        let outcome = await accessManager.restorePurchases()
        switch outcome {
        case .restored:
            onToast?(l10n.proRestoreSuccess)
            dismiss()
        case .nothingToRestore:
            localToastMessage = l10n.proRestoreEmpty
        case .failed(let error):
            localToastMessage = error.message(l10n: l10n)
        }
    }
}
