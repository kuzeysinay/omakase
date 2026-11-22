//
//  InterestSuggestor.swift
//  omakase
//
//  Lightweight service that calls POST /interests/suggest and returns
//  AI-generated interest suggestions.
//

import Foundation

struct InterestSuggestResponse: Sendable {
    var suggestions: [String]
    /// When `suggestions` is empty, a short reason for the UI (HTTP detail, connectivity, etc.).
    var loadingIssue: String?

    static let empty = InterestSuggestResponse(suggestions: [], loadingIssue: nil)
}

enum InterestSuggestor {

    /// The backend base URL — centralized via `APITokenProvider.baseURL`.
    private static var baseURL: URL { APITokenProvider.baseURL }

    // MARK: - Public

    /// Fetch AI suggestions for the given interests + draft text.
    /// `excludeSuggestions` lists ideas already shown so the API returns different ones (e.g. refresh).
    /// - Throws: `CancellationError` when the calling task is cancelled.
    static func suggest(
        interests: [String],
        draft: String,
        excludeSuggestions: [String] = [],
        language: AppLanguage
    ) async throws -> InterestSuggestResponse {
        let l10n = L10n(lang: language)
        let url = baseURL.appendingPathComponent("interests/suggest")
        var body: [String: Any] = [
            "interests": interests,
            "draft": draft,
            "language": language.rawValue,
            "timezone": TimeZone.current.identifier,
        ]
        if !excludeSuggestions.isEmpty {
            body["exclude_suggestions"] = excludeSuggestions
        }
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            let mapped = OmakaseError.generationFailed
            ErrorReporter.record(nil, mapped: mapped, area: "interest_suggest_encode")
            return InterestSuggestResponse(suggestions: [], loadingIssue: mapped.message(l10n: l10n))
        }

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let authed = await APITokenProvider.shared.authorizedRequest(request)
            var (data, response) = try await URLSession.shared.data(for: authed)
            if let firstHttp = response as? HTTPURLResponse, firstHttp.statusCode == 401 {
                let retried = await APITokenProvider.shared.authorizedRequest(request, forceRefresh: true)
                (data, response) = try await URLSession.shared.data(for: retried)
            }
            if Task.isCancelled { throw CancellationError() }
            guard let http = response as? HTTPURLResponse else {
                let mapped = OmakaseError.serviceUnavailable
                ErrorReporter.record(nil, mapped: mapped, area: "interest_suggest_response")
                return InterestSuggestResponse(suggestions: [], loadingIssue: mapped.message(l10n: l10n))
            }
            guard (200..<300).contains(http.statusCode) else {
                let mapped = OmakaseError.fromHTTP(
                    status: http.statusCode,
                    data: data,
                    retryAfterHeader: http.value(forHTTPHeaderField: "Retry-After")
                )
                let finalMapped = mapped == .unknown ? OmakaseError.generationFailed : mapped
                ErrorReporter.record(
                    nil,
                    mapped: finalMapped,
                    area: "interest_suggest_http",
                    metadata: ["status": "\(http.statusCode)"]
                )
                return InterestSuggestResponse(suggestions: [], loadingIssue: finalMapped.message(l10n: l10n))
            }
            guard
                let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let list = decoded["suggestions"] as? [String]
            else {
                let mapped = OmakaseError.generationFailed
                ErrorReporter.record(nil, mapped: mapped, area: "interest_suggest_decode")
                return InterestSuggestResponse(suggestions: [], loadingIssue: mapped.message(l10n: l10n))
            }
            let cleaned = list.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            if cleaned.isEmpty {
                return InterestSuggestResponse(suggestions: [], loadingIssue: l10n.couldNotLoadIdeas)
            }
            return InterestSuggestResponse(suggestions: cleaned, loadingIssue: nil)
        } catch let error as CancellationError {
            throw error
        } catch {
            let mapped = OmakaseError.from(error)
            ErrorReporter.record(error, mapped: mapped, area: "interest_suggest")
            return InterestSuggestResponse(
                suggestions: [],
                loadingIssue: mapped.message(l10n: l10n)
            )
        }
    }
}
