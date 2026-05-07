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

    init(authService: AuthService) {
        self.authService = authService
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

    /// Refresh the timeline (pull-to-refresh).
    func refresh() async {
        await loadTimeline()
    }
}
