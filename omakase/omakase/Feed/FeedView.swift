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
            Group {
                if viewModel.posts.isEmpty {
                    emptyState
                } else {
                    reelsFeed(bookmarkStore: bookmarkStore)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    // Custom nav header — avoids iOS's automatic circular button
                    // decoration that UINavigationBar applies to non-SF-Symbol images.
                    // Uses .bar material (same as InlineTasteBar) for visual unity.
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
                    .background(.bar)   // same material as InlineTasteBar → seamless unity

                    InlineTasteBar(
                        allInterests: allInterests,
                        activeInterests: $activeInterests,
                        onAddInterest: { addInterest($0) },
                        onRemoveInterest: { removeInterest($0) },
                        isLetterboxdActive: $isLetterboxdActive,
                        onLetterboxdToggle: { handleLetterboxdToggle($0) }
                    )
                    .environment(\.appLanguage, appLanguage)
                }

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
                        withAnimation {
                            viewModel.removePost(id: id)
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
                        viewModel.fetchLetterboxdFilms()
                    } else {
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
            let parsed = Self.parse(interests: storedInterests)
            activeInterests = Set(parsed)
            viewModel.setContentLanguage(appLanguage)
            viewModel.updateInterests(parsed)
            if viewModel.isOffline && viewModel.posts.isEmpty {
                await viewModel.loadCachedPosts()
            } else if viewModel.posts.isEmpty {
                viewModel.requestNextPost()
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
        GeometryReader { geo in
            ZStack(alignment: .top) {
                ScrollViewReader { proxy in
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
                                generateNextCard
                                Spacer()
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                            .id("generate-card")
                        }
                    }
                    .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                    .scrollTargetLayout()
                    .onChange(of: viewModel.posts.last?.id) { _, newID in
                        guard let newID else { return }
                        proxy.scrollTo(newID, anchor: .top)
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

    private var generateNextCard: some View {
        let isDisabled = viewModel.isGenerating || viewModel.isOffline

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

            Button {
                viewModel.requestNextPost()
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isGenerating {
                        ProgressView()
                            .controlSize(.small)
                            .tint(OmakaseTheme.chipActiveText)
                    }
                    Text(viewModel.isGenerating ? l10n.generating : l10n.serveNextPost)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: 280)
            }
            .buttonStyle(.borderedProminent)
            .tint(OmakaseTheme.chipActiveFill)
            .controlSize(.large)
            .disabled(isDisabled)
        }
        .padding(.horizontal, 32)
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

    private var isBookmarked: Bool {
        bookmarkStore.contains(postId: post.id)
    }

    var body: some View {
        // Use a single VStack instead of a nested ScrollView — the outer
        // paging ScrollView already provides vertical scrolling. Nesting two
        // vertical ScrollViews caused severe gesture contention and redundant
        // layout passes, which was the primary source of scroll stutter.
        VStack(alignment: .leading, spacing: 16) {
            // Header: title, timestamp, LIVE badge
            postHeader
                .padding(.top, 8)

            // Main post body text
            if post.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !post.isComplete {
                skeletonBody
                    .transition(.opacity)
            } else {
                Text(postBody)
                    .font(.body)
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

            // Tags
            if post.isComplete, !post.tags.isEmpty {
                tagChips
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            if post.isComplete, !post.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                actionBar
                    .transition(.opacity)
                    .padding(.top, 8)
            }
            
            Spacer(minLength: 20)
        }
        .padding(.horizontal, 20)
        .animation(.easeOut(duration: 0.6), value: post.isComplete)
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
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 32))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(cardTitle)
                    .font(.headline)
                    .lineLimit(2)
                Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            if !post.isComplete {
                Text(l10n.liveBadge)
                    .font(.caption2.monospaced()).bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.15), in: Capsule())
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
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
            }
        }
    }

    // MARK: - Action Bar (bottom, horizontal, like Reels)

    private var actionBar: some View {
        HStack(spacing: 28) {
            // Deep Dive button — opens sheet (re-read if already fetched)
            Button {
                if post.deepDiveText == nil {
                    viewModel.requestDeepDive(for: post)
                }
                isDeepDiveExpanded = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: post.deepDiveText != nil ? "fish.fill" : "fish")
                        .font(.title2)
                    Text(post.deepDiveText != nil
                         ? (l10n.lang == .turkish ? "Yeniden Oku" : "Re-read")
                         : l10n.actionDive)
                        .font(.caption2)
                        .lineLimit(1)
                        .fixedSize()
                }
                // Fixed width prevents icon from shifting when label text changes
                .frame(width: 52)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.deepDiveA11y)

            // Share to timeline button
            Button {
                Task { await toggleShare() }
            } label: {
                VStack(spacing: 4) {
                    if isSharePending {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: isShared ? "paperplane.fill" : "paperplane")
                            .font(.title2)
                    }
                    Text(isShared ? l10n.actionShared : l10n.actionShare)
                        .font(.caption2)
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
                ShareService.presentShareSheet(post: post)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
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
                        .font(.title2)
                    Text(isBookmarked ? l10n.actionSaved : l10n.actionSave)
                        .font(.caption2)
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(width: 52)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isBookmarked ? l10n.removeBookmarkA11y : l10n.bookmarkPostA11y)
        }
        .padding(.vertical, 12)
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
        return Self.fallbackTitle(from: post.text, isStreaming: !post.isComplete, l10n: l10n)
    }

    private static func fallbackTitle(from text: String, isStreaming: Bool, l10n: L10n) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return isStreaming ? l10n.composingTitle : l10n.untitledBite }
        let snippet = trimmed.prefix(52)
        if snippet.count < trimmed.count {
            return String(snippet).trimmingCharacters(in: .whitespaces) + "…"
        }
        return String(snippet)
    }

    private var postBody: AttributedString {
        let cleanText = String(post.text.drop(while: { $0.isWhitespace || $0.isNewline }))
        return AttributedString(cleanText)
    }

    private func attributedDeepDive(_ deepDive: String) -> AttributedString {
        let cleanText = String(deepDive.drop(while: { $0.isWhitespace || $0.isNewline }))
        return AttributedString(cleanText)
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
            ForEach(post.tags, id: \.self) { tag in
                Text(tag.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.08), in: Capsule())
                    .foregroundStyle(.primary)
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
