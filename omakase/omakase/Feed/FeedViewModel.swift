//
//  FeedViewModel.swift
//  omakase
//

import Foundation
import Network
import Observation

@Observable
@MainActor
final class FeedViewModel {

    // MARK: - Published state

    private(set) var posts: [Post] = []
    private(set) var isGenerating: Bool = false
    private(set) var errorMessage: String?
    /// Cycles while ``isGenerating`` so the UI can show rotating “kitchen” lines.
    private(set) var loadingQuipIndex: Int = 0

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

    /// Mirrors UI language for localized transport errors and API payload `language`.
    private var contentLanguage: AppLanguage = .english

    private(set) var isOffline = false
    private(set) var isShowingCachedContent = false
    private let monitor = NWPathMonitor()

    private var interests: [String]
    private var streamingTask: Task<Void, Never>?
    private var loadingQuipTask: Task<Void, Never>?
    /// The post the current `streamingTask` is filling; only that task may clear `isGenerating`.
    private var activeStreamPostID: UUID?

    // MARK: - Letterboxd

    /// Recently fetched films from Letterboxd (cached across post generations).
    private(set) var letterboxdFilms: [LetterboxdFilm] = []
    /// Whether Letterboxd mode is currently active for post generation.
    var isLetterboxdActive: Bool = false
    /// The Letterboxd username, persisted via FeedView's @AppStorage.
    var letterboxdUsername: String = ""
    private(set) var isFetchingLetterboxd: Bool = false
    private(set) var letterboxdError: String?
    
    // Typewriter effect state removed (handled by backend token drip)

    // MARK: - Init

    init(interests: [String]) {
        self.interests = interests
        startNetworkMonitoring()
    }

    func updateInterests(_ newValue: [String]) {
        interests = newValue
    }

    func setContentLanguage(_ lang: AppLanguage) {
        contentLanguage = lang
    }

    // MARK: - Actions

    /// Append a new post **at the end** and start streaming it. Safe to call while another
    /// stream is in flight — the previous one is cancelled.
    func requestNextPost() {
        streamingTask?.cancel()
        errorMessage = nil

        let post = Post()
        // Newest last — append so new posts appear below in Reels-style feed.
        posts.append(post)
        let postID = post.id
        isGenerating = true
        activeStreamPostID = postID
        startLoadingQuipRotation()

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
        var requestBody: [String: Any] = [
            "interests": interests,
            "seen_count": max(posts.count - 1, 0),
            "language": contentLanguage.rawValue,
        ]

        // Inject Letterboxd films when the mode is active.
        if isLetterboxdActive, !letterboxdFilms.isEmpty {
            requestBody["letterboxd_films"] = letterboxdFilms.map { $0.asDictionary }
        }

        let bodyData = (try? JSONSerialization.data(withJSONObject: requestBody)) ?? Data()

        // `Task { }` created here would inherit MainActor and block the UI on
        // URLSession; use `detached` and hop back per event.
        let streamURL = url
        let streamBody = bodyData
        let streamPostID = postID
        let apiBaseForErrors = baseURL
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
                    let isBodyToken = (event.event == "token")
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        self.handle(event: event, for: streamPostID)
                    }
                    if isBodyToken {
                        await Task.yield()
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
                            let l10n = L10n(lang: self.contentLanguage)
                            self.errorMessage = l10n.streamEndedNoText
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
                    self.errorMessage = Self.friendlyStreamError(
                        error,
                        apiBase: apiBaseForErrors,
                        l10n: L10n(lang: self.contentLanguage)
                    )
                    self.markPostComplete(streamPostID)
                }
            }
            await MainActor.run { [weak self] in
                guard
                    let self,
                    self.activeStreamPostID == streamPostID
                else { return }
                self.isGenerating = false
                self.stopLoadingQuipRotation()
            }
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    func cookingCaption(l10n: L10n) -> String {
        let quips = l10n.cookingQuips
        guard !quips.isEmpty else { return "" }
        return quips[loadingQuipIndex % quips.count]
    }

    func reset() {
        streamingTask?.cancel()
        streamingTask = nil
        activeStreamPostID = nil
        posts = []
        isGenerating = false
        errorMessage = nil
        stopLoadingQuipRotation()
        loadingQuipIndex = 0
    }

    func removePost(id: UUID) {
        posts.removeAll { $0.id == id }
    }

    // MARK: - Network monitoring

    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOffline = (path.status != .satisfied)
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }

    // MARK: - Offline cache

    func loadCachedPosts() async {
        let cached = await PostCacheService.shared.loadCachedPosts()
        if !cached.isEmpty {
            posts = cached
            isShowingCachedContent = true
        }
    }

    // MARK: - Letterboxd

    /// Fetch the user's recently watched films from Letterboxd (via the backend).
    /// Results are cached in `letterboxdFilms` and reused across post generations.
    func fetchLetterboxdFilms() {
        let username = letterboxdUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else {
            letterboxdError = "No Letterboxd username set."
            return
        }
        isFetchingLetterboxd = true
        letterboxdError = nil

        Task {
            do {
                let films = try await LetterboxdService.fetchFilms(username: username)
                await MainActor.run {
                    self.letterboxdFilms = films
                    self.isFetchingLetterboxd = false
                    if films.isEmpty {
                        self.letterboxdError = "No films found for @\(username)."
                    }
                }
            } catch is CancellationError {
                // ignore
            } catch {
                await MainActor.run {
                    self.letterboxdError = error.localizedDescription
                    self.isFetchingLetterboxd = false
                }
            }
        }
    }

    // MARK: - Deep Dive

    func requestDeepDive(for post: Post) {
        streamingTask?.cancel()
        guard !isGenerating else { return }
        isGenerating = true
        errorMessage = nil

        guard let idx = posts.firstIndex(where: { $0.id == post.id }) else {
            isGenerating = false
            return
        }
        var copy = posts
        copy[idx].isComplete = false
        // Initialize deepDiveText to direct incoming tokens to the deep dive section.
        if copy[idx].deepDiveText == nil {
            copy[idx].deepDiveText = ""
        }
        posts = copy

        let deepDiveId = post.id
        activeStreamPostID = deepDiveId
        startLoadingQuipRotation()

        let url = baseURL.appendingPathComponent("feed/deep-dive")
        let requestBody: [String: Any] = [
            "original_title": post.title,
            "original_text": post.text,
            "interests": interests,
            "language": contentLanguage.rawValue,
        ]
        let bodyData = (try? JSONSerialization.data(withJSONObject: requestBody)) ?? Data()

        let streamURL = url
        let streamBody = bodyData
        let streamPostID = deepDiveId
        let apiBaseForErrors = baseURL
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
                    let isBodyToken = (event.event == "token")
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        self.handle(event: event, for: streamPostID)
                    }
                    if isBodyToken {
                        await Task.yield()
                    }
                }
                let streamEndedByCancellation = Task.isCancelled
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if streamEndedByCancellation {
                        self.handleStreamAbandoned(postID: streamPostID)
                    } else {
                        let p = self.posts.first { $0.id == streamPostID }
                        if let p, !p.isComplete, p.text.isEmpty, self.errorMessage == nil {
                            let l10n = L10n(lang: self.contentLanguage)
                            self.errorMessage = l10n.streamEndedNoText
                            self.markPostComplete(streamPostID)
                        }
                    }
                }
            } catch is CancellationError {
                await MainActor.run { [weak self] in
                    self?.handleStreamAbandoned(postID: streamPostID)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.errorMessage = Self.friendlyStreamError(
                        error,
                        apiBase: apiBaseForErrors,
                        l10n: L10n(lang: self.contentLanguage)
                    )
                    self.markPostComplete(streamPostID)
                }
            }
            await MainActor.run { [weak self] in
                guard
                    let self,
                    self.activeStreamPostID == streamPostID
                else { return }
                self.isGenerating = false
                self.stopLoadingQuipRotation()
            }
        }
    }

    // MARK: - Private

    private func startLoadingQuipRotation() {
        loadingQuipTask?.cancel()
        loadingQuipIndex = 0
        loadingQuipTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(2800))
                guard !Task.isCancelled else { break }
                guard self.isGenerating else { break }
                self.loadingQuipIndex += 1
            }
        }
    }

    private func stopLoadingQuipRotation() {
        loadingQuipTask?.cancel()
        loadingQuipTask = nil
    }

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
        case "format":
            if let format = payload["format"] as? String {
                setPostFormat(format, for: postID)
            }
        case "title":
            if let title = payload["title"] as? String {
                setTitle(title, for: postID)
            }
        case "tags":
            if let tags = payload["tags"] as? [String] {
                setTags(tags, for: postID)
            }
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
            if let idx = posts.firstIndex(where: { $0.id == postID }) {
                Task {
                    await PostCacheService.shared.cachePost(posts[idx])
                    await PostCacheService.shared.clearOldPosts()
                }
            }
        case "error":
            let message = (payload["message"] as? String) ?? "Unknown server error."
            errorMessage = message
            markPostComplete(postID)
        default:
            // `start` or anything we don't care about — ignore.
            break
        }
    }

    private func setTitle(_ title: String, for postID: UUID) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = posts.firstIndex(where: { $0.id == postID }) else { return }
        // Only set title if it's empty to prevent overwriting existing post titles during deep dives
        if posts[idx].title.isEmpty || posts[idx].title == "Diving deeper..." {
            var copy = posts
            copy[idx].title = trimmed
            posts = copy
        }
    }

    private func setTags(_ tags: [String], for postID: UUID) {
        guard !tags.isEmpty, let idx = posts.firstIndex(where: { $0.id == postID }) else { return }
        var copy = posts
        copy[idx].tags = tags
        posts = copy
    }

    private func setPostFormat(_ format: String, for postID: UUID) {
        guard let idx = posts.firstIndex(where: { $0.id == postID }) else { return }
        var copy = posts
        copy[idx].postFormat = format
        posts = copy
    }

    private func appendText(_ text: String, to postID: UUID) {
        guard let idx = posts.firstIndex(where: { $0.id == postID }) else { return }
        var copy = self.posts
        if copy[idx].deepDiveText != nil {
            copy[idx].deepDiveText! += text
        } else {
            copy[idx].text += text
        }
        self.posts = copy
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

    /// Maps URLSession / transport errors to a short hint (default URL error text is vague).
    private static func friendlyStreamError(_ error: Error, apiBase: URL, l10n: L10n) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost, .notConnectedToInternet,
                 .timedOut, .dnsLookupFailed:
                return l10n.couldNotConnect(apiBase: apiBase.absoluteString)
            default:
                break
            }
        }
        return error.localizedDescription
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
