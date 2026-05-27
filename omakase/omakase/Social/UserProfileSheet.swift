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
                .tint(isFollowing ? .secondary : .accentColor)
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
                                .background(Color.accentColor.opacity(0.12), in: Capsule())
                                .foregroundStyle(Color.accentColor)
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

/// My own profile sheet with sign-out.
struct MyProfileSheet: View {

    let authService: AuthService

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var profile: UserProfile?
    @State private var followerCount = 0
    @State private var followingCount = 0
    @State private var userPosts: [SharedPost] = []
    @State private var isLoadingPosts = true

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 20)

                if let urlStr = profile?.photoURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFill()
                                .frame(width: 80, height: 80).clipShape(Circle())
                        } else { defaultAvatar }
                    }
                } else { defaultAvatar }

                Text(profile?.displayName ?? authService.displayName ?? "")
                    .font(.title2.bold())

                Text(profile?.email ?? authService.email ?? "")
                    .font(.subheadline).foregroundStyle(.secondary)

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

                Spacer()

                Button(role: .destructive) {
                    authService.signOut()
                    dismiss()
                } label: {
                    Text(l10n.signOut)
                        .fontWeight(.semibold)
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
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
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer().frame(height: 32)
            }
            } // Close ScrollView
            .navigationTitle(l10n.myProfile)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.done) { dismiss() }
                }
            }
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

    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 72)).symbolRenderingMode(.hierarchical).foregroundStyle(.secondary)
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
