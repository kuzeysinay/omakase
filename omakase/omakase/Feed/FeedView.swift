//
//  FeedView.swift
//  omakase
//

import SwiftUI

struct FeedView: View {

    @Environment(\.appLanguage) private var appLanguage
    @AppStorage("omakase.interests") private var storedInterests: String = ""

    @State private var viewModel: FeedViewModel
    @State private var bookmarkStore = BookmarkStore()
    @State private var showBookmarks = false
    @State private var activeInterests: Set<String> = []
    @State private var pendingDeletePostID: UUID?
    @State private var showDeletePostConfirmation = false
    @State private var toastMessage: String?
    @State private var generateTriggerCardID: UUID?
    @State private var feedScrollPosition: AnyHashable?
    @State private var isBentoExpanded: Bool = true

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

    private func toggleBentoExpanded() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            isBentoExpanded.toggle()
        }
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
            ZStack(alignment: .bottom) {
                Group {
                    if viewModel.posts.isEmpty {
                        emptyState
                            .padding(.bottom, 80)
                    } else {
                        reelsFeed(bookmarkStore: bookmarkStore)
                            .padding(.bottom, 80)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                BentoTasteBox(
                    allInterests: allInterests,
                    activeInterests: $activeInterests,
                    onAddInterest: { addInterest($0) },
                    onRemoveInterest: { removeInterest($0) },
                    isLetterboxdActive: $isLetterboxdActive,
                    isExpanded: $isBentoExpanded,
                    onToggleExpand: {
                        toggleBentoExpanded()
                    },
                    isGenerating: viewModel.isGenerating,
                    isCooldownActive: viewModel.isCooldownActive,
                    cooldownRemaining: viewModel.readingCooldownRemaining,
                    cooldownTotal: viewModel.readingCooldownTotal,
                    onSelectDedicatedTopic: { topic in
                        viewModel.requestDedicatedPost(topic: topic)
                    },
                    onPromptLetterboxdUsername: {
                        letterboxdDraft = storedLetterboxdUsername
                        showLetterboxdUsernamePrompt = true
                    },
                    onSelectLetterboxdPost: {
                        let clean = storedLetterboxdUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                        viewModel.requestLetterboxdDedicatedPost(username: clean)
                    }
                )
                .environment(\.appLanguage, appLanguage)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
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
                        .padding(.leading, 16)

                        Spacer()

                        // Trailing buttons: 44×44 frame matches iOS standard tap target
                        Button {
                            showBookmarks = true
                        } label: {
                            Image(systemName: "bookmark")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.primary.opacity(0.85))
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(l10n.savedPostsA11y(count: bookmarkStore.count))

                        Spacer().frame(width: 8)
                    }
                    .frame(height: 44) // standard iOS nav bar height
                    .background(Color(uiColor: .systemBackground))

                    Divider().opacity(0.12)
                }
                .background(Color(uiColor: .systemBackground))
            }
            .alert(
                l10n.errorSomethingWrong,
                isPresented: .init(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.dismissError() } }
                )
            ) {
                Button(l10n.ok, role: .cancel) { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
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
                                fallbackID = nil
                            }
                        } else {
                            fallbackID = nil
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
            .sheet(isPresented: $showBookmarks) {
                BookmarksSheet(bookmarkStore: bookmarkStore, authService: authService)
                    .environment(\.appLanguage, appLanguage)
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
            if viewModel.posts.isEmpty {
                await viewModel.loadCachedPosts()
                if viewModel.posts.isEmpty {
                    viewModel.requestNextPost()
                } else if let lastID = viewModel.posts.last?.id {
                    feedScrollPosition = lastID
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

    private func handleLetterboxdToggle(_ isActive: Bool) {
        if isActive {
            let username = storedLetterboxdUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            if username.isEmpty {
                // No username yet — prompt the user.
                showLetterboxdUsernamePrompt = true
            } else {
                // Username exists; ensure ViewModel knows & fetch if needed.
                viewModel.letterboxdUsername = username
                viewModel.isLetterboxdActive = true
                if viewModel.letterboxdFilms.isEmpty {
                    viewModel.fetchLetterboxdFilms()
                }
            }
        } else {
            viewModel.isLetterboxdActive = false
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(OmakaseTheme.ink)
            Text(l10n.emptyFeedHeadline)
                .font(.title3.bold())
            Text(l10n.emptyFeedDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            generateButton
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Instagram Reels-style vertical paging feed. Each post occupies the full screen height.
    private func reelsFeed(bookmarkStore: BookmarkStore) -> some View {
        ScrollViewReader { proxy in
            GeometryReader { geo in
            ZStack(alignment: .top) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.posts) { post in
                            ReelsPostCard(
                                post: post,
                                bookmarkStore: bookmarkStore,
                                authService: authService,
                                viewModel: viewModel,
                                toastMessage: $toastMessage,
                                onDelete: {
                                    pendingDeletePostID = post.id
                                    showDeletePostConfirmation = true
                                }
                            )
                            .environment(\.appLanguage, appLanguage)
                            .id(post.id)
                            .frame(width: geo.size.width, height: geo.size.height)
                        }

                        // Generate next post card at the end
                        VStack {
                            Spacer()
                            generateNextCard(triggerCardID: viewModel.posts.last?.id, containerHeight: geo.size.height)
                            Spacer()
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .id("generate-card")
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $feedScrollPosition, anchor: .top)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    if let lastID = viewModel.posts.last?.id {
                        feedScrollPosition = lastID
                        DispatchQueue.main.async {
                            proxy.scrollTo(lastID, anchor: .top)
                        }
                    }
                }
                .task(id: feedScrollPosition) {
                    guard let str = feedScrollPosition as? String, str == "generate-card" else { return }
                    do {
                        // Debounce to ignore momentary scroll jumps during layout animations (e.g. TasteBar expanding)
                        try await Task.sleep(for: .milliseconds(250))
                        guard !Task.isCancelled else { return }
                        
                        if let lastID = viewModel.posts.last?.id {
                            triggerGenerateNextPostIfNeeded(for: lastID)
                        }
                    } catch { }
                }
                .onChange(of: viewModel.posts.last?.id) { _, newID in
                    guard let newID else { return }
                    generateTriggerCardID = nil
                    proxy.scrollTo(newID, anchor: .top)
                }
                .onChange(of: viewModel.isGenerating) { _, generating in
                    if !generating, let pos = feedScrollPosition as? String, pos == "generate-card", let id = viewModel.posts.last?.id {
                        triggerGenerateNextPostIfNeeded(for: id)
                    }
                }

                // Offline banner floats above the scroll, doesn't affect paging
                if viewModel.isOffline && viewModel.isShowingCachedContent {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                            .font(.subheadline.weight(.semibold))
                        Text(l10n.offlineBanner)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(OmakaseTheme.ink)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            }
        }
    }
    }

    private func generateNextCard(triggerCardID: UUID?, containerHeight: CGFloat) -> some View {
        return VStack(spacing: 20) {
            Image(systemName: viewModel.isGenerating ? "wand.and.stars" : "sparkles")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(OmakaseTheme.ink)
                .symbolEffect(.pulse, isActive: viewModel.isGenerating)

            Text(viewModel.isGenerating ? l10n.generating : l10n.serveNextPost)
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            if viewModel.isOffline && !viewModel.isGenerating {
                Label(l10n.internetRequired, systemImage: "wifi.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 32)
        .contentShape(Rectangle())
        .onTapGesture {
            if let triggerCardID {
                triggerGenerateNextPostIfNeeded(for: triggerCardID)
            }
        }
    }

    private var generateButton: some View {
        let isDisabled = viewModel.isGenerating || viewModel.isOffline
        return Button {
            viewModel.requestNextPost()
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    if viewModel.isGenerating {
                        ProgressView()
                            .controlSize(.small)
                            .tint(OmakaseTheme.chipActiveText)
                    }
                    if viewModel.isOffline && !viewModel.isGenerating {
                        Text(l10n.internetRequired)
                            .fontWeight(.semibold)
                    } else {
                        Text(viewModel.isGenerating ? l10n.generating : l10n.serveNextPost)
                            .fontWeight(.semibold)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 0)
        }
        .buttonStyle(.borderedProminent)
        .tint(OmakaseTheme.chipActiveFill)
        .controlSize(.large)
        .disabled(isDisabled)
    }

    private func triggerGenerateNextPostIfNeeded(for cardID: UUID) {
        guard generateTriggerCardID != cardID else { return }
        guard !viewModel.isGenerating, !viewModel.isOffline else { return }
        generateTriggerCardID = cardID
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.requestNextPost()
    }

    // MARK: - Helpers

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
    @Bindable var bookmarkStore: BookmarkStore
    let authService: AuthService
    var viewModel: FeedViewModel
    var toastMessage: Binding<String?>
    var onDelete: () -> Void

    @Environment(\.appLanguage) private var appLanguage

    private var l10n: L10n { L10n(lang: appLanguage) }

    @State private var showCursor: Bool = true
    @State private var isShared: Bool = false
    @State private var isSharePending: Bool = false
    @State private var isDeepDiveExpanded: Bool = false
    @State private var swipeOffset: CGFloat = 0

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
            if post.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !post.isComplete {
                skeletonBody
                    .transition(.opacity)
            } else {
                Text(postBody)
                    .font(.system(size: 16.5, weight: .regular))
                    .lineSpacing(5)
                    .foregroundStyle(Color.primary.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                    // Removed per-token .contentTransition/.animation — they
                    // fired on every SSE token causing continuous animation
                    // overhead and layout thrashing during streaming.
                    .transition(.opacity)
            }

            // Deep dive indicator (content shown in sheet, not inline)
            if post.deepDiveText != nil, !post.isComplete {
                HStack(spacing: 6) {
                    Image(systemName: "fish.fill")
                        .foregroundStyle(.primary)
                    Text(l10n.lang == .turkish ? "Derinlemesine inceleme yazılıyor…" : "Writing deep dive…")
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
            // (transitions from nil → "" as streaming starts).
            if oldValue == nil, newValue != nil {
                isDeepDiveExpanded = true
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

                // Delete button
                if post.isComplete {
                    Menu {
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
                }
                isDeepDiveExpanded = true
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: post.deepDiveText != nil ? "fish.fill" : "fish")
                        .font(.title3)
                        .foregroundStyle(post.deepDiveText != nil ? OmakaseTheme.ink : .primary)
                    Text(post.deepDiveText != nil
                         ? (l10n.lang == .turkish ? "Yeniden Oku" : "Re-read")
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
                            .foregroundStyle(isShared ? Color.blue : .primary)
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
                ShareService.presentShareSheet(post: post, language: appLanguage)
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
                .foregroundStyle(.secondary)
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
                    if let deepDive = post.deepDiveText {
                        if deepDive.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && !post.isComplete {
                            // Still loading — show animated skeleton
                            skeletonBody
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        } else {
                            Text(attributedDeepDive(deepDive))
                                .font(.body)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
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
            .navigationTitle(l10n.lang == .turkish ? "Derinlemesine İnceleme" : "Deep Dive")
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
                    .accessibilityLabel(l10n.lang == .turkish ? "Kapat" : "Close")
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

    private var postBody: AttributedString {
        parseMarkdown(text: post.cleanDisplayBody)
    }

    private func attributedDeepDive(_ deepDive: String) -> AttributedString {
        parseMarkdown(text: deepDive)
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
                toastMessage.wrappedValue = l10n.toastPostShared
            }
        } catch {
            print("Error toggling share: \(error)")
            toastMessage.wrappedValue = "Error: \(error.localizedDescription)"
        }
        isSharePending = false
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

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8), in: Capsule())
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                        .task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            withAnimation(.easeInOut) {
                                self.message = nil
                            }
                        }
                }
            }
            .animation(.spring(), value: message)
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
