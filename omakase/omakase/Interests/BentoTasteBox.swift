//
//  BentoTasteBox.swift
//  omakase
//
//  Gamified Bento Box (2048-style) interest discovery engine for Feed.
//  Dynamic, tactile tile grid that morphs into sub-interests on tap,
//  with live AI synthesis feeling, while preserving ample room for posts.
//

import SwiftUI

struct BentoTasteBox: View {

    let allInterests: [String]
    @Binding var activeInterests: Set<String>
    var onAddInterest: (String) -> Void
    var onRemoveInterest: (String) -> Void
    @Binding var isLetterboxdActive: Bool
    var onResetInterests: (() -> Void)? = nil
    @Binding var isExpanded: Bool
    var onToggleExpand: (() -> Void)? = nil
    var isGenerating: Bool = false
    var isCooldownActive: Bool = false
    var cooldownRemaining: Int = 0
    var cooldownTotal: Int = 0
    var onSelectDedicatedTopic: ((String) -> Void)? = nil

    @Environment(\.appLanguage) private var appLanguage

    // MARK: - Navigation / Game State
    enum BoxMode: Equatable {
        case rootCategories
        case subInterests(category: InterestCategory)
    }

    @State private var mode: BoxMode = .rootCategories
    @State private var categoryOffset: Int = 0

    // AI synthesis state
    @State private var isSynthesizing: Bool = false
    @State private var synthesisTaskId: UUID = UUID()
    @State private var currentSubInterests: [String] = []
    @State private var revealedTilesCount: Int = 0
    @State private var justAddedInterest: String? = nil

    // Manual text entry
    @State private var showManualInput: Bool = false
    @State private var manualText: String = ""
    @FocusState private var isManualFieldFocused: Bool

    private var l10n: L10n { L10n(lang: appLanguage) }

    private var cooldownProgress: CGFloat {
        guard cooldownTotal > 0 else { return 0 }
        return max(0, min(1, CGFloat(cooldownRemaining) / CGFloat(cooldownTotal)))
    }

    // Visible root categories in the Bento (6 categories at a time)
    private var visibleCategories: [InterestCategory] {
        let all = InterestCategory.presets
        guard !all.isEmpty else { return [] }
        var result: [InterestCategory] = []
        for i in 0..<min(6, all.count) {
            let index = (categoryOffset + i) % all.count
            result.append(all[index])
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Full-width Edge-to-Edge Decreasing Reading Cooldown Bar / Hairline Divider
            topProgressBar

            // Mini Header Bar (Mode title, Back/Shuffle, Collapse toggle)
            headerBar

            if isExpanded {
                // The Bento Box Grid Canvas (2048-style)
                bentoGridCanvas
                    .frame(height: 122)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .bottom)))

                // Active interests ribbon (if user has any active interests)
                if !allInterests.isEmpty {
                    activeInterestsRibbon
                        .padding(.top, 2)
                        .padding(.bottom, 6)
                }

                // Optional manual text entry field
                if showManualInput {
                    manualInputBar
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            } else {
                // Collapsed Compact Ribbon
                collapsedRibbon
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .clipped()
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: mode)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: showManualInput)
    }

    // MARK: - Top Edge Progress Bar (Reading Cooldown & Hairline Divider)

    private var topProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                if isCooldownActive {
                    // Dimmed track
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                    // Active decreasing progress bar
                    Rectangle()
                        .fill(OmakaseTheme.ink)
                        .frame(width: max(0, geo.size.width * cooldownProgress))
                        .animation(.linear(duration: 0.95), value: cooldownRemaining)
                } else {
                    // Minimalist, razor-clean hairline separator
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 0.5)
                }
            }
        }
        .frame(height: isCooldownActive ? 3.5 : 0.5)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isCooldownActive)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 8) {
            switch mode {
            case .rootCategories:
                // Reading cooldown or generation indicator on the left
                if isCooldownActive {
                    HStack(spacing: 5) {
                        Image(systemName: "book.pages")
                            .font(.caption2.weight(.bold))
                        Text(appLanguage == .turkish ? "Okuma süresi: \(cooldownRemaining)s" : "Reading: \(cooldownRemaining)s")
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
                    .foregroundStyle(.secondary)
                } else if isGenerating {
                    HStack(spacing: 5) {
                        ProgressView()
                            .controlSize(.mini)
                        Text(appLanguage == .turkish ? "Post hazırlanıyor…" : "Cooking post…")
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Shuffle Button (2048 "New Deal" feeling)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        categoryOffset = (categoryOffset + 3) % InterestCategory.presets.count
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2.weight(.semibold))
                        Text(l10n.bentoShuffle)
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .systemBackground), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

            case .subInterests(let category):
                // Back Button (2048 Undo/Back)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        mode = .rootCategories
                        currentSubInterests = []
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.bold))
                        Image(systemName: category.iconName)
                            .font(.caption.weight(.semibold))
                        Text(category.localizedName(for: appLanguage))
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                // Refresh Button (regenerates 10 topics)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    loadCategory(category, refresh: true)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2.weight(.bold))
                            .rotationEffect(.degrees(isSynthesizing ? 360 : 0))
                            .animation(isSynthesizing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isSynthesizing)
                        Text(appLanguage == .turkish ? "Yenile" : "Refresh")
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .systemBackground), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(isSynthesizing || isGenerating || isCooldownActive)

                // Cooldown / AI Live Synthesis Indicator
                if isCooldownActive {
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages")
                            .font(.caption2)
                        Text("\(cooldownRemaining)s")
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
                    .foregroundStyle(.secondary)
                } else if isGenerating {
                    HStack(spacing: 4) {
                        ProgressView().controlSize(.mini)
                        Text(appLanguage == .turkish ? "Üretiliyor" : "Generating")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
                    .foregroundStyle(.secondary)
                } else if isSynthesizing {
                    HStack(spacing: 4) {
                        ProgressView().controlSize(.mini)
                        Text(l10n.bentoAiSynthesizing)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
                    .foregroundStyle(.secondary)
                }
            }

            // Keyboard Toggle Button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    showManualInput.toggle()
                    if showManualInput {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            isManualFieldFocused = true
                        }
                    } else {
                        isManualFieldFocused = false
                    }
                }
            } label: {
                Image(systemName: showManualInput ? "keyboard.chevron.compact.down" : "magnifyingglass")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .background(Color(uiColor: .systemBackground), in: Circle())
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Collapse / Expand Toggle
            Button {
                if isExpanded {
                    showManualInput = false
                    isManualFieldFocused = false
                }
                if let onToggleExpand {
                    onToggleExpand()
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                        if !isExpanded {
                            showManualInput = false
                            isManualFieldFocused = false
                        }
                    }
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .background(Color(uiColor: .systemBackground), in: Circle())
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, isExpanded ? 4 : 8)
    }

    // MARK: - Bento Grid Canvas (2048-Style)

    private var bentoGridCanvas: some View {
        GeometryReader { geo in
            let tileW = (geo.size.width - 16) / 3
            let tileH = (geo.size.height - 8) / 2

            ZStack {
                switch mode {
                case .rootCategories:
                    // 2x3 Root Bento Grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                        ],
                        spacing: 8
                    ) {
                        ForEach(visibleCategories) { category in
                            RootBentoTile(
                                category: category,
                                language: appLanguage,
                                width: tileW,
                                height: tileH
                            ) {
                                openCategory(category)
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.94).combined(with: .opacity),
                        removal: .scale(scale: 1.04).combined(with: .opacity)
                    ))

                case .subInterests(let category):
                    // Sub-interests 2048-style grid (Horizontal scrollable 2 rows x 5 items = 10 items)
                    subInterestsBentoGrid(tileW: max(tileW, 120), tileH: tileH, category: category)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 1.05).combined(with: .opacity),
                            removal: .scale(scale: 0.94).combined(with: .opacity)
                        ))
                }
            }
        }
    }

    // MARK: - Sub-Interests Bento Grid (10 Items)

    private func subInterestsBentoGrid(tileW: CGFloat, tileH: CGFloat, category: InterestCategory) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(
                rows: [
                    GridItem(.fixed(tileH), spacing: 8),
                    GridItem(.fixed(tileH), spacing: 8),
                ],
                spacing: 8
            ) {
                ForEach(Array(currentSubInterests.prefix(10).enumerated()), id: \.element) { index, topic in
                    SubInterestBentoTile(
                        title: topic,
                        isRevealed: index < revealedTilesCount,
                        isDisabled: isGenerating || isCooldownActive,
                        width: tileW,
                        height: tileH,
                        onTap: {
                            selectDedicatedTopic(topic)
                        }
                    )
                }
            }
            .padding(.trailing, 8)
        }
    }

    // MARK: - Active Interests Ribbon

    private var activeInterestsRibbon: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Letterboxd pill if active
                if isLetterboxdActive {
                    HStack(spacing: 4) {
                        Image(systemName: "film")
                            .font(.caption2)
                        Text("Letterboxd")
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.18), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.green.opacity(0.4), lineWidth: 1))
                    .foregroundStyle(Color.green)
                }

                // Active User Interests
                ForEach(allInterests, id: \.self) { interest in
                    let isActive = activeInterests.contains(interest)

                    HStack(spacing: 5) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                if isActive {
                                    activeInterests.remove(interest)
                                } else {
                                    activeInterests.insert(interest)
                                }
                            }
                        } label: {
                            Text(interest)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                        }

                        // Remove 'x' button
                        Button {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                onRemoveInterest(interest)
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(isActive ? OmakaseTheme.chipActiveText.opacity(0.7) : Color.secondary)
                        }
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(
                            isActive
                                ? OmakaseTheme.chipActiveFill
                                : Color(uiColor: .systemBackground)
                        )
                    )
                    .overlay(
                        Capsule().strokeBorder(
                            isActive ? Color.clear : Color.primary.opacity(0.15),
                            lineWidth: 1
                        )
                    )
                    .foregroundStyle(
                        isActive ? OmakaseTheme.chipActiveText : Color.primary
                    )
                }
            }
            .padding(.horizontal, 14)
        }
    }

    // MARK: - Collapsed Ribbon

    private var collapsedRibbon: some View {
        HStack(spacing: 8) {
            Button {
                if let onToggleExpand {
                    onToggleExpand()
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        isExpanded = true
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.caption2.weight(.bold))
                    Text(l10n.bentoExpand)
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(OmakaseTheme.chipActiveFill, in: Capsule())
                .foregroundStyle(OmakaseTheme.chipActiveText)
            }
            .buttonStyle(.plain)

            // Scroll of active tastes
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(allInterests, id: \.self) { interest in
                        Text(interest)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(uiColor: .systemBackground), in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - Manual Input Bar

    private var manualInputBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(l10n.addTastePlaceholder, text: $manualText)
                .font(.subheadline)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isManualFieldFocused)
                .onSubmit(commitManualInput)

            if !manualText.isEmpty {
                Button(action: commitManualInput) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OmakaseTheme.ink)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Game Mechanics & AI Synthesis

    private func openCategory(_ category: InterestCategory) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            mode = .subInterests(category: category)
        }
        loadCategory(category)
    }

    private func loadCategory(_ category: InterestCategory, refresh: Bool = false) {
        var fallbacks = category.fallbackInterests(for: appLanguage)
        if refresh {
            fallbacks.shuffle()
        }
        let initial10 = Array(fallbacks.prefix(10))
        currentSubInterests = initial10
        revealedTilesCount = 0
        isSynthesizing = true

        // Reveal fallback tiles with rapid cascading stagger
        animateStaggeredTiles(total: initial10.count)

        // Live AI expansion from backend
        let taskId = UUID()
        synthesisTaskId = taskId

        Task {
            do {
                let aiResults = try await CategoryExpansionService.expand(
                    category: category.localizedName(for: appLanguage),
                    existingInterests: refresh ? [] : allInterests,
                    language: appLanguage
                )
                guard synthesisTaskId == taskId else { return }

                await MainActor.run {
                    if !aiResults.isEmpty {
                        let filtered = aiResults.filter { ContentModerationService.isAppropriate($0) }
                        if filtered.count >= 6 {
                            let top10 = Array(filtered.prefix(10))
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentSubInterests = top10
                                revealedTilesCount = top10.count
                                isSynthesizing = false
                            }
                            return
                        }
                    }
                    isSynthesizing = false
                }
            } catch {
                guard synthesisTaskId == taskId else { return }
                await MainActor.run {
                    isSynthesizing = false
                }
            }
        }
    }

    private func selectDedicatedTopic(_ topic: String) {
        guard !isGenerating && !isCooldownActive else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onSelectDedicatedTopic?(topic)
    }

    private func animateStaggeredTiles(total: Int) {
        for i in 1...total {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    revealedTilesCount = max(revealedTilesCount, i)
                }
            }
        }
    }

    private func collectInterest(_ topic: String) {
        guard ContentModerationService.isAppropriate(topic) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        let isAlreadyInList = allInterests.contains { $0.caseInsensitiveCompare(topic) == .orderedSame }
        if !isAlreadyInList {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            justAddedInterest = topic
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onAddInterest(topic)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                if justAddedInterest == topic {
                    justAddedInterest = nil
                }
            }
        } else {
            // Toggle active state
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                if activeInterests.contains(topic) {
                    activeInterests.remove(topic)
                } else {
                    activeInterests.insert(topic)
                }
            }
        }
    }

    private func commitManualInput() {
        let trimmed = manualText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard ContentModerationService.isAppropriate(trimmed) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            manualText = ""
            return
        }
        collectInterest(trimmed)
        manualText = ""
        isManualFieldFocused = false
        withAnimation {
            showManualInput = false
        }
    }
}

// MARK: - Root Bento Tile (Level 0)

private struct RootBentoTile: View {
    let category: InterestCategory
    let language: AppLanguage
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top) {
                    Image(systemName: category.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(OmakaseTheme.ink)
                        .scaleEffect(isPressed ? 1.12 : 1.0)
                        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressed)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isPressed ? Color.primary : Color.secondary.opacity(0.6))
                        .offset(x: isPressed ? 2.5 : 0)
                        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressed)
                }

                Spacer(minLength: 0)

                Text(category.localizedName(for: language))
                    .font(.caption.weight(isPressed ? .bold : .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: width, height: height, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isPressed ? OmakaseTheme.ink.opacity(0.08) : Color(uiColor: .systemBackground))
                    .shadow(
                        color: .black.opacity(isPressed ? 0.01 : 0.04),
                        radius: isPressed ? 0.5 : 3,
                        y: isPressed ? 0.5 : 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(
                        isPressed ? OmakaseTheme.ink.opacity(0.55) : Color.primary.opacity(0.12),
                        lineWidth: isPressed ? 1.5 : 1
                    )
            )
            .offset(y: isPressed ? 1.5 : 0)
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.68), value: isPressed)
        }
        .buttonStyle(BentoPressButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Sub-Interest Bento Tile (Single-Shot Dedicated Post Generator)

private struct SubInterestBentoTile: View {
    let title: String
    let isRevealed: Bool
    let isDisabled: Bool
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isDisabled ? Color.secondary.opacity(0.6) : OmakaseTheme.ink)
                    .scaleEffect(isPressed ? 1.15 : 1.0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressed)

                Text(title)
                    .font(.caption.weight(isPressed ? .semibold : .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(isDisabled ? Color.secondary : Color.primary)

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(isDisabled ? Color.secondary.opacity(0.3) : Color.secondary.opacity(0.6))
                    .offset(x: isPressed ? 1.5 : 0, y: isPressed ? -1.5 : 0)
                    .scaleEffect(isPressed ? 1.15 : 1.0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressed)
            }
            .padding(.horizontal, 10)
            .frame(width: max(width, 130), height: height)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isPressed ? OmakaseTheme.ink.opacity(0.08) : Color(uiColor: .systemBackground))
                    .shadow(
                        color: .black.opacity(isPressed ? 0.01 : 0.03),
                        radius: isPressed ? 0.5 : 2.5,
                        y: isPressed ? 0.5 : 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(
                        isPressed ? OmakaseTheme.ink.opacity(0.55) : Color.primary.opacity(isDisabled ? 0.06 : 0.12),
                        lineWidth: isPressed ? 1.5 : 1
                    )
            )
            .offset(y: isPressed ? 1.5 : 0)
            .scaleEffect(isRevealed ? (isPressed ? 0.94 : 1.0) : 0.75)
            .opacity(isRevealed ? (isDisabled ? 0.45 : 1.0) : 0.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: isRevealed)
            .animation(.spring(response: 0.2, dampingFraction: 0.68), value: isPressed)
        }
        .buttonStyle(BentoPressButtonStyle(isPressed: $isPressed))
        .disabled(isDisabled)
    }
}

// MARK: - Bento Press Button Style

private struct BentoPressButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
                if pressed {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
    }
}
