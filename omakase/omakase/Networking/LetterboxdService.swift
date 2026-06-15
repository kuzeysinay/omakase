//
//  LetterboxdService.swift
//  omakase
//
//  Lightweight service that calls POST /letterboxd/films on the backend
//  and returns recently watched films for the logged-in Letterboxd user.
//

import Foundation

/// A single film entry parsed from a Letterboxd RSS feed.
struct LetterboxdFilm: Codable, Sendable, Identifiable {
    var id: String { "\(title)-\(year ?? 0)-\(watchedDate ?? "")" }
    let title: String
    let year: Int?
    let rating: Double?
    let watchedDate: String?

    enum CodingKeys: String, CodingKey {
        case title
        case year
        case rating
        case watchedDate = "watched_date"
    }

    /// Converts to the dict format expected by the backend's FeedRequest.letterboxd_films.
    var asDictionary: [String: Any] {
        var d: [String: Any] = ["title": title]
        if let year { d["year"] = year }
        if let rating { d["rating"] = rating }
        if let watchedDate { d["watched_date"] = watchedDate }
        return d
    }
}

struct LetterboxdFilmsResponse: Codable, Sendable {
    let films: [LetterboxdFilm]
    let username: String
}

enum LetterboxdService {

    /// Mirrors the resolution logic in FeedViewModel / InterestSuggestor.
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

    /// Fetch the user's recently watched films from Letterboxd via the backend.
    /// - Parameters:
    ///   - username: The Letterboxd username (e.g. "kuzeysinay").
    ///   - limit: Maximum number of films to return (default 5).
    /// - Returns: An array of `LetterboxdFilm`.
    /// - Throws: `CancellationError` or a descriptive error string.
    static func fetchFilms(
        username: String,
        limit: Int = 5
    ) async throws -> [LetterboxdFilm] {
        let url = baseURL.appendingPathComponent("letterboxd/films")
        let body: [String: Any] = [
            "username": username,
            "limit": limit,
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw LetterboxdError.badRequest
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)
        if Task.isCancelled { throw CancellationError() }

        guard let http = response as? HTTPURLResponse else {
            throw LetterboxdError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            // Try to extract FastAPI detail message.
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = obj["detail"] as? String {
                throw LetterboxdError.serverError(detail)
            }
            throw LetterboxdError.serverError("HTTP \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(LetterboxdFilmsResponse.self, from: data)
        return decoded.films
    }
}

enum LetterboxdError: Error, LocalizedError {
    case badRequest
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .badRequest:
            return "Could not build the Letterboxd request."
        case .invalidResponse:
            return "Invalid server response."
        case .serverError(let detail):
            return detail
        }
    }
}
