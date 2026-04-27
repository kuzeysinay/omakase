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

    /// The backend base URL.  Mirrors the resolution logic in FeedViewModel.
    private static let baseURL: URL = {
        if
            let raw = Bundle.main.object(forInfoDictionaryKey: "OMAKASE_API_URL") as? String,
            let url = URL(string: raw)
        {
            return url
        }
        return URL(string: "http://127.0.0.1:8000")!
    }()

    // MARK: - Public

    /// Fetch AI suggestions for the given interests + draft text.
    /// `excludeSuggestions` lists ideas already shown so the API returns different ones (e.g. refresh).
    /// - Throws: `CancellationError` when the calling task is cancelled.
    static func suggest(
        interests: [String],
        draft: String,
        excludeSuggestions: [String] = []
    ) async throws -> InterestSuggestResponse {
        let url = baseURL.appendingPathComponent("interests/suggest")
        var body: [String: Any] = [
            "interests": interests,
            "draft": draft,
        ]
        if !excludeSuggestions.isEmpty {
            body["exclude_suggestions"] = excludeSuggestions
        }
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            return InterestSuggestResponse(suggestions: [], loadingIssue: "Could not build the request.")
        }

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if Task.isCancelled { throw CancellationError() }
            guard let http = response as? HTTPURLResponse else {
                return InterestSuggestResponse(suggestions: [], loadingIssue: "Invalid server response.")
            }
            guard (200..<300).contains(http.statusCode) else {
                let detail = Self.parseFastAPIDetail(data: data)
                    ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
                return InterestSuggestResponse(
                    suggestions: [],
                    loadingIssue: "Suggestions failed (\(http.statusCode)): \(detail)"
                )
            }
            guard
                let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let list = decoded["suggestions"] as? [String]
            else {
                return InterestSuggestResponse(
                    suggestions: [],
                    loadingIssue: "Server returned an unexpected format."
                )
            }
            let cleaned = list.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            if cleaned.isEmpty {
                return InterestSuggestResponse(
                    suggestions: [],
                    loadingIssue: "No ideas in the response. Try refresh or check the backend logs."
                )
            }
            return InterestSuggestResponse(suggestions: cleaned, loadingIssue: nil)
        } catch let error as CancellationError {
            throw error
        } catch {
            return InterestSuggestResponse(
                suggestions: [],
                loadingIssue: error.localizedDescription
            )
        }
    }

    /// FastAPI often uses `{ "detail": "..." }` or a validation array for errors.
    private static func parseFastAPIDetail(data: Data) -> String? {
        guard
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        if let s = obj["detail"] as? String {
            return s
        }
        if let arr = obj["detail"] as? [[String: Any]] {
            let parts = arr.compactMap { $0["msg"] as? String }
            if !parts.isEmpty { return parts.joined(separator: " ") }
        }
        return nil
    }
}
