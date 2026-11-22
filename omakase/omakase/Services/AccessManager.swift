//
//  AccessManager.swift
//  omakase
//
//  Centralized RevenueCat subscription state, backend entitlement sync,
//  and daily "Today's Menu" quota management.
//

import Foundation
import Observation
import RevenueCat
import StoreKit
import UIKit

struct AccessSnapshot: Codable, Equatable, Sendable {
    var isPro: Bool
    var status: String
    var productId: String?
    var expiresAt: String?
    var willRenew: Bool
    var dayKey: String
    var timezone: String
    var resetsAt: String
    var platesUsed: Int
    var platesLimit: Int
    var platesRemaining: Int
    var deepDivesUsed: Int
    var deepDivesLimit: Int
    var deepDivesRemaining: Int
    var suggestionsUsed: Int
    var suggestionsLimit: Int
    var suggestionsRemaining: Int
    var shareBonusClaimed: Bool
    var canClaimShareBonus: Bool

    enum CodingKeys: String, CodingKey {
        case isPro = "is_pro"
        case status
        case productId = "product_id"
        case expiresAt = "expires_at"
        case willRenew = "will_renew"
        case dayKey = "day_key"
        case timezone
        case resetsAt = "resets_at"
        case platesUsed = "plates_used"
        case platesLimit = "plates_limit"
        case platesRemaining = "plates_remaining"
        case deepDivesUsed = "deep_dives_used"
        case deepDivesLimit = "deep_dives_limit"
        case deepDivesRemaining = "deep_dives_remaining"
        case suggestionsUsed = "suggestions_used"
        case suggestionsLimit = "suggestions_limit"
        case suggestionsRemaining = "suggestions_remaining"
        case shareBonusClaimed = "share_bonus_claimed"
        case canClaimShareBonus = "can_claim_share_bonus"
    }

    static let defaultFree = AccessSnapshot(
        isPro: false,
        status: "free",
        productId: nil,
        expiresAt: nil,
        willRenew: false,
        dayKey: "",
        timezone: TimeZone.current.identifier,
        resetsAt: "",
        platesUsed: 0,
        platesLimit: 3,
        platesRemaining: 3,
        deepDivesUsed: 0,
        deepDivesLimit: 1,
        deepDivesRemaining: 1,
        suggestionsUsed: 0,
        suggestionsLimit: 10,
        suggestionsRemaining: 10,
        shareBonusClaimed: false,
        canClaimShareBonus: true
    )

    var resetsAtDate: Date? {
        Self.parseISO8601(resetsAt)
    }

    var expiresAtDate: Date? {
        Self.parseISO8601(expiresAt)
    }

    private static func parseISO8601(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = fractional.date(from: raw) { return d }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: raw)
    }
}

enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    case cancelled
    case pending
    case failed(OmakaseError)
}

enum RestoreOutcome: Equatable, Sendable {
    case restored
    case nothingToRestore
    case failed(OmakaseError)
}

@Observable
@MainActor
final class AccessManager {

    static let shared = AccessManager()

    private(set) var snapshot: AccessSnapshot = .defaultFree
    private(set) var currentOffering: Offering?
    private(set) var isLoadingOfferings: Bool = false
    private(set) var isPurchasing: Bool = false
    private(set) var isRestoring: Bool = false
    private(set) var isConfigured: Bool = false
    private(set) var rcEntitlementActive: Bool = false
    private(set) var rcExpirationDate: Date?
    private(set) var rcWillRenew: Bool = false
    private(set) var rcIsTrial: Bool = false

    @ObservationIgnored
    private var customerInfoTask: Task<Void, Never>?
    @ObservationIgnored
    private var currentUID: String?

    private let entitlementID = "pro"
    private let yearlyProductID = "omakase.pro.yearly"
    private let monthlyProductID = "omakase.pro.monthly"

    private init() {}

    // MARK: - Computed Status

    var isPro: Bool {
        snapshot.isPro || rcEntitlementActive
    }

    var isPlateLimitReached: Bool {
        !isPro && snapshot.platesRemaining <= 0
    }

    var isDeepDiveLimitReached: Bool {
        !isPro && snapshot.deepDivesRemaining <= 0
    }

    var canClaimShareBonus: Bool {
        !isPro && snapshot.canClaimShareBonus
    }

    var effectiveStatus: String {
        if rcEntitlementActive && !snapshot.isPro {
            return rcIsTrial ? "trial" : "active"
        }
        return snapshot.status
    }

    var effectiveExpirationDate: Date? {
        snapshot.expiresAtDate ?? rcExpirationDate
    }

    var effectiveWillRenew: Bool {
        snapshot.isPro ? snapshot.willRenew : rcWillRenew
    }

    var nextResetDate: Date {
        if let parsed = snapshot.resetsAtDate, parsed > Date() {
            return parsed
        }
        let calendar = Calendar.current
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
            return calendar.startOfDay(for: tomorrow)
        }
        return Date().addingTimeInterval(3600)
    }

    var annualPackage: Package? {
        currentOffering?.annual
            ?? currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == yearlyProductID })
    }

    var monthlyPackage: Package? {
        currentOffering?.monthly
            ?? currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == monthlyProductID })
    }

    // MARK: - Lifecycle

    func configure() {
        guard !isConfigured else { return }
        guard
            let rawKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String
        else {
            ErrorReporter.record(nil, mapped: .billingSyncFailed, area: "revenuecat_missing_key")
            return
        }
        let apiKey = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            ErrorReporter.record(nil, mapped: .billingSyncFailed, area: "revenuecat_empty_key")
            return
        }

        #if DEBUG
        Purchases.logLevel = .warn
        #else
        Purchases.logLevel = .error
        #endif

        let config = Configuration.Builder(withAPIKey: apiKey)
            .with(storeKitVersion: .storeKit2)
            .with(entitlementVerificationMode: .informational)
            .build()
        Purchases.configure(with: config)
        isConfigured = true

        customerInfoTask?.cancel()
        customerInfoTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                guard let self, !Task.isCancelled else { break }
                await self.handleCustomerInfoUpdate(info)
            }
        }
    }

    func syncAuthUser(uid: String?) async {
        currentUID = uid
        guard let uid, !uid.isEmpty else {
            if isConfigured, !Purchases.shared.isAnonymous {
                _ = try? await Purchases.shared.logOut()
            }
            rcEntitlementActive = false
            rcExpirationDate = nil
            rcWillRenew = false
            rcIsTrial = false
            snapshot = .defaultFree
            return
        }

        if isConfigured {
            do {
                let (info, _) = try await Purchases.shared.logIn(uid)
                _ = applyCustomerInfo(info)
            } catch {
                let mapped = mapRevenueCatError(error)
                ErrorReporter.record(error, mapped: mapped, area: "revenuecat_login")
            }
            await loadOfferings()
        }

        await refreshAccessStatus()
    }

    func loadOfferings() async {
        guard isConfigured else { return }
        isLoadingOfferings = true
        defer { isLoadingOfferings = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
        } catch {
            let mapped = mapRevenueCatError(error)
            ErrorReporter.record(error, mapped: mapped, area: "revenuecat_offerings")
        }
    }

    // MARK: - Purchase & Explicit Restore

    func purchase(package: Package) async -> PurchaseOutcome {
        guard isConfigured else { return .failed(.billingSyncFailed) }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                return .cancelled
            }
            _ = applyCustomerInfo(result.customerInfo)
            _ = await syncWithBackend(retryOnFailure: true)
            return isPro ? .purchased : .pending
        } catch {
            let nsError = error as NSError
            if nsError.domain == RevenueCat.ErrorCode.errorDomain,
               let rcCode = RevenueCat.ErrorCode(rawValue: nsError.code) {
                switch rcCode {
                case .purchaseCancelledError:
                    return .cancelled
                case .paymentPendingError:
                    return .pending
                case .networkError, .offlineConnectionError:
                    return .failed(.offline)
                default:
                    break
                }
            }
            let mapped = mapRevenueCatError(error)
            ErrorReporter.record(error, mapped: mapped, area: "revenuecat_purchase")
            return .failed(mapped)
        }
    }

    /// Explicit user-triggered Restore Purchases action (`AppStore.sync()` via RevenueCat).
    func restorePurchases() async -> RestoreOutcome {
        guard isConfigured else { return .failed(.billingSyncFailed) }
        isRestoring = true
        defer { isRestoring = false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            _ = applyCustomerInfo(info)
            _ = await syncWithBackend(retryOnFailure: true)
            return isPro ? .restored : .nothingToRestore
        } catch {
            let mapped = mapRevenueCatError(error)
            ErrorReporter.record(error, mapped: mapped, area: "revenuecat_restore")
            return .failed(mapped)
        }
    }

    func openManageSubscriptions() async {
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            do {
                try await StoreKit.AppStore.showManageSubscriptions(in: scene)
                await syncWithBackend(retryOnFailure: false)
                return
            } catch {
                ErrorReporter.record(error, mapped: .billingSyncFailed, area: "manage_subscriptions")
            }
        }
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            await UIApplication.shared.open(url)
        }
    }

    // MARK: - Backend Quota & Sync

    func refreshAccessStatus() async {
        guard currentUID != nil else { return }
        var components = URLComponents(
            url: APITokenProvider.baseURL.appendingPathComponent("billing/status"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "timezone", value: TimeZone.current.identifier)
        ]
        guard let url = components?.url else { return }

        var request = URLRequest(url: url, timeoutInterval: 12)
        request.httpMethod = "GET"
        request.setValue(TimeZone.current.identifier, forHTTPHeaderField: "X-Omakase-Timezone")

        do {
            let (data, response) = try await performAuthedRequest(request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return
            }
            if let decoded = try? JSONDecoder().decode(AccessSnapshot.self, from: data) {
                snapshot = decoded
            }
        } catch {
            let mapped = OmakaseError.from(error)
            if mapped != .offline {
                ErrorReporter.record(error, mapped: mapped, area: "billing_status")
            }
        }
    }

    @discardableResult
    func syncWithBackend(retryOnFailure: Bool = false) async -> Bool {
        guard currentUID != nil else { return false }
        let url = APITokenProvider.baseURL.appendingPathComponent("billing/sync")
        let body = ["timezone": TimeZone.current.identifier]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return false }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(TimeZone.current.identifier, forHTTPHeaderField: "X-Omakase-Timezone")
        request.httpBody = bodyData

        let maxAttempts = retryOnFailure ? 2 : 1
        for attempt in 1...maxAttempts {
            do {
                let (data, response) = try await performAuthedRequest(request)
                guard let http = response as? HTTPURLResponse else { continue }
                if (200..<300).contains(http.statusCode),
                   let decoded = try? JSONDecoder().decode(AccessSnapshot.self, from: data) {
                    snapshot = decoded
                    return true
                }
            } catch {
                if attempt == maxAttempts {
                    let mapped = OmakaseError.from(error)
                    ErrorReporter.record(error, mapped: .billingSyncFailed, area: "billing_sync")
                    _ = mapped
                }
            }
            if attempt < maxAttempts {
                try? await Task.sleep(for: .milliseconds(600))
            }
        }
        return false
    }

    func claimShareBonus() async -> Bool {
        guard currentUID != nil, canClaimShareBonus else { return false }
        let url = APITokenProvider.baseURL.appendingPathComponent("feed/reward-share")
        let body = ["timezone": TimeZone.current.identifier]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return false }

        var request = URLRequest(url: url, timeoutInterval: 12)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(TimeZone.current.identifier, forHTTPHeaderField: "X-Omakase-Timezone")
        request.httpBody = bodyData

        do {
            let (data, response) = try await performAuthedRequest(request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return false
            }
            struct RewardResponse: Decodable {
                let granted: Bool
                let access: AccessSnapshot
            }
            if let decoded = try? JSONDecoder().decode(RewardResponse.self, from: data) {
                snapshot = decoded.access
                return decoded.granted
            }
        } catch {
            let mapped = OmakaseError.from(error)
            if mapped != .offline {
                ErrorReporter.record(error, mapped: mapped, area: "reward_share")
            }
        }
        return false
    }

    func applySSEAccessPayload(_ dict: [String: Any]) {
        guard
            let data = try? JSONSerialization.data(withJSONObject: dict),
            let decoded = try? JSONDecoder().decode(AccessSnapshot.self, from: data)
        else { return }
        snapshot = decoded
    }

    func applyQuotaExceeded(kind: QuotaKind, resetsAt: Date?) {
        var next = snapshot
        switch kind {
        case .plate:
            next.platesRemaining = 0
            next.platesUsed = max(next.platesUsed, next.platesLimit)
        case .deepDive:
            next.deepDivesRemaining = 0
            next.deepDivesUsed = max(next.deepDivesUsed, next.deepDivesLimit)
        case .suggestion:
            next.suggestionsRemaining = 0
            next.suggestionsUsed = max(next.suggestionsUsed, next.suggestionsLimit)
        }
        if let resetsAt {
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime]
            next.resetsAt = fmt.string(from: resetsAt)
        }
        snapshot = next
    }

    // MARK: - Private Helpers

    @discardableResult
    private func applyCustomerInfo(_ info: CustomerInfo) -> Bool {
        let ent = info.entitlements[entitlementID]
        let verifiedActive = (ent?.isActive == true) && (ent?.verification != .failed)
        let changed = (verifiedActive != rcEntitlementActive)
        rcEntitlementActive = verifiedActive
        rcExpirationDate = ent?.expirationDate
        rcWillRenew = ent?.willRenew ?? false
        rcIsTrial = (ent?.periodType == .trial)
        return changed
    }

    private func handleCustomerInfoUpdate(_ info: CustomerInfo) async {
        let changed = applyCustomerInfo(info)
        if changed, currentUID != nil {
            await syncWithBackend(retryOnFailure: false)
        }
    }

    private func performAuthedRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let authed = await APITokenProvider.shared.authorizedRequest(request)
        let (data, response) = try await URLSession.shared.data(for: authed)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            let retried = await APITokenProvider.shared.authorizedRequest(request, forceRefresh: true)
            return try await URLSession.shared.data(for: retried)
        }
        return (data, response)
    }

    private func mapRevenueCatError(_ error: Error) -> OmakaseError {
        let nsError = error as NSError
        if nsError.domain == RevenueCat.ErrorCode.errorDomain,
           let code = RevenueCat.ErrorCode(rawValue: nsError.code) {
            switch code {
            case .networkError, .offlineConnectionError:
                return .offline
            default:
                return .billingSyncFailed
            }
        }
        return OmakaseError.from(error)
    }
}
