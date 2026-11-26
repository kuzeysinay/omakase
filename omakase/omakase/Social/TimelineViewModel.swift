//
//  TimelineViewModel.swift
//  omakase
//

import Foundation
import Observation

enum TimelineFeedMode: String, CaseIterable, Identifiable, Sendable {
    case discover
    case following

    var id: String { rawValue }
}

/// Drives the social timeline tab — supports a shuffled Discover feed across
/// community readers as well as a dedicated Following feed.
@Observable
@MainActor
final class TimelineViewModel {

    // MARK: - Published state

    var feedMode: TimelineFeedMode = .discover
    private(set) var discoverPosts: [SharedPost] = []
    private(set) var followingPosts: [SharedPost] = []
    private(set) var isLoading: Bool = false
    private(set) var loadError: OmakaseError?
    private(set) var followingUIDs: [String] = []

    var posts: [SharedPost] {
        feedMode == .discover ? discoverPosts : followingPosts
    }

    private let authService: AuthService
    @ObservationIgnored
    private var blockObserver: NSObjectProtocol?

    init(authService: AuthService) {
        self.authService = authService
        blockObserver = NotificationCenter.default.addObserver(
            forName: .omakaseDidUpdateBlockedUsers,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.filterOutBlockedAuthors()
            }
        }
    }

    deinit {
        if let blockObserver {
            NotificationCenter.default.removeObserver(blockObserver)
        }
    }

    // MARK: - Actions

    /// Load both the shuffled Discover feed and the Following feed.
    func loadTimeline() async {
        guard let uid = authService.uid else { return }
        isLoading = true
        loadError = nil

        do {
            async let fetchedFollowingUIDs = FirestoreService.shared.fetchFollowingUIDs(currentUid: uid)
            async let fetchedDiscover = FirestoreService.shared.fetchDiscoverTimeline(limit: 60)

            let (resolvedFollowing, rawDiscover) = try await (fetchedFollowingUIDs, fetchedDiscover)
            followingUIDs = resolvedFollowing
            discoverPosts = Self.interleaveAndShuffleDiscoverPosts(rawDiscover)

            if resolvedFollowing.isEmpty {
                followingPosts = []
            } else {
                var allUIDs = resolvedFollowing
                allUIDs.append(uid)
                followingPosts = try await FirestoreService.shared.fetchTimeline(followingUIDs: allUIDs)
            }
        } catch {
            let mapped = OmakaseError.from(error, context: .timelineLoad)
            ErrorReporter.record(error, mapped: mapped, area: "timeline_load")
            loadError = mapped
        }

        isLoading = false
    }

    func removePost(id: String) {
        discoverPosts.removeAll { $0.id == id }
        followingPosts.removeAll { $0.id == id }
    }

    func filterOutBlockedAuthors() {
        let blocked = FirestoreService.shared.blockedUIDs
        discoverPosts.removeAll { blocked.contains($0.authorId) }
        followingPosts.removeAll { blocked.contains($0.authorId) }
        followingUIDs.removeAll { blocked.contains($0) }
    }

    /// Refresh the timeline (pull-to-refresh).
    func refresh() async {
        await loadTimeline()
    }

    // MARK: - Helpers

    /// Groups discover posts by author, shuffles author order, and interleaves
    /// one post per author in round-robin rounds so random readers surface first.
    private static func interleaveAndShuffleDiscoverPosts(_ posts: [SharedPost]) -> [SharedPost] {
        guard posts.count > 1 else { return posts }
        var buckets: [String: [SharedPost]] = [:]
        for post in posts {
            buckets[post.authorId, default: []].append(post)
        }
        var authors = Array(buckets.keys).shuffled()
        for author in authors {
            buckets[author]?.shuffle()
        }

        var result: [SharedPost] = []
        result.reserveCapacity(posts.count)
        while !authors.isEmpty {
            var remainingAuthors: [String] = []
            for author in authors {
                if var list = buckets[author], !list.isEmpty {
                    result.append(list.removeFirst())
                    if !list.isEmpty {
                        buckets[author] = list
                        remainingAuthors.append(author)
                    }
                }
            }
            authors = remainingAuthors.shuffled()
        }
        return result
    }
}
