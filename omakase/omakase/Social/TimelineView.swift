//
//  TimelineView.swift
//  omakase
//

import SwiftUI

/// Social community tab — shows posts shared by people the current user follows,
/// with an integrated top search bar for discovering people and filtering posts.
struct TimelineView: View {

    @Environment(\.appLanguage) private var appLanguage
    let authService: AuthService
    @Binding var deepLinkedPostId: String?

    @State private var viewModel: TimelineViewModel
    @State private var showUserSearch = false
    @State private var selectedAuthorId: String?
    @State private var activeDeepLinkedPostId: String?

    // Inline top search bar state
    @State private var searchQuery: String = ""
    @State private var userResults: [UserProfile] = []
    @State private var isSearchingUsers = false
    @State private var followingSet: Set<String> = []
    @State private var pendingFollowActions: Set<String> = []
    @State private var toastMessage: String?
    @FocusState private var isSearchFocused: Bool

    private var l10n: L10n { L10n(lang: appLanguage) }

    init(authService: AuthService, deepLinkedPostId: Binding<String?> = .constant(nil)) {
        self.authService = authService
        self._deepLinkedPostId = deepLinkedPostId
        _viewModel = State(initialValue: TimelineViewModel(authService: authService))
    }

    private var trimmedQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredPosts: [SharedPost] {
        guard !trimmedQuery.isEmpty else { return viewModel.posts }
        let q = trimmedQuery.localizedLowercase
        return viewModel.posts.filter { post in
            post.title.localizedLowercase.contains(q)
                || post.text.localizedLowercase.contains(q)
                || post.authorName.localizedLowercase.contains(q)
                || (post.authorUsername?.localizedLowercase.contains(q) ?? false)
                || post.tags.contains(where: { $0.localizedLowercase.contains(q) })
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Search Bar + Discover/Following Mode Switcher
                VStack(spacing: 10) {
                    topSearchBar
                    feedModePicker
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)

                Divider().opacity(0.12)

                Group {
                    if viewModel.isLoading && viewModel.posts.isEmpty && trimmedQuery.isEmpty {
                        ProgressView(l10n.loadingTimeline)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let loadError = viewModel.loadError, viewModel.posts.isEmpty && trimmedQuery.isEmpty {
                        timelineErrorState(loadError)
                    } else if !trimmedQuery.isEmpty {
                        searchResultsList
                    } else if viewModel.posts.isEmpty {
                        emptyState
                    } else {
                        postList
                    }
                }
            }
            .navigationTitle(l10n.tabTimeline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showUserSearch = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.primary.opacity(0.85))
                    }
                    .accessibilityLabel(l10n.findPeople)
                    .accessibilityIdentifier("community.findPeopleButton")
                }
            }
            .refreshable {
                await viewModel.refresh()
                followingSet = Set(viewModel.followingUIDs)
                if let loadError = viewModel.loadError, !viewModel.posts.isEmpty {
                    toastMessage = loadError.message(l10n: l10n)
                }
            }
            .toast(message: $toastMessage)
            .task {
                await viewModel.loadTimeline()
                followingSet = Set(viewModel.followingUIDs)
            }
            .onChange(of: viewModel.feedMode) { _, _ in
                HapticManager.selection()
            }
            .onChange(of: searchQuery) { _, newValue in
                let clean = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if clean.isEmpty {
                    userResults = []
                    isSearchingUsers = false
                    return
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(350))
                    guard searchQuery == newValue else { return }
                    await performUserSearch(query: clean)
                }
            }
            .sheet(isPresented: $showUserSearch) {
                UserSearchView(authService: authService)
                    .environment(\.appLanguage, appLanguage)
            }
            .sheet(item: $selectedAuthorId) { authorId in
                UserProfileSheet(
                    userId: authorId,
                    authService: authService
                )
                .environment(\.appLanguage, appLanguage)
            }
            .sheet(item: $activeDeepLinkedPostId) { postId in
                CommentsView(postId: postId, authService: authService)
                    .environment(\.appLanguage, appLanguage)
            }
            .onAppear {
                if let postId = deepLinkedPostId {
                    activeDeepLinkedPostId = postId
                    deepLinkedPostId = nil
                }
            }
            .onChange(of: deepLinkedPostId) { _, newPostId in
                if let postId = newPostId {
                    activeDeepLinkedPostId = postId
                    deepLinkedPostId = nil
                    Task { await viewModel.refresh() }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .omakaseDidReceiveForegroundNotification)) { _ in
                Task { await viewModel.refresh() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .omakaseDidUpdateBlockedUsers)) { _ in
                let blocked = FirestoreService.shared.blockedUIDs
                userResults.removeAll { blocked.contains($0.id) }
                followingSet.subtract(blocked)
            }
        }
    }

    // MARK: - Top Search Bar

    private var topSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(l10n.communitySearchPlaceholder, text: $searchQuery)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    let clean = trimmedQuery
                    if !clean.isEmpty {
                        Task { await performUserSearch(query: clean) }
                    }
                }
                .accessibilityIdentifier("community.searchField")

            if isSearchingUsers {
                ProgressView()
                    .controlSize(.small)
            } else if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    userResults = []
                    isSearchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var feedModePicker: some View {
        Picker("", selection: $viewModel.feedMode) {
            Text(l10n.timelineModeDiscover).tag(TimelineFeedMode.discover)
            Text(l10n.timelineModeFollowing).tag(TimelineFeedMode.following)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("community.feedModePicker")
    }

    // MARK: - Search Results View (Users + Filtered Posts)

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Matching Users Section
                if !userResults.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(l10n.searchPeopleSection)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        ForEach(userResults) { user in
                            inlineUserRow(user)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground).opacity(0.6))
                    )
                }

                // Matching Posts Section
                if !filteredPosts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        if !userResults.isEmpty {
                            Text(l10n.profilePosts)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                        }

                        ForEach(filteredPosts, id: \.id) { post in
                            TimelinePostCard(
                                post: post,
                                authService: authService,
                                onAuthorTap: {
                                    selectedAuthorId = post.authorId
                                },
                                onDelete: {
                                    Task {
                                        await deletePost(post)
                                    }
                                },
                                onToast: { toastMessage = $0 },
                                isFollowingAuthor: post.authorId == authService.uid ? nil : followingSet.contains(post.authorId),
                                isFollowPending: pendingFollowActions.contains(post.authorId),
                                onToggleFollowAuthor: {
                                    Task { await toggleFollowAuthorFromCard(post: post) }
                                }
                            )
                        }
                    }
                }

                if !isSearchingUsers && userResults.isEmpty && filteredPosts.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(.secondary)
                        Text(l10n.noSearchResults)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func inlineUserRow(_ user: UserProfile) -> some View {
        let isFollowing = followingSet.contains(user.id)
        let isPending = pendingFollowActions.contains(user.id)

        return HStack(spacing: 12) {
            Button {
                selectedAuthorId = user.id
            } label: {
                HStack(spacing: 12) {
                    MonogramAvatarView(name: user.displayName, size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text(user.formattedHandle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                Task { await toggleFollow(user: user, currentlyFollowing: isFollowing) }
            } label: {
                if isPending {
                    ProgressView().controlSize(.small)
                } else {
                    Text(isFollowing ? l10n.following : l10n.follow)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
            }
            .buttonStyle(.bordered)
            .tint(isFollowing ? .secondary : .primary)
            .disabled(isPending)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private func timelineErrorState(_ error: OmakaseError) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)

            Text(error.message(l10n: l10n))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    await viewModel.loadTimeline()
                    followingSet = Set(viewModel.followingUIDs)
                }
            } label: {
                Text(l10n.tryAgain)
                    .fontWeight(.semibold)
                    .foregroundStyle(OmakaseTheme.chipActiveText)
            }
            .buttonStyle(.borderedProminent)
            .tint(OmakaseTheme.chipActiveFill)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.feedMode == .following ? "person.2" : "person.2.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)

            Text(viewModel.feedMode == .following ? l10n.followingEmptyHeadline : l10n.timelineEmptyHeadline)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(viewModel.feedMode == .following ? l10n.followingEmptyDetail : l10n.timelineEmptyDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if viewModel.feedMode == .following {
                Button {
                    withAnimation {
                        viewModel.feedMode = .discover
                    }
                } label: {
                    Label(l10n.exploreDiscoverCTA, systemImage: "sparkles")
                        .fontWeight(.semibold)
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                }
                .buttonStyle(.borderedProminent)
                .tint(OmakaseTheme.chipActiveFill)
                .controlSize(.large)
                .padding(.top, 8)
            } else {
                Button {
                    showUserSearch = true
                } label: {
                    Label(l10n.findPeople, systemImage: "person.badge.plus")
                        .fontWeight(.semibold)
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                }
                .buttonStyle(.borderedProminent)
                .tint(OmakaseTheme.chipActiveFill)
                .controlSize(.large)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var postList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.feedMode == .discover {
                    discoverBanner
                }

                ForEach(viewModel.posts, id: \.id) { post in
                    TimelinePostCard(
                        post: post,
                        authService: authService,
                        onAuthorTap: {
                            selectedAuthorId = post.authorId
                        },
                        onDelete: {
                            Task {
                                await deletePost(post)
                            }
                        },
                        onToast: { toastMessage = $0 },
                        isFollowingAuthor: post.authorId == authService.uid ? nil : followingSet.contains(post.authorId),
                        isFollowPending: pendingFollowActions.contains(post.authorId),
                        onToggleFollowAuthor: {
                            Task { await toggleFollowAuthorFromCard(post: post) }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var discoverBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(l10n.discoverBannerTitle)
                    .font(.subheadline.bold())
                Text(l10n.discoverFeedSubheader)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Search & Follow Actions

    private func performUserSearch(query: String) async {
        guard let uid = authService.uid else { return }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            userResults = []
            return
        }
        isSearchingUsers = true
        do {
            userResults = try await FirestoreService.shared.searchUsers(query: trimmed, currentUid: uid)
        } catch {
            let mapped = OmakaseError.from(error, context: .userSearch)
            ErrorReporter.record(error, mapped: mapped, area: "timeline_user_search")
            userResults = []
            toastMessage = mapped.message(l10n: l10n)
        }
        isSearchingUsers = false
    }

    private func deletePost(_ post: SharedPost) async {
        guard let postId = post.id else { return }
        do {
            try await FirestoreService.shared.deleteSharedPost(postId: postId)
            withAnimation {
                viewModel.removePost(id: postId)
            }
        } catch {
            let mapped = OmakaseError.from(error, context: .postDelete)
            ErrorReporter.record(error, mapped: mapped, area: "timeline_delete_post")
            toastMessage = mapped.message(l10n: l10n)
        }
    }

    private func toggleFollow(user: UserProfile, currentlyFollowing: Bool) async {
        guard let uid = authService.uid else { return }
        pendingFollowActions.insert(user.id)
        do {
            if currentlyFollowing {
                try await FirestoreService.shared.unfollow(targetUid: user.id, currentUid: uid)
                followingSet.remove(user.id)
            } else {
                try await FirestoreService.shared.follow(
                    targetUid: user.id,
                    targetDisplayName: user.displayName,
                    currentUid: uid,
                    currentDisplayName: authService.displayName ?? "omakase User"
                )
                followingSet.insert(user.id)
                NotificationManager.shared.notifySocialEvent(
                    type: "follow",
                    targetUid: user.id,
                    actorName: authService.displayName
                )
            }
            await viewModel.loadTimeline()
        } catch {
            let context: SocialActionContext = currentlyFollowing ? .unfollow : .follow
            let mapped = OmakaseError.from(error, context: context)
            ErrorReporter.record(error, mapped: mapped, area: "timeline_toggle_follow")
            toastMessage = mapped.message(l10n: l10n)
        }
        pendingFollowActions.remove(user.id)
    }

    private func toggleFollowAuthorFromCard(post: SharedPost) async {
        guard let uid = authService.uid, post.authorId != uid else { return }
        let targetUid = post.authorId
        guard !followingSet.contains(targetUid), !pendingFollowActions.contains(targetUid) else { return }

        pendingFollowActions.insert(targetUid)
        do {
            try await FirestoreService.shared.follow(
                targetUid: targetUid,
                targetDisplayName: post.authorName,
                currentUid: uid,
                currentDisplayName: authService.displayName ?? "omakase User"
            )
            followingSet.insert(targetUid)
            NotificationManager.shared.notifySocialEvent(
                type: "follow",
                targetUid: targetUid,
                actorName: authService.displayName
            )
            await viewModel.loadTimeline()
        } catch {
            let mapped = OmakaseError.from(error, context: .follow)
            ErrorReporter.record(error, mapped: mapped, area: "timeline_card_follow")
            toastMessage = mapped.message(l10n: l10n)
        }
        pendingFollowActions.remove(targetUid)
    }
}

// MARK: - String conformance for sheet(item:)

extension String: @retroactive Identifiable {
    public var id: String { self }
}
