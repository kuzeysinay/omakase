//
//  BookmarksSheet.swift
//  omakase
//

import SwiftUI

// MARK: - Type-Safe Navigation Route for Saved Posts

enum BookmarksNavigationRoute: Hashable {
    case collections
    case collectionEntries(String)
    case entryDetail(UUID)
}

extension View {
    /// Registers all Saved Posts destinations at the root of a `NavigationStack`
    /// so every push (`collections` -> `collectionEntries` -> `entryDetail`) resolves unambiguously.
    func bookmarksNavigationDestinations(
        bookmarkStore: BookmarkStore,
        authService: AuthService,
        appLanguage: AppLanguage
    ) -> some View {
        self.navigationDestination(for: BookmarksNavigationRoute.self) { route in
            switch route {
            case .collections:
                BookmarksCollectionsView(
                    bookmarkStore: bookmarkStore,
                    authService: authService
                )
                .environment(\.appLanguage, appLanguage)

            case .collectionEntries(let collectionId):
                CollectionEntriesView(
                    bookmarkStore: bookmarkStore,
                    authService: authService,
                    collectionId: collectionId
                )
                .environment(\.appLanguage, appLanguage)

            case .entryDetail(let entryId):
                if let entry = bookmarkStore.entries.first(where: { $0.id == entryId }) {
                    BookmarkDetailView(
                        entry: entry,
                        bookmarkStore: bookmarkStore,
                        authService: authService
                    )
                    .environment(\.appLanguage, appLanguage)
                }
            }
        }
    }
}

// MARK: - Modal Wrapper (if presented as a sheet)

struct BookmarksSheet: View {

    @Environment(\.appLanguage) private var appLanguage
    @Bindable var bookmarkStore: BookmarkStore
    let authService: AuthService
    @Environment(\.dismiss) private var dismiss

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            BookmarksCollectionsView(bookmarkStore: bookmarkStore, authService: authService)
                .bookmarksNavigationDestinations(
                    bookmarkStore: bookmarkStore,
                    authService: authService,
                    appLanguage: appLanguage
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(l10n.done) { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Level 1: Main Subject Folders List

struct BookmarksCollectionsView: View {

    @Environment(\.appLanguage) private var appLanguage
    @Bindable var bookmarkStore: BookmarkStore
    let authService: AuthService

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        Group {
            if bookmarkStore.entries.isEmpty {
                ContentUnavailableView {
                    Label(l10n.noBookmarks, systemImage: "bookmark")
                } description: {
                    Text(l10n.bookmarksHint)
                }
            } else {
                List {
                    ForEach(bookmarkStore.collectionNames, id: \.self) { collectionId in
                        NavigationLink(value: BookmarksNavigationRoute.collectionEntries(collectionId)) {
                            HStack(spacing: 12) {
                                Label {
                                    Text(bookmarkStore.displayTitle(for: collectionId, language: appLanguage))
                                        .font(.body.weight(collectionId == "All" ? .semibold : .regular))
                                        .foregroundStyle(.primary)
                                } icon: {
                                    Image(systemName: bookmarkStore.iconName(for: collectionId))
                                        .foregroundStyle(OmakaseTheme.ink)
                                }
                                Spacer()
                                Text("\(bookmarkStore.entryCount(in: collectionId))")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(l10n.collectionsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Level 2: Entries in a Main Subject Folder

struct CollectionEntriesView: View {

    @Environment(\.appLanguage) private var appLanguage
    @Bindable var bookmarkStore: BookmarkStore
    let authService: AuthService
    let collectionId: String

    private var l10n: L10n { L10n(lang: appLanguage) }

    // MARK: - Selection state

    @State private var isEditing = false
    @State private var selection: Set<UUID> = []

    // MARK: - Confirmation alert state

    enum PendingDelete {
        case single(UUID)
        case selected
        case all
    }
    @State private var pendingDelete: PendingDelete?
    @State private var showDeleteConfirmation = false

    private var filteredEntries: [BookmarkEntry] {
        bookmarkStore.entries(in: collectionId)
    }

    var body: some View {
        Group {
            if filteredEntries.isEmpty {
                ContentUnavailableView {
                    Label(l10n.noBookmarks, systemImage: "bookmark")
                } description: {
                    Text(l10n.bookmarksHint)
                }
            } else {
                List(selection: isEditing ? $selection : nil) {
                    ForEach(filteredEntries) { entry in
                        NavigationLink(value: BookmarksNavigationRoute.entryDetail(entry.id)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                     ? l10n.savedPostFallbackTitle
                                     : entry.title)
                                    .font(.headline)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(entry.postCreatedAt.localizedFormatted(for: appLanguage))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(Post.splitBodyAndSource(from: entry.text).body)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(4)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                pendingDelete = .single(entry.id)
                                showDeleteConfirmation = true
                            } label: {
                                Label(l10n.remove, systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            moveToMenu(for: entry)
                        }
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if isEditing && !selection.isEmpty {
                        VStack(spacing: 0) {
                            Divider().opacity(0.35)
                            Button(role: .destructive) {
                                pendingDelete = .selected
                                showDeleteConfirmation = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                    Text(l10n.deleteSelectedCount(selection.count))
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .controlSize(.large)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        }
                        .background(.bar)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: isEditing)
                .animation(.easeInOut(duration: 0.25), value: selection.isEmpty)
            }
        }
        .navigationTitle(bookmarkStore.displayTitle(for: collectionId, language: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !filteredEntries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(isEditing ? l10n.cancel : l10n.selectEdit) {
                            if isEditing {
                                isEditing = false
                                selection.removeAll()
                            } else {
                                isEditing = true
                            }
                        }
                        if !isEditing {
                            Menu {
                                Button(l10n.removeAllSaved, systemImage: "trash", role: .destructive) {
                                    pendingDelete = .all
                                    showDeleteConfirmation = true
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            }
        }
        .alert(deleteAlertTitle, isPresented: $showDeleteConfirmation) {
            Button(l10n.cancel, role: .cancel) {
                pendingDelete = nil
            }
            Button(l10n.remove, role: .destructive) {
                executePendingDelete()
            }
        } message: {
            Text(deleteAlertMessage)
        }
        .onChange(of: filteredEntries.count) { _, newCount in
            if newCount == 0 {
                isEditing = false
                selection.removeAll()
            }
        }
    }

    // MARK: - Move-to Main Subject submenu

    @ViewBuilder
    private func moveToMenu(for entry: BookmarkEntry) -> some View {
        let otherCategories = InterestCategory.presets.filter { $0.id != entry.collectionName }
        Menu(l10n.moveToCategory) {
            ForEach(otherCategories) { targetCat in
                Button {
                    withAnimation {
                        bookmarkStore.moveToCollection(entryId: entry.id, collectionId: targetCat.id)
                    }
                } label: {
                    Label(targetCat.localizedName(for: appLanguage), systemImage: targetCat.iconName)
                }
            }
        }
    }

    // MARK: - Alert helpers

    private var deleteAlertTitle: String {
        switch pendingDelete {
        case .single:
            return l10n.confirmDeleteTitle
        case .selected:
            return l10n.confirmDeleteSelectedTitle(selection.count)
        case .all:
            return l10n.confirmDeleteAllTitle
        case nil:
            return ""
        }
    }

    private var deleteAlertMessage: String {
        switch pendingDelete {
        case .single:
            return l10n.confirmDeleteMessage
        case .selected:
            return l10n.confirmDeleteSelectedMessage(selection.count)
        case .all:
            return l10n.confirmDeleteAllMessage
        case nil:
            return ""
        }
    }

    private func executePendingDelete() {
        guard let action = pendingDelete else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            switch action {
            case .single(let id):
                bookmarkStore.remove(id: id)
            case .selected:
                for id in selection {
                    bookmarkStore.remove(id: id)
                }
                selection.removeAll()
            case .all:
                bookmarkStore.removeAll(in: collectionId)
            }
        }
        pendingDelete = nil
    }
}

// MARK: - Level 3: Bookmark Detail View

struct BookmarkDetailView: View {

    let entry: BookmarkEntry
    @Bindable var bookmarkStore: BookmarkStore
    let authService: AuthService

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    private var l10n: L10n { L10n(lang: appLanguage) }

    @State private var showDeepDiveSheet = false
    @State private var showExportSheet = false
    @State private var isShared = false
    @State private var isSharePending = false
    @State private var toastMessage: String?

    private var post: Post { entry.toPost() }
    private var parsedPost: ParsedPostContent { post.parsedContent }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(cardTitle)
                        .font(.system(size: 20, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                        Text(entry.postCreatedAt.localizedFormatted(for: appLanguage))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Full post body
                Text(parsedPost.body)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                if let source = parsedPost.source {
                    PostSourceView(source: source)
                }

                // Deep dive — opens dedicated reader sheet
                if let deepDive = entry.deepDiveText, !deepDive.isEmpty {
                    Button {
                        showDeepDiveSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "fish.fill")
                                .font(.title3)
                                .foregroundStyle(OmakaseTheme.ink)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(l10n.deepDiveTitle)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(OmakaseTheme.ink)
                                Text(deepDivePreview(deepDive))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(OmakaseTheme.stroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Tags
                if !entry.tags.isEmpty {
                    FlowLayoutBookmarks(spacing: 6) {
                        ForEach(entry.tags, id: \.self) { tag in
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

                Divider().padding(.vertical, 4)

                // Action bar
                HStack(spacing: 24) {
                    // Share to social timeline
                    Button {
                        Task { await toggleShare() }
                    } label: {
                        if isSharePending {
                            ProgressView().controlSize(.small)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: isShared ? "paperplane.fill" : "paperplane")
                                    .font(.title3)
                                    .foregroundStyle(isShared ? OmakaseTheme.ink : .primary)
                                Text(isShared
                                     ? l10n.actionShared
                                     : l10n.actionShare)
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(isSharePending)

                    // Export Studio
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showExportSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                        }
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    // Remove bookmark
                    Button(role: .destructive) {
                        bookmarkStore.remove(id: entry.id)
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bookmark.slash.fill")
                                .font(.title3)
                        }
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.top, 4)
                .padding(.bottom, 2)
                .padding(.horizontal, 4)
            }
            .padding()
        }
        .navigationTitle(l10n.savedPostFallbackTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDeepDiveSheet) {
            DeepDiveReaderSheet(
                text: Post.sanitizeTemplateLabels(from: entry.deepDiveText ?? ""),
                title: l10n.deepDiveTitle
            )
            .environment(\.appLanguage, appLanguage)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportPostSheet(post: post)
                .environment(\.appLanguage, appLanguage)
        }
        .toast(message: $toastMessage)
        .task {
            // Check if already shared
            guard let user = authService.currentUser else { return }
            isShared = (try? await FirestoreService.shared.hasSharedPost(
                text: entry.text, authorId: user.uid
            )) ?? false
        }
    }

    private var cardTitle: String {
        let t = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? l10n.savedPostFallbackTitle : t
    }

    private func deepDivePreview(_ text: String) -> String {
        let clean = Post.splitBodyAndSource(from: text).body
        let snippet = clean.prefix(120)
        if snippet.count < clean.count {
            return String(snippet).trimmingCharacters(in: .whitespaces) + "…"
        }
        return String(snippet)
    }

    // MARK: - Share action

    private func toggleShare() async {
        guard let user = authService.currentUser else { return }
        isSharePending = true
        do {
            if isShared {
                try await FirestoreService.shared.unsharePost(text: post.text, authorId: user.uid)
                isShared = false
                toastMessage = l10n.toastPostUnshared
            } else {
                try await FirestoreService.shared.sharePost(post, author: user)
                isShared = true
                if AccessManager.shared.canClaimShareBonus,
                   await AccessManager.shared.claimShareBonus() {
                    toastMessage = l10n.toastShareBonusGranted
                } else {
                    toastMessage = l10n.toastPostShared
                }
            }
        } catch {
            let context: SocialActionContext = isShared ? .unshare : .share
            let mapped = OmakaseError.from(error, context: context)
            ErrorReporter.record(error, mapped: mapped, area: "bookmarks_toggle_share")
            toastMessage = mapped.message(l10n: l10n)
        }
        isSharePending = false
    }
}

// MARK: - FlowLayout for Bookmarks module

private struct FlowLayoutBookmarks: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layoutRows(proposal: proposal, subviews: subviews).size
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
