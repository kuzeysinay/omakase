//
//  CategoryExpansionService.swift
//  omakase
//
//  Lightweight service that calls POST /interests/expand-category and
//  returns AI-generated sub-interests for a given category.
//

import Foundation

enum CategoryExpansionService {

    /// The backend base URL — mirrors InterestSuggestor's resolution logic.
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

    /// Expand a category into specific sub-interest suggestions.
    /// - Parameters:
    ///   - category: The broad category name (e.g. "Film", "Müzik").
    ///   - existingInterests: Interests already added, so the backend can exclude them.
    ///   - language: `AppLanguage` for localized suggestions.
    /// - Returns: An array of specific interest strings.
    /// - Throws: `CancellationError` when the calling task is cancelled.
    static func expand(
        category: String,
        existingInterests: [String],
        language: AppLanguage
    ) async throws -> [String] {
        let url = baseURL.appendingPathComponent("interests/expand-category")
        let body: [String: Any] = [
            "category": category,
            "existing_interests": existingInterests,
            "language": language.rawValue,
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            return []
        }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)
        if Task.isCancelled { throw CancellationError() }

        guard
            let http = response as? HTTPURLResponse,
            (200..<300).contains(http.statusCode),
            let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let list = decoded["suggestions"] as? [String]
        else {
            return []
        }

        return list
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
