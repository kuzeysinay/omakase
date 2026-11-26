//
//  GuestTasteView.swift
//  omakase
//
//  Try-Before-Signup authentic feed experience: picks 2 random stories from
//  GuestStaticCatalog and streams them token-by-token inside the exact same
//  Reels-style FeedView UI (LIVE badge, skeleton shimmer, clickable PostSourceView,
//  live-streaming Deep Dive, reading cooldown bar, and Nigiri quota pill)
//  before requiring sign-up.
//

import Observation
import SwiftUI

@Observable
@MainActor
final class GuestFeedViewModel {

    private(set) var posts: [Post] = []
    private(set) var isGenerating: Bool = false
    private(set) var platesUsed: Int = 0
    let platesLimit: Int = 2

    var readingCooldownRemaining: Int = 0
    var readingCooldownTotal: Int = 0
    private(set) var readingCooldownStartDate: Date?
    private(set) var readingCooldownEndDate: Date?
    var isCooldownActive: Bool { readingCooldownRemaining > 0 }

    @ObservationIgnored
    private var selectedTemplates: [GuestStaticPost] = []
    @ObservationIgnored
    private var templateByPostID: [UUID: GuestStaticPost] = [:]
    @ObservationIgnored
    private var streamingTask: Task<Void, Never>?
    @ObservationIgnored
    private var cooldownTimerTask: Task<Void, Never>?
    @ObservationIgnored
    private var activeLanguage: AppLanguage = .english

    var platesRemaining: Int {
        max(0, platesLimit - platesUsed)
    }

    var hasServedAllPlates: Bool {
        platesUsed >= platesLimit
    }

    func prepareIfNeeded(language: AppLanguage) {
        if selectedTemplates.isEmpty {
            activeLanguage = language
            selectedTemplates = GuestStaticPost.pickRandomTwo(for: language)
        }
    }

    func serveNextPost(language: AppLanguage) {
        prepareIfNeeded(language: language)
        guard !isGenerating, platesUsed < platesLimit else { return }

        let template = selectedTemplates[platesUsed]
        platesUsed += 1

        streamingTask?.cancel()
        let post = Post(
            title: "",
            text: "",
            isComplete: false,
            tags: [],
            categoryId: template.categoryId,
            createdAt: .now
        )
        templateByPostID[post.id] = template
        posts.append(post)
        isGenerating = true

        let postID = post.id
        let chunks = Self.tokenizeForStreaming(template.bodyWithSource)

        streamingTask = Task { @MainActor [weak self] in
            // Snappy local TTFT pause showing skeleton shimmer + pulsing LIVE badge
            try? await Task.sleep(for: .milliseconds(150))
            guard let self, !Task.isCancelled else { return }
            guard let target = self.posts.first(where: { $0.id == postID }) else { return }

            target.title = template.title
            target.tags = template.tags

            for chunk in chunks {
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.14)) {
                    target.text += chunk
                }
                let delayMs = Int.random(in: 16...28)
                try? await Task.sleep(for: .milliseconds(delayMs))
            }

            guard !Task.isCancelled else { return }
            target.isComplete = true
            self.isGenerating = false
        }
    }

    /// Immediately finalizes any still-streaming post (if the user swiped down early)
    /// and serves the next static post without waiting on a button or cooldown timer.
    func finishCurrentPostAndServeNext(language: AppLanguage) {
        guard platesUsed < platesLimit else { return }
        if isGenerating {
            streamingTask?.cancel()
            streamingTask = nil
            if let current = posts.last, !current.isComplete, let template = templateByPostID[current.id] {
                current.title = template.title
                current.tags = template.tags
                current.text = template.bodyWithSource
                current.isComplete = true
            }
            isGenerating = false
        }
        serveNextPost(language: language)
    }

    func requestDeepDive(for post: Post) {
        guard !isGenerating else { return }
        guard let template = templateByPostID[post.id] else { return }

        streamingTask?.cancel()
        isGenerating = true
        post.isComplete = false
        if post.deepDiveText == nil {
            post.deepDiveText = ""
        }

        let postID = post.id
        let chunks = Self.tokenizeForStreaming(template.deepDiveWithSource)

        streamingTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard let self, !Task.isCancelled else { return }
            guard let target = self.posts.first(where: { $0.id == postID }) else { return }

            for chunk in chunks {
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.14)) {
                    target.deepDiveText = (target.deepDiveText ?? "") + chunk
                }
                let delayMs = Int.random(in: 14...24)
                try? await Task.sleep(for: .milliseconds(delayMs))
            }

            guard !Task.isCancelled else { return }
            target.isComplete = true
            self.isGenerating = false
        }
    }

    func stopTasks() {
        streamingTask?.cancel()
        streamingTask = nil
        cooldownTimerTask?.cancel()
        cooldownTimerTask = nil
    }

    private func startReadingCooldown(for text: String) {
        cooldownTimerTask?.cancel()
        let words = text.split { $0.isWhitespace }.count
        let seconds = max(15, min(25, words / 3))
        let now = Date()
        let endDate = now.addingTimeInterval(TimeInterval(seconds))
        readingCooldownTotal = seconds
        readingCooldownRemaining = seconds
        readingCooldownStartDate = now
        readingCooldownEndDate = endDate

        cooldownTimerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self, !Task.isCancelled else { break }
                let remaining = endDate.timeIntervalSinceNow
                if remaining <= 0 {
                    self.readingCooldownRemaining = 0
                    self.readingCooldownStartDate = nil
                    self.readingCooldownEndDate = nil
                    break
                } else {
                    let nextSeconds = max(1, Int(ceil(remaining)))
                    if self.readingCooldownRemaining != nextSeconds {
                        self.readingCooldownRemaining = nextSeconds
                    }
                }
            }
        }
    }

    /// Splits text into realistic LLM-sized token chunks for smooth SSE-like streaming
    /// across both space-separated languages and CJK scripts (`ja`, `ko`).
    private static func tokenizeForStreaming(_ text: String) -> [String] {
        var chunks: [String] = []
        var buffer = ""

        for ch in text {
            buffer.append(ch)
            let isCJK = ch.unicodeScalars.contains { scalar in
                (0x3040...0x30FF).contains(scalar.value)
                    || (0x4E00...0x9FFF).contains(scalar.value)
                    || (0xAC00...0xD7AF).contains(scalar.value)
            }
            if ch == "\n" || ch == " " || (isCJK && buffer.count >= 3) || buffer.count >= 9 {
                chunks.append(buffer)
                buffer = ""
            }
        }
        if !buffer.isEmpty {
            chunks.append(buffer)
        }
        return chunks
    }
}

struct GuestTasteView: View {

    let authService: AuthService
    let onContinueToAuth: () -> Void

    @Environment(\.appLanguage) private var appLanguage

    @State private var viewModel = GuestFeedViewModel()
    @State private var bookmarkStore = BookmarkStore.shared
    @State private var feedScrollPosition: String?
    @State private var toastMessage: String?
    @State private var selectedTab: AppTab = .feed
    @State private var showAuthSheet: Bool = false
    @State private var nextPostTriggerTask: Task<Void, Never>?

    private var l10n: L10n { L10n(lang: appLanguage) }

    init(authService: AuthService, onContinueToAuth: @escaping () -> Void) {
        self.authService = authService
        self.onContinueToAuth = onContinueToAuth
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.12)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == .feed {
                    selectedTab = .feed
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTab = .feed
                    showAuthSheet = true
                }
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            NavigationStack {
                reelsFeed
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .systemBackground))
                    .toolbar(.hidden, for: .navigationBar)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        topHeaderBar
                    }
                    .toast(message: $toastMessage)
            }
            .tag(AppTab.feed)
            .tabItem {
                Label(l10n.tabMyFeed, systemImage: "fork.knife")
                    .accessibilityIdentifier("tab.feed")
            }

            Color(uiColor: .systemBackground)
                .tag(AppTab.community)
                .tabItem {
                    Label(l10n.tabTimeline, systemImage: "person.2.fill")
                        .accessibilityIdentifier("tab.community")
                }

            Color(uiColor: .systemBackground)
                .tag(AppTab.profile)
                .tabItem {
                    Label(l10n.tabProfile, systemImage: "person.crop.circle")
                        .accessibilityIdentifier("tab.profile")
                }
        }
        .tint(OmakaseTheme.ink)
        .sheet(isPresented: $showAuthSheet) {
            AuthView(
                authService: authService,
                onClose: { showAuthSheet = false }
            )
            .environment(\.appLanguage, appLanguage)
        }
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth {
                showAuthSheet = false
            }
        }
        .task {
            viewModel.prepareIfNeeded(language: appLanguage)
            if viewModel.posts.isEmpty {
                viewModel.serveNextPost(language: appLanguage)
                if let firstID = viewModel.posts.first?.id.uuidString {
                    feedScrollPosition = firstID
                }
            }
        }
        .onDisappear {
            nextPostTriggerTask?.cancel()
            nextPostTriggerTask = nil
            viewModel.stopTasks()
        }
    }

    // MARK: - Top Header Bar (Matches FeedView 1:1)

    private var topHeaderBar: some View {
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
                    .accessibilityIdentifier("feed.header.title")
            }
            .padding(.leading, 18)

            Spacer()

            HStack(spacing: 8) {
                guestQuotaPill

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showAuthSheet = true
                } label: {
                    Text(l10n.guestTasteSignIn)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.06), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("guestTaste.signInButton")
            }
            .padding(.trailing, 16)
        }
        .frame(height: 44)
        .background(Color(uiColor: .systemBackground))
    }

    @ViewBuilder
    private var guestQuotaPill: some View {
        let limit = viewModel.platesLimit
        let remaining = viewModel.platesRemaining
        let isCritical = remaining <= 1
        let accentColor: Color = remaining == 0 ? .red : (remaining == 1 ? .orange : .primary)
        let fillColor: Color = remaining == 0
            ? Color.red.opacity(0.14)
            : (remaining == 1 ? Color.orange.opacity(0.14) : Color.primary.opacity(0.07))
        let strokeColor: Color = remaining == 0
            ? Color.red.opacity(0.45)
            : (remaining == 1 ? Color.orange.opacity(0.45) : Color.primary.opacity(0.14))

        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showAuthSheet = true
        } label: {
            HStack(spacing: 6) {
                HStack(spacing: 3.5) {
                    ForEach(0..<limit, id: \.self) { index in
                        NigiriSushiIcon(
                            isFilled: index < remaining,
                            fillColor: accentColor
                        )
                        .frame(width: 13, height: 9.5)
                    }
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

    // MARK: - Reels Feed (Matches FeedView 1:1)

    private var reelsFeed: some View {
        ScrollViewReader { proxy in
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 100) {
                        ForEach(viewModel.posts) { post in
                            GuestReelsPostCard(
                                post: post,
                                isLastPost: post.id == viewModel.posts.last?.id,
                                bookmarkStore: bookmarkStore,
                                viewModel: viewModel,
                                toastMessage: $toastMessage,
                                onScrollToBottom: {
                                    withAnimation(.spring(response: 0.36, dampingFraction: 0.85)) {
                                        feedScrollPosition = "guest-bottom-page"
                                        proxy.scrollTo("guest-bottom-page", anchor: .top)
                                    }
                                }
                            )
                            .environment(\.appLanguage, appLanguage)
                            .id(post.id.uuidString)
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                            .clipped()
                        }

                        bottomPage(proxy: proxy)
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                            .clipped()
                            .id("guest-bottom-page")
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.vertical, 0, for: .scrollContent)
                .scrollPosition(id: $feedScrollPosition, anchor: .top)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .onChange(of: viewModel.posts.last?.id) { _, newID in
                    guard let newID = newID?.uuidString else { return }
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.85)) {
                            feedScrollPosition = newID
                            proxy.scrollTo(newID, anchor: .top)
                        }
                    }
                }
                .onChange(of: feedScrollPosition) { oldPos, newPos in
                    nextPostTriggerTask?.cancel()
                    nextPostTriggerTask = nil

                    if let oldPos, let newPos, oldPos != newPos {
                        HapticManager.soft()
                    }

                    guard newPos == "guest-bottom-page",
                          !viewModel.hasServedAllPlates else { return }

                    nextPostTriggerTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        guard !Task.isCancelled,
                              feedScrollPosition == "guest-bottom-page",
                              !viewModel.hasServedAllPlates else { return }
                        HapticManager.light()
                        viewModel.finishCurrentPostAndServeNext(language: appLanguage)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bottomPage(proxy: ScrollViewProxy) -> some View {
        if viewModel.hasServedAllPlates {
            guestSignupGatePage(proxy: proxy)
        } else {
            ZStack {
                Color(uiColor: .systemBackground)
                ProgressView()
                    .tint(OmakaseTheme.ink)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func guestSignupGatePage(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 24) {
            if let lastID = viewModel.posts.last?.id.uuidString {
                Button {
                    HapticManager.light()
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.85)) {
                        feedScrollPosition = lastID
                        proxy.scrollTo(lastID, anchor: .top)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.up")
                            .font(.caption.weight(.bold))
                        Text(l10n.guestLimitBackToPosts)
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemBackground), in: Capsule())
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }

            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(width: 72, height: 72)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(OmakaseTheme.ink)
                }

                Text(l10n.guestLimitTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(l10n.guestLimitSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onContinueToAuth()
            } label: {
                HStack(spacing: 8) {
                    Text(l10n.guestLimitSignUpCTA)
                        .font(.body.weight(.bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(OmakaseTheme.chipActiveFill)
                )
                .foregroundStyle(OmakaseTheme.chipActiveText)
            }
            .buttonStyle(OmakaseChipButtonStyle())
            .accessibilityIdentifier("guestTaste.primaryButton")

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Guest Reels Post Card (Matches ReelsPostCard 1:1)

private struct GuestReelsPostCard: View {
    let post: Post
    let isLastPost: Bool
    @Bindable var bookmarkStore: BookmarkStore
    var viewModel: GuestFeedViewModel
    var toastMessage: Binding<String?>
    var onScrollToBottom: () -> Void

    @Environment(\.appLanguage) private var appLanguage

    @State private var showCursor: Bool = true
    @State private var isDeepDiveExpanded: Bool = false
    @State private var showExportSheet: Bool = false

    private var l10n: L10n { L10n(lang: appLanguage) }

    private var isBookmarked: Bool {
        bookmarkStore.contains(postId: post.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            postHeader
                .padding(.top, 20)

            if parsedPost.body.isEmpty && !post.isComplete {
                skeletonBody
                    .transition(.opacity)
            } else {
                Text(postBody)
                    .font(.system(size: 16.5, weight: .regular))
                    .lineSpacing(5)
                    .foregroundStyle(Color.primary.opacity(0.92))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .transition(.opacity)
                    .accessibilityIdentifier("feed.post.body")
            }

            if let source = parsedPost.source {
                PostSourceView(source: source)
                    .padding(.top, 2)
                    .transition(.opacity)
            }

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

            VStack(alignment: .leading, spacing: 10) {
                if !post.tags.isEmpty {
                    tagChips
                }
                if !post.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    actionBar
                        .padding(.top, 2)
                }
            }
            .opacity(post.isComplete ? 1 : 0)
            .allowsHitTesting(post.isComplete)
            .accessibilityHidden(!post.isComplete)
            .animation(.easeOut(duration: 0.3), value: post.isComplete)

            Spacer(minLength: 16)

            if isLastPost {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onScrollToBottom()
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
                .opacity(post.isComplete ? 1 : 0)
                .allowsHitTesting(post.isComplete)
                .accessibilityHidden(!post.isComplete)
                .animation(.easeOut(duration: 0.3), value: post.isComplete)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
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
        .onChange(of: post.deepDiveText) { oldValue, newValue in
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
        .sheet(isPresented: $showExportSheet) {
            ExportPostSheet(post: post)
                .environment(\.appLanguage, appLanguage)
        }
    }

    private var postHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(cardTitle)
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("feed.post.title")

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

            ZStack(alignment: .trailing) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                        .opacity(showCursor ? 1.0 : 0.35)
                        .animation(
                            post.isComplete ? nil : .easeInOut(duration: 0.55).repeatForever(autoreverses: true),
                            value: showCursor
                        )
                    Text(l10n.liveBadge)
                        .font(.caption2.weight(.bold).monospaced())
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.12), in: Capsule())
                .foregroundStyle(.red)
                .opacity(post.isComplete ? 0 : 1)
                .allowsHitTesting(!post.isComplete)
                .accessibilityHidden(post.isComplete)
            }
            .frame(width: 68, height: 32, alignment: .trailing)
            .animation(.easeOut(duration: 0.25), value: post.isComplete)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 24) {
            Button {
                HapticManager.light()
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
                    Text(post.deepDiveText != nil ? l10n.actionReRead : l10n.actionDive)
                        .font(.caption2.weight(post.deepDiveText != nil ? .semibold : .regular))
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(width: 52)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                toastMessage.wrappedValue = l10n.guestShareSignInToast
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "paperplane")
                        .font(.title3)
                    Text(l10n.actionShare)
                        .font(.caption2)
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(width: 52)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showExportSheet = true
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

            Spacer()

            Button {
                bookmarkStore.toggle(post)
                if bookmarkStore.contains(postId: post.id) {
                    HapticManager.medium()
                    toastMessage.wrappedValue = l10n.toastBookmarked
                } else {
                    HapticManager.light()
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
        }
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    private var deepDiveSheetContent: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let parsed = parsedDeepDive {
                        if parsed.body.isEmpty && !post.isComplete {
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
                                .accessibilityIdentifier("deepdive.sheet.body")

                            if let source = parsed.source {
                                PostSourceView(source: source)
                                    .padding(.horizontal, 20)
                                    .transition(.opacity)
                            }
                        }
                    }

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

    private var cardTitle: String {
        let t = post.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        if !post.isComplete {
            return l10n.composingTitle
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
        let normalizedText = cleanText.replacingOccurrences(of: "**", with: "*")
        var attrStr = (try? AttributedString(
            markdown: normalizedText,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(cleanText)

        for run in attrStr.runs {
            if let intent = run.inlinePresentationIntent {
                if intent.contains(.emphasized) || intent.contains(.stronglyEmphasized) {
                    var newIntent = intent
                    newIntent.remove(.emphasized)
                    newIntent.remove(.stronglyEmphasized)
                    attrStr[run.range].inlinePresentationIntent = newIntent.isEmpty ? nil : newIntent
                    attrStr[run.range].font = .system(size: 16.5, weight: .semibold)
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
        FlowLayoutShared(spacing: 6) {
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
}
