//
//  SSEClient.swift
//  omakase
//
//  A tiny Server-Sent Events client built on top of URLSession's async
//  byte streams. It parses SSE frames incrementally and yields them as an
//  AsyncThrowingStream so callers can `for try await event in client.events(...)`.
//

import Foundation
import FirebaseAuth
import Security

/// Centralizes backend base URL resolution and Firebase Auth Bearer token attachment
/// (`knowledge.networking.authenticated-requests` Rules 1-4 & `knowledge.xcode.build-configurations`).
actor APITokenProvider {
    static let shared = APITokenProvider()

    private var refreshTask: Task<String?, Never>?
    private var cachedToken: String?
    private var cachedUID: String?
    private var cachedTokenExpiry: Date = .distantPast

    /// Resolves `OMAKASE_API_URL` from `Info.plist`, falling back to localhost only in `DEBUG` builds.
    nonisolated static let baseURL: URL = {
        if
            let raw = Bundle.main.object(forInfoDictionaryKey: "OMAKASE_API_URL") as? String,
            let url = URL(string: raw)
        {
            return url
        }
        #if DEBUG
        return URL(string: "http://127.0.0.1:8000")!
        #else
        return URL(string: "https://omakase-backend-20235796246.us-central1.run.app")!
        #endif
    }()

    /// Anonymous, non-tracking Keychain installation identifier used solely for
    /// server-side daily free-quota anti-abuse across account switches/deletions.
    /// Never synced to iCloud and never cleared on sign-out or account deletion.
    private nonisolated static let quotaDeviceID: String = {
        let service = "kuzeysinay.omakase.device"
        let account = "quota_device_id"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let existing = String(data: data, encoding: .utf8),
           !existing.isEmpty {
            return existing
        }

        let generated = UUID().uuidString.lowercased()
        if let data = generated.data(using: .utf8) {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
            SecItemAdd(addQuery as CFDictionary, nil)
        }
        return generated
    }()

    /// Attaches `Authorization: Bearer <token>` and `X-Omakase-Device-Id` to the request.
    /// Never logs the token value (`authenticated-requests` Rule 4).
    func authorizedRequest(_ request: URLRequest, forceRefresh: Bool = false) async -> URLRequest {
        var authed = request
        authed.setValue(Self.quotaDeviceID, forHTTPHeaderField: "X-Omakase-Device-Id")
        if let token = await fetchToken(forceRefresh: forceRefresh) {
            authed.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return authed
    }

    /// Clears any cached Firebase ID token (for example, on sign-out or account switch).
    func invalidateCache() {
        refreshTask?.cancel()
        refreshTask = nil
        cachedToken = nil
        cachedUID = nil
        cachedTokenExpiry = .distantPast
    }

    /// Single-flight token fetch/refresh with in-memory caching (`authenticated-requests` Rule 2).
    func fetchToken(forceRefresh: Bool = false) async -> String? {
        let currentUID = await MainActor.run { Auth.auth().currentUser?.uid }
        guard let currentUID else {
            cachedToken = nil
            cachedUID = nil
            cachedTokenExpiry = .distantPast
            return nil
        }

        if
            !forceRefresh,
            cachedUID == currentUID,
            let cachedToken,
            Date() < cachedTokenExpiry
        {
            return cachedToken
        }

        if let existing = refreshTask {
            return await existing.value
        }

        let task = Task<String?, Never> {
            guard let user = await MainActor.run(body: { Auth.auth().currentUser }) else { return nil }
            return try? await user.getIDToken(forcingRefresh: forceRefresh)
        }
        refreshTask = task
        let token = await task.value
        refreshTask = nil

        if let token {
            cachedToken = token
            cachedUID = currentUID
            // Cache for 45 minutes (Firebase ID tokens are valid for 60 minutes)
            cachedTokenExpiry = Date().addingTimeInterval(45 * 60)
        }
        return token
    }
}

struct SSEEvent: Sendable {
    var event: String
    var data: String
}

enum SSEError: Error, Sendable {
    case badResponse(status: Int, code: String?, retryAfter: Int?, resetsAt: String?, kind: String?)
    case notEventStream(contentType: String?)
}

/// Opens an SSE connection and yields decoded events.
///
/// Usage:
/// ```swift
/// let stream = SSEClient.events(from: url, method: "POST", body: data)
/// for try await event in stream { ... }
/// ```
enum SSEClient {
    /// Shared ephemeral session reused across SSE streams so HTTP/2 TLS connections stay warm
    /// (`knowledge.networking.url-session-configuration` Rules 1-4).
    private nonisolated static let streamSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    /// Not isolated to the main actor so callers can open streams from
    /// `Task.detached` (the app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).
    nonisolated static func events(
        from url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 60
    ) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: url, timeoutInterval: timeout)
                    request.httpMethod = method
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                    // Avoid middleboxes or stacks that hand gzip to the app as opaque bytes, which can break SSE.
                    request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
                    for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
                    if let body {
                        request.httpBody = body
                        if request.value(forHTTPHeaderField: "Content-Type") == nil {
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        }
                    }

                    let session = Self.streamSession

                    let authedRequest = await APITokenProvider.shared.authorizedRequest(request)
                    var (bytes, response) = try await session.bytes(for: authedRequest)

                    if let firstHttp = response as? HTTPURLResponse, firstHttp.statusCode == 401 {
                        // Single-flight 401 token refresh and retry once (Rule 2)
                        let retryRequest = await APITokenProvider.shared.authorizedRequest(request, forceRefresh: true)
                        (bytes, response) = try await session.bytes(for: retryRequest)
                    }

                    guard let http = response as? HTTPURLResponse else {
                        throw SSEError.badResponse(
                            status: -1,
                            code: nil,
                            retryAfter: nil,
                            resetsAt: nil,
                            kind: nil
                        )
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        var errorData = Data()
                        for try await byte in bytes {
                            if Task.isCancelled { break }
                            errorData.append(byte)
                            if errorData.count >= 8192 { break }
                        }
                        var code: String?
                        var retryAfter: Int?
                        var resetsAt: String?
                        var kind: String?
                        if !errorData.isEmpty,
                           let obj = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any] {
                            code = obj["code"] as? String
                            if let raInt = obj["retry_after"] as? Int {
                                retryAfter = raInt
                            } else if let raDouble = obj["retry_after"] as? Double {
                                retryAfter = Int(ceil(raDouble))
                            }
                            resetsAt = obj["resets_at"] as? String
                            kind = obj["kind"] as? String
                        }
                        if retryAfter == nil,
                           let raHeader = http.value(forHTTPHeaderField: "Retry-After")?.trimmingCharacters(in: .whitespacesAndNewlines),
                           let parsed = Int(raHeader) {
                            retryAfter = parsed
                        }
                        throw SSEError.badResponse(
                            status: http.statusCode,
                            code: code,
                            retryAfter: retryAfter,
                            resetsAt: resetsAt,
                            kind: kind
                        )
                    }
                    let contentType = (http.value(forHTTPHeaderField: "Content-Type") ?? "").lowercased()
                    guard contentType.contains("text/event-stream") else {
                        throw SSEError.notEventStream(contentType: contentType)
                    }

                    // Assemble a byte buffer and split on `\n\n` / `\r\n\r\n` so the event
                    // boundary never depends on line iteration quirks or UTF-8 line assembly.
                    try await Self.scanSSE(
                        from: bytes,
                        onYield: { continuation.yield($0) },
                        isCancelled: { Task.isCancelled }
                    )

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            // Only cancel the URLSession work when the *consumer* cancels the
            // stream. Calling `task.cancel()` on a normal `.finished` termination
            // races the producer and can kill the connection before any bytes
            // are delivered (symptom: empty feed, no error).
            continuation.onTermination = { reason in
                if case .cancelled = reason {
                    task.cancel()
                }
            }
        }
    }

    private nonisolated static let sseDelimiterLF = Data([0x0A, 0x0A])
    private nonisolated static let sseDelimiterCRLF = Data([0x0D, 0x0A, 0x0D, 0x0A])

    /// Collects the response body and yields each SSE *event* as soon as a full frame
    /// (terminated by a blank line) is present, per the HTML / WHATWG spec.
    nonisolated private static func scanSSE(
        from bytes: URLSession.AsyncBytes,
        onYield: (SSEEvent) -> Void,
        isCancelled: () -> Bool
    ) async throws {
        var buffer = Data()
        for try await byte in bytes {
            if isCancelled() { break }
            buffer.append(byte)
            while let (frame, _) = extractNextSseFrame(from: &buffer) {
                if let ev = parseSseEventFrameData(frame) {
                    onYield(ev)
                }
            }
        }
        if isCancelled() { return }
        if !buffer.isEmpty {
            let tail = String(decoding: buffer, as: UTF8.self)
            if let ev = parseSseEventFrameString(tail) {
                onYield(ev)
            }
        }
    }

    /// Pops the first complete SSE event from the front of `buffer` (delimited by `\n\n` or
    /// `\r\n\r\n`, whichever occurs first) and returns `(frame, bytesRemoved)`.
    private nonisolated static func extractNextSseFrame(from buffer: inout Data) -> (Data, Int)? {
        if buffer.isEmpty { return nil }
        var bestFrameEnd: Int?
        var bestRemoveEnd: Int?
        if let r = buffer.range(of: sseDelimiterLF) {
            bestFrameEnd = r.lowerBound
            bestRemoveEnd = r.upperBound
        }
        if let r2 = buffer.range(of: sseDelimiterCRLF) {
            let fe = r2.lowerBound
            let re = r2.upperBound
            if bestFrameEnd == nil || fe < bestFrameEnd! {
                bestFrameEnd = fe
                bestRemoveEnd = re
            }
        }
        guard let fe = bestFrameEnd, let re = bestRemoveEnd else { return nil }
        let frame = buffer.subdata(in: buffer.startIndex..<fe)
        buffer.removeSubrange(buffer.startIndex..<re)
        return (frame, re)
    }

    private nonisolated static func parseSseEventFrameData(_ data: Data) -> SSEEvent? {
        let s = String(decoding: data, as: UTF8.self)
        return parseSseEventFrameString(s)
    }

    private nonisolated static func parseSseEventFrameString(_ block: String) -> SSEEvent? {
        if block.isEmpty { return nil }
        var eventName = "message"
        var dataLines: [String] = []
        for line in block.components(separatedBy: "\n") {
            var s = line
            if s.last == "\r" { s.removeLast() }
            if s.isEmpty { continue }
            if s.hasPrefix(":") { continue }
            let (field, value) = splitField(s)
            switch field {
            case "event": eventName = value
            case "data": dataLines.append(value)
            case "id", "retry": break
            default: break
            }
        }
        let payload = dataLines.joined(separator: "\n")
        if dataLines.isEmpty, eventName == "message" { return nil }
        return SSEEvent(event: eventName, data: payload)
    }

    nonisolated private static func splitField(_ line: String) -> (String, String) {
        guard let colon = line.firstIndex(of: ":") else {
            return (line, "")
        }
        let field = String(line[..<colon])
        var valueStart = line.index(after: colon)
        // A single leading space after the colon is part of the framing, not the value.
        if valueStart < line.endIndex, line[valueStart] == " " {
            valueStart = line.index(after: valueStart)
        }
        return (field, String(line[valueStart...]))
    }
}
