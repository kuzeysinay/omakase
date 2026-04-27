//
//  FeedView.swift
//  omakase
//

import SwiftUI

struct FeedView: View {

    @AppStorage("omakase.interests") private var storedInterests: String = ""

    @State private var viewModel: FeedViewModel
    @State private var bookmarkStore = BookmarkStore()
    @State private var showBookmarks = false
    @State private var showAdjustTastes = false

    init() {
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
            .navigationTitle("Omakase")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        tastePillButton
                        bookmarkToolbarButton(bookmarkStore: bookmarkStore)
                        Menu {
                            Button("Clear feed", systemImage: "trash", role: .destructive) {
                                viewModel.reset()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                generateButton
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
            }
            .alert(
                "Something went wrong",
                isPresented: .init(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.dismissError() } }
                )
            ) {
                Button("OK", role: .cancel) { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showBookmarks) {
                BookmarksSheet(bookmarkStore: bookmarkStore)
            }
            .sheet(isPresented: $showAdjustTastes) {
                AdjustTastesSheet()
            }
        }
        .task {
            viewModel.updateInterests(Self.parse(interests: storedInterests))
            if viewModel.posts.isEmpty {
                viewModel.requestNextPost()
            }
        }
        .onChange(of: storedInterests) { _, newValue in
            viewModel.updateInterests(Self.parse(interests: newValue))
        }
    }

    // MARK: - Toolbar

    private var tastePillButton: some View {
        Button {
            showAdjustTastes = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text(dynamicTasteLabel)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit tastes, \(dynamicTasteAccessibility)")
    }

    private var dynamicTasteLabel: String {
        let list = Self.parse(interests: storedInterests)
        if list.isEmpty { return "Add tastes" }
        if list.count == 1 {
            let one = list[0]
            return one.count > 16 ? String(one.prefix(14)) + "…" : one
        }
        return "\(list.count) tastes"
    }

    private var dynamicTasteAccessibility: String {
        let list = Self.parse(interests: storedInterests)
        if list.isEmpty { return "none selected" }
        return "\(list.count) selected"
    }

    private func bookmarkToolbarButton(bookmarkStore: BookmarkStore) -> some View {
        Button {
            showBookmarks = true
        } label: {
            Image(systemName: "bookmark")
                .overlay(alignment: .topTrailing) {
                    if bookmarkStore.count > 0 {
                        Text("\(bookmarkStore.count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.accentColor, in: Capsule())
                            .offset(x: 8, y: -8)
                    }
                }
        }
        .accessibilityLabel(
            bookmarkStore.count > 0
                ? "Saved posts, \(bookmarkStore.count)"
                : "Saved posts"
        )
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tint)
            Text("Your feed is warming up…")
                .font(.headline)
            Text("Tap the button below to taste the first post.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func feedList(bookmarkStore: BookmarkStore) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                        PostCard(post: post, bookmarkStore: bookmarkStore)
                            .id(post.id)
                            .padding(.horizontal)
                    }

                    if viewModel.isGenerating, viewModel.posts.last?.isComplete == true {
                        ProgressView().padding()
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: viewModel.posts.last?.id) { _, newID in
                guard let newID else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(newID, anchor: .top)
                }
            }
        }
    }

    private var generateButton: some View {
        Button {
            viewModel.requestNextPost()
        } label: {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Text(viewModel.isGenerating ? "Generating…" : "Serve next post")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isGenerating)
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

    @State private var showCursor: Bool = true

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
                if post.isComplete, !post.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        bookmarkStore.toggle(post)
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(isBookmarked ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark post")
                }
                if !post.isComplete {
                    Text("LIVE")
                        .font(.caption2.monospaced()).bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.15), in: Capsule())
                        .foregroundStyle(.red)
                }
            }

            Text(postBody)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.default, value: post.text)
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
    }

    private var cardTitle: String {
        let t = post.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        return Self.fallbackTitle(from: post.text, isStreaming: !post.isComplete)
    }

    private static func fallbackTitle(from text: String, isStreaming: Bool) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return isStreaming ? "Composing…" : "Untitled bite" }
        let snippet = trimmed.prefix(52)
        if snippet.count < trimmed.count {
            return String(snippet).trimmingCharacters(in: .whitespaces) + "…"
        }
        return String(snippet)
    }

    private var postBody: AttributedString {
        var attributed = AttributedString(post.text.isEmpty && !post.isComplete ? "…" : post.text)
        if !post.isComplete {
            var cursor = AttributedString(showCursor ? "▌" : " ")
            cursor.foregroundColor = .accentColor
            attributed.append(cursor)
        }
        return attributed
    }
}

#Preview {
    FeedView()
}
