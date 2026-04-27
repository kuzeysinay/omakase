//
//  OnboardingView.swift
//  omakase
//

import SwiftUI

struct OnboardingView: View {

    @AppStorage("omakase.interests") private var storedInterests: String = ""
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false

    @State private var interests: [String] = []
    @State private var draft: String = ""
    @FocusState private var isFieldFocused: Bool

    // AI suggestion state
    @State private var aiSuggestions: [String] = []
    @State private var isSuggesting: Bool = false
    /// Shown when the last suggest request returned no chips (HTTP error, parse, connectivity).
    @State private var suggestionFootnote: String?
    @State private var debounceTask: Task<Void, Never>? = nil
    /// Separate from `debounceTask` so typing / debounce does not cancel an in-flight refresh.
    @State private var refreshTask: Task<Void, Never>? = nil

    /// Suggestions not already added as interests (case-insensitive).
    private var visibleSuggestions: [String] {
        aiSuggestions.filter { suggestion in
            !interests.contains { $0.caseInsensitiveCompare(suggestion) == .orderedSame }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    inputField

                    if !interests.isEmpty {
                        chips
                    }

                    suggestionSection

                    Spacer(minLength: 32)
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                continueButton
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            interests = FeedView.parse(interests: storedInterests)
            scheduleSuggestion()
        }
        .onChange(of: draft) { _, _ in scheduleSuggestion() }
        .onChange(of: interests) { _, _ in scheduleSuggestion() }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Omakase")
                .font(.largeTitle.bold())
            Text("Tell us what you love. Your feed is generated fresh, just for you.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var inputField: some View {
        HStack {
            TextField(
                "e.g. David Fincher, Aftersun, Secret Hitler",
                text: $draft
            )
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($isFieldFocused)
            .submitLabel(.done)
            .onSubmit(commitDraft)

            Button(action: commitDraft) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .disabled(trimmedDraft.isEmpty)
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var chips: some View {
        FlowLayout(spacing: 8) {
            ForEach(interests, id: \.self) { interest in
                Button {
                    interests.removeAll { $0 == interest }
                } label: {
                    HStack(spacing: 6) {
                        Text(interest)
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Ideas to try")
                    .font(.headline)
                if isSuggesting {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Thinking…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                Spacer(minLength: 0)
                Button {
                    refreshIdeas()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .disabled(isSuggesting)
                .accessibilityLabel("Refresh ideas")
            }
            .animation(.easeInOut(duration: 0.2), value: isSuggesting)

            if !visibleSuggestions.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(visibleSuggestions, id: \.self) { suggestion in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                interests.append(suggestion)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkle")
                                    .font(.caption2)
                                    .foregroundStyle(Color.accentColor)
                                Text(suggestion)
                            }
                        }
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.background.secondary, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.accentColor.opacity(0.5), Color.accentColor.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .foregroundStyle(.primary)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: visibleSuggestions)
            }

            if let footnote = suggestionFootnote, !isSuggesting {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var continueButton: some View {
        Button {
            save()
        } label: {
            Text(interests.isEmpty ? "Add at least one interest" : "Start my feed")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(interests.isEmpty)
    }

    // MARK: - Actions

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commitDraft() {
        let value = trimmedDraft
        guard !value.isEmpty else { return }
        if !interests.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) {
            interests.append(value)
        }
        draft = ""
        isFieldFocused = true
    }

    /// Cancel any pending debounce and schedule a new one.
    private func scheduleSuggestion() {
        debounceTask?.cancel()
        debounceTask = Task {
            // 600 ms debounce — fast enough to feel reactive, slow enough to
            // avoid a request per keystroke.
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }

            let (snapshotInterests, snapshotDraft) = await MainActor.run {
                (interests, trimmedDraft)
            }

            await MainActor.run {
                isSuggesting = true
                suggestionFootnote = nil
            }

            let outcome: InterestSuggestResponse
            do {
                outcome = try await Task.detached {
                    try await InterestSuggestor.suggest(
                        interests: snapshotInterests,
                        draft: snapshotDraft,
                        excludeSuggestions: []
                    )
                }.value
            } catch {
                await MainActor.run { isSuggesting = false }
                return
            }

            await MainActor.run {
                applySuggestOutcome(outcome)
            }
        }
    }

    /// New AI batch excluding the current pills.
    private func refreshIdeas() {
        debounceTask?.cancel()
        refreshTask?.cancel()
        let exclude = aiSuggestions
        let snapshotInterests = interests
        let snapshotDraft = trimmedDraft
        refreshTask = Task {
            await MainActor.run {
                isSuggesting = true
                suggestionFootnote = nil
            }
            let outcome: InterestSuggestResponse
            do {
                outcome = try await Task.detached {
                    try await InterestSuggestor.suggest(
                        interests: snapshotInterests,
                        draft: snapshotDraft,
                        excludeSuggestions: exclude
                    )
                }.value
            } catch {
                await MainActor.run { isSuggesting = false }
                return
            }
            await MainActor.run {
                applySuggestOutcome(outcome)
            }
        }
    }

    private func applySuggestOutcome(_ outcome: InterestSuggestResponse) {
        if !outcome.suggestions.isEmpty {
            suggestionFootnote = nil
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                aiSuggestions = outcome.suggestions
            }
        } else {
            suggestionFootnote = outcome.loadingIssue ?? "Could not load ideas."
        }
        isSuggesting = false
    }

    private func save() {
        storedInterests = interests.joined(separator: ", ")
        hasOnboarded = true
    }
}

// MARK: - FlowLayout

/// Simple left-to-right wrapping layout for chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        return CGSize(width: totalWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    OnboardingView()
}
