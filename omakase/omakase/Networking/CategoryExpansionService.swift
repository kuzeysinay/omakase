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
        // 1. Try dedicated expand-category endpoint
        let url = baseURL.appendingPathComponent("interests/expand-category")
        let body: [String: Any] = [
            "category": category,
            "existing_interests": existingInterests,
            "language": language.rawValue,
        ]

        if let bodyData = try? JSONSerialization.data(withJSONObject: body) {
            var request = URLRequest(url: url, timeoutInterval: 10)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if Task.isCancelled { throw CancellationError() }

                if let http = response as? HTTPURLResponse,
                   (200..<300).contains(http.statusCode),
                   let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let list = decoded["suggestions"] as? [String] {
                    let cleaned = list
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    if cleaned.count >= 6 {
                        return cleaned
                    }
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // Proceed to fallback endpoint
            }
        }

        // 2. Fallback to /interests/suggest with draft and exclude list
        let fallbackURL = baseURL.appendingPathComponent("interests/suggest")
        let fallbackBody: [String: Any] = [
            "interests": [],
            "draft": category,
            "exclude_suggestions": existingInterests,
            "language": language.rawValue,
        ]

        if let fallbackData = try? JSONSerialization.data(withJSONObject: fallbackBody) {
            var fallbackReq = URLRequest(url: fallbackURL, timeoutInterval: 8)
            fallbackReq.httpMethod = "POST"
            fallbackReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            fallbackReq.httpBody = fallbackData

            do {
                let (fData, fResp) = try await URLSession.shared.data(for: fallbackReq)
                if Task.isCancelled { throw CancellationError() }

                if let fHttp = fResp as? HTTPURLResponse,
                   (200..<300).contains(fHttp.statusCode),
                   let fDecoded = try JSONSerialization.jsonObject(with: fData) as? [String: Any],
                   let fList = fDecoded["suggestions"] as? [String] {
                    let cleaned = fList
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    if !cleaned.isEmpty {
                        return cleaned
                    }
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // Handled below
            }
        }

        return []
    }
}
