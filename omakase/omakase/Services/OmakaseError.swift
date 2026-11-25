//
//  OmakaseError.swift
//  omakase
//
//  Canonical error taxonomy, backend/framework mapping, localized UI helpers,
//  and non-fatal Crashlytics telemetry.
//

import AuthenticationServices
import FirebaseAuth
import FirebaseCrashlytics
import Foundation

enum QuotaKind: String, Equatable, Sendable {
    case plate
    case letterboxd
    case deepDive = "deep_dive"
    case suggestion

    nonisolated init(backendValue: String?) {
        switch backendValue?.lowercased() {
        case "letterboxd":
            self = .letterboxd
        case "deep_dive":
            self = .deepDive
        case "suggestion":
            self = .suggestion
        default:
            self = .plate
        }
    }
}

enum SocialActionContext: String, Equatable, Sendable {
    case share
    case unshare
    case commentSend
    case commentLoad
    case commentDelete
    case report
    case block
    case unblock
    case follow
    case unfollow
    case reaction
    case timelineLoad
    case userSearch
    case profileLoad
    case postDelete
}

enum ErrorPresentation: Equatable, Sendable {
    case inline
    case toast
    case alert(canRetry: Bool)
}

enum OmakaseError: Error, Equatable, Sendable {
    case offline
    case timeout
    case serverUnreachable
    case unauthorized
    case rateLimited(retryAfter: Int?)
    case quotaExceeded(kind: QuotaKind, resetsAt: Date?)
    case contentBlocked
    case generationFailed
    case serviceUnavailable
    case letterboxdNotFound
    case letterboxdPrivate
    case billingSyncFailed
    case authInvalidEmail
    case authEmailInUse
    case authWeakPassword
    case authInvalidCredential
    case authRequiresRecentLogin
    case authTooManyRequests
    case authUserDisabled
    case authProviderFailed
    case authSignOutFailed
    case socialActionFailed(SocialActionContext)
    case unknown

    // MARK: - Mapping

    nonisolated static func fromBackendCode(
        _ code: String?,
        retryAfter: Int? = nil,
        resetsAt: Date? = nil,
        kind: String? = nil
    ) -> OmakaseError {
        switch code?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "offline":
            return .offline
        case "timeout":
            return .timeout
        case "server_unreachable":
            return .serverUnreachable
        case "unauthorized":
            return .unauthorized
        case "rate_limited":
            return .rateLimited(retryAfter: retryAfter)
        case "quota_exceeded":
            return .quotaExceeded(kind: QuotaKind(backendValue: kind), resetsAt: resetsAt)
        case "content_blocked":
            return .contentBlocked
        case "generation_failed":
            return .generationFailed
        case "service_unavailable":
            return .serviceUnavailable
        case "letterboxd_not_found":
            return .letterboxdNotFound
        case "letterboxd_private":
            return .letterboxdPrivate
        case "billing_sync_failed":
            return .billingSyncFailed
        default:
            return .unknown
        }
    }

    nonisolated static func fromHTTP(
        status: Int,
        data: Data?,
        retryAfterHeader: String?
    ) -> OmakaseError {
        var code: String?
        var retryAfter: Int?
        var resetsAtString: String?
        var kind: String?

        if let data,
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            code = obj["code"] as? String
            if let raInt = obj["retry_after"] as? Int {
                retryAfter = raInt
            } else if let raDouble = obj["retry_after"] as? Double {
                retryAfter = Int(ceil(raDouble))
            }
            resetsAtString = obj["resets_at"] as? String
            kind = obj["kind"] as? String
        }

        if retryAfter == nil,
           let rawHeader = retryAfterHeader?.trimmingCharacters(in: .whitespacesAndNewlines),
           let parsedHeader = Int(rawHeader) {
            retryAfter = parsedHeader
        }

        let resetsAt = parseISO8601Date(resetsAtString)

        if let code, !code.isEmpty {
            return fromBackendCode(code, retryAfter: retryAfter, resetsAt: resetsAt, kind: kind)
        }

        switch status {
        case 401:
            return .unauthorized
        case 402:
            return .quotaExceeded(kind: QuotaKind(backendValue: kind), resetsAt: resetsAt)
        case 429:
            return .rateLimited(retryAfter: retryAfter)
        case 500...599:
            return .serviceUnavailable
        default:
            return .unknown
        }
    }

    nonisolated static func from(_ error: Error, context: SocialActionContext? = nil) -> OmakaseError {
        if let already = error as? OmakaseError {
            return already
        }

        if let sseError = error as? SSEError {
            switch sseError {
            case .badResponse(let status, let code, let retryAfter, let resetsAtString, let kind):
                let resetsAt = parseISO8601Date(resetsAtString)
                if let code, !code.isEmpty {
                    return fromBackendCode(code, retryAfter: retryAfter, resetsAt: resetsAt, kind: kind)
                }
                switch status {
                case 401:
                    return .unauthorized
                case 402:
                    return .quotaExceeded(kind: QuotaKind(backendValue: kind), resetsAt: resetsAt)
                case 429:
                    return .rateLimited(retryAfter: retryAfter)
                case 500...599:
                    return .serviceUnavailable
                default:
                    return .generationFailed
                }
            case .notEventStream:
                return .serviceUnavailable
            }
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff:
                return .offline
            case .timedOut:
                return .timeout
            case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost, .dnsLookupFailed:
                return .serverUnreachable
            default:
                if let context {
                    return .socialActionFailed(context)
                }
                return .serverUnreachable
            }
        }

        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain,
           let authCode = AuthErrorCode(rawValue: nsError.code) {
            switch authCode {
            case .invalidEmail:
                return .authInvalidEmail
            case .emailAlreadyInUse:
                return .authEmailInUse
            case .weakPassword:
                return .authWeakPassword
            case .wrongPassword, .invalidCredential, .userNotFound:
                return .authInvalidCredential
            case .requiresRecentLogin:
                return .authRequiresRecentLogin
            case .networkError:
                return .offline
            case .tooManyRequests:
                return .authTooManyRequests
            case .userDisabled:
                return .authUserDisabled
            default:
                break
            }
        }

        if error is ASAuthorizationError || nsError.domain == ASAuthorizationError.errorDomain {
            return .authProviderFailed
        }

        if let context {
            return .socialActionFailed(context)
        }
        return .unknown
    }

    nonisolated private static func parseISO8601Date(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) {
            return date
        }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: raw)
    }

    // MARK: - Telemetry & Presentation

    nonisolated var analyticsCode: String {
        switch self {
        case .offline: "offline"
        case .timeout: "timeout"
        case .serverUnreachable: "server_unreachable"
        case .unauthorized: "unauthorized"
        case .rateLimited: "rate_limited"
        case .quotaExceeded: "quota_exceeded"
        case .contentBlocked: "content_blocked"
        case .generationFailed: "generation_failed"
        case .serviceUnavailable: "service_unavailable"
        case .letterboxdNotFound: "letterboxd_not_found"
        case .letterboxdPrivate: "letterboxd_private"
        case .billingSyncFailed: "billing_sync_failed"
        case .authInvalidEmail: "auth_invalid_email"
        case .authEmailInUse: "auth_email_in_use"
        case .authWeakPassword: "auth_weak_password"
        case .authInvalidCredential: "auth_invalid_credential"
        case .authRequiresRecentLogin: "auth_requires_recent_login"
        case .authTooManyRequests: "auth_too_many_requests"
        case .authUserDisabled: "auth_user_disabled"
        case .authProviderFailed: "auth_provider_failed"
        case .authSignOutFailed: "auth_sign_out_failed"
        case .socialActionFailed(let context): "social_\(context.rawValue)_failed"
        case .unknown: "unknown"
        }
    }

    nonisolated fileprivate var crashNumericCode: Int {
        switch self {
        case .offline: 1001
        case .timeout: 1002
        case .serverUnreachable: 1003
        case .unauthorized: 1004
        case .rateLimited: 1005
        case .quotaExceeded: 1006
        case .contentBlocked: 1007
        case .generationFailed: 1008
        case .serviceUnavailable: 1009
        case .letterboxdNotFound: 1010
        case .letterboxdPrivate: 1011
        case .billingSyncFailed: 1012
        case .authInvalidEmail: 2001
        case .authEmailInUse: 2002
        case .authWeakPassword: 2003
        case .authInvalidCredential: 2004
        case .authRequiresRecentLogin: 2005
        case .authTooManyRequests: 2006
        case .authUserDisabled: 2007
        case .authProviderFailed: 2008
        case .authSignOutFailed: 2009
        case .socialActionFailed: 3001
        case .unknown: 9999
        }
    }

    nonisolated var presentation: ErrorPresentation {
        switch self {
        case .offline, .quotaExceeded, .letterboxdNotFound, .letterboxdPrivate:
            return .inline
        case .rateLimited, .contentBlocked, .billingSyncFailed, .socialActionFailed:
            return .toast
        case .timeout, .serverUnreachable, .generationFailed, .serviceUnavailable, .unknown:
            return .alert(canRetry: true)
        case .unauthorized,
             .authInvalidEmail, .authEmailInUse, .authWeakPassword, .authInvalidCredential,
             .authRequiresRecentLogin, .authTooManyRequests, .authUserDisabled,
             .authProviderFailed, .authSignOutFailed:
            return .alert(canRetry: false)
        }
    }

    // MARK: - Localized Copy

    func title(l10n: L10n) -> String {
        switch self {
        case .timeout:
            return l10n.errorTimeoutTitle
        case .serverUnreachable, .offline:
            return l10n.errorServerUnreachableTitle
        case .unauthorized:
            return l10n.errorUnauthorizedTitle
        case .quotaExceeded:
            return l10n.errorQuotaExceededTitle
        case .generationFailed:
            return l10n.errorGenerationFailedTitle
        case .serviceUnavailable:
            return l10n.errorServiceUnavailableTitle
        default:
            return l10n.errorSomethingWrong
        }
    }

    func message(l10n: L10n) -> String {
        switch self {
        case .offline:
            return l10n.errorOfflineMessage
        case .timeout:
            return l10n.errorTimeoutMessage
        case .serverUnreachable:
            return l10n.errorServerUnreachableMessage
        case .unauthorized:
            return l10n.errorUnauthorizedMessage
        case .rateLimited(let retryAfter):
            return l10n.errorRateLimitedMessage(seconds: retryAfter)
        case .quotaExceeded:
            return l10n.errorQuotaExceededMessage
        case .contentBlocked:
            return l10n.errorContentBlockedMessage
        case .generationFailed:
            return l10n.errorGenerationFailedMessage
        case .serviceUnavailable:
            return l10n.errorServiceUnavailableMessage
        case .letterboxdNotFound:
            return l10n.errorLetterboxdNotFoundMessage
        case .letterboxdPrivate:
            return l10n.errorLetterboxdPrivateMessage
        case .billingSyncFailed:
            return l10n.errorBillingSyncFailedMessage
        case .authInvalidEmail:
            return l10n.authErrorInvalidEmail
        case .authEmailInUse:
            return l10n.authErrorEmailInUse
        case .authWeakPassword:
            return l10n.authErrorWeakPassword
        case .authInvalidCredential:
            return l10n.authErrorInvalidCredential
        case .authRequiresRecentLogin:
            return l10n.accountDeleteRequiresReauth
        case .authTooManyRequests:
            return l10n.authErrorTooManyRequests
        case .authUserDisabled:
            return l10n.authErrorUserDisabled
        case .authProviderFailed:
            return l10n.authErrorProviderFailed
        case .authSignOutFailed:
            return l10n.authErrorSignOutFailed
        case .socialActionFailed(let context):
            switch context {
            case .share:
                return l10n.errorShareFailed
            case .unshare:
                return l10n.errorUnshareFailed
            case .commentSend:
                return l10n.errorCommentSendFailed
            case .commentLoad:
                return l10n.errorCommentLoadFailed
            case .commentDelete:
                return l10n.errorCommentDeleteFailed
            case .report:
                return l10n.errorReportFailed
            case .block:
                return l10n.errorBlockFailed
            case .unblock:
                return l10n.errorUnblockFailed
            case .follow:
                return l10n.errorFollowFailed
            case .unfollow:
                return l10n.errorUnfollowFailed
            case .reaction:
                return l10n.errorReactionFailed
            case .timelineLoad:
                return l10n.errorTimelineLoadFailed
            case .userSearch:
                return l10n.errorUserSearchFailed
            case .profileLoad:
                return l10n.errorProfileLoadFailed
            case .postDelete:
                return l10n.errorPostDeleteFailed
            }
        case .unknown:
            return l10n.errorUnknownMessage
        }
    }
}

enum ErrorReporter {
    static func setUserID(_ uid: String?) {
        Crashlytics.crashlytics().setUserID(uid ?? "")
    }

    static func record(
        _ error: Error?,
        mapped: OmakaseError,
        area: String,
        metadata: [String: String] = [:]
    ) {
        if let error, error is CancellationError {
            return
        }
        switch mapped {
        case .offline, .quotaExceeded:
            return
        default:
            break
        }

        let crashlytics = Crashlytics.crashlytics()
        crashlytics.setCustomValue(mapped.analyticsCode, forKey: "omakase_error_code")
        crashlytics.setCustomValue(area, forKey: "omakase_area")
        for (key, value) in metadata {
            let safeKey = key.replacingOccurrences(of: " ", with: "_")
            crashlytics.setCustomValue(String(value.prefix(128)), forKey: "omakase_\(safeKey)")
        }

        let sourceType = error.map { String(describing: type(of: $0)) } ?? "None"
        let nsError = NSError(
            domain: "com.omakase.error.\(area)",
            code: mapped.crashNumericCode,
            userInfo: [
                NSLocalizedDescriptionKey: "\(mapped.analyticsCode): \(sourceType)",
            ]
        )
        crashlytics.record(error: nsError)
    }
}
