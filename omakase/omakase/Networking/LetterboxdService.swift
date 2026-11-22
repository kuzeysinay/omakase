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

    /// Centralized backend base URL (`APITokenProvider.baseURL`).
    private static var baseURL: URL { APITokenProvider.baseURL }

    // MARK: - Public

    /// Fetch the user's recently watched films from Letterboxd via the backend.
    /// - Parameters:
    ///   - username: The Letterboxd username (e.g. "kuzeysinay").
    ///   - limit: Maximum number of films to return (default 50).
    /// - Returns: An array of `LetterboxdFilm`.
    /// - Throws: `CancellationError` or `OmakaseError`.
    static func fetchFilms(
        username: String,
        limit: Int = 50
    ) async throws -> [LetterboxdFilm] {
        let url = baseURL.appendingPathComponent("letterboxd/films")
        let body: [String: Any] = [
            "username": username,
            "limit": limit,
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw OmakaseError.serviceUnavailable
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let authed = await APITokenProvider.shared.authorizedRequest(request)
        var (data, response) = try await URLSession.shared.data(for: authed)
        if let firstHttp = response as? HTTPURLResponse, firstHttp.statusCode == 401 {
            let retried = await APITokenProvider.shared.authorizedRequest(request, forceRefresh: true)
            (data, response) = try await URLSession.shared.data(for: retried)
        }
        if Task.isCancelled { throw CancellationError() }

        guard let http = response as? HTTPURLResponse else {
            throw OmakaseError.serviceUnavailable
        }

        guard (200..<300).contains(http.statusCode) else {
            throw OmakaseError.fromHTTP(
                status: http.statusCode,
                data: data,
                retryAfterHeader: http.value(forHTTPHeaderField: "Retry-After")
            )
        }

        let decoded = try JSONDecoder().decode(LetterboxdFilmsResponse.self, from: data)
        return decoded.films
    }
}
