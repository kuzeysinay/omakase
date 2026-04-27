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

    private let suggestions: [String] = [
        "David Fincher",
        "Aftersun",
        "Secret Hitler",
        "Brutalist architecture",
        "Kendrick Lamar",
        "Cooking with lemons",
        "Studio Ghibli",
        "Formula 1 strategy",
    ]

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
        }
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
            Text("Ideas to try")
                .font(.headline)
            FlowLayout(spacing: 8) {
                ForEach(suggestions.filter { !interests.contains($0) }, id: \.self) { suggestion in
                    Button(suggestion) {
                        interests.append(suggestion)
                    }
                    .font(.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.background.secondary, in: Capsule())
                    .overlay(Capsule().stroke(.separator, lineWidth: 0.5))
                    .foregroundStyle(.primary)
                }
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
