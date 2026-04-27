//
//  FeedViewModel.swift
//  omakase
//

import Foundation
import Observation

@Observable
@MainActor
final class FeedViewModel {

    // MARK: - Published state

    private(set) var posts: [Post] = []
    private(set) var isGenerating: Bool = false
    private(set) var errorMessage: String?

    // MARK: - Config

    /// The backend URL. Override by adding `OMAKASE_API_URL` as a string in
    /// the app target's Info.plist. Defaults to the value below, which works
    /// for the iOS Simulator talking to a backend running on the same Mac.
    private let baseURL: URL = {
        if
            let raw = Bundle.main.object(forInfoDictionaryKey: "OMAKASE_API_URL") as? String,
            let url = URL(string: raw)
        {
            return url
        }
        return URL(string: "http://127.0.0.1:8000")!
    }()

    private var interests: [String]
    private var streamingTask: Task<Void, Never>?
    /// The post the current `streamingTask` is filling; only that task may clear `isGenerating`.
    private var activeStreamPostID: UUID?

    // MARK: - Init

    init(interests: [String]) {
        self.interests = interests
    }

    func updateInterests(_ newValue: [String]) {
        interests = newValue
    }

    // MARK: - Actions

    /// Append a new post and start streaming it. Safe to call while another
    /// stream is in flight — the previous one is cancelled.
    func requestNextPost() {
        streamingTask?.cancel()
        errorMessage = nil

        let post = Post()
        // Whole-array assignment so @Observable reliably invalidates SwiftUI.
        posts = posts + [post]
        let postID = post.id
        isGenerating = true
        activeStreamPostID = postID

        // #region agent log
        AgentDebugLog.log(
            location: "FeedViewModel.swift:requestNextPost",
            message: "starting stream",
            hypothesisId: "H5",
            data: [
                "baseURL": baseURL.absoluteString,
                "streamPath": "feed/stream",
                "interestsCount": String(interests.count),
                "seenCount": String(max(posts.count - 1, 0)),
            ]
        )
        // #endregion

        let url = baseURL.appendingPathComponent("feed/stream")
        let requestBody: [String: Any] = [
            "interests": interests,
            "seen_count": max(posts.count - 1, 0),
        ]
        let bodyData = (try? JSONSerialization.data(withJSONObject: requestBody)) ?? Data()

        // `Task { }` created here would inherit MainActor and block the UI on
        // URLSession; use `detached` and hop back per event.
        let streamURL = url
        let streamBody = bodyData
        let streamPostID = postID
        streamingTask = Task.detached(priority: .userInitiated) {
            let stream = SSEClient.events(
                from: streamURL,
                method: "POST",
                headers: ["Content-Type": "application/json"],
                body: streamBody
            )

            do {
                for try await event in stream {
                    if Task.isCancelled { break }
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        self.handle(event: event, for: streamPostID)
                    }
                }
                let streamEndedByCancellation = Task.isCancelled
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if streamEndedByCancellation {
                        self.handleStreamAbandoned(postID: streamPostID)
                        // #region agent log
                        AgentDebugLog.log(
                            location: "FeedViewModel.swift:streamCancelAfterBreak",
                            message: "stream loop ended via cancellation (break); abandoned post",
                            hypothesisId: "H4",
                            data: [
                                "runId": "post-fix",
                            ]
                        )
                        // #endregion
                    } else {
                        // #region agent log
                        let p = self.posts.first { $0.id == streamPostID }
                        let incomplete = p.map { !$0.isComplete } ?? true
                        let len = p?.text.count ?? -1
                        AgentDebugLog.log(
                            location: "FeedViewModel.swift:streamLoopEnd",
                            message: "for-await stream finished",
                            hypothesisId: "H4",
                            data: [
                                "postIncomplete": String(incomplete),
                                "textLength": String(len),
                                "runId": "post-fix",
                            ]
                        )
                        // #endregion
                        if
                            let p,
                            !p.isComplete,
                            p.text.isEmpty,
                            self.errorMessage == nil
                        {
                            self.errorMessage = (
                                "The feed stream ended with no post text. Check that the backend is running, "
                                + "GEMINI_API_KEY and GEMINI_MODEL are set, and the device can reach the API (on a real "
                                + "iPhone, use your Mac’s LAN address instead of 127.0.0.1 in OMAKASE_API_URL)."
                            )
                            self.markPostComplete(streamPostID)
                        }
                    }
                }
            } catch is CancellationError {
                await MainActor.run { [weak self] in
                    self?.handleStreamAbandoned(postID: streamPostID)
                }
            } catch {
                // #region agent log
                AgentDebugLog.log(
                    location: "FeedViewModel.swift:streamError",
                    message: "stream threw",
                    hypothesisId: "H4",
                    data: [
                        "error": String(describing: error),
                        "runId": "post-fix",
                    ]
                )
                // #endregion
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.errorMessage = error.localizedDescription
                    self.markPostComplete(streamPostID)
                }
            }
            await MainActor.run { [weak self] in
                guard
                    let self,
                    self.activeStreamPostID == streamPostID
                else { return }
                self.isGenerating = false
            }
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    func reset() {
        streamingTask?.cancel()
        streamingTask = nil
        activeStreamPostID = nil
        posts = []
        isGenerating = false
        errorMessage = nil
    }

    // MARK: - Private

    private func handle(event: SSEEvent, for postID: UUID) {
        // Each event's `data` is a JSON object. Parse defensively so a single
        // malformed frame doesn't take down the stream.
        let payload = Self.decodeJSON(event.data)
        // #region agent log
        let dataPrefix = String(event.data.prefix(200))
        if event.event == "start" || event.event == "done" || event.event == "error" {
            AgentDebugLog.log(
                location: "FeedViewModel.swift:handle",
                message: "sse event",
                hypothesisId: "H1",
                data: [
                    "eventName": event.event,
                    "dataLen": String(event.data.count),
                    "payloadKeys": payload.keys.sorted().joined(separator: ","),
                    "dataPrefix": dataPrefix,
                ]
            )
        } else if event.event == "token" {
            let hasText = payload["text"] as? String != nil
            if !hasText {
                AgentDebugLog.log(
                    location: "FeedViewModel.swift:handle",
                    message: "token without string text",
                    hypothesisId: "H2",
                    data: [
                        "payloadKeys": payload.keys.sorted().joined(separator: ","),
                        "dataPrefix": dataPrefix,
                    ]
                )
            }
        }
        // #endregion

        switch event.event {
        case "token":
            if let text = payload["text"] as? String {
                // #region agent log
                if text.count > 0 {
                    let cur = posts.first { $0.id == postID }?.text.count ?? 0
                    if cur == 0 {
                        AgentDebugLog.log(
                            location: "FeedViewModel.swift:handle",
                            message: "first token chunk for post",
                            hypothesisId: "H1",
                            data: ["chunkLen": String(text.count)]
                        )
                    }
                }
                // #endregion
                appendText(text, to: postID)
            }
        case "done":
            markPostComplete(postID)
        case "error":
            let message = (payload["message"] as? String) ?? "Unknown server error."
            errorMessage = message
            markPostComplete(postID)
        default:
            // `start` or anything we don't care about — ignore.
            break
        }
    }

    private func appendText(_ text: String, to postID: UUID) {
        guard let idx = posts.firstIndex(where: { $0.id == postID }) else {
            // #region agent log
            AgentDebugLog.log(
                location: "FeedViewModel.swift:appendText",
                message: "post id not in posts",
                hypothesisId: "H3",
                data: ["postID": postID.uuidString, "postsCount": String(posts.count)]
            )
            // #endregion
            return
        }
        var copy = posts
        copy[idx].text.append(contentsOf: text)
        posts = copy
    }

    private func markPostComplete(_ postID: UUID) {
        guard let idx = posts.firstIndex(where: { $0.id == postID }) else { return }
        var copy = posts
        copy[idx].isComplete = true
        posts = copy
    }

    /// When a stream is superseded (new request) or cancelled, avoid stuck LIVE / empty "…" cards.
    private func handleStreamAbandoned(postID: UUID) {
        guard let idx = posts.firstIndex(where: { $0.id == postID }) else { return }
        if posts[idx].text.isEmpty {
            var copy = posts
            copy.remove(at: idx)
            posts = copy
        } else {
            markPostComplete(postID)
        }
    }

    private static func decodeJSON(_ raw: String) -> [String: Any] {
        guard
            let data = raw.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        return obj
    }
}

// #region agent log
enum AgentDebugLog {
    private static let ingestURL = URL(string: "http://127.0.0.1:7607/ingest/20ae730c-fbc4-40a0-8eec-3e252145ce8f")!
    private static let sessionId = "2ae36b"

    static func log(
        location: String,
        message: String,
        hypothesisId: String,
        data: [String: String] = [:]
    ) {
        let ts = Int64(Date().timeIntervalSince1970 * 1000)
        var payload: [String: Any] = [
            "sessionId": sessionId,
            "location": location,
            "message": message,
            "hypothesisId": hypothesisId,
            "timestamp": ts,
            "data": data,
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        if let line = String(data: body, encoding: .utf8) {
            print("[agent-debug] \(line)")
        }
        var request = URLRequest(url: ingestURL, timeoutInterval: 5)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionId, forHTTPHeaderField: "X-Debug-Session-Id")
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error {
                print("[agent-debug] Ingest POST failed: \(error.localizedDescription) — .cursor debug log file on Mac will not be updated (ingest on 127.0.0.1:7607 not reachable or not running).")
                return
            }
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                print("[agent-debug] Ingest returned HTTP \(http.statusCode) — .cursor log may be empty.")
            }
        }.resume()
    }
}
// #endregion
