//
//  FeedView.swift
//  omakase
//

import SwiftUI

struct FeedView: View {

    @AppStorage("omakase.interests") private var storedInterests: String = ""

    @State private var viewModel: FeedViewModel
    @State private var bookmarksStore = BookmarksStore.shared
    @State private var showBookmarksSheet = false
    @State private var showInterestsEditor = false

    init() {
        // `@AppStorage` isn't available at init time, so read UserDefaults
        // directly for the initial interests list.
        let raw = UserDefaults.standard.string(forKey: "omakase.interests") ?? ""
        let interests = Self.parse(interests: raw)
        _viewModel = State(initialValue: FeedViewModel(interests: interests))
    }

    var body: some View {
        // Helps SwiftUI track @Observable mutations from this @State-held model.
        @Bindable var viewModel = viewModel
        return NavigationStack {
            VStack(spacing: 0) {
                tastesStrip
                Group {
                    if viewModel.posts.isEmpty {
                        emptyState
                    } else {
                        feedList
                    }
                }
            }
            .navigationTitle("Omakase")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 20) {
                        Button {
                            showBookmarksSheet = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bookmark")
                                if bookmarksStore.items.count > 0 {
                                    Text("\(bookmarksStore.items.count)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(minWidth: 16, minHeight: 16)
                                        .background(Color.accentColor, in: Circle())
                                        .offset(x: 10, y: -10)
                                }
                            }
                        }
                        .accessibilityLabel("Saved bookmarks")

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
            .sheet(isPresented: $showBookmarksSheet) {
                BookmarksSheet(store: bookmarksStore)
            }
            .sheet(isPresented: $showInterestsEditor) {
                InterestsEditorSheet(storedInterests: $storedInterests)
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

    // MARK: - Subviews

    /// Live taste chips + edit affordance (replaces routing back through onboarding).
    private var tastesStrip: some View {
        let tags = Self.parse(interests: storedInterests)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Your tastes", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
                Spacer(minLength: 8)
                Button {
                    showInterestsEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle.fill")
                        .font(.caption.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if tags.isEmpty {
                        Text("Tap Edit to add what you're into")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.14), in: Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
    }

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

    private var feedList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                        PostCard(
                            post: post,
                            isBookmarked: bookmarksStore.contains(postID: post.id),
                            onBookmarkToggle: { bookmarksStore.toggle(post) }
                        )
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
    let isBookmarked: Bool
    let onBookmarkToggle: () -> Void

    @State private var showCursor: Bool = true

    private var canBookmark: Bool {
        post.isComplete && !post.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                Button {
                    onBookmarkToggle()
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.body.weight(.medium))
                        .foregroundStyle(isBookmarked ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.borderless)
                .disabled(!canBookmark)
                .opacity(canBookmark ? 1 : 0.35)
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark post")

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

    /// When the backend does not send `title` (older server) or the model skips `TITLE:`.
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
