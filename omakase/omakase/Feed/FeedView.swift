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
            .navigationTitle(l10n.appTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showBookmarks = true
                    } label: {
                        Image(systemName: "bookmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.primary.opacity(0.85))
                    }
                    .accessibilityLabel(l10n.savedPostsA11y(count: bookmarkStore.count))
                    Menu {
                        LanguagePicker(isSubmenu: true)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.primary.opacity(0.85))
                    }
                    .accessibilityLabel(l10n.feedMoreActionsA11y)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
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
                .foregroundStyle(.tint)
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
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // Offline banner (sits above the first post)
                        if viewModel.isOffline && viewModel.isShowingCachedContent {
                            HStack(spacing: 8) {
                                Image(systemName: "wifi.slash")
                                    .font(.subheadline.weight(.semibold))
                                Text(l10n.offlineBanner)
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.orange)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }

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
                                },
                                cookingCaption: viewModel.isGenerating && !post.isComplete
                                    ? viewModel.cookingCaption(l10n: l10n)
                                    : nil
                            )
                            .environment(\.appLanguage, appLanguage)
                            .id(post.id)
                            .frame(height: geo.size.height)
                        }

                        // Generate next post card at the end
                        VStack {
                            Spacer()
                            generateNextCard
                            Spacer()
                        }
                        .frame(height: geo.size.height)
                        .id("generate-card")
                    }
                }
                .scrollTargetBehavior(.paging)
                .onChange(of: viewModel.posts.first?.id) { _, newID in
                    guard let newID else { return }
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(newID, anchor: .top)
                    }
                }
            }
        }
    }

    /// The "generate next" card shown as the last page in the Reels feed.
    private var generateNextCard: some View {
        let isDisabled = viewModel.isGenerating || viewModel.isOffline
        let quip = viewModel.isGenerating ? viewModel.cookingCaption(l10n: l10n) : nil

        return VStack(spacing: 20) {
            Image(systemName: viewModel.isGenerating ? "wand.and.stars" : "sparkles")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, isActive: viewModel.isGenerating)

            Text(viewModel.isGenerating ? l10n.generating : l10n.serveNextPost)
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            if let quip {
                Text(quip)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            if viewModel.isOffline && !viewModel.isGenerating {
                Label(l10n.internetRequired, systemImage: "wifi.slash")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            Button {
                viewModel.requestNextPost()
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isGenerating {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text(viewModel.isGenerating ? l10n.generating : l10n.serveNextPost)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: 280)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isDisabled)
        }
        .animation(.easeInOut(duration: 0.35), value: quip)
        .padding(.horizontal, 32)
    }

    private var generateButton: some View {
        let quip =
            viewModel.isGenerating ? viewModel.cookingCaption(l10n: l10n) : nil
        let isDisabled = viewModel.isGenerating || viewModel.isOffline
        return Button {
            viewModel.requestNextPost()
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    if viewModel.isGenerating {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    if viewModel.isOffline && !viewModel.isGenerating {
                        Text(l10n.internetRequired)
                            .fontWeight(.semibold)
                    } else {
                        Text(viewModel.isGenerating ? l10n.generating : l10n.serveNextPost)
                            .fontWeight(.semibold)
                    }
                }
                if let quip {
                    Text(quip)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .foregroundStyle(Color.white.opacity(0.92))
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: quip)
            .frame(maxWidth: .infinity)
            .padding(.vertical, viewModel.isGenerating && quip != nil ? 10 : 0)
        }
        .buttonStyle(.borderedProminent)
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
    /// Kitchen-style line while Gemini streams (`nil` once the card is idle or finished).
    var cookingCaption: String?

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
        ZStack(alignment: .bottom) {
            // Full-screen scrollable content area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header: title, timestamp, LIVE badge
                    postHeader
                        .padding(.top, 8)

                    // Cooking caption while streaming
                    if let cookingCaption, !cookingCaption.isEmpty {
                        Text(cookingCaption)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.35), value: cookingCaption)
                    }

                    // Main post body text
                    Text(postBody)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    // Deep dive section
                    if let deepDive = post.deepDiveText, !deepDive.isEmpty {
                        deepDiveSection(deepDive)
                    }

                    // Tags
                    if post.isComplete, !post.tags.isEmpty {
                        tagChips
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .animation(.easeOut(duration: 0.3), value: post.tags)
                    }

                    // Bottom spacer to ensure content doesn't hide behind action bar
                    Spacer()
                        .frame(height: 80)
                }
                .padding(.horizontal, 20)
            }
            .scrollDisabled(!post.isComplete && post.text.count < 200)

            // Bottom action bar overlay
            if post.isComplete, !post.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                actionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .task {
            // Check if this post was already shared.
            guard post.isComplete, let user = authService.currentUser else { return }
            isShared = (try? await FirestoreService.shared.hasSharedPost(
                text: post.text, authorId: user.uid
            )) ?? false
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
            // Deep Dive button
            Button {
                viewModel.requestDeepDive(for: post)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "fish")
                        .font(.title2)
                    Text("Dive")
                        .font(.caption2)
                }
                .foregroundStyle(Color.secondary)
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
                    Text(isShared ? "Shared" : "Share")
                        .font(.caption2)
                }
                .foregroundStyle(isShared ? Color.accentColor : .secondary)
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
                    Text("Export")
                        .font(.caption2)
                }
                .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.shareSheetA11y)

            Spacer()

            // Bookmark button
            Button {
                bookmarkStore.toggle(post)
                if bookmarkStore.contains(postId: post.id) {
                    toastMessage.wrappedValue = "Post bookmarked"
                } else {
                    toastMessage.wrappedValue = "Bookmark removed"
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title2)
                    Text(isBookmarked ? "Saved" : "Save")
                        .font(.caption2)
                }
                .foregroundStyle(isBookmarked ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isBookmarked ? l10n.removeBookmarkA11y : l10n.bookmarkPostA11y)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 0)
        )
    }

    // MARK: - Deep Dive Section

    @ViewBuilder
    private func deepDiveSection(_ deepDive: String) -> some View {
        let expanded = isDeepDiveExpanded || !post.isComplete

        VStack(spacing: 0) {
            if expanded {
                Divider().padding(.vertical, 8)

                HStack(spacing: 8) {
                    Image(systemName: "fish.fill")
                        .foregroundStyle(.blue)
                    Text("Derinlemesine İnceleme")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Spacer()
                    Button {
                        isDeepDiveExpanded = false
                    } label: {
                        Image(systemName: "chevron.up")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 8)

                Text(deepDive + (!post.isComplete ? (showCursor ? "▌" : " ") : ""))
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            } else {
                Button {
                    isDeepDiveExpanded = true
                } label: {
                    HStack {
                        Image(systemName: "fish")
                        Text("Derinlemesine İncelemeyi Oku")
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline.bold())
                    .padding()
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.spring(), value: expanded)
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
        var attributed = AttributedString(post.text.isEmpty && !post.isComplete ? "…" : post.text)
        if !post.isComplete && post.deepDiveText == nil {
            var cursor = AttributedString(showCursor ? "▌" : " ")
            cursor.foregroundColor = .accentColor
            attributed.append(cursor)
        }
        return attributed
    }

    private var tagChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(post.tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                    .foregroundStyle(Color.accentColor)
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
                toastMessage.wrappedValue = "Post unshared"
            } else {
                try await FirestoreService.shared.sharePost(post, author: user)
                isShared = true
                toastMessage.wrappedValue = "Post shared to Social Feed"
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
