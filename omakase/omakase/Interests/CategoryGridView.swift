//
//  CategoryGridView.swift
//  omakase
//
//  Animated category grid for tap-first interest discovery.
//  Used in onboarding and (via CategoryStripView) in the feed explorer.
//

import SwiftUI

// MARK: - Full Grid (Onboarding)

struct CategoryGridView: View {

    @Environment(\.appLanguage) private var appLanguage
    @Binding var interests: [String]
    @State private var expandedCategory: String?
    @State private var categorySubInterests: [String: [String]] = [:]
    @State private var loadingCategories: Set<String> = []
    @State private var expansionTasks: [String: Task<Void, Never>] = [:]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(InterestCategory.presets) { category in
                    CategoryCard(
                        category: category,
                        language: appLanguage,
                        isExpanded: expandedCategory == category.id,
                        isLoading: loadingCategories.contains(category.id),
                        subInterests: categorySubInterests[category.id] ?? [],
                        existingInterests: interests,
                        onTapCategory: { toggleCategory(category) },
                        onAddInterest: { addInterest($0) }
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleCategory(_ category: InterestCategory) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if expandedCategory == category.id {
                expandedCategory = nil
            } else {
                expandedCategory = category.id
                loadSubInterests(for: category)
            }
        }
    }

    private func loadSubInterests(for category: InterestCategory) {
        // If we already have results, don't reload
        if let existing = categorySubInterests[category.id], !existing.isEmpty {
            return
        }

        // Show fallbacks immediately
        categorySubInterests[category.id] = category.fallbackInterests(for: appLanguage)

        // Cancel any existing task for this category
        expansionTasks[category.id]?.cancel()

        loadingCategories.insert(category.id)

        expansionTasks[category.id] = Task {
            do {
                let results = try await CategoryExpansionService.expand(
                    category: category.localizedName(for: appLanguage),
                    existingInterests: interests,
                    language: appLanguage
                )
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if !results.isEmpty {
                        let filtered = results.filter { suggestion in
                            ContentModerationService.isAppropriate(suggestion)
                        }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            categorySubInterests[category.id] = filtered
                            loadingCategories.remove(category.id)
                        }
                    } else {
                        loadingCategories.remove(category.id)
                    }
                }
            } catch {
                await MainActor.run {
                    _ = loadingCategories.remove(category.id)
                }
            }
        }
    }

    private func addInterest(_ interest: String) {
        guard ContentModerationService.isAppropriate(interest) else { return }
        guard !interests.contains(where: { $0.caseInsensitiveCompare(interest) == .orderedSame }) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            interests.append(interest)
        }
    }
}

// MARK: - Category Card

private struct CategoryCard: View {

    let category: InterestCategory
    let language: AppLanguage
    let isExpanded: Bool
    let isLoading: Bool
    let subInterests: [String]
    let existingInterests: [String]
    var onTapCategory: () -> Void
    var onAddInterest: (String) -> Void

    @State private var appear = false

    private var filteredSubInterests: [String] {
        subInterests.filter { suggestion in
            !existingInterests.contains {
                $0.caseInsensitiveCompare(suggestion) == .orderedSame
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header
            Button(action: onTapCategory) {
                HStack(spacing: 10) {
                    Text(category.emoji)
                        .font(.title2)

                    Text(category.localizedName(for: language))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 0)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded sub-interests
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.horizontal, 14)

                    if isLoading && filteredSubInterests.isEmpty {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text(language == .turkish ? "Yükleniyor…" : "Loading…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                    } else {
                        FlowLayout(spacing: 6) {
                            ForEach(filteredSubInterests, id: \.self) { interest in
                                SubInterestChip(
                                    title: interest,
                                    isAlreadyAdded: existingInterests.contains(where: {
                                        $0.caseInsensitiveCompare(interest) == .orderedSame
                                    }),
                                    action: { onAddInterest(interest) }
                                )
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 12)

                        if isLoading {
                            HStack(spacing: 4) {
                                ProgressView().scaleEffect(0.6)
                                Text(language == .turkish ? "Daha fazla yükleniyor…" : "Loading more…")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 8)
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isExpanded
                        ? Color.primary.opacity(0.3)
                        : Color.primary.opacity(0.08),
                    lineWidth: isExpanded ? 1.5 : 1
                )
        )
        .scaleEffect(appear ? 1 : 0.92)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double.random(in: 0...0.15))) {
                appear = true
            }
        }
    }
}

// MARK: - Sub-Interest Chip

private struct SubInterestChip: View {
    let title: String
    let isAlreadyAdded: Bool
    let action: () -> Void

    @State private var justAdded = false

    var body: some View {
        Button {
            guard !isAlreadyAdded && !justAdded else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                justAdded = true
            }
            action()
        } label: {
            HStack(spacing: 4) {
                if justAdded || isAlreadyAdded {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "plus")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(
                        (justAdded || isAlreadyAdded)
                            ? Color.primary.opacity(0.12)
                            : Color.primary.opacity(0.05)
                    )
            )
            .foregroundStyle(
                (justAdded || isAlreadyAdded) ? .secondary : .primary
            )
        }
        .buttonStyle(.plain)
        .disabled(isAlreadyAdded)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: justAdded)
    }
}

// MARK: - Flow Layout (reusable)

/// Simple left-to-right wrapping layout for chips.
/// Duplicated from InterestsEditorForm to keep this file standalone.
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

// MARK: - Compact Strip (Feed Explorer)

struct CategoryStripView: View {

    @Environment(\.appLanguage) private var appLanguage
    let existingInterests: [String]
    var onAddInterest: (String) -> Void

    @State private var selectedCategory: InterestCategory?
    @State private var subInterests: [String] = []
    @State private var isLoading = false
    @State private var expansionTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Horizontal category strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(InterestCategory.presets) { category in
                        Button {
                            selectCategory(category)
                        } label: {
                            HStack(spacing: 5) {
                                Text(category.emoji)
                                    .font(.caption)
                                Text(category.localizedName(for: appLanguage))
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(
                                    selectedCategory?.id == category.id
                                        ? OmakaseTheme.chipActiveFill
                                        : Color.primary.opacity(0.06)
                                )
                            )
                            .foregroundStyle(
                                selectedCategory?.id == category.id
                                    ? OmakaseTheme.chipActiveText
                                    : .primary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Sub-interest chips for selected category
            if selectedCategory != nil {
                if isLoading && filteredSubInterests.isEmpty {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text(appLanguage == .turkish ? "Yükleniyor…" : "Loading…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                    .transition(.opacity)
                } else if !filteredSubInterests.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filteredSubInterests, id: \.self) { interest in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    onAddInterest(interest)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.caption2.weight(.bold))
                                        Text(interest)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(Color.primary.opacity(0.06))
                                    )
                                    .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                                .transition(.scale(scale: 0.85).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: filteredSubInterests)
                    }
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var filteredSubInterests: [String] {
        subInterests.filter { suggestion in
            ContentModerationService.isAppropriate(suggestion) &&
            !existingInterests.contains {
                $0.caseInsensitiveCompare(suggestion) == .orderedSame
            }
        }
    }

    private func selectCategory(_ category: InterestCategory) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if selectedCategory?.id == category.id {
                selectedCategory = nil
                subInterests = []
                return
            }
            selectedCategory = category
            // Show fallbacks immediately
            subInterests = category.fallbackInterests(for: appLanguage)
        }

        // Fetch AI-powered expansion
        expansionTask?.cancel()
        isLoading = true

        expansionTask = Task {
            do {
                let results = try await CategoryExpansionService.expand(
                    category: category.localizedName(for: appLanguage),
                    existingInterests: existingInterests,
                    language: appLanguage
                )
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if !results.isEmpty {
                        let filtered = results.filter { ContentModerationService.isAppropriate($0) }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            subInterests = filtered
                            isLoading = false
                        }
                    } else {
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}
