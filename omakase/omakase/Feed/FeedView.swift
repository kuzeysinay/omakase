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
    @State private var showAdjustTastes = false
    @State private var pendingDeletePostID: UUID?
    @State private var showDeletePostConfirmation = false
    @State private var toastMessage: String?

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
                    feedList(bookmarkStore: bookmarkStore)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(l10n.appTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showAdjustTastes = true
                    } label: {
                        Image(systemName: "wand.and.stars")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.primary.opacity(0.85))
                    }
                    .accessibilityLabel(l10n.editTastesA11y(dynamicTasteAccessibility))
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
                        Button(l10n.clearFeed, systemImage: "trash.fill", role: .destructive) {
                            viewModel.reset()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.primary.opacity(0.85))
                    }
                    .accessibilityLabel(l10n.feedMoreActionsA11y)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                        .opacity(0.35)
                    generateButton
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .background(.bar)
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
                BookmarksSheet(bookmarkStore: bookmarkStore)
                    .environment(\.appLanguage, appLanguage)
            }
            .sheet(isPresented: $showAdjustTastes) {
                AdjustTastesSheet()
                    .environment(\.appLanguage, appLanguage)
            }
            .toast(message: $toastMessage)
        }
        .task {
            viewModel.setContentLanguage(appLanguage)
            viewModel.updateInterests(Self.parse(interests: storedInterests))
            if viewModel.isOffline && viewModel.posts.isEmpty {
                await viewModel.loadCachedPosts()
            } else if viewModel.posts.isEmpty {
                viewModel.requestNextPost()
            }
        }
        .onChange(of: appLanguage) { _, newLang in
            viewModel.setContentLanguage(newLang)
        }
        .onChange(of: storedInterests) { _, newValue in
            viewModel.updateInterests(Self.parse(interests: newValue))
        }
    }

    private var dynamicTasteAccessibility: String {
        let list = Self.parse(interests: storedInterests)
        if list.isEmpty { return l10n.tastesNoneA11y() }
        return l10n.tastesCountA11y(list.count)
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tint)
            Text(l10n.emptyFeedHeadline)
                .font(.headline)
            Text(l10n.emptyFeedDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func feedList(bookmarkStore: BookmarkStore) -> some View {
        ScrollViewReader { proxy in
            List {
                // Offline banner
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
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }

                ForEach(viewModel.posts) { post in
                    PostCard(
                        post: post,
                        bookmarkStore: bookmarkStore,
                        authService: authService,
                        viewModel: viewModel,
                        toastMessage: $toastMessage,
                        cookingCaption: viewModel.isGenerating && !post.isComplete
                            ? viewModel.cookingCaption(l10n: l10n)
                            : nil
                    )
                    .environment(\.appLanguage, appLanguage)
                    .id(post.id)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            pendingDeletePostID = post.id
                            showDeletePostConfirmation = true
                        } label: {
                            Label(l10n.remove, systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.vertical, 8)
            .onChange(of: viewModel.posts.first?.id) { _, newID in
                guard let newID else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(newID, anchor: .top)
                }
            }
        }
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
// MARK: - Post card

private struct PostCard: View {
    let post: Post
    @Bindable var bookmarkStore: BookmarkStore
    let authService: AuthService
    var viewModel: FeedViewModel
    var toastMessage: Binding<String?>
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cardTitle)
                        .font(.subheadline).bold()
                        .lineLimit(2)
                    Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !post.isComplete {
                    Text(l10n.liveBadge)
                        .font(.caption2.monospaced()).bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.15), in: Capsule())
                        .foregroundStyle(.red)
                }
            }

            if let cookingCaption, !cookingCaption.isEmpty {
                Text(cookingCaption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.35), value: cookingCaption)
            }

            Text(postBody)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                
            if let deepDive = post.deepDiveText, !deepDive.isEmpty {
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

            if post.isComplete, !post.tags.isEmpty {
                tagChips
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeOut(duration: 0.3), value: post.tags)
            }
            
            if post.isComplete, !post.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Divider().padding(.vertical, 4)
                
                HStack(spacing: 24) {
                    // Deep Dive button
                    Button {
                        viewModel.requestDeepDive(for: post)
                    } label: {
                        Image(systemName: "fish")
                            .font(.title3)
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(l10n.deepDiveA11y)

                    // Share to timeline button
                    Button {
                        Task { await toggleShare() }
                    } label: {
                        if isSharePending {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: isShared ? "paperplane.fill" : "paperplane")
                                .font(.title3)
                                .foregroundStyle(isShared ? Color.accentColor : .secondary)
                        }
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(isShared ? l10n.unsharePost : l10n.sharePost)
                    .disabled(isSharePending)
                    
                    // iOS Share Sheet button
                    Button {
                        ShareService.presentShareSheet(post: post)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.borderless)
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
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.title3)
                            .foregroundStyle(isBookmarked ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(isBookmarked ? l10n.removeBookmarkA11y : l10n.bookmarkPostA11y)
                }
                .padding(.top, 4)
                .padding(.bottom, 2)
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
        )
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

    @ViewBuilder
    private func formatBadge(_ format: String) -> some View {
        let info = formatInfo(format)
        HStack(spacing: 5) {
            Image(systemName: info.icon)
                .font(.caption2.weight(.semibold))
            Text(info.label)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(info.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(info.color.opacity(0.12), in: Capsule())
    }

    private func formatInfo(_ format: String) -> (icon: String, label: String, color: Color) {
        switch format {
        case "DEBATE":
            return ("bubble.left.and.bubble.right", "Debate", .orange)
        case "TIMELINE":
            return ("clock.arrow.circlepath", "Timeline", .cyan)
        case "VERSUS":
            return ("arrow.left.arrow.right", "Versus", .red)
        case "MYTHBUSTER":
            return ("xmark.shield", "Mythbuster", .purple)
        case "IF_YOU_LIKE_X_TRY_Y":
            return ("arrow.triangle.branch", "If You Like…", .mint)
        case "FUN FACT DROP":
            return ("lightbulb", "Fun Fact", .yellow)
        case "NICHES & NUANCE":
            return ("magnifyingglass", "Niche", .indigo)
        case "UNLIKELY CONNECTION":
            return ("link", "Connection", .pink)
        case "TINY RECOMMENDATION":
            return ("star", "Recommendation", .orange)
        case "REFRAME":
            return ("arrow.triangle.2.circlepath", "Reframe", .teal)
        case "THE THING NOBODY TALKS ABOUT":
            return ("eye.slash", "Underrated", .brown)
        case "CURSED TRIVIA":
            return ("exclamationmark.triangle", "Cursed Trivia", .red)
        default:
            return ("sparkles", format.capitalized, .secondary)
        }
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
        } catch { }
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
