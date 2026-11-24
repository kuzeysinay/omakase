//
//  FeedView.swift
//  omakase
//

import SwiftUI

struct FeedView: View {

    @Environment(\.appLanguage) private var appLanguage
    @AppStorage("omakase.interests") private var storedInterests: String = ""

    @State private var viewModel: FeedViewModel
    @State private var bookmarkStore = BookmarkStore.shared
    @State private var accessManager = AccessManager.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var activeInterests: Set<String> = []
    @State private var pendingDeletePostID: UUID?
    @State private var showDeletePostConfirmation = false
    @State private var toastMessage: String?
    @State private var paywallSource: PaywallSource?
    @State private var pendingNotificationTopicAfterPaywall: (topic: String, categoryId: String?)?
    @State private var showNotificationDeniedAlert = false
    @State private var feedScrollPosition: AnyHashable?
    @State private var isHydratingCache = false

    // Letterboxd
    @AppStorage("omakase.letterboxd_username") private var storedLetterboxdUsername: String = ""
    @State private var isLetterboxdActive: Bool = false
    @State private var showLetterboxdUsernamePrompt: Bool = false
    @State private var letterboxdDraft: String = ""

    let authService: AuthService
    /// Reference kept so PostCard can call deep dive.
    private var feedViewModelForCards: FeedViewModel { viewModel }

    private var l10n: L10n {
        L10n(lang: appLanguage)
    }

    private func continuousCooldownProgress(at now: Date) -> CGFloat {
        if let start = viewModel.readingCooldownStartDate,
           let end = viewModel.readingCooldownEndDate {
            let total = end.timeIntervalSince(start)
            guard total > 0 else { return 0 }
            let remaining = end.timeIntervalSince(now)
            return CGFloat(max(0, min(1, remaining / total)))
        }
        guard viewModel.readingCooldownTotal > 0 else { return 0 }
        return max(0, min(1, CGFloat(viewModel.readingCooldownRemaining) / CGFloat(viewModel.readingCooldownTotal)))
    }

    init(authService: AuthService) {
        self.authService = authService
        let raw = UserDefaults.standard.string(forKey: "omakase.interests") ?? ""
        let interests = Self.parse(interests: raw)
        _viewModel = State(initialValue: FeedViewModel(interests: interests))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        @Bindable var bookmarkStore = bookmarkStore
        return NavigationStack {
            reelsFeed(bookmarkStore: bookmarkStore)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemBackground))
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .top, spacing: 0) {
                    topHeaderBar
                }
            .alert(
                viewModel.activeError?.title(l10n: l10n) ?? l10n.errorSomethingWrong,
                isPresented: .init(
                    get: { viewModel.activeError != nil },
                    set: { if !$0 { viewModel.dismissError() } }
                )
            ) {
                if let activeError = viewModel.activeError {
                    if case .unauthorized = activeError {
                        Button(l10n.cancel, role: .cancel) { viewModel.dismissError() }
                        Button(l10n.signInAgain) {
                            viewModel.dismissError()
                            authService.signOut(l10n: l10n)
                        }
                    } else if case .alert(let canRetry) = activeError.presentation, canRetry {
                        Button(l10n.cancel, role: .cancel) { viewModel.dismissError() }
                        Button(l10n.tryAgain) { viewModel.retryLastRequest() }
                    } else {
                        Button(l10n.ok, role: .cancel) { viewModel.dismissError() }
                    }
                } else {
                    Button(l10n.ok, role: .cancel) { viewModel.dismissError() }
                }
            } message: {
                Text(viewModel.activeError?.message(l10n: l10n) ?? "")
            }
            .alert(l10n.confirmDeletePostTitle, isPresented: $showDeletePostConfirmation) {
                Button(l10n.cancel, role: .cancel) {
                    pendingDeletePostID = nil
                }
                Button(l10n.remove, role: .destructive) {
                    if let id = pendingDeletePostID {
                        let fallbackID: AnyHashable?
                        if let idx = viewModel.posts.firstIndex(where: { $0.id == id }) {
                            if idx > 0 {
                                fallbackID = viewModel.posts[idx - 1].id
                            } else if viewModel.posts.count > 1 {
                                fallbackID = viewModel.posts[idx + 1].id
                            } else {
                                fallbackID = "category-page"
                            }
                        } else {
                            fallbackID = "category-page"
                        }

                        withAnimation {
                            viewModel.removePost(id: id)
                            if let fallbackID {
                                feedScrollPosition = fallbackID
                            }
                        }
                    }
                    pendingDeletePostID = nil
                }
            } message: {
                Text(l10n.confirmDeletePostMessage)
            }
            .alert(
                l10n.letterboxdUsernamePromptTitle,
                isPresented: $showLetterboxdUsernamePrompt
            ) {
                TextField(l10n.letterboxdUsernamePlaceholder, text: $letterboxdDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(l10n.ok) {
                    let trimmed = letterboxdDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        storedLetterboxdUsername = trimmed
                        viewModel.letterboxdUsername = trimmed
                        viewModel.isLetterboxdActive = true
                        isLetterboxdActive = true
                        viewModel.requestLetterboxdDedicatedPost(username: trimmed)
                    } else {
                        storedLetterboxdUsername = ""
                        isLetterboxdActive = false
                        viewModel.isLetterboxdActive = false
                    }
                    letterboxdDraft = ""
                }
                Button(l10n.cancel, role: .cancel) {
                    isLetterboxdActive = false
                    viewModel.isLetterboxdActive = false
                    letterboxdDraft = ""
                }
            } message: {
                Text(l10n.letterboxdUsernamePromptMessage)
            }
            .toast(message: $toastMessage)
            .sheet(item: $paywallSource) { source in
                OmakasePaywallView(
                    source: source,
                    onToast: { toastMessage = $0 }
                )
                .environment(\.appLanguage, appLanguage)
            }
            .alert(l10n.notificationsDeniedAlertTitle, isPresented: $showNotificationDeniedAlert) {
                Button(l10n.cancel, role: .cancel) { }
                Button(l10n.openSettingsCTA) {
                    NotificationManager.shared.openSystemNotificationSettings()
                }
            } message: {
                Text(l10n.notificationsDeniedAlertMessage)
            }
        }
        .task {
            let rawParsed = Self.parse(interests: storedInterests)
            let parsed = ContentModerationService.filterAppropriate(rawParsed)
            if parsed != rawParsed {
                storedInterests = parsed.joined(separator: ", ")
            }
            activeInterests = Set(parsed)
            viewModel.setContentLanguage(appLanguage)
            viewModel.updateInterests(parsed)
            SubTopicDiscoveryStore.shared.prewarmAllCategories(language: appLanguage, userInterests: parsed)
            if viewModel.posts.isEmpty {
                isHydratingCache = true
                await viewModel.loadCachedPosts()
                if viewModel.isOffline, let lastID = viewModel.posts.last?.id {
                    feedScrollPosition = lastID
                } else {
                    feedScrollPosition = "category-page"
                }
                // Allow SwiftUI's onChange for posts.last?.id to observe the hydrated state
                // before re-enabling auto-scroll for newly generated posts.
                try? await Task.sleep(for: .milliseconds(50))
                isHydratingCache = false
            }
            await handlePendingNotificationTopicIfNeeded()
        }
        .onChange(of: notificationManager.pendingTopicRequest) { _, request in
            guard request != nil else { return }
            Task {
                await handlePendingNotificationTopicIfNeeded()
            }
        }
        .onChange(of: accessManager.isPro) { _, isPro in
            guard isPro, let pending = pendingNotificationTopicAfterPaywall else { return }
            pendingNotificationTopicAfterPaywall = nil
            paywallSource = nil
            viewModel.requestDedicatedPostFromNotification(
                topic: pending.topic,
                categoryId: pending.categoryId
            )
        }
        .onChange(of: paywallSource) { _, newSource in
            if newSource == nil && !accessManager.isPro {
                pendingNotificationTopicAfterPaywall = nil
            }
        }
        .onChange(of: viewModel.isOffline) { _, isOffline in
            if isOffline && viewModel.posts.isEmpty {
                Task {
                    await viewModel.loadCachedPosts()
                }
            }
        }
        .onChange(of: appLanguage) { _, newLang in
            viewModel.setContentLanguage(newLang)
        }
        .onChange(of: storedInterests) { oldValue, newValue in
            let oldParsed = Set(Self.parse(interests: oldValue))
            let newParsed = Set(Self.parse(interests: newValue))
            activeInterests = activeInterests.intersection(newParsed)
                .union(newParsed.subtracting(oldParsed))
        }
        .onChange(of: activeInterests) { _, newValue in
            let all = Self.parse(interests: storedInterests)
            let active = all.filter { newValue.contains($0) }
            viewModel.updateInterests(active)
        }
        .onChange(of: isLetterboxdActive) { _, newValue in
            viewModel.isLetterboxdActive = newValue
        }
        .onChange(of: viewModel.pendingToastError) { _, newError in
            guard let newError else { return }
            toastMessage = newError.message(l10n: l10n)
            _ = viewModel.consumeToastError()
        }
        .onChange(of: viewModel.shouldPresentSoftPaywall) { _, shouldShow in
            guard shouldShow else { return }
            viewModel.shouldPresentSoftPaywall = false
            guard !accessManager.isPro,
                  !UserDefaults.standard.bool(forKey: "omakase.hasShownFirstPlatePaywall") else {
                return
            }
            UserDefaults.standard.set(true, forKey: "omakase.hasShownFirstPlatePaywall")
            paywallSource = .firstPlateSoft
        }
        .onChange(of: viewModel.requestedPaywallSource) { _, requested in
            guard let requested else { return }
            viewModel.requestedPaywallSource = nil
            paywallSource = requested
        }
    }

    private var allInterests: [String] {
        Self.parse(interests: storedInterests)
    }

    private func addInterest(_ interest: String) {
        guard ContentModerationService.isAppropriate(interest) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            toastMessage = l10n.toastInappropriateInterest
            return
        }
        var list = allInterests
        guard !list.contains(where: { $0.caseInsensitiveCompare(interest) == .orderedSame }) else { return }
        list.append(interest)
        storedInterests = list.joined(separator: ", ")
    }

    private func removeInterest(_ interest: String) {
        var list = allInterests
        list.removeAll { $0.caseInsensitiveCompare(interest) == .orderedSame }
        storedInterests = list.joined(separator: ", ")
    }

    // MARK: - Subviews

    private var topHeaderBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 7) {
                    Image("AppLogo")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(Color.primary)
                    Text(l10n.appTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }
                .padding(.leading, 18)

                Spacer()

                if !accessManager.isPro {
                    dailyQuotaStressPill
                        .padding(.trailing, 16)
                }
            }
            .frame(height: 44)
            .background(Color(uiColor: .systemBackground))

            cooldownBarView
        }
        .background(Color(uiColor: .systemBackground))
    }

    @ViewBuilder
    private var dailyQuotaStressPill: some View {
        let limit = max(1, accessManager.snapshot.platesLimit)
        let remaining = max(0, min(limit, accessManager.snapshot.platesRemaining))
        let isCritical = remaining <= 1
        let isWarning = remaining == 2
        let accentColor: Color = isCritical ? .red : (isWarning ? .orange : .primary)
        let fillColor: Color = isCritical
            ? Color.red.opacity(0.14)
            : (isWarning ? Color.orange.opacity(0.14) : Color.primary.opacity(0.07))
        let strokeColor: Color = isCritical
            ? Color.red.opacity(0.45)
            : (isWarning ? Color.orange.opacity(0.45) : Color.primary.opacity(0.14))

        Button {
            paywallSource = .plateLimit
        } label: {
            HStack(spacing: 6) {
                if limit <= 5 {
                    HStack(spacing: 3) {
                        ForEach(0..<limit, id: \.self) { index in
                            Circle()
                                .fill(index < remaining ? accentColor : Color.primary.opacity(0.16))
                                .frame(width: 5, height: 5)
                        }
                    }
                } else {
                    let progressWidth: CGFloat = 28
                    let ratio = CGFloat(remaining) / CGFloat(limit)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.16))
                        Capsule()
                            .fill(accentColor)
                            .frame(width: max(0, progressWidth * ratio))
                    }
                    .frame(width: progressWidth, height: 5)
                    .clipShape(Capsule())
                }

                if isCritical {
                    Image(systemName: remaining == 0 ? "lock.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                }

                Text(l10n.feedQuotaPlatesRemaining(remaining: remaining, limit: limit))
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(accentColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(fillColor, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(strokeColor, lineWidth: 1)
            )
            .animation(.snappy(duration: 0.25), value: remaining)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l10n.feedQuotaAccessibilityLabel(remaining: remaining, limit: limit))
    }

    private var cooldownBarView: some View {
        SwiftUI.TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !viewModel.isCooldownActive)) { timeline in
            let progress = continuousCooldownProgress(at: timeline.date)
            GeometryReader { barGeo in
                ZStack(alignment: .leading) {
                    if viewModel.isCooldownActive {
                        Rectangle()
                            .fill(Color.primary.opacity(0.08))
                        Rectangle()
                            .fill(OmakaseTheme.ink)
                            .frame(width: max(0, barGeo.size.width * progress))
                    } else {
                        Rectangle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(height: 0.5)
                    }
                }
            }
        }
        .frame(height: viewModel.isCooldownActive ? 3.0 : 0.5)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isCooldownActive)
    }

    /// Instagram Reels-style vertical paging feed.
    /// Each post occupies the full screen height, followed by the full-screen Category page.
    private func reelsFeed(bookmarkStore: BookmarkStore) -> some View {
        ScrollViewReader { proxy in
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 100) {
                            ForEach(viewModel.posts) { post in
                                ReelsPostCard(
                                    post: post,
                                    isLastPost: post.id == viewModel.posts.last?.id,
                                    bookmarkStore: bookmarkStore,
                                    authService: authService,
                                    viewModel: viewModel,
                                    toastMessage: $toastMessage,
                                    onDelete: {
                                        pendingDeletePostID = post.id
                                        showDeletePostConfirmation = true
                                    },
                                    onScrollToCategories: {
                                        withAnimation(.spring(response: 0.36, dampingFraction: 0.85)) {
                                            feedScrollPosition = "category-page"
                                            proxy.scrollTo("category-page", anchor: .top)
                                        }
                                    }
                                )
                                .environment(\.appLanguage, appLanguage)
                                .id(post.id)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                            }

                            // Full-screen Categories or Daily Limit Page:
                            // Covers the entire page when there are no posts, disappears while a post
                            // is generating, and opens again when scrolling down after a post.
                            if !viewModel.isGenerating {
                                if accessManager.isPlateLimitReached {
                                    DailyLimitCardView(
                                        resetsAt: accessManager.nextResetDate,
                                        hasExistingPosts: !viewModel.posts.isEmpty,
                                        onScrollToLastPost: {
                                            if let lastID = viewModel.posts.last?.id {
                                                withAnimation(.spring(response: 0.36, dampingFraction: 0.85)) {
                                                    feedScrollPosition = lastID
                                                    proxy.scrollTo(lastID, anchor: .top)
                                                }
                                            }
                                        },
                                        onUpgrade: {
                                            paywallSource = .plateLimit
                                        },
                                        onRemind: {
                                            Task {
                                                let result = await NotificationManager.shared.enableDailyReminderFromLimitCard(
                                                    interests: allInterests,
                                                    language: appLanguage
                                                )
                                                switch result {
                                                case .scheduled(let timeText):
                                                    toastMessage = l10n.limitCardRemindScheduledToast(timeText: timeText)
                                                case .denied:
                                                    showNotificationDeniedAlert = true
                                                case .notGranted:
                                                    toastMessage = l10n.notificationsNotGrantedToast
                                                }
                                            }
                                        }
                                    )
                                    .environment(\.appLanguage, appLanguage)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                                    .id("category-page")
                                    .transition(.opacity)
                                } else {
                                    BentoTasteBox(
                                        allInterests: allInterests,
                                        activeInterests: $activeInterests,
                                        onAddInterest: { addInterest($0) },
                                        onRemoveInterest: { removeInterest($0) },
                                        isLetterboxdActive: $isLetterboxdActive,
                                        isGenerating: viewModel.isGenerating,
                                        isOffline: viewModel.isOffline,
                                        isCooldownActive: viewModel.isCooldownActive,
                                        cooldownRemaining: viewModel.readingCooldownRemaining,
                                        cooldownTotal: viewModel.readingCooldownTotal,
                                        hasExistingPosts: !viewModel.posts.isEmpty,
                                        onScrollToLastPost: {
                                            if let lastID = viewModel.posts.last?.id {
                                                withAnimation(.spring(response: 0.36, dampingFraction: 0.85)) {
                                                    feedScrollPosition = lastID
                                                    proxy.scrollTo(lastID, anchor: .top)
                                                }
                                            }
                                        },
                                        onSelectDedicatedTopic: { topic, categoryId in
                                            guard !viewModel.isGenerating && !viewModel.isCooldownActive else { return }
                                            viewModel.requestDedicatedPost(topic: topic, categoryId: categoryId)
                                        },
                                        onPromptLetterboxdUsername: {
                                            letterboxdDraft = storedLetterboxdUsername
                                            showLetterboxdUsernamePrompt = true
                                        },
                                        onSelectLetterboxdPost: {
                                            guard !viewModel.isGenerating && !viewModel.isCooldownActive else { return }
                                            let clean = storedLetterboxdUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                                            viewModel.requestLetterboxdDedicatedPost(username: clean)
                                        }
                                    )
                                    .environment(\.appLanguage, appLanguage)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                                    .id("category-page")
                                    .transition(.opacity)
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .contentMargins(.vertical, 0, for: .scrollContent)
                    .scrollPosition(id: $feedScrollPosition, anchor: .top)
                    .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                    .scrollDismissesKeyboard(.interactively)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .onChange(of: viewModel.posts.last?.id) { _, newID in
                        if isHydratingCache {
                            let target: AnyHashable = (viewModel.isOffline && newID != nil) ? newID! : "category-page"
                            feedScrollPosition = target
                            DispatchQueue.main.async {
                                proxy.scrollTo(target, anchor: .top)
                            }
                            return
                        }
                        guard let newID else {
                            feedScrollPosition = "category-page"
                            return
                        }
                        feedScrollPosition = newID
                        proxy.scrollTo(newID, anchor: .top)
                    }
                    .onChange(of: viewModel.isGenerating) { _, isGenerating in
                        if !isGenerating {
                            if let lastID = viewModel.posts.last?.id {
                                feedScrollPosition = lastID
                                DispatchQueue.main.async {
                                    proxy.scrollTo(lastID, anchor: .top)
                                }
                            } else {
                                feedScrollPosition = "category-page"
                                DispatchQueue.main.async {
                                    proxy.scrollTo("category-page", anchor: .top)
                                }
                            }
                        }
                    }

                    // Floating inline status banners (offline & Letterboxd issues)
                    if viewModel.isOffline || viewModel.letterboxdIssue != nil {
                        VStack(spacing: 8) {
                            if viewModel.isOffline {
                                HStack(spacing: 8) {
                                    Image(systemName: "wifi.slash")
                                        .font(.subheadline.weight(.semibold))
                                    Text(l10n.errorOfflineMessage)
                                        .font(.subheadline.weight(.medium))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                                .foregroundStyle(OmakaseTheme.ink)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }

                            if let issue = viewModel.letterboxdIssue {
                                HStack(spacing: 10) {
                                    Image(systemName: "film")
                                        .font(.subheadline.weight(.semibold))
                                    Text(issue.message(l10n: l10n))
                                        .font(.caption.weight(.medium))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 4)
                                    Button(l10n.editUsername) {
                                        letterboxdDraft = storedLetterboxdUsername
                                        viewModel.dismissLetterboxdIssue()
                                        showLetterboxdUsernamePrompt = true
                                    }
                                    .font(.caption.weight(.bold))
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)

                                    Button {
                                        viewModel.dismissLetterboxdIssue()
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(l10n.dismissLabel)
                                }
                                .foregroundStyle(OmakaseTheme.ink)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(uiColor: .secondarySystemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    @MainActor
    private func handlePendingNotificationTopicIfNeeded() async {
        guard let req = notificationManager.consumePendingTopicRequest() else { return }

        guard let rawTopic = req.topic?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawTopic.isEmpty else {
            await accessManager.refreshAccessStatus()
            if accessManager.isPlateLimitReached {
                pendingNotificationTopicAfterPaywall = nil
                paywallSource = .plateLimit
            }
            return
        }

        let cleanCategoryId = req.categoryId.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCategoryId = cleanCategoryId.isEmpty
            ? InterestCategory.resolveMainCategory(tags: [rawTopic], title: rawTopic).id
            : cleanCategoryId

        SubTopicDiscoveryStore.shared.recordSeen([rawTopic], for: resolvedCategoryId, language: appLanguage)
        await accessManager.refreshAccessStatus()

        if accessManager.isPlateLimitReached {
            pendingNotificationTopicAfterPaywall = (topic: rawTopic, categoryId: resolvedCategoryId)
            paywallSource = .plateLimit
        } else {
            viewModel.requestDedicatedPostFromNotification(
                topic: rawTopic,
                categoryId: resolvedCategoryId
            )
        }
    }

    static func parse(interests raw: String) -> [String] {
        raw
            .split(whereSeparator: { $0 == "," || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Reels-style Post Card (full-screen, one post per page)

private struct ReelsPostCard: View {
    let post: Post
    let isLastPost: Bool
    @Bindable var bookmarkStore: BookmarkStore
    let authService: AuthService
    var viewModel: FeedViewModel
    var toastMessage: Binding<String?>
    var onDelete: () -> Void
    var onScrollToCategories: () -> Void

    @Environment(\.appLanguage) private var appLanguage

    private var l10n: L10n { L10n(lang: appLanguage) }

    @State private var showCursor: Bool = true
    @State private var isShared: Bool = false
    @State private var isSharePending: Bool = false
    @State private var isDeepDiveExpanded: Bool = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showReportDialog: Bool = false
    @State private var showReportConfirmation: Bool = false
    @State private var isReported: Bool = false
    @State private var isReportPending: Bool = false

    private var isBookmarked: Bool {
        bookmarkStore.contains(postId: post.id)
    }

    var body: some View {
        // Use a single VStack instead of a nested ScrollView — the outer
        // paging ScrollView already provides vertical scrolling. Nesting two
        // vertical ScrollViews caused severe gesture contention and redundant
        // layout passes, which was the primary source of scroll stutter.
        ZStack(alignment: .trailing) {
            if post.isComplete {
                ZStack(alignment: .trailing) {
                    Color.red
                    Image(systemName: "trash.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 40)
                        .scaleEffect(swipeOffset < -100 ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: swipeOffset)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
            // Header: title, timestamp, LIVE badge
            postHeader
                .padding(.top, 8)

            // Main post body text
            if parsedPost.body.isEmpty && !post.isComplete {
                skeletonBody
                    .transition(.opacity)
            } else {
                Text(postBody)
                    .font(.system(size: 16.5, weight: .regular))
                    .lineSpacing(5)
                    .foregroundStyle(Color.primary.opacity(0.92))
                    .minimumScaleFactor(0.85)
                    .contentTransition(.opacity)
                    .transition(.opacity)
            }

            if let source = parsedPost.source {
                PostSourceView(source: source)
                    .padding(.top, 2)
                    .transition(.opacity)
            }

            // Deep dive indicator (content shown in sheet, not inline)
            if post.deepDiveText != nil, !post.isComplete {
                HStack(spacing: 6) {
                    Image(systemName: "fish.fill")
                        .foregroundStyle(.primary)
                    Text(l10n.writingDeepDive)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView().controlSize(.mini)
                }
                .transition(.opacity)
            }

            // Tags and Action Bar grouped under post content with balanced breathing room
            if post.isComplete {
                VStack(alignment: .leading, spacing: 10) {
                    if !post.tags.isEmpty {
                        tagChips
                    }
                    if !post.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        actionBar
                            .padding(.top, 2)
                    }
                }
                .transition(.opacity)
            }

            Spacer(minLength: 16)

            if post.isComplete && isLastPost {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onScrollToCategories()
                } label: {
                    HStack(spacing: 6) {
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                        Text(l10n.scrollDownForNewPost)
                            .font(.caption.weight(.medium))
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeOut(duration: 0.6), value: post.isComplete)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .offset(x: swipeOffset)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    guard post.isComplete else { return }
                    if value.translation.width < 0 {
                        swipeOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    guard post.isComplete else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if value.translation.width < -120 || value.predictedEndTranslation.width < -200 {
                            swipeOffset = 0
                            onDelete()
                        } else {
                            swipeOffset = 0
                        }
                    }
                }
        )
        }
        .task(id: post.isComplete) {
            guard !post.isComplete else {
                showCursor = false
                return
            }
            while !Task.isCancelled && !post.isComplete {
                showCursor.toggle()
                try? await Task.sleep(for: .milliseconds(450))
            }
            showCursor = false
        }
        .onChange(of: post.isComplete) { _, isComplete in
            // Only check share status after post finishes streaming.
            // Running this Firestore query during streaming or mid-scroll
            // caused hitches from the network roundtrip.
            guard isComplete, let user = authService.currentUser else { return }
            Task {
                isShared = (try? await FirestoreService.shared.hasSharedPost(
                    text: post.text, authorId: user.uid
                )) ?? false
            }
        }
        .onChange(of: post.deepDiveText) { oldValue, newValue in
            // Auto-open the sheet the moment ViewModel sets deepDiveText
            // (transitions from nil → "" as streaming starts) and close if cleared on error.
            if oldValue == nil, newValue != nil {
                isDeepDiveExpanded = true
            } else if oldValue != nil, newValue == nil {
                isDeepDiveExpanded = false
            }
        }
        .sheet(isPresented: $isDeepDiveExpanded) {
            deepDiveSheetContent
                .environment(\.appLanguage, appLanguage)
        }
    }

    // MARK: - Header

    private var postHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(cardTitle)
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Text(post.createdAt.localizedFormatted(for: appLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                if !post.isComplete {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                            .opacity(showCursor ? 1.0 : 0.35)
                            .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true), value: showCursor)
                        Text(l10n.liveBadge)
                            .font(.caption2.weight(.bold).monospaced())
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12), in: Capsule())
                    .foregroundStyle(.red)
                }

                // More menu: Report AI content (Guideline 1.2) & Remove
                if post.isComplete {
                    Menu {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showReportDialog = true
                        } label: {
                            Label(
                                isReported ? l10n.actionReported : l10n.reportAIPostTitle,
                                systemImage: isReported ? "flag.fill" : "flag"
                            )
                        }
                        .disabled(isReportPending)

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label(l10n.remove, systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color.primary.opacity(0.04), in: Circle())
                    }
                    .confirmationDialog(
                        l10n.reportAIPostTitle,
                        isPresented: $showReportDialog,
                        titleVisibility: .visible
                    ) {
                        Button(l10n.reportReasonInaccurate) {
                            Task { await submitAIReport(reason: l10n.reportReasonInaccurate) }
                        }
                        Button(l10n.reportReasonInappropriate, role: .destructive) {
                            Task { await submitAIReport(reason: l10n.reportReasonInappropriate) }
                        }
                        Button(l10n.reportReasonOther) {
                            Task { await submitAIReport(reason: l10n.reportReasonOther) }
                        }
                        Button(l10n.cancel, role: .cancel) {}
                    } message: {
                        Text(l10n.reportAIPostMessage)
                    }
                    .alert(l10n.reportAIPostTitle, isPresented: $showReportConfirmation) {
                        Button(l10n.ok, role: .cancel) {}
                    } message: {
                        Text(l10n.reportSubmittedToast)
                    }
                }
            }
        }
    }

    // MARK: - Action Bar (bottom, horizontal, like Reels)

    private var actionBar: some View {
        HStack(spacing: 24) {
            // Deep Dive button — opens sheet (re-read if already fetched)
            Button {
                if post.deepDiveText == nil {
                    viewModel.requestDeepDive(for: post)
                } else {
                    isDeepDiveExpanded = true
                }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: post.deepDiveText != nil ? "fish.fill" : "fish")
                        .font(.title3)
                        .foregroundStyle(post.deepDiveText != nil ? OmakaseTheme.ink : .primary)
                    Text(post.deepDiveText != nil
                         ? l10n.actionReRead
                         : l10n.actionDive)
                        .font(.caption2.weight(post.deepDiveText != nil ? .semibold : .regular))
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(width: 52)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.deepDiveA11y)

            // Share to timeline button
            Button {
                Task { await toggleShare() }
            } label: {
                VStack(spacing: 3) {
                    if isSharePending {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: isShared ? "paperplane.fill" : "paperplane")
                            .font(.title3)
                            .foregroundStyle(isShared ? OmakaseTheme.ink : .primary)
                    }
                    Text(isShared ? l10n.actionShared : l10n.actionShare)
                        .font(.caption2.weight(isShared ? .semibold : .regular))
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(width: 52)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isShared ? l10n.unsharePost : l10n.sharePost)
            .disabled(isSharePending)

            // iOS Share Sheet button
            Button {
                ShareService.presentShareSheet(post: post, language: appLanguage) {
                    guard AccessManager.shared.canClaimShareBonus else { return }
                    Task {
                        if await AccessManager.shared.claimShareBonus() {
                            toastMessage.wrappedValue = l10n.toastShareBonusGranted
                        }
                    }
                }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                    Text(l10n.actionExport)
                        .font(.caption2)
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(width: 52)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.shareSheetA11y)

            Spacer()

            // Bookmark button
            Button {
                bookmarkStore.toggle(post)
                if bookmarkStore.contains(postId: post.id) {
                    toastMessage.wrappedValue = l10n.toastBookmarked
                } else {
                    toastMessage.wrappedValue = l10n.toastBookmarkRemoved
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundStyle(isBookmarked ? OmakaseTheme.ink : .primary)
                    Text(isBookmarked ? l10n.actionSaved : l10n.actionSave)
                        .font(.caption2.weight(isBookmarked ? .semibold : .regular))
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(width: 52)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isBookmarked ? l10n.removeBookmarkA11y : l10n.bookmarkPostA11y)
        }
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    // MARK: - Deep Dive Sheet
    //
    // Presented as a bottom sheet so it never overflows the fixed-height
    // paging card. The sheet has its own ScrollView to handle arbitrarily
    // long content without touching the outer layout.

    private var deepDiveSheetContent: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let parsed = parsedDeepDive {
                        if parsed.body.isEmpty && !post.isComplete {
                            // Still loading — show animated skeleton
                            skeletonBody
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        } else {
                            Text(parseMarkdown(text: parsed.body))
                                .font(.body)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)

                            if let source = parsed.source {
                                PostSourceView(source: source)
                                    .padding(.horizontal, 20)
                                    .transition(.opacity)
                            }
                        }
                    }

                    // LIVE streaming indicator while content is arriving
                    if !post.isComplete {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(l10n.liveBadge)
                                .font(.caption2.monospaced()).bold()
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 48)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(l10n.deepDiveTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "fish.fill")
                        .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isDeepDiveExpanded = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(l10n.closeLabel)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private var cardTitle: String {
        let t = post.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        if !post.isComplete {
            return l10n.composingTitle
        }
        if let firstTag = post.tags.first(where: { !$0.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).isEmpty }) {
            return firstTag.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).capitalized
        }
        return l10n.untitledBite
    }

    private var parsedPost: ParsedPostContent {
        post.parsedContent
    }

    private var parsedDeepDive: ParsedPostContent? {
        post.deepDiveText.map { Post.splitBodyAndSource(from: $0, isStreaming: !post.isComplete) }
    }

    private var postBody: AttributedString {
        parseMarkdown(text: parsedPost.body)
    }
    
    private func parseMarkdown(text: String) -> AttributedString {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Normalize ** to * so all asterisk wrappers are parsed uniformly
        let normalizedText = cleanText.replacingOccurrences(of: "**", with: "*")
        
        var attrStr = (try? AttributedString(markdown: normalizedText, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(cleanText)
        
        for run in attrStr.runs {
            if let intent = run.inlinePresentationIntent {
                if intent.contains(.emphasized) || intent.contains(.stronglyEmphasized) {
                    var newIntent = intent
                    newIntent.remove(.emphasized)
                    newIntent.remove(.stronglyEmphasized)
                    attrStr[run.range].inlinePresentationIntent = newIntent.isEmpty ? nil : newIntent
                    attrStr[run.range].font = .body.weight(.semibold)
                }
            }
        }
        return attrStr
    }

    private var skeletonBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This is a placeholder for the first line to show a skeleton.")
            Text("Another line of skeleton goes right here.")
            Text("And a short one.")
        }
        .font(.body)
        .redacted(reason: .placeholder)
        .opacity(showCursor ? 0.3 : 0.7)
        .animation(.easeInOut(duration: 0.6), value: showCursor)
    }

    private var tagChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(post.tags, id: \.self) { rawTag in
                let cleanTag = rawTag.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).capitalized
                if !cleanTag.isEmpty {
                    Text(cleanTag)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(Color(uiColor: .secondarySystemBackground), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Share action

    private func toggleShare() async {
        guard let user = authService.currentUser else { return }
        isSharePending = true
        do {
            if isShared {
                try await FirestoreService.shared.unsharePost(text: post.text, authorId: user.uid)
                isShared = false
                toastMessage.wrappedValue = l10n.toastPostUnshared
            } else {
                try await FirestoreService.shared.sharePost(post, author: user)
                isShared = true
                if AccessManager.shared.canClaimShareBonus,
                   await AccessManager.shared.claimShareBonus() {
                    toastMessage.wrappedValue = l10n.toastShareBonusGranted
                } else {
                    toastMessage.wrappedValue = l10n.toastPostShared
                }
            }
        } catch {
            let context: SocialActionContext = isShared ? .unshare : .share
            let mapped = OmakaseError.from(error, context: context)
            ErrorReporter.record(error, mapped: mapped, area: "feed_toggle_share")
            toastMessage.wrappedValue = mapped.message(l10n: l10n)
        }
        isSharePending = false
    }

    // MARK: - Report AI Content (Guideline 1.2)

    private func submitAIReport(reason: String) async {
        guard let uid = authService.currentUser?.uid else { return }
        isReportPending = true
        defer { isReportPending = false }

        let snippet = String(post.text.replacingOccurrences(of: "\n", with: " ").prefix(220))
        do {
            try await FirestoreService.shared.reportAIPost(
                postId: post.id.uuidString,
                reporterUid: uid,
                reason: reason,
                postSnippet: snippet
            )
            isReported = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showReportConfirmation = true
        } catch {
            let mapped = OmakaseError.from(error, context: .report)
            ErrorReporter.record(error, mapped: mapped, area: "feed_report_ai_post")
            toastMessage.wrappedValue = mapped.message(l10n: l10n)
        }
    }
}

/// Simple flow layout that wraps chips onto new rows.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layoutRows(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layoutRows(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func layoutRows(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return LayoutResult(
            size: CGSize(width: totalWidth, height: currentY + rowHeight),
            positions: positions
        )
    }
}

#Preview {
    FeedView(authService: AuthService())
}

// MARK: - Toast Modifier (HIG Feedback: multi-channel icon + text + tap-to-dismiss)

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    @Environment(\.colorScheme) private var colorScheme

    private enum ToastKind {
        case error
        case success
        case info

        var iconName: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    private func classify(_ text: String) -> ToastKind {
        let lower = text.lowercased()
        let errorKeywords = [
            "hata", "başarısız", "olmadı", "bulunamadı", "kapalı", "beklenmeyen",
            "bağlan", "çevrimdışı", "silinemedi", "yüklenemedi", "gönderilemedi",
            "tekrar dene", "sorun", "error", "failed", "couldn't", "could not",
            "offline", "try again", "unavailable", "no active", "not found", "expired"
        ]
        if errorKeywords.contains(where: { lower.contains($0) }) {
            return .error
        }
        let successKeywords = [
            "kaydedildi", "paylaşıldı", "hoş geldin", "geri yüklendi", "açıldı",
            "ayarlandı", "alındı", "bookmarked", "shared", "welcome", "restored",
            "unlocked", "scheduled", "submitted"
        ]
        if successKeywords.contains(where: { lower.contains($0) }) {
            return .success
        }
        return .info
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    let kind = classify(message)
                    HStack(spacing: 10) {
                        Image(systemName: kind.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(kind == .error ? Color.red : OmakaseTheme.ink)
                            .frame(width: 28, height: 28)
                            .background(
                                (kind == .error ? Color.red.opacity(0.12) : OmakaseTheme.wash),
                                in: Circle()
                            )

                        Text(message)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 4)

                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                self.message = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 24)
                                .background(Color.primary.opacity(0.06), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                kind == .error
                                    ? Color.red.opacity(colorScheme == .dark ? 0.45 : 0.3)
                                    : OmakaseTheme.stroke,
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10), radius: 14, y: 6)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                    .task(id: message) {
                        if kind == .error {
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        }
                        try? await Task.sleep(for: .seconds(3.2))
                        guard !Task.isCancelled else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            self.message = nil
                        }
                    }
                }
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.84), value: message)
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
