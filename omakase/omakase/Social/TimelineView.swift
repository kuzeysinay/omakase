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

    @State private var viewModel: TimelineViewModel
    @State private var showUserSearch = false
    @State private var selectedAuthorId: String?

    // Inline top search bar state
    @State private var searchQuery: String = ""
    @State private var userResults: [UserProfile] = []
    @State private var isSearchingUsers = false
    @State private var followingSet: Set<String> = []
    @State private var pendingFollowActions: Set<String> = []
    @FocusState private var isSearchFocused: Bool

    private var l10n: L10n { L10n(lang: appLanguage) }

    init(authService: AuthService) {
        self.authService = authService
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
                // Top Search Bar
                topSearchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                Divider().opacity(0.12)

                Group {
                    if viewModel.isLoading && viewModel.posts.isEmpty && trimmedQuery.isEmpty {
                        ProgressView(l10n.loadingTimeline)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                }
            }
            .refreshable {
                await viewModel.refresh()
                followingSet = Set(viewModel.followingUIDs)
            }
            .task {
                await viewModel.loadTimeline()
                followingSet = Set(viewModel.followingUIDs)
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

    // MARK: - Search Results View (Users + Filtered Posts)

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Matching Users Section
                if !userResults.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(appLanguage == .turkish ? "Kişiler" : "People")
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
                            Text(appLanguage == .turkish ? "Gönderiler" : "Posts")
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
                                        if let postId = post.id {
                                            try? await FirestoreService.shared.deleteSharedPost(postId: postId)
                                            withAnimation {
                                                viewModel.removePost(id: postId)
                                            }
                                        }
                                    }
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
                        Text(appLanguage == .turkish ? "Sonuç bulunamadı" : "No results found")
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
                    avatarView(urlString: user.photoURL)
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

    @ViewBuilder
    private func avatarView(urlString: String?) -> some View {
        if let s = urlString, let url = URL(string: s) {
            AsyncImage(url: url) { phase in
                if let img = phase.image {
                    img.resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                } else {
                    defaultAvatar
                }
            }
        } else {
            defaultAvatar
        }
    }

    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 36))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)

            Text(l10n.timelineEmptyHeadline)
                .font(.headline)

            Text(l10n.timelineEmptyDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showUserSearch = true
            } label: {
                Label(l10n.findPeople, systemImage: "person.badge.plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(OmakaseTheme.chipActiveFill)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var postList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.followingUIDs.isEmpty {
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
                                if let postId = post.id {
                                    try? await FirestoreService.shared.deleteSharedPost(postId: postId)
                                    withAnimation {
                                        viewModel.removePost(id: postId)
                                    }
                                }
                            }
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
                Text(l10n.discoverBannerDetail)
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
        userResults = (try? await FirestoreService.shared.searchUsers(query: trimmed, currentUid: uid)) ?? []
        isSearchingUsers = false
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
                    currentDisplayName: authService.displayName ?? "Omakase User"
                )
                followingSet.insert(user.id)
            }
            await viewModel.loadTimeline()
        } catch { }
        pendingFollowActions.remove(user.id)
    }
}

// MARK: - String conformance for sheet(item:)

extension String: @retroactive Identifiable {
    public var id: String { self }
}
