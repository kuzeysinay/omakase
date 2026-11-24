//
//  UserProfileSheet.swift
//  omakase
//

import SwiftUI
import UserNotifications

/// Shows another user's profile with follow/unfollow, report, and block actions.
struct UserProfileSheet: View {

    let userId: String
    let authService: AuthService

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var profile: UserProfile?
    @State private var isFollowing = false
    @State private var isBlocked = false
    @State private var isPending = false
    @State private var followerCount = 0
    @State private var followingCount = 0
    @State private var userPosts: [SharedPost] = []
    @State private var isLoadingPosts = true
    @State private var showBlockConfirm = false
    @State private var showReportConfirmation = false
    @State private var toastMessage: String?
    @State private var loadError: OmakaseError?

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    ScrollView {
                        profileContent(profile)
                    }
                } else if let loadError {
                    VStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.secondary)
                        Text(loadError.message(l10n: l10n))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button(l10n.tryAgain) {
                            Task { await loadProfile() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(OmakaseTheme.chipActiveFill)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

                if userId != authService.uid {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                Task {
                                    guard let uid = authService.uid else { return }
                                    do {
                                        try await FirestoreService.shared.reportUser(
                                            reportedUid: userId,
                                            reporterUid: uid
                                        )
                                        showReportConfirmation = true
                                    } catch {
                                        let mapped = OmakaseError.from(error, context: .report)
                                        ErrorReporter.record(error, mapped: mapped, area: "user_profile_report")
                                        toastMessage = mapped.message(l10n: l10n)
                                    }
                                }
                            } label: {
                                Label(l10n.reportUser, systemImage: "flag")
                            }

                            if isBlocked {
                                Button {
                                    Task { _ = await toggleBlock() }
                                } label: {
                                    Label(l10n.unblockUser, systemImage: "hand.raised.slash")
                                }
                            } else {
                                Button(role: .destructive) {
                                    showBlockConfirm = true
                                } label: {
                                    Label(l10n.blockUser, systemImage: "hand.raised")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel(l10n.feedMoreActionsA11y)
                    }
                }
            }
            .alert(l10n.confirmBlockUserTitle, isPresented: $showBlockConfirm) {
                Button(l10n.cancel, role: .cancel) { }
                Button(l10n.blockUser, role: .destructive) {
                    Task {
                        if await toggleBlock() {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text(l10n.confirmBlockUserMessage)
            }
            .alert(l10n.reportUser, isPresented: $showReportConfirmation) {
                Button(l10n.ok, role: .cancel) { }
            } message: {
                Text(l10n.reportSubmittedToast)
            }
            .toast(message: $toastMessage)
        }
        .task { await loadProfile() }
    }

    private func profileContent(_ user: UserProfile) -> some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)

            // Avatar
            MonogramAvatarView(name: user.displayName, size: 80)

            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.title2.bold())
                Text(user.formattedHandle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

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
                HStack(spacing: 12) {
                    if !isBlocked {
                        Button {
                            Task { await toggleFollow() }
                        } label: {
                            if isPending {
                                ProgressView().controlSize(.small)
                            } else {
                                Text(isFollowing ? l10n.following : l10n.follow)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: 180)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isFollowing ? .secondary : .primary)
                        .controlSize(.large)
                        .disabled(isPending)
                    } else {
                        Button {
                            Task { _ = await toggleBlock() }
                        } label: {
                            Label(l10n.unblockUser, systemImage: "hand.raised.slash")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.large)
                    }
                }
            }

            if !user.interests.isEmpty && !isBlocked {
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
            } else if userPosts.isEmpty || isBlocked {
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
                            onDelete: nil,
                            onToast: { toastMessage = $0 }
                        )
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    private func loadProfile() async {
        guard let uid = authService.uid else { return }
        loadError = nil
        do {
            profile = try await FirestoreService.shared.fetchUserProfile(uid: userId)
            if profile == nil {
                loadError = .socialActionFailed(.profileLoad)
            }
        } catch {
            let mapped = OmakaseError.from(error, context: .profileLoad)
            ErrorReporter.record(error, mapped: mapped, area: "user_profile_load")
            loadError = mapped
        }
        isBlocked = FirestoreService.shared.isUserBlocked(targetUid: userId)
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
                NotificationManager.shared.notifySocialEvent(
                    type: "follow",
                    targetUid: userId,
                    actorName: authService.displayName
                )
            }
        } catch {
            let context: SocialActionContext = isFollowing ? .unfollow : .follow
            let mapped = OmakaseError.from(error, context: context)
            ErrorReporter.record(error, mapped: mapped, area: "user_profile_follow")
            toastMessage = mapped.message(l10n: l10n)
        }
        isPending = false
    }

    private func toggleBlock() async -> Bool {
        guard let uid = authService.uid else { return false }
        isPending = true
        defer { isPending = false }
        do {
            if isBlocked {
                try await FirestoreService.shared.unblockUser(targetUid: userId, currentUid: uid)
                isBlocked = false
                userPosts = (try? await FirestoreService.shared.fetchUserTimeline(uid: userId)) ?? []
            } else {
                try await FirestoreService.shared.blockUser(
                    targetUid: userId,
                    targetDisplayName: profile?.displayName ?? "",
                    currentUid: uid
                )
                isBlocked = true
                isFollowing = false
                userPosts = []
                toastMessage = l10n.userBlockedToast
            }
            return true
        } catch {
            let context: SocialActionContext = isBlocked ? .unblock : .block
            let mapped = OmakaseError.from(error, context: context)
            ErrorReporter.record(error, mapped: mapped, area: "user_profile_block")
            toastMessage = mapped.message(l10n: l10n)
            return false
        }
    }
}

/// My own profile sheet — clean grouped-list layout matching iOS Settings conventions.
struct MyProfileSheet: View {

    let authService: AuthService
    var isTab: Bool = false

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var profile: UserProfile?
    @State private var followerCount = 0
    @State private var followingCount = 0
    @State private var userPosts: [SharedPost] = []
    @State private var isLoadingPosts = true
    @State private var bookmarkStore = BookmarkStore.shared
    @State private var accessManager = AccessManager.shared
    @State private var notificationManager = NotificationManager.shared

    @AppStorage("omakase.interests") private var storedInterests: String = ""
    @AppStorage("omakase.letterboxd_username") private var storedLetterboxdUsername: String = ""
    @AppStorage("omakase.language") private var languageCode: String = AppLanguage.systemDefault.rawValue
    @AppStorage("omakase.appearance") private var appearanceCode: String = AppAppearance.system.rawValue
    @State private var isShowingLetterboxdPrompt = false
    @State private var tempLetterboxdUsername = ""
    @State private var isShowingDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var accountErrorMessage: String?
    @State private var isShowingPaywall = false
    @State private var isShowingEditProfile = false
    @State private var isShowingFeedbackSheet = false
    @State private var profileToastMessage: String?

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Profile Header
                    VStack(spacing: 14) {
                        avatarView

                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Text(profile?.displayName ?? authService.displayName ?? "")
                                    .font(.title2.bold())
                                    .multilineTextAlignment(.center)
                                if accessManager.isPro {
                                    Text("PRO")
                                        .font(.caption2.weight(.bold).monospaced())
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(OmakaseTheme.chipActiveFill, in: Capsule())
                                        .foregroundStyle(OmakaseTheme.chipActiveText)
                                }
                            }
                            if let profile {
                                Text(profile.formattedHandle)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            isShowingEditProfile = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil")
                                    .font(.caption.weight(.bold))
                                Text(l10n.editProfileTitle)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color(uiColor: .systemBackground), in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(OmakaseTheme.ink.opacity(0.28), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // Stats pill
                        HStack(spacing: 0) {
                            statCell(value: followerCount, label: l10n.followers)
                            Divider().frame(height: 30)
                            statCell(value: followingCount, label: l10n.followingLabel)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(uiColor: .systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
                        )

                        if let interests = profile?.interests, !interests.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(l10n.yourTastes)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                FlowLayoutShared(spacing: 6) {
                                    ForEach(interests, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(OmakaseTheme.wash, in: Capsule())
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // MARK: - Quick Cards (Saved Posts & Pro Upgrade)
                    VStack(spacing: 10) {
                        NavigationLink(value: BookmarksNavigationRoute.collections) {
                            HStack(spacing: 12) {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(OmakaseTheme.ink)
                                    .frame(width: 34, height: 34)
                                    .background(OmakaseTheme.wash, in: Circle())

                                Text(l10n.savedPostsLabel)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text("\(bookmarkStore.entryCount(in: "All"))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(uiColor: .systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        if !accessManager.isPro {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                isShowingPaywall = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(OmakaseTheme.chipActiveText)
                                        .frame(width: 34, height: 34)
                                        .background(OmakaseTheme.chipActiveText.opacity(0.14), in: Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(l10n.profileUpgradeToPro)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(OmakaseTheme.chipActiveText)
                                        Text(
                                            l10n.profileDailyQuotaSummary(
                                                platesRemaining: accessManager.snapshot.platesRemaining,
                                                platesLimit: accessManager.snapshot.platesLimit,
                                                deepDivesRemaining: accessManager.snapshot.deepDivesRemaining,
                                                deepDivesLimit: accessManager.snapshot.deepDivesLimit
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundStyle(OmakaseTheme.chipActiveText.opacity(0.75))
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(OmakaseTheme.chipActiveText)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(OmakaseTheme.chipActiveFill)
                                )
                            }
                            .buttonStyle(OmakaseChipButtonStyle())
                        }
                    }

                    // MARK: - Shared Posts
                    VStack(alignment: .leading, spacing: 12) {
                        Text(userPosts.isEmpty ? l10n.profilePosts : "\(l10n.profilePosts) (\(userPosts.count))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)

                        if isLoadingPosts {
                            HStack { Spacer(); ProgressView(); Spacer() }
                                .padding(.vertical, 24)
                        } else if userPosts.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.stack")
                                    .foregroundStyle(.secondary)
                                Text(l10n.noPostsYet)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 28)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(uiColor: .systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
                            )
                        } else {
                            LazyVStack(spacing: 12) {
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
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            .navigationTitle(l10n.myProfile)
            .navigationBarTitleDisplayMode(.inline)
            .bookmarksNavigationDestinations(
                bookmarkStore: bookmarkStore,
                authService: authService,
                appLanguage: appLanguage
            )
            .toolbar {
                if !isTab {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(l10n.done) { dismiss() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        settingsDestination
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(l10n.settingsTitle)
                }
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            OmakasePaywallView(
                source: .profile,
                onToast: { profileToastMessage = $0 }
            )
            .environment(\.appLanguage, appLanguage)
        }
        .sheet(isPresented: $isShowingEditProfile) {
            EditProfileSheet(
                authService: authService,
                currentProfile: profile,
                onSaved: { updated in
                    profile = updated
                    profileToastMessage = l10n.profileSavedToast
                }
            )
            .environment(\.appLanguage, appLanguage)
        }
        .sheet(isPresented: $isShowingFeedbackSheet) {
            FeedbackSheetView(
                screenContext: "profile_settings",
                onSubmitted: {
                    profileToastMessage = l10n.feedbackSentToast
                }
            )
            .environment(\.appLanguage, appLanguage)
        }
        .toast(message: $profileToastMessage)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await notificationManager.refreshAuthorizationStatus() }
            }
        }
        .task {
            await accessManager.refreshAccessStatus()
            await notificationManager.refreshAuthorizationStatus()
            guard let uid = authService.uid else { return }
            profile = try? await FirestoreService.shared.fetchUserProfile(uid: uid)
            followerCount = (try? await FirestoreService.shared.fetchFollowerCount(uid: uid)) ?? 0
            followingCount = (try? await FirestoreService.shared.fetchFollowingCount(uid: uid)) ?? 0
            userPosts = (try? await FirestoreService.shared.fetchUserTimeline(uid: uid)) ?? []
            isLoadingPosts = false
        }
    }

    // MARK: - Dedicated Settings Screen (HIG Settings Rule 2 & 5)

    private var settingsDestination: some View {
        List {
            // Membership
            Section(l10n.profileMembershipSection) {
                if accessManager.isPro {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(l10n.proTitle, systemImage: "checkmark.seal.fill")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(proStatusLabel)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.primary.opacity(0.08), in: Capsule())
                                .foregroundStyle(.primary)
                        }
                        if let expDate = accessManager.effectiveExpirationDate {
                            let dateText = expDate.formatted(date: .abbreviated, time: .omitted)
                            Text(accessManager.effectiveWillRenew ? l10n.proRenewsOn(dateText) : l10n.proExpiresOn(dateText))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)

                    Button {
                        Task { await accessManager.openManageSubscriptions() }
                    } label: {
                        HStack {
                            Label(l10n.proManageSubscription, systemImage: "creditcard")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2.bold())
                                .foregroundStyle(.tertiary)
                        }
                    }
                } else {
                    Button {
                        isShowingPaywall = true
                    } label: {
                        HStack {
                            Label(l10n.profileUpgradeToPro, systemImage: "sparkles")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Button {
                    Task { await handleProfileRestore() }
                } label: {
                    HStack {
                        Label(l10n.proRestorePurchases, systemImage: "arrow.clockwise")
                            .foregroundStyle(.primary)
                        Spacer()
                        if accessManager.isRestoring {
                            ProgressView().controlSize(.small)
                        }
                    }
                }
                .disabled(accessManager.isRestoring)
            }
            .listRowBackground(Color(uiColor: .systemBackground))

            // Preferences
            Section(l10n.profilePreferences) {
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
                            .foregroundStyle(.primary)
                    }
                }

                Button {
                    tempLetterboxdUsername = storedLetterboxdUsername
                    isShowingLetterboxdPrompt = true
                } label: {
                    HStack(spacing: 8) {
                        Label {
                            Text("Letterboxd")
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "film")
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        Text(storedLetterboxdUsername.isEmpty ? l10n.letterboxdConnectDiary : "@\(storedLetterboxdUsername)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .listRowBackground(Color(uiColor: .systemBackground))

            // Notifications
            Section {
                if notificationManager.authorizationStatus == .denied {
                    Button {
                        notificationManager.openSystemNotificationSettings()
                    } label: {
                        HStack(spacing: 10) {
                            Label {
                                Text(l10n.notificationsDeniedBanner)
                                    .foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: "bell.slash")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2.bold())
                                .foregroundStyle(.tertiary)
                        }
                    }
                } else {
                    if notificationManager.authorizationStatus == .provisional {
                        Button {
                            notificationManager.openSystemNotificationSettings()
                        } label: {
                            HStack(spacing: 8) {
                                Text(l10n.notificationsProvisionalHint)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 4)
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    Toggle(
                        isOn: Binding(
                            get: { notificationManager.dailyReminderEnabled },
                            set: { newValue in
                                Task {
                                    await notificationManager.setDailyReminderEnabled(
                                        newValue,
                                        interests: parsedStoredInterests,
                                        language: appLanguage,
                                        menuCompletedToday: !accessManager.isPro && accessManager.snapshot.platesRemaining == 0
                                    )
                                }
                            }
                        )
                    ) {
                        Label {
                            Text(l10n.notificationsDailyMenuToggle)
                        } icon: {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(.primary)
                        }
                    }
                    .tint(OmakaseTheme.ink)

                    if notificationManager.dailyReminderEnabled {
                        DatePicker(
                            selection: Binding(
                                get: { notificationManager.reminderDateBinding },
                                set: { newDate in
                                    Task {
                                        await notificationManager.updateReminderTime(
                                            newDate,
                                            interests: parsedStoredInterests,
                                            language: appLanguage,
                                            menuCompletedToday: !accessManager.isPro && accessManager.snapshot.platesRemaining == 0
                                        )
                                    }
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        ) {
                            Label {
                                Text(l10n.notificationsReminderTime)
                            } icon: {
                                Image(systemName: "clock")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }

                    Toggle(
                        isOn: Binding(
                            get: { notificationManager.commentPushEnabled },
                            set: { newValue in
                                Task {
                                    await notificationManager.setCommentPushEnabled(newValue)
                                }
                            }
                        )
                    ) {
                        Label {
                            Text(l10n.notificationsCommentsToggle)
                        } icon: {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .foregroundStyle(.primary)
                        }
                    }
                    .tint(OmakaseTheme.ink)

                    Toggle(
                        isOn: Binding(
                            get: { notificationManager.dailyDigestEnabled },
                            set: { newValue in
                                Task {
                                    await notificationManager.setDailyDigestEnabled(newValue)
                                }
                            }
                        )
                    ) {
                        Label {
                            Text(l10n.notificationsDigestToggle)
                        } icon: {
                            Image(systemName: "sparkles.rectangle.stack")
                                .foregroundStyle(.primary)
                        }
                    }
                    .tint(OmakaseTheme.ink)
                }
            } header: {
                Text(l10n.notificationsSectionTitle)
            } footer: {
                if notificationManager.authorizationStatus != .denied {
                    Text(l10n.notificationsQuietHoursFooter)
                }
            }
            .listRowBackground(Color(uiColor: .systemBackground))

            // Support & Legal
            Section(l10n.profileSupportAndLegal) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    isShowingFeedbackSheet = true
                } label: {
                    HStack {
                        Label {
                            Text(l10n.feedbackRowLabel)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }

                if let supportURL = URL(string: "mailto:destek@getomakase.app") {
                    Link(destination: supportURL) {
                        HStack {
                            Label {
                                Text(l10n.contactSupport)
                                    .foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: "envelope")
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Text("destek@getomakase.app")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.up.right")
                                .font(.caption2.bold())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                if let privacyURL = URL(string: "https://getomakase.app/privacy.html") {
                    Link(destination: privacyURL) {
                        HStack {
                            Label {
                                Text(l10n.privacyPolicy)
                                    .foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: "hand.raised")
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2.bold())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                if let termsURL = URL(string: "https://getomakase.app/terms.html") {
                    Link(destination: termsURL) {
                        HStack {
                            Label {
                                Text(l10n.termsOfUse)
                                    .foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2.bold())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .listRowBackground(Color(uiColor: .systemBackground))

            // Account
            Section(l10n.profileAccount) {
                if let email = authService.email, !email.isEmpty {
                    HStack {
                        Label(email, systemImage: "person.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    Task {
                        await authService.signOutAndCleanup(l10n: l10n)
                        if authService.isAuthenticated, let err = authService.errorMessage {
                            accountErrorMessage = err
                        } else {
                            dismiss()
                        }
                    }
                } label: {
                    Label(l10n.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.primary)
                }
                .disabled(isDeletingAccount)

                Button(role: .destructive) {
                    isShowingDeleteAccountAlert = true
                } label: {
                    if isDeletingAccount {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(l10n.deleteAccount)
                        }
                    } else {
                        Label(l10n.deleteAccount, systemImage: "trash")
                    }
                }
                .disabled(isDeletingAccount)
            }
            .listRowBackground(Color(uiColor: .systemBackground))
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .navigationTitle(l10n.settingsTitle)
        .navigationBarTitleDisplayMode(.inline)
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
        .alert(l10n.confirmDeleteAccountTitle, isPresented: $isShowingDeleteAccountAlert) {
            Button(l10n.cancel, role: .cancel) { }
            Button(l10n.deleteAccountConfirmButton, role: .destructive) {
                Task {
                    isDeletingAccount = true
                    let deleted = await authService.deleteAccount(l10n: l10n)
                    isDeletingAccount = false
                    if deleted {
                        dismiss()
                    } else if let err = authService.errorMessage {
                        accountErrorMessage = err
                    }
                }
            }
        } message: {
            Text(l10n.confirmDeleteAccountMessage)
        }
        .alert(
            l10n.errorSomethingWrong,
            isPresented: Binding(
                get: { accountErrorMessage != nil },
                set: { if !$0 { accountErrorMessage = nil } }
            )
        ) {
            Button(l10n.ok, role: .cancel) { accountErrorMessage = nil }
        } message: {
            Text(accountErrorMessage ?? "")
        }
    }

    // MARK: - Helpers

    private var avatarView: some View {
        MonogramAvatarView(
            name: profile?.displayName ?? authService.displayName ?? "Omakase",
            size: 80
        )
    }

    private var proStatusLabel: String {
        switch accessManager.effectiveStatus {
        case "trial":
            return l10n.proTrialStatus
        case "billing_issue":
            return l10n.proBillingIssueStatus
        default:
            return l10n.proActiveStatus
        }
    }

    private func handleProfileRestore() async {
        let outcome = await accessManager.restorePurchases()
        switch outcome {
        case .restored:
            profileToastMessage = l10n.proRestoreSuccess
        case .nothingToRestore:
            profileToastMessage = l10n.proRestoreEmpty
        case .failed(let error):
            profileToastMessage = error.message(l10n: l10n)
        }
    }

    private var parsedStoredInterests: [String] {
        storedInterests
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
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

// MARK: - Edit Profile Sheet (Display Name + Unique @username with 14-day cooldown)

struct EditProfileSheet: View {
    let authService: AuthService
    let currentProfile: UserProfile?
    var onSaved: (UserProfile) -> Void

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var isCheckingUsername = false
    @State private var isUsernameAvailable: Bool? = nil
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var debounceTask: Task<Void, Never>?

    private var l10n: L10n { L10n(lang: appLanguage) }

    private var cleanUsername: String { UserProfile.sanitizeUsername(username) }
    private var trimmedName: String { displayName.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var originalUsername: String {
        UserProfile.sanitizeUsername(currentProfile?.username ?? "")
    }

    private var usernameChanged: Bool {
        cleanUsername != originalUsername
    }

    private var cooldownDaysRemaining: Int {
        guard let currentProfile, !(currentProfile.username ?? "").isEmpty else { return 0 }
        return currentProfile.daysUntilNextUsernameChange
    }

    private var canEditUsername: Bool {
        cooldownDaysRemaining == 0
    }

    private var canSave: Bool {
        guard !isSaving, !trimmedName.isEmpty, cleanUsername.count >= 3 else { return false }
        if usernameChanged {
            return canEditUsername && !isCheckingUsername && isUsernameAvailable == true
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    MonogramAvatarView(
                        name: trimmedName.isEmpty ? (cleanUsername.isEmpty ? "O" : cleanUsername) : trimmedName,
                        size: 84
                    )
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(l10n.profileDisplayNameLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        TextField(l10n.authDisplayNamePlaceholder, text: $displayName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(OmakaseTheme.ink.opacity(0.25), lineWidth: 1)
                            )

                        Text(l10n.profileDisplayNameHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(l10n.profileUsernameLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            Text("@")
                                .font(.body.weight(.bold))
                                .foregroundStyle(.secondary)

                            TextField(l10n.authUsernamePlaceholder, text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .disabled(!canEditUsername)

                            if usernameChanged && canEditUsername {
                                if isCheckingUsername {
                                    ProgressView().controlSize(.small)
                                } else if isUsernameAvailable == true {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.primary)
                                } else if isUsernameAvailable == false {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            } else if !canEditUsername {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    (usernameChanged && isUsernameAvailable == false)
                                        ? Color.red.opacity(0.5)
                                        : OmakaseTheme.ink.opacity(canEditUsername ? 0.25 : 0.12),
                                    lineWidth: 1
                                )
                        )
                        .opacity(canEditUsername ? 1.0 : 0.65)

                        if !canEditUsername {
                            Text(l10n.profileUsernameLockedDays(cooldownDaysRemaining))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if usernameChanged && isUsernameAvailable == false {
                            Text(l10n.authUsernameTaken)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.red)
                        } else {
                            Text(l10n.profileUsernameCooldownNote)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.red.opacity(0.35), lineWidth: 1)
                        )
                    }

                    Button {
                        Task { await saveProfile() }
                    } label: {
                        ZStack {
                            if isSaving {
                                ProgressView().tint(OmakaseTheme.chipActiveText)
                            } else {
                                Text(l10n.save)
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(OmakaseTheme.chipActiveFill)
                        )
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                        .opacity(canSave ? 1.0 : 0.4)
                    }
                    .buttonStyle(OmakaseChipButtonStyle())
                    .disabled(!canSave)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            .navigationTitle(l10n.editProfileTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.cancel) { dismiss() }
                }
            }
        }
        .onAppear {
            displayName = currentProfile?.displayName ?? authService.displayName ?? ""
            username = currentProfile?.username ?? ""
        }
        .onChange(of: username) { _, newValue in
            let sanitized = UserProfile.sanitizeUsername(newValue)
            if sanitized != newValue {
                username = sanitized
            }
            checkAvailabilityDebounced(sanitized)
        }
    }

    private func checkAvailabilityDebounced(_ candidate: String) {
        debounceTask?.cancel()
        errorMessage = nil
        guard candidate != originalUsername else {
            isCheckingUsername = false
            isUsernameAvailable = true
            return
        }
        guard candidate.count >= 3 else {
            isCheckingUsername = false
            isUsernameAvailable = nil
            return
        }
        isCheckingUsername = true
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            let available = (try? await FirestoreService.shared.isUsernameAvailable(
                candidate,
                excludingUid: authService.uid
            )) ?? false
            await MainActor.run {
                if UserProfile.sanitizeUsername(username) == candidate {
                    isUsernameAvailable = available
                    isCheckingUsername = false
                }
            }
        }
    }

    private func saveProfile() async {
        guard let uid = authService.uid else { return }
        isSaving = true
        errorMessage = nil
        do {
            let updated = try await FirestoreService.shared.updateUserProfile(
                uid: uid,
                displayName: trimmedName,
                newUsername: cleanUsername
            )
            await authService.markProfileSetupCompleted(displayName: updated.displayName)
            isSaving = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSaved(updated)
            dismiss()
        } catch let err as ProfileUpdateError {
            isSaving = false
            switch err {
            case .usernameTaken:
                errorMessage = l10n.authUsernameTaken
                isUsernameAvailable = false
            case .cooldownActive(let days):
                errorMessage = l10n.profileUsernameLockedDays(days)
            case .invalidUsername:
                errorMessage = l10n.authUsernameInvalid
            case .invalidDisplayName:
                errorMessage = l10n.errorContentBlockedMessage
            }
        } catch {
            isSaving = false
            errorMessage = OmakaseError.from(error).message(l10n: l10n)
        }
    }
}

// MARK: - Hidden Folks Ink-on-Paper Monogram Avatar

struct MonogramAvatarView: View {
    let name: String
    var size: CGFloat

    private var initials: String {
        let cleaned = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        let parts = cleaned.split(whereSeparator: \.isWhitespace)
        if parts.count >= 2,
           let first = parts.first?.first,
           let last = parts.last?.first {
            return "\(first)\(last)".uppercased()
        }
        if let only = parts.first {
            // Single-word name or handle (e.g. "Kuzey" or email user) -> 2 crisp letters
            return String(only.prefix(2)).uppercased()
        }
        return "O"
    }

    var body: some View {
        Circle()
            .fill(Color(uiColor: .systemBackground))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(OmakaseTheme.ink, lineWidth: max(1.5, size * 0.025))
            )
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .heavy, design: .rounded))
                    .tracking(-0.3)
                    .foregroundStyle(OmakaseTheme.ink)
            )
            .accessibilityHidden(true)
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
