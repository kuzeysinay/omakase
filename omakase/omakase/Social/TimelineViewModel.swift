//
//  TimelineViewModel.swift
//  omakase
//

import Foundation
import Observation

/// Drives the social timeline tab — fetches shared posts from followed users.
@Observable
@MainActor
final class TimelineViewModel {

    // MARK: - Published state

    private(set) var posts: [SharedPost] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var followingUIDs: [String] = []

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
            Task { @MainActor in
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

    /// Load the timeline: fetch following list, then fetch their shared posts.
    func loadTimeline() async {
        guard let uid = authService.uid else { return }
        isLoading = true
        errorMessage = nil

        do {
            followingUIDs = try await FirestoreService.shared.fetchFollowingUIDs(currentUid: uid)

            if followingUIDs.isEmpty {
                // Show discover feed when not following anyone yet.
                posts = try await FirestoreService.shared.fetchDiscoverTimeline(limit: 50)
            } else {
                // Include own shared posts in timeline too.
                var allUIDs = followingUIDs
                allUIDs.append(uid)
                posts = try await FirestoreService.shared.fetchTimeline(followingUIDs: allUIDs)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func removePost(id: String) {
        posts.removeAll { $0.id == id }
    }

    func filterOutBlockedAuthors() {
        let blocked = FirestoreService.shared.blockedUIDs
        posts.removeAll { blocked.contains($0.authorId) }
        followingUIDs.removeAll { blocked.contains($0) }
    }

    /// Refresh the timeline (pull-to-refresh).
    func refresh() async {
        await loadTimeline()
    }
}
