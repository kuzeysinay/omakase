//
//  InlineTasteBar.swift
//  omakase
//
//  Inline horizontal chip bar for toggling, adding, and discovering interests
//  directly from the feed — no sheet needed.
//

import SwiftUI

struct InlineTasteBar: View {

    let allInterests: [String]
    @Binding var activeInterests: Set<String>
    var onAddInterest: (String) -> Void
    var onRemoveInterest: (String) -> Void
    @Binding var isLetterboxdActive: Bool
    var onLetterboxdToggle: (Bool) -> Void

    @Environment(\.appLanguage) private var appLanguage

    @State private var showAddField = false
    @State private var draftText = ""
    @FocusState private var isFieldFocused: Bool

    @State private var aiSuggestions: [String] = []
    @State private var isFetchingSuggestions = false
    @State private var suggestionTask: Task<Void, Never>?
    @State private var rotationAngle: Double = 0

    private var l10n: L10n { L10n(lang: appLanguage) }

    private var visibleSuggestions: [String] {
        Array(
            aiSuggestions
                .filter { suggestion in
                    !allInterests.contains {
                        $0.caseInsensitiveCompare(suggestion) == .orderedSame
                    }
                }
                .prefix(3)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            chipRow

            if showAddField {
                addField
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider().opacity(0.35)
        }
        .background(.bar)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showAddField)
        .task { fetchSuggestions() }
        .onChange(of: allInterests) { _, _ in fetchSuggestions() }
    }

    // MARK: - Chip row

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                refreshButton

                letterboxdChip

                ForEach(allInterests, id: \.self) { interest in
                    interestChip(interest)
                }

                if isFetchingSuggestions && visibleSuggestions.isEmpty {
                    HStack(spacing: 8) {
                        ShimmeringPill(width: 80)
                        ShimmeringPill(width: 110)
                        ShimmeringPill(width: 70)
                    }
                    .transition(.blurReplace.combined(with: .opacity))
                }

                ForEach(visibleSuggestions, id: \.self) { suggestion in
                    suggestionChip(suggestion)
                }

                addButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: allInterests)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: activeInterests)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: visibleSuggestions)
        }
    }

    // MARK: - Chips

    private func interestChip(_ interest: String) -> some View {
        let isActive = activeInterests.contains(interest)
        return Text(interest)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                isActive ? OmakaseTheme.chipActiveFill : Color.clear,
                in: Capsule()
            )
            .foregroundStyle(isActive ? OmakaseTheme.chipActiveText : .secondary)
            .overlay(
                Capsule()
                    .stroke(
                        isActive ? Color.clear : OmakaseTheme.chipInactiveStroke,
                        lineWidth: 1
                    )
            )
            .contentShape(Capsule())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    if isActive {
                        activeInterests.remove(interest)
                    } else {
                        activeInterests.insert(interest)
                    }
                }
            }
            .contextMenu {
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onRemoveInterest(interest)
                    }
                } label: {
                    Label(l10n.remove, systemImage: "trash")
                }
            }
            .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    private func suggestionChip(_ suggestion: String) -> some View {
        AnimatedSuggestionChip(suggestion: suggestion) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onAddInterest(suggestion)
            }
        }
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    private var refreshButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                rotationAngle += 360
            }
            fetchSuggestions()
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.secondary)
                .rotationEffect(.degrees(rotationAngle))
                .frame(width: 30, height: 30)
                .background(Color.secondary.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isFetchingSuggestions)
    }

    private var letterboxdChip: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            let newValue = !isLetterboxdActive
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isLetterboxdActive = newValue
            }
            onLetterboxdToggle(newValue)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "film.fill")
                    .font(.caption.weight(.bold))
                Text("Letterboxd")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isLetterboxdActive ? OmakaseTheme.chipActiveFill : Color.clear,
                in: Capsule()
            )
            .foregroundStyle(isLetterboxdActive ? OmakaseTheme.chipActiveText : .secondary)
            .overlay(
                Capsule()
                    .stroke(
                        isLetterboxdActive
                            ? Color.clear
                            : OmakaseTheme.chipInactiveStroke,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
    }

    private var addButton: some View {
        Button {
            withAnimation {
                showAddField.toggle()
                if showAddField {
                    isFieldFocused = true
                }
            }
        } label: {
            Image(systemName: showAddField ? "xmark" : "plus")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
                .frame(width: 30, height: 30)
                .background(Color.primary.opacity(0.08), in: Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add field

    private var addField: some View {
        HStack(spacing: 8) {
            TextField(l10n.addTastePlaceholder, text: $draftText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isFieldFocused)
                .submitLabel(.done)
                .onSubmit(commitDraft)
                .font(.subheadline)

            Button(action: commitDraft) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func commitDraft() {
        let value = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        if !allInterests.contains(where: {
            $0.caseInsensitiveCompare(value) == .orderedSame
        }) {
            onAddInterest(value)
        }
        draftText = ""
        isFieldFocused = true
    }

    private func fetchSuggestions() {
        suggestionTask?.cancel()
        let snapshot = allInterests
        let lang = appLanguage
        let exclude = aiSuggestions
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            aiSuggestions.removeAll()
            isFetchingSuggestions = true
        }
        
        suggestionTask = Task {
            guard !Task.isCancelled else { return }
            do {
                let result = try await Task.detached {
                    try await InterestSuggestor.suggest(
                        interests: snapshot,
                        draft: "",
                        excludeSuggestions: exclude,
                        language: lang
                    )
                }.value
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if !result.suggestions.isEmpty {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            aiSuggestions = result.suggestions
                        }
                    }
                    withAnimation {
                        isFetchingSuggestions = false
                    }
                }
            } catch is CancellationError {
                // Cancelled — nothing to do.
            } catch {
                await MainActor.run { 
                    withAnimation { isFetchingSuggestions = false }
                }
            }
        }
    }
}

// MARK: - Live Animations

fileprivate struct AnimatedSuggestionChip: View {
    let suggestion: String
    let action: () -> Void

    @State private var isBreathing = false

    var body: some View {
        Button(action: action) {
            Text(suggestion)
                .lineLimit(1)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(isBreathing ? 0.12 : 0.04),
                            Color.primary.opacity(isBreathing ? 0.04 : 0.12),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(
                            Color.primary.opacity(isBreathing ? 0.35 : 0.12),
                            lineWidth: 1
                        )
                )
                .foregroundStyle(.primary)
                .offset(y: isBreathing ? -1 : 1)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

fileprivate struct ShimmeringPill: View {
    let width: CGFloat
    @State private var isShimmering = false

    var body: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.1))
            .frame(width: width, height: 32)
            .overlay(
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, Color.primary.opacity(0.15), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(isShimmering ? 15 : -15))
                    .offset(x: isShimmering ? width : -width)
            )
            .clipShape(Capsule())
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isShimmering = true
                }
            }
    }
}
