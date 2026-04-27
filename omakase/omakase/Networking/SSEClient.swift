//
//  SSEClient.swift
//  omakase
//
//  A tiny Server-Sent Events client built on top of URLSession's async
//  byte streams. It parses SSE frames incrementally and yields them as an
//  AsyncThrowingStream so callers can `for try await event in client.events(...)`.
//

import Foundation

struct SSEEvent: Sendable {
    var event: String
    var data: String
}

enum SSEError: Error, LocalizedError {
    case badResponse(status: Int)
    case notEventStream(contentType: String?)

    var errorDescription: String? {
        switch self {
        case .badResponse(let status):
            return "Server returned HTTP \(status)."
        case .notEventStream(let contentType):
            return "Expected text/event-stream, got \(contentType ?? "nothing")."
        }
    }
}

/// Opens an SSE connection and yields decoded events.
///
/// Usage:
/// ```swift
/// let stream = SSEClient.events(from: url, method: "POST", body: data)
/// for try await event in stream { ... }
/// ```
enum SSEClient {
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

                    let config = URLSessionConfiguration.ephemeral
                    config.requestCachePolicy = .reloadIgnoringLocalCacheData
                    config.timeoutIntervalForRequest = timeout
                    config.timeoutIntervalForResource = max(timeout, 300)
                    let session = URLSession(configuration: config)
                    let (bytes, response) = try await session.bytes(for: request)

                    guard let http = response as? HTTPURLResponse else {
                        throw SSEError.badResponse(status: -1)
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        throw SSEError.badResponse(status: http.statusCode)
                    }
                    let contentType = (http.value(forHTTPHeaderField: "Content-Type") ?? "").lowercased()
                    guard contentType.contains("text/event-stream") else {
                        throw SSEError.notEventStream(contentType: contentType)
                    }
                    // #region agent log
                    AgentDebugLog.log(
                        location: "SSEClient.swift:events",
                        message: "sse response ok",
                        hypothesisId: "H4",
                        data: [
                            "httpStatus": String(http.statusCode),
                            "contentType": contentType,
                        ]
                    )
                    // #endregion

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
