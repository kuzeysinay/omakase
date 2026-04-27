//
//  FeedView.swift
//  omakase
//

import SwiftUI

struct FeedView: View {

    @AppStorage("omakase.interests") private var storedInterests: String = ""
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false

    @State private var viewModel: FeedViewModel

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
            Group {
                if viewModel.posts.isEmpty {
                    emptyState
                } else {
                    feedList
                }
            }
            .navigationTitle("Omakase")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit interests", systemImage: "slider.horizontal.3") {
                            hasOnboarded = false
                        }
                        Button("Clear feed", systemImage: "trash", role: .destructive) {
                            viewModel.reset()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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
                        PostCard(post: post)
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

    @State private var showCursor: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .pink, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Omakase")
                        .font(.subheadline).bold()
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
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
