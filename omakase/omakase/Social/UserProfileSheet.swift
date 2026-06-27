//
//  UserProfileSheet.swift
//  omakase
//

import SwiftUI

/// Shows another user's profile with follow/unfollow action.
struct UserProfileSheet: View {

    let userId: String
    let authService: AuthService

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var profile: UserProfile?
    @State private var isFollowing = false
    @State private var isPending = false
    @State private var followerCount = 0
    @State private var followingCount = 0
    @State private var userPosts: [SharedPost] = []
    @State private var isLoadingPosts = true

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    ScrollView {
                        profileContent(profile)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.done) { dismiss() }
                }
            }
        }
        .task { await loadProfile() }
    }

    private func profileContent(_ user: UserProfile) -> some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)

            // Avatar
            if let urlStr = user.photoURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                            .frame(width: 80, height: 80).clipShape(Circle())
                    } else { defaultAvatar }
                }
            } else { defaultAvatar }

            Text(user.displayName)
                .font(.title2.bold())

            HStack(spacing: 32) {
                VStack(spacing: 2) {
                    Text("\(followerCount)").font(.headline)
                    Text(l10n.followers).font(.caption).foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(followingCount)").font(.headline)
                    Text(l10n.followingLabel).font(.caption).foregroundStyle(.secondary)
                }
            }

            if userId != authService.uid {
                Button {
                    Task { await toggleFollow() }
                } label: {
                    if isPending {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(isFollowing ? l10n.following : l10n.follow)
                            .fontWeight(.semibold)
                            .frame(maxWidth: 200)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isFollowing ? .secondary : .primary)
                .controlSize(.large)
                .disabled(isPending)
            }

            if !user.interests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(l10n.yourTastes)
                        .font(.subheadline.bold())
                    FlowLayoutShared(spacing: 6) {
                        ForEach(user.interests, id: \.self) { tag in
                            Text(tag)
                                .font(.caption).fontWeight(.medium)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.primary.opacity(0.08), in: Capsule())
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            }

            Divider().padding(.vertical)

            if isLoadingPosts {
                ProgressView().padding()
            } else if userPosts.isEmpty {
                Text(l10n.noPostsYet)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(userPosts) { post in
                        TimelinePostCard(
                            post: post, 
                            authService: authService,
                            onAuthorTap: { },
                            onDelete: nil
                        )
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 72)).symbolRenderingMode(.hierarchical).foregroundStyle(.secondary)
    }

    private func loadProfile() async {
        guard let uid = authService.uid else { return }
        profile = try? await FirestoreService.shared.fetchUserProfile(uid: userId)
        isFollowing = (try? await FirestoreService.shared.isFollowing(targetUid: userId, currentUid: uid)) ?? false
        followerCount = (try? await FirestoreService.shared.fetchFollowerCount(uid: userId)) ?? 0
        followingCount = (try? await FirestoreService.shared.fetchFollowingCount(uid: userId)) ?? 0
        
        userPosts = (try? await FirestoreService.shared.fetchUserTimeline(uid: userId)) ?? []
        isLoadingPosts = false
    }

    private func toggleFollow() async {
        guard let uid = authService.uid else { return }
        isPending = true
        do {
            if isFollowing {
                try await FirestoreService.shared.unfollow(targetUid: userId, currentUid: uid)
                isFollowing = false; followerCount = max(0, followerCount - 1)
            } else {
                try await FirestoreService.shared.follow(
                    targetUid: userId, targetDisplayName: profile?.displayName ?? "",
                    currentUid: uid, currentDisplayName: authService.displayName ?? ""
                )
                isFollowing = true; followerCount += 1
            }
        } catch { }
        isPending = false
    }
}

/// My own profile sheet — clean grouped-list layout matching iOS Settings conventions.
struct MyProfileSheet: View {

    let authService: AuthService

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var profile: UserProfile?
    @State private var followerCount = 0
    @State private var followingCount = 0
    @State private var userPosts: [SharedPost] = []
    @State private var isLoadingPosts = true

    @AppStorage("omakase.letterboxd_username") private var storedLetterboxdUsername: String = ""
    @AppStorage("omakase.language") private var languageCode: String = AppLanguage.english.rawValue
    @AppStorage("omakase.appearance") private var appearanceCode: String = AppAppearance.system.rawValue
    @State private var isShowingLetterboxdPrompt = false
    @State private var tempLetterboxdUsername = ""

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            List {

                // MARK: - Profile Header
                Section {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 8)

                        avatarView

                        VStack(spacing: 4) {
                            Text(profile?.displayName ?? authService.displayName ?? "")
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                            Text(profile?.email ?? authService.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Stats pill
                        HStack(spacing: 0) {
                            statCell(value: followerCount, label: l10n.followers)
                            Divider().frame(height: 32)
                            statCell(value: followingCount, label: l10n.followingLabel)
                        }
                        .background(Color(.tertiarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12))

                        Spacer().frame(height: 8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // MARK: - Preferences
                Section(l10n.profilePreferences) {

                    // Language — native Picker renders as a menu row automatically
                    Picker(selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.pickerLabel).tag(lang.rawValue)
                        }
                    } label: {
                        Label {
                            Text(l10n.languageMenuAccessibility)
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(.primary)
                        }
                    }

                    // Appearance mode
                    Picker(selection: $appearanceCode) {
                        ForEach(AppAppearance.allCases) { mode in
                            Text(l10n.appearanceName(mode)).tag(mode.rawValue)
                        }
                    } label: {
                        let current = AppAppearance(rawValue: appearanceCode) ?? .system
                        Label {
                            Text(l10n.appearanceLabel)
                        } icon: {
                            Image(systemName: current.iconName)
                                .foregroundStyle(current.iconColor)
                        }
                    }

                    // Letterboxd integration
                    Button {
                        tempLetterboxdUsername = storedLetterboxdUsername
                        isShowingLetterboxdPrompt = true
                    } label: {
                        HStack {
                            Label {
                                if storedLetterboxdUsername.isEmpty {
                                    Text(l10n.updateLetterboxdButton)
                                } else {
                                    Text("Letterboxd: @\(storedLetterboxdUsername)")
                                }
                            } icon: {
                                Image(systemName: "film")
                            }
                            .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                // MARK: - Posts
                Section(l10n.profilePosts) {
                    if isLoadingPosts {
                        HStack { Spacer(); ProgressView(); Spacer() }
                            .padding(.vertical, 8)
                    } else if userPosts.isEmpty {
                        Text(l10n.noPostsYet)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(userPosts) { post in
                            TimelinePostCard(
                                post: post,
                                authService: authService,
                                onAuthorTap: { },
                                onDelete: {
                                    Task {
                                        if let postId = post.id {
                                            try? await FirestoreService.shared.deleteSharedPost(postId: postId)
                                            withAnimation {
                                                userPosts.removeAll { $0.id == post.id }
                                            }
                                        }
                                    }
                                }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    }
                }

                // MARK: - Account / Sign Out
                Section(l10n.profileAccount) {
                    Button(role: .destructive) {
                        authService.signOut()
                        dismiss()
                    } label: {
                        Label(l10n.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(l10n.myProfile)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.done) { dismiss() }
                }
            }
        }
        .alert(l10n.letterboxdUsernamePromptTitle, isPresented: $isShowingLetterboxdPrompt) {
            TextField(l10n.letterboxdUsernamePlaceholder, text: $tempLetterboxdUsername)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button(l10n.cancel, role: .cancel) { }
            Button(l10n.save) {
                storedLetterboxdUsername = tempLetterboxdUsername
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } message: {
            Text(l10n.letterboxdUsernamePromptMessage)
        }
        .task {
            guard let uid = authService.uid else { return }
            profile = try? await FirestoreService.shared.fetchUserProfile(uid: uid)
            followerCount = (try? await FirestoreService.shared.fetchFollowerCount(uid: uid)) ?? 0
            followingCount = (try? await FirestoreService.shared.fetchFollowingCount(uid: uid)) ?? 0
            userPosts = (try? await FirestoreService.shared.fetchUserTimeline(uid: uid)) ?? []
            isLoadingPosts = false
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private var avatarView: some View {
        if let urlStr = profile?.photoURL, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                if let img = phase.image {
                    img.resizable().scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                } else { defaultAvatar }
            }
        } else { defaultAvatar }
    }

    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 80))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
    }

    private func statCell(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)").font(.headline.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Shared FlowLayout

struct FlowLayoutShared: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layoutRows(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layoutRows(proposal: .init(width: bounds.width, height: bounds.height), subviews: subviews)
        for (i, pos) in result.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private struct R { var size: CGSize; var positions: [CGPoint] }

    private func layoutRows(proposal: ProposedViewSize, subviews: Subviews) -> R {
        let maxW = proposal.width ?? .infinity
        var positions: [CGPoint] = []; var x: CGFloat = 0; var y: CGFloat = 0
        var rh: CGFloat = 0; var tw: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > maxW, x > 0 { x = 0; y += rh + spacing; rh = 0 }
            positions.append(CGPoint(x: x, y: y))
            rh = max(rh, s.height); x += s.width + spacing; tw = max(tw, x - spacing)
        }
        return R(size: CGSize(width: tw, height: y + rh), positions: positions)
    }
}
