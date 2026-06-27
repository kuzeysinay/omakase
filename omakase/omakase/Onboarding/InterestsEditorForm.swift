//
//  InterestsEditorForm.swift
//  omakase
//
//  Shared chips + AI “Ideas to try” editor (onboarding + adjust tastes sheet).
//

import SwiftUI

struct InterestsEditorForm: View {

    @Environment(\.appLanguage) private var appLanguage
    @Binding var interests: [String]

    private var l10n: L10n { L10n(lang: appLanguage) }

    @State private var draft: String = ""
    @FocusState private var isFieldFocused: Bool

    @State private var aiSuggestions: [String] = []
    @State private var isSuggesting: Bool = false
    @State private var suggestionFootnote: String?
    @State private var debounceTask: Task<Void, Never>? = nil
    @State private var refreshTask: Task<Void, Never>? = nil

    private let suggestionLimit = 3

    private enum SuggestionRefreshReason: Equatable {
        case initial
        case draftChange
        case interestsChange
        case manualRefresh
    }

    private var visibleSuggestions: [String] {
        aiSuggestions.filter { suggestion in
            !interests.contains { $0.caseInsensitiveCompare(suggestion) == .orderedSame }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            inputField

            if !interests.isEmpty {
                chips
            }

            suggestionSection
        }
        .onAppear {
            scheduleSuggestion(reason: .initial)
        }
        .onChange(of: draft) { _, _ in scheduleSuggestion(reason: .draftChange) }
        .onChange(of: interests) { _, _ in scheduleSuggestion(reason: .interestsChange) }
    }

    private var inputField: some View {
        HStack {
            TextField(
                l10n.addTastePlaceholder,
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
                    .background(Color.primary.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(l10n.ideasToTry)
                    .font(.headline)
                if isSuggesting {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text(l10n.thinking)
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
                .accessibilityLabel(l10n.refreshIdeasA11y)
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
                                    .foregroundStyle(.secondary)
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
                                    Color.primary.opacity(0.2),
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

    private func scheduleSuggestion(reason: SuggestionRefreshReason) {
        debounceTask?.cancel()
        refreshTask?.cancel()
        debounceTask = Task {
            if reason != .initial {
                try? await Task.sleep(for: .milliseconds(600))
            }
            guard !Task.isCancelled else { return }

            switch reason {
            case .draftChange, .initial:
                await loadFreshSuggestions()
            case .interestsChange:
                await appendReplacementSuggestion()
            case .manualRefresh:
                await loadFreshSuggestions()
            }
        }
    }

    private func refreshIdeas() {
        debounceTask?.cancel()
        refreshTask?.cancel()
        scheduleSuggestion(reason: .manualRefresh)
    }

    private func loadFreshSuggestions() async {
        let snapshotInterests = await MainActor.run { interests }
        let snapshotDraft = await MainActor.run { trimmedDraft }
        let snapshotLang = await MainActor.run { appLanguage }

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
                        excludeSuggestions: [],
                        language: snapshotLang
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

    private func appendReplacementSuggestion() async {
        let snapshotInterests = await MainActor.run { interests }
        let snapshotDraft = await MainActor.run { trimmedDraft }
        let snapshotLang = await MainActor.run { appLanguage }
        let exclude = await MainActor.run { aiSuggestions }

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
                        excludeSuggestions: exclude,
                        language: snapshotLang
                    )
                }.value
            } catch {
                await MainActor.run { isSuggesting = false }
                return
            }

            await MainActor.run {
                if let next = outcome.suggestions.first,
                   !aiSuggestions.contains(where: { $0.caseInsensitiveCompare(next) == .orderedSame }) {
                    aiSuggestions.append(next)
                    if aiSuggestions.count > suggestionLimit * 2 {
                        aiSuggestions = Array(aiSuggestions.suffix(suggestionLimit * 2))
                    }
                    suggestionFootnote = nil
                } else if aiSuggestions.isEmpty {
                    applySuggestOutcome(outcome)
                    return
                } else if let loadingIssue = outcome.loadingIssue {
                    suggestionFootnote = loadingIssue
                }
                isSuggesting = false
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
            suggestionFootnote = outcome.loadingIssue ?? l10n.couldNotLoadIdeas
        }
        isSuggesting = false
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
