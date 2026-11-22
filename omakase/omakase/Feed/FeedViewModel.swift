//
//  FeedViewModel.swift
//  omakase
//

import Foundation
import Network
import Observation
import SwiftUI

@Observable
@MainActor
final class FeedViewModel {

    // MARK: - Published state

    private(set) var posts: [Post] = []
    private(set) var isGenerating: Bool = false
    private(set) var activeError: OmakaseError?
    var pendingToastError: OmakaseError?
    private(set) var letterboxdIssue: OmakaseError?
    var shouldPresentSoftPaywall: Bool = false
    var requestedPaywallSource: PaywallSource?

    // MARK: - Config

    /// The backend URL — centralized via `APITokenProvider.baseURL`.
    private let baseURL: URL = APITokenProvider.baseURL

    /// Mirrors UI language for localized transport errors and API payload `language`.
    private var contentLanguage: AppLanguage = .english

    private(set) var isOffline = false
    private(set) var isShowingCachedContent = false
    private let monitor = NWPathMonitor()

    private var interests: [String]
    private var streamingTask: Task<Void, Never>?
    /// The post the current `streamingTask` is filling; only that task may clear `isGenerating`.
    private var activeStreamPostID: UUID?
    private var activeStreamHasError: Bool = false

    private enum RetryAction {
        case nextPost
        case dedicated(topic: String, categoryId: String?)
        case letterboxd(username: String)
        case deepDive(postID: UUID)
    }

    private var lastRetryAction: RetryAction?

    // MARK: - Letterboxd

    /// Recently fetched films from Letterboxd (cached across post generations).
    private(set) var letterboxdFilms: [LetterboxdFilm] = []
    /// Whether Letterboxd mode is currently active for post generation.
    var isLetterboxdActive: Bool = false
    /// The Letterboxd username, persisted via FeedView's @AppStorage.
    var letterboxdUsername: String = ""
    private(set) var isFetchingLetterboxd: Bool = false

    // MARK: - Reading Cooldown
    var readingCooldownRemaining: Int = 0
    var readingCooldownTotal: Int = 0
    private(set) var readingCooldownStartDate: Date?
    private(set) var readingCooldownEndDate: Date?
    var isCooldownActive: Bool { readingCooldownRemaining > 0 }
    private var cooldownTimerTask: Task<Void, Never>? = nil

    func startReadingCooldown(for text: String) {
        cooldownTimerTask?.cancel()
        // Calculate reading time based on word count (~200 words/min = ~3.3 words/sec)
        let words = text.split { $0.isWhitespace }.count
        // Ensure reading cooldown is between 15s and 25s
        let seconds = max(15, min(25, words / 3))
        let now = Date()
        let endDate = now.addingTimeInterval(TimeInterval(seconds))
        readingCooldownTotal = seconds
        readingCooldownRemaining = seconds
        readingCooldownStartDate = now
        readingCooldownEndDate = endDate

        cooldownTimerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { break }
                let remaining = endDate.timeIntervalSinceNow
                if remaining <= 0 {
                    readingCooldownRemaining = 0
                    readingCooldownStartDate = nil
                    readingCooldownEndDate = nil
                    if !AccessManager.shared.isPro,
                       !UserDefaults.standard.bool(forKey: "omakase.hasShownFirstPlatePaywall"),
                       posts.contains(where: { $0.isComplete && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                        shouldPresentSoftPaywall = true
                    }
                    break
                } else {
                    let nextSeconds = max(1, Int(ceil(remaining)))
                    if readingCooldownRemaining != nextSeconds {
                        readingCooldownRemaining = nextSeconds
                    }
                }
            }
        }
    }

    private func clearReadingCooldown() {
        cooldownTimerTask?.cancel()
        cooldownTimerTask = nil
        readingCooldownRemaining = 0
        readingCooldownStartDate = nil
        readingCooldownEndDate = nil
    }

    // MARK: - Init

    init(interests: [String]) {
        self.interests = interests
        self.letterboxdUsername = UserDefaults.standard.string(forKey: "omakase.letterboxd_username") ?? ""
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
        guard !isGenerating && !isCooldownActive else { return }
        if isOffline {
            pendingToastError = .offline
            return
        }
        if AccessManager.shared.isPlateLimitReached {
            return
        }

        streamingTask?.cancel()
        activeError = nil
        lastRetryAction = .nextPost

        let post = Post()
        // Newest last — append so new posts appear below in Reels-style feed.
        posts.append(post)
        let postID = post.id
        isGenerating = true
        activeStreamPostID = postID
        activeStreamHasError = false

        var requestBody: [String: Any] = [
            "interests": interests,
            "seen_count": max(posts.count - 1, 0),
            "language": contentLanguage.rawValue,
            "timezone": TimeZone.current.identifier,
        ]
        if isLetterboxdActive, !letterboxdFilms.isEmpty {
            requestBody["letterboxd_films"] = letterboxdFilms.map { $0.asDictionary }
        }

        streamPost(postID: postID, requestBody: requestBody, area: "feed_next")
    }

    /// Generate a single post specifically and exclusively focused on the tapped topic,
    /// without mutating the user's persistent interests list in memory.
    func requestDedicatedPost(topic: String, categoryId: String? = nil) {
        guard !isGenerating && !isCooldownActive else { return }
        if isOffline {
            pendingToastError = .offline
            return
        }
        if AccessManager.shared.isPlateLimitReached {
            return
        }

        streamingTask?.cancel()
        clearReadingCooldown()
        activeError = nil
        lastRetryAction = .dedicated(topic: topic, categoryId: categoryId)

        let resolvedCategoryId = categoryId ?? InterestCategory.resolveMainCategory(tags: [topic], title: topic).id
        let post = Post(tags: [topic], categoryId: resolvedCategoryId)
        posts.append(post)
        let postID = post.id
        isGenerating = true
        activeStreamPostID = postID
        activeStreamHasError = false

        var requestBody: [String: Any] = [
            "interests": [topic],
            "seen_count": max(posts.count - 1, 0),
            "language": contentLanguage.rawValue,
            "timezone": TimeZone.current.identifier,
        ]
        if isLetterboxdActive, !letterboxdFilms.isEmpty {
            requestBody["letterboxd_films"] = letterboxdFilms.map { $0.asDictionary }
        }

        streamPost(postID: postID, requestBody: requestBody, area: "feed_dedicated")
    }

    /// Shared SSE post-streaming helper used by feed, dedicated topic, and Letterboxd posts.
    private func streamPost(postID: UUID, requestBody: [String: Any], area: String) {
        let streamURL = baseURL.appendingPathComponent("feed/stream")
        let streamBody = (try? JSONSerialization.data(withJSONObject: requestBody)) ?? Data()
        let streamPostID = postID

        // `Task { }` created here would inherit MainActor and block the UI on
        // URLSession; use `detached` and hop back per event.
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
                    } else if let p = self.posts.first(where: { $0.id == streamPostID }),
                              !p.isComplete,
                              p.text.isEmpty,
                              !self.activeStreamHasError {
                        self.handleStreamFailure(
                            nil,
                            mapped: .generationFailed,
                            postID: streamPostID,
                            isDeepDive: false,
                            area: "\(area)_empty"
                        )
                    }
                }
            } catch is CancellationError {
                await MainActor.run { [weak self] in
                    self?.handleStreamAbandoned(postID: streamPostID)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    let mapped = OmakaseError.from(error)
                    self.handleStreamFailure(
                        error,
                        mapped: mapped == .unknown ? .generationFailed : mapped,
                        postID: streamPostID,
                        isDeepDive: false,
                        area: area
                    )
                }
            }

            await MainActor.run { [weak self] in
                guard
                    let self,
                    self.activeStreamPostID == streamPostID
                else { return }
                self.isGenerating = false
                if !self.activeStreamHasError,
                   let post = self.posts.first(where: { $0.id == streamPostID }),
                   post.isComplete,
                   !post.text.isEmpty {
                    self.startReadingCooldown(for: post.text)
                }
            }
        }
    }

    func retryLastRequest() {
        guard let action = lastRetryAction else { return }
        activeError = nil
        switch action {
        case .nextPost:
            requestNextPost()
        case .dedicated(let topic, let categoryId):
            requestDedicatedPost(topic: topic, categoryId: categoryId)
        case .letterboxd(let username):
            requestLetterboxdDedicatedPost(username: username)
        case .deepDive(let postID):
            if let post = posts.first(where: { $0.id == postID }) {
                requestDeepDive(for: post)
            }
        }
    }

    func dismissError() {
        activeError = nil
    }

    func dismissLetterboxdIssue() {
        letterboxdIssue = nil
    }

    func consumeToastError() -> OmakaseError? {
        defer { pendingToastError = nil }
        return pendingToastError
    }

    func reset() {
        streamingTask?.cancel()
        streamingTask = nil
        clearReadingCooldown()
        activeStreamPostID = nil
        activeStreamHasError = false
        posts = []
        isGenerating = false
        activeError = nil
        pendingToastError = nil
        letterboxdIssue = nil
    }

    func removePost(id: UUID) {
        posts.removeAll { $0.id == id }
        Task {
            await PostCacheService.shared.deleteCachedPost(id: id)
        }
    }

    // MARK: - Network monitoring

    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let isOffline = (path.status != .satisfied)
            Task { @MainActor in
                self.isOffline = isOffline
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
            letterboxdIssue = .letterboxdNotFound
            return
        }
        if isOffline {
            pendingToastError = .offline
            return
        }

        isFetchingLetterboxd = true
        letterboxdIssue = nil

        Task {
            do {
                let films = try await LetterboxdService.fetchFilms(username: username)
                await MainActor.run {
                    self.letterboxdFilms = films
                    self.isFetchingLetterboxd = false
                    if films.isEmpty {
                        ErrorReporter.record(nil, mapped: .letterboxdNotFound, area: "letterboxd_fetch_empty")
                        self.letterboxdIssue = .letterboxdNotFound
                    }
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.isFetchingLetterboxd = false
                }
            } catch {
                await MainActor.run {
                    let mapped = OmakaseError.from(error)
                    ErrorReporter.record(error, mapped: mapped, area: "letterboxd_fetch")
                    self.isFetchingLetterboxd = false
                    if mapped == .letterboxdNotFound || mapped == .letterboxdPrivate {
                        self.letterboxdIssue = mapped
                    } else {
                        self.presentError(mapped)
                    }
                }
            }
        }
    }

    /// Request a cinema post specifically contextualized with the user's Letterboxd watched films.
    func requestLetterboxdDedicatedPost(username overrideUsername: String? = nil) {
        guard !isGenerating && !isCooldownActive else { return }
        if isOffline {
            pendingToastError = .offline
            return
        }
        if AccessManager.shared.isPlateLimitReached {
            return
        }

        let previousUsername = letterboxdUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        if let overrideUsername, !overrideUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let cleanOverride = overrideUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanOverride.caseInsensitiveCompare(previousUsername) != .orderedSame {
                letterboxdFilms = []
            }
            self.letterboxdUsername = cleanOverride
        } else if previousUsername.isEmpty {
            self.letterboxdUsername = UserDefaults.standard.string(forKey: "omakase.letterboxd_username") ?? ""
        }

        let username = letterboxdUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else {
            letterboxdIssue = .letterboxdNotFound
            return
        }

        streamingTask?.cancel()
        clearReadingCooldown()
        activeError = nil
        letterboxdIssue = nil
        activeStreamHasError = false
        isLetterboxdActive = true
        lastRetryAction = .letterboxd(username: username)

        let post = Post(tags: ["Film"], categoryId: "film")
        posts.append(post)
        let postID = post.id
        isGenerating = true
        activeStreamPostID = postID

        if !letterboxdFilms.isEmpty {
            let requestBody: [String: Any] = [
                "interests": ["Film"],
                "seen_count": max(posts.count - 1, 0),
                "language": contentLanguage.rawValue,
                "timezone": TimeZone.current.identifier,
                "letterboxd_films": letterboxdFilms.map { $0.asDictionary },
            ]
            streamPost(postID: postID, requestBody: requestBody, area: "letterboxd_feed")
            return
        }

        isFetchingLetterboxd = true
        Task {
            do {
                let fetched = try await LetterboxdService.fetchFilms(username: username)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isFetchingLetterboxd = false
                    if fetched.isEmpty {
                        ErrorReporter.record(nil, mapped: .letterboxdNotFound, area: "letterboxd_empty")
                        self.handleStreamAbandoned(postID: postID)
                        if self.activeStreamPostID == postID {
                            self.isGenerating = false
                        }
                        self.isLetterboxdActive = false
                        self.letterboxdIssue = .letterboxdNotFound
                        return
                    }
                    self.letterboxdFilms = fetched
                    let requestBody: [String: Any] = [
                        "interests": ["Film"],
                        "seen_count": max(self.posts.count - 1, 0),
                        "language": self.contentLanguage.rawValue,
                        "timezone": TimeZone.current.identifier,
                        "letterboxd_films": fetched.map { $0.asDictionary },
                    ]
                    self.streamPost(postID: postID, requestBody: requestBody, area: "letterboxd_feed")
                }
            } catch is CancellationError {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isFetchingLetterboxd = false
                    self.handleStreamAbandoned(postID: postID)
                    if self.activeStreamPostID == postID {
                        self.isGenerating = false
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isFetchingLetterboxd = false
                    let mapped = OmakaseError.from(error)
                    ErrorReporter.record(error, mapped: mapped, area: "letterboxd_dedicated")
                    self.handleStreamAbandoned(postID: postID)
                    if self.activeStreamPostID == postID {
                        self.isGenerating = false
                    }
                    self.isLetterboxdActive = false
                    if mapped == .letterboxdNotFound || mapped == .letterboxdPrivate {
                        self.letterboxdIssue = mapped
                    } else {
                        self.presentError(mapped)
                    }
                }
            }
        }
    }

    // MARK: - Deep Dive

    func requestDeepDive(for post: Post) {
        if isOffline {
            pendingToastError = .offline
            return
        }
        if AccessManager.shared.isDeepDiveLimitReached {
            requestedPaywallSource = .deepDiveLimit
            return
        }
        guard !isGenerating else { return }

        streamingTask?.cancel()
        isGenerating = true
        activeError = nil
        activeStreamHasError = false
        lastRetryAction = .deepDive(postID: post.id)

        guard let targetPost = posts.first(where: { $0.id == post.id }) else {
            isGenerating = false
            return
        }
        targetPost.isComplete = false
        // Initialize deepDiveText to direct incoming tokens to the deep dive section.
        if targetPost.deepDiveText == nil {
            targetPost.deepDiveText = ""
        }

        let deepDiveId = post.id
        activeStreamPostID = deepDiveId

        let url = baseURL.appendingPathComponent("feed/deep-dive")
        let requestBody: [String: Any] = [
            "original_title": post.title,
            "original_text": post.text,
            "interests": interests,
            "language": contentLanguage.rawValue,
            "timezone": TimeZone.current.identifier,
        ]
        let bodyData = (try? JSONSerialization.data(withJSONObject: requestBody)) ?? Data()

        let streamURL = url
        let streamBody = bodyData
        let streamPostID = deepDiveId
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
                    } else if let p = self.posts.first(where: { $0.id == streamPostID }),
                              !p.isComplete,
                              (p.deepDiveText ?? "").isEmpty,
                              !self.activeStreamHasError {
                        self.handleStreamFailure(
                            nil,
                            mapped: .generationFailed,
                            postID: streamPostID,
                            isDeepDive: true,
                            area: "deep_dive_empty"
                        )
                    }
                }
            } catch is CancellationError {
                await MainActor.run { [weak self] in
                    self?.handleStreamAbandoned(postID: streamPostID)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    let mapped = OmakaseError.from(error)
                    self.handleStreamFailure(
                        error,
                        mapped: mapped == .unknown ? .generationFailed : mapped,
                        postID: streamPostID,
                        isDeepDive: true,
                        area: "deep_dive"
                    )
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

    // MARK: - Private

    private func handle(event: SSEEvent, for postID: UUID) {
        // Each event's `data` is a JSON object. Parse defensively so a single
        // malformed frame doesn't take down the stream.
        let payload = Self.decodeJSON(event.data)

        switch event.event {
        case "format":
            if let format = payload["format"] as? String {
                setPostFormat(format, for: postID)
            }
        case "title":
            if let title = (payload["title"] as? String) ?? (payload["text"] as? String) {
                setTitle(title, for: postID)
            }
        case "tags":
            if let tags = payload["tags"] as? [String] {
                setTags(tags, for: postID)
            }
        case "token":
            if let text = payload["text"] as? String {
                appendText(text, to: postID)
            }
        case "done":
            markPostComplete(postID)
            if let accessDict = payload["access"] as? [String: Any] {
                AccessManager.shared.applySSEAccessPayload(accessDict)
            }
            if let idx = posts.firstIndex(where: { $0.id == postID }) {
                Task {
                    await PostCacheService.shared.cachePost(posts[idx])
                    await PostCacheService.shared.clearOldPosts()
                }
            }
        case "error":
            let code = payload["code"] as? String
            let retryAfter = (payload["retry_after"] as? Int)
                ?? (payload["retry_after"] as? Double).map { Int(ceil($0)) }
            let resetsAtRaw = payload["resets_at"] as? String
            let kind = payload["kind"] as? String
            var mapped = OmakaseError.fromBackendCode(
                code,
                retryAfter: retryAfter,
                resetsAt: Self.parseISO8601Date(resetsAtRaw),
                kind: kind
            )
            if mapped == .unknown {
                mapped = .generationFailed
            }
            let isDeepDive = posts.first(where: { $0.id == postID })?.deepDiveText != nil
            handleStreamFailure(
                nil,
                mapped: mapped,
                postID: postID,
                isDeepDive: isDeepDive,
                area: isDeepDive ? "deep_dive_sse_error" : "feed_sse_error"
            )
        default:
            // `start` or anything we don't care about — ignore.
            break
        }
    }

    private func handleStreamFailure(
        _ rawError: Error?,
        mapped: OmakaseError,
        postID: UUID,
        isDeepDive: Bool,
        area: String
    ) {
        activeStreamHasError = true
        ErrorReporter.record(rawError, mapped: mapped, area: area)

        if isDeepDive {
            if let post = posts.first(where: { $0.id == postID }) {
                if (post.deepDiveText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    post.deepDiveText = nil
                }
                post.isComplete = true
            }
        } else {
            handleStreamAbandoned(postID: postID)
        }

        presentError(mapped)
    }

    private func presentError(_ mapped: OmakaseError) {
        if case .quotaExceeded(let kind, let resetsAt) = mapped {
            AccessManager.shared.applyQuotaExceeded(kind: kind, resetsAt: resetsAt)
            if kind == .deepDive {
                requestedPaywallSource = .deepDiveLimit
            }
            return
        }
        switch mapped.presentation {
        case .toast, .inline:
            pendingToastError = mapped
        case .alert:
            activeError = mapped
        }
    }

    private func setTitle(_ title: String, for postID: UUID) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let post = posts.first(where: { $0.id == postID }) else { return }
        // Only set title if it's empty to prevent overwriting existing post titles during deep dives
        if post.title.isEmpty || post.title == "Diving deeper..." {
            post.title = trimmed
        }
    }

    private func setTags(_ tags: [String], for postID: UUID) {
        guard !tags.isEmpty, let post = posts.first(where: { $0.id == postID }) else { return }
        post.tags = tags
    }

    private func setPostFormat(_ format: String, for postID: UUID) {
        guard let post = posts.first(where: { $0.id == postID }) else { return }
        post.postFormat = format
    }

    private func appendText(_ text: String, to postID: UUID) {
        guard let post = posts.first(where: { $0.id == postID }) else { return }
        withAnimation(.easeOut(duration: 0.14)) {
            if post.deepDiveText != nil {
                post.deepDiveText! += text
            } else {
                post.text += text
            }
        }
    }

    private func markPostComplete(_ postID: UUID) {
        guard let post = posts.first(where: { $0.id == postID }) else { return }
        post.isComplete = true
    }

    /// When a stream is superseded (new request) or cancelled, avoid stuck LIVE / empty "…" cards.
    private func handleStreamAbandoned(postID: UUID) {
        guard let idx = posts.firstIndex(where: { $0.id == postID }) else { return }
        if posts[idx].text.isEmpty {
            posts.remove(at: idx)
        } else {
            markPostComplete(postID)
        }
    }

    private static func parseISO8601Date(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) {
            return date
        }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: raw)
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
