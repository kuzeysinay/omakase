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
            if let urlStr = user.photoURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                            .frame(width: 80, height: 80).clipShape(Circle())
                    } else { defaultAvatar }
                }
            } else { defaultAvatar }

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

    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 72)).symbolRenderingMode(.hierarchical).foregroundStyle(.secondary)
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
    @State private var profileToastMessage: String?

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
                            if let email = authService.email, !email.isEmpty {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        // Stats pill
                        HStack(spacing: 0) {
                            statCell(value: followerCount, label: l10n.followers)
                            Divider().frame(height: 32)
                            statCell(value: followingCount, label: l10n.followingLabel)
                        }
                        .background(Color(.tertiarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12))

                        if let interests = profile?.interests, !interests.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(l10n.yourTastes)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                FlowLayoutShared(spacing: 6) {
                                    ForEach(interests, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption).fontWeight(.medium)
                                            .padding(.horizontal, 10).padding(.vertical, 4)
                                            .background(Color.primary.opacity(0.08), in: Capsule())
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                        }

                        Spacer().frame(height: 8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // MARK: - Saved Posts
                Section(l10n.savedTitle) {
                    NavigationLink(value: BookmarksNavigationRoute.collections) {
                        HStack(spacing: 10) {
                            Label {
                                Text(l10n.savedPostsLabel)
                                    .foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: "bookmark.fill")
                                    .foregroundStyle(OmakaseTheme.ink)
                            }
                            Spacer()
                            Text("\(bookmarkStore.entryCount(in: "All"))")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Posts
                Section(userPosts.isEmpty ? l10n.profilePosts : "\(l10n.profilePosts) (\(userPosts.count))") {
                    if isLoadingPosts {
                        HStack { Spacer(); ProgressView(); Spacer() }
                            .padding(.vertical, 8)
                    } else if userPosts.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.stack")
                                .foregroundStyle(.secondary)
                            Text(l10n.noPostsYet)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
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
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowSeparator(.hidden)
                        }
                    }
                }

                // MARK: - Membership (Omakase Pro)
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
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(l10n.profileUpgradeToPro)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(
                                            l10n.profileDailyQuotaSummary(
                                                platesRemaining: accessManager.snapshot.platesRemaining,
                                                platesLimit: accessManager.snapshot.platesLimit,
                                                deepDivesRemaining: accessManager.snapshot.deepDivesRemaining,
                                                deepDivesLimit: accessManager.snapshot.deepDivesLimit
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(OmakaseTheme.ink)
                                }
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
                                .foregroundStyle(.primary)
                        }
                    }

                    // Letterboxd integration
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

                // MARK: - Notifications (Phase 3)
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

                // MARK: - Support & Legal (Guidelines 1.2, 1.5 & 5.1.1(i))
                Section(l10n.profileSupportAndLegal) {
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

                // MARK: - Account / Sign Out & Delete Account (Guideline 5.1.1(v))
                Section(l10n.profileAccount) {
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
            }
            .listStyle(.insetGrouped)
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
        .sheet(isPresented: $isShowingPaywall) {
            OmakasePaywallView(
                source: .profile,
                onToast: { profileToastMessage = $0 }
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
