//
//  FollowListSheet.swift
//  omakase
//
//  Interactive Followers & Following sheet accessible from both MyProfileSheet
//  and UserProfileSheet, supporting live tab switching, inline follow toggles,
//  and drilling into any user's profile.
//

import SwiftUI

enum FollowListMode: String, Identifiable, Hashable {
    case followers
    case following

    var id: String { rawValue }
}

struct FollowListSheet: View {

    let userId: String
    let initialMode: FollowListMode
    let authService: AuthService
    var onFollowChanged: (() -> Void)? = nil

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var mode: FollowListMode
    @State private var followers: [UserProfile] = []
    @State private var following: [UserProfile] = []
    @State private var myFollowingSet: Set<String> = []
    @State private var pendingActions: Set<String> = []
    @State private var isLoading = true
    @State private var loadError: OmakaseError? = nil
    @State private var toastMessage: String? = nil
    @State private var selectedProfileUid: String? = nil

    private var l10n: L10n { L10n(lang: appLanguage) }

    init(
        userId: String,
        initialMode: FollowListMode,
        authService: AuthService,
        onFollowChanged: (() -> Void)? = nil
    ) {
        self.userId = userId
        self.initialMode = initialMode
        self.authService = authService
        self.onFollowChanged = onFollowChanged
        _mode = State(initialValue: initialMode)
    }

    private var displayedUsers: [UserProfile] {
        switch mode {
        case .followers: return followers
        case .following: return following
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $mode) {
                    Text(l10n.followers).tag(FollowListMode.followers)
                    Text(l10n.followingLabel).tag(FollowListMode.following)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .onChange(of: mode) { _, _ in
                    HapticManager.selection()
                }

                Divider().opacity(0.15)

                Group {
                    if isLoading && displayedUsers.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let loadError, displayedUsers.isEmpty {
                        errorState(loadError)
                    } else if displayedUsers.isEmpty {
                        emptyState
                    } else {
                        List(displayedUsers) { user in
                            userRow(user)
                                .listRowBackground(Color(uiColor: .systemBackground))
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await loadAll()
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            .navigationTitle(mode == .followers ? l10n.followers : l10n.followingLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.done) { dismiss() }
                }
            }
            .toast(message: $toastMessage)
            .sheet(item: $selectedProfileUid) { targetUid in
                UserProfileSheet(userId: targetUid, authService: authService)
                    .environment(\.appLanguage, appLanguage)
            }
            .task {
                await loadAll()
            }
        }
    }

    private func userRow(_ user: UserProfile) -> some View {
        HStack(spacing: 12) {
            Button {
                HapticManager.light()
                selectedProfileUid = user.id
            } label: {
                HStack(spacing: 12) {
                    MonogramAvatarView(name: user.displayName, size: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(.body.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(user.formattedHandle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            if user.id != authService.uid {
                followButton(for: user)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func followButton(for user: UserProfile) -> some View {
        let isFollowing = myFollowingSet.contains(user.id)
        let isPending = pendingActions.contains(user.id)

        Button {
            HapticManager.light()
            Task { await toggleFollow(user: user, currentlyFollowing: isFollowing) }
        } label: {
            Group {
                if isPending {
                    ProgressView()
                        .controlSize(.small)
                        .tint(isFollowing ? Color.primary : OmakaseTheme.chipActiveText)
                } else {
                    Text(isFollowing ? l10n.following : l10n.follow)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isFollowing ? Color.primary : OmakaseTheme.chipActiveText)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(
                Capsule()
                    .fill(isFollowing ? Color(uiColor: .secondarySystemFill) : OmakaseTheme.chipActiveFill)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isFollowing ? OmakaseTheme.stroke : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPending)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: mode == .followers ? "person.2" : "person.badge.plus")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(.secondary)

            Text(mode == .followers ? l10n.noFollowersYet : l10n.notFollowingAnyoneYet)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ error: OmakaseError) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(.secondary)

            Text(error.message(l10n: l10n))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await loadAll() }
            } label: {
                Text(l10n.tryAgain)
                    .fontWeight(.semibold)
                    .foregroundStyle(OmakaseTheme.chipActiveText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(OmakaseTheme.chipActiveFill, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadAll() async {
        isLoading = true
        loadError = nil
        do {
            let currentUid = authService.uid
            async let followersTask = FirestoreService.shared.fetchFollowers(uid: userId)
            async let followingTask = FirestoreService.shared.fetchFollowing(uid: userId)
            async let myFollowingTask: [String] = {
                guard let currentUid else { return [] }
                return (try? await FirestoreService.shared.fetchFollowingUIDs(currentUid: currentUid)) ?? []
            }()

            let (fetchedFollowers, fetchedFollowing, myUIDs) = try await (
                followersTask,
                followingTask,
                myFollowingTask
            )
            followers = fetchedFollowers
            following = fetchedFollowing
            myFollowingSet = Set(myUIDs)
        } catch {
            loadError = OmakaseError.from(error)
        }
        isLoading = false
    }

    private func toggleFollow(user: UserProfile, currentlyFollowing: Bool) async {
        guard let uid = authService.uid else { return }
        pendingActions.insert(user.id)
        do {
            if currentlyFollowing {
                try await FirestoreService.shared.unfollow(targetUid: user.id, currentUid: uid)
                myFollowingSet.remove(user.id)
                if userId == uid {
                    following.removeAll { $0.id == user.id }
                }
            } else {
                try await FirestoreService.shared.follow(
                    targetUid: user.id,
                    targetDisplayName: user.displayName,
                    currentUid: uid,
                    currentDisplayName: authService.displayName ?? "omakase"
                )
                myFollowingSet.insert(user.id)
            }
            onFollowChanged?()
        } catch {
            let context: SocialActionContext = currentlyFollowing ? .unfollow : .follow
            toastMessage = OmakaseError.from(error, context: context).message(l10n: l10n)
        }
        pendingActions.remove(user.id)
    }
}
