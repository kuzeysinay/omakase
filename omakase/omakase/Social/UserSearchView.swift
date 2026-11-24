//
//  UserSearchView.swift
//  omakase
//

import SwiftUI

/// Sheet for searching and following/unfollowing other users.
struct UserSearchView: View {

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    let authService: AuthService

    @State private var query: String = ""
    @State private var results: [UserProfile] = []
    @State private var isSearching = false
    @State private var followingSet: Set<String> = []
    @State private var pendingActions: Set<String> = []
    @State private var selectedProfileUid: String?
    @State private var toastMessage: String?
    @State private var searchError: OmakaseError?

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                contentArea
            }
            .navigationTitle(l10n.findPeople)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.done) { dismiss() }
                }
            }
            .toast(message: $toastMessage)
        }
        .task {
            guard let uid = authService.uid else { return }
            if let uids = try? await FirestoreService.shared.fetchFollowingUIDs(currentUid: uid) {
                followingSet = Set(uids)
            }
        }
        .onChange(of: query) { _, newValue in
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                guard query == newValue, !newValue.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                await search()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .omakaseDidUpdateBlockedUsers)) { _ in
            guard let uid = authService.uid else { return }
            Task {
                if let blocked = try? await FirestoreService.shared.fetchBlockedUIDs(currentUid: uid) {
                    results.removeAll { blocked.contains($0.id) }
                    followingSet.subtract(blocked)
                }
            }
        }
        .sheet(item: $selectedProfileUid) { uid in
            UserProfileSheet(userId: uid, authService: authService)
                .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if isSearching {
            Spacer()
            ProgressView()
            Spacer()
        } else if let searchError, results.isEmpty {
            Spacer()
            VStack(spacing: 14) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.secondary)
                Text(searchError.message(l10n: l10n))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Button(l10n.tryAgain) {
                    Task { await search() }
                }
                .buttonStyle(.borderedProminent)
                .tint(OmakaseTheme.chipActiveFill)
            }
            Spacer()
        } else if results.isEmpty && !query.isEmpty {
            Spacer()
            ContentUnavailableView {
                Label(l10n.noUsersFound, systemImage: "person.slash")
            }
            Spacer()
        } else if results.isEmpty {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "person.2.gobackward")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.secondary)
                Text(l10n.searchUsersHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        } else {
            List {
                ForEach(results) { user in
                    userRow(user)
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(l10n.searchUsersPlaceholder, text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { Task { await search() } }
            if !query.isEmpty {
                Button { query = ""; results = [] } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .accessibilityLabel(l10n.clearSearch)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.bar, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func userRow(_ user: UserProfile) -> some View {
        HStack(spacing: 12) {
            Button {
                selectedProfileUid = user.id
            } label: {
                HStack(spacing: 12) {
                    MonogramAvatarView(name: user.displayName, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName).font(.body.bold()).foregroundStyle(.primary)
                        Text(user.formattedHandle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            followButton(for: user)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func followButton(for user: UserProfile) -> some View {
        let isFollowing = followingSet.contains(user.id)
        let isPending = pendingActions.contains(user.id)
        Button {
            Task { await toggleFollow(user: user, currentlyFollowing: isFollowing) }
        } label: {
            if isPending { ProgressView().controlSize(.small) }
            else { Text(isFollowing ? l10n.following : l10n.follow).font(.subheadline.bold()) }
        }
        .buttonStyle(.bordered)
        .tint(isFollowing ? .secondary : .primary)
        .disabled(isPending)
    }

    // MARK: - Actions

    private func search() async {
        guard let uid = authService.uid else { return }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        searchError = nil
        do {
            results = try await FirestoreService.shared.searchUsers(query: trimmed, currentUid: uid)
        } catch {
            let mapped = OmakaseError.from(error, context: .userSearch)
            ErrorReporter.record(error, mapped: mapped, area: "user_search")
            results = []
            searchError = mapped
        }
        isSearching = false
    }

    private func toggleFollow(user: UserProfile, currentlyFollowing: Bool) async {
        guard let uid = authService.uid else { return }
        pendingActions.insert(user.id)
        do {
            if currentlyFollowing {
                try await FirestoreService.shared.unfollow(targetUid: user.id, currentUid: uid)
                followingSet.remove(user.id)
            } else {
                try await FirestoreService.shared.follow(
                    targetUid: user.id, targetDisplayName: user.displayName,
                    currentUid: uid, currentDisplayName: authService.displayName ?? "Omakase User"
                )
                followingSet.insert(user.id)
                NotificationManager.shared.notifySocialEvent(
                    type: "follow",
                    targetUid: user.id,
                    actorName: authService.displayName
                )
            }
        } catch {
            let context: SocialActionContext = currentlyFollowing ? .unfollow : .follow
            let mapped = OmakaseError.from(error, context: context)
            ErrorReporter.record(error, mapped: mapped, area: "user_search_follow")
            toastMessage = mapped.message(l10n: l10n)
        }
        pendingActions.remove(user.id)
    }
}
