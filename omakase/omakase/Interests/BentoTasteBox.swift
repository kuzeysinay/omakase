//
//  BentoTasteBox.swift
//  omakase
//
//  Full-screen Bento Box interest & topic discovery page for Feed.
//  Covers the entire screen when no post is shown or when scrolling down
//  to generate a new post, and disappears while a post is being generated.
//

import SwiftUI

struct BentoTasteBox: View {

    let allInterests: [String]
    @Binding var activeInterests: Set<String>
    var onAddInterest: (String) -> Void
    var onRemoveInterest: (String) -> Void
    @Binding var isLetterboxdActive: Bool
    var onResetInterests: (() -> Void)? = nil
    var isGenerating: Bool = false
    var isOffline: Bool = false
    var isCooldownActive: Bool = false

    private var isGenerationDisabled: Bool {
        isGenerating || isCooldownActive || isOffline
    }
    var cooldownRemaining: Int = 0
    var cooldownTotal: Int = 0
    var hasExistingPosts: Bool = false
    var onScrollToLastPost: (() -> Void)? = nil
    var onSelectDedicatedTopic: ((String, String?) -> Void)? = nil
    var onPromptLetterboxdUsername: (() -> Void)? = nil
    var onSelectLetterboxdPost: (() -> Void)? = nil
    @AppStorage("omakase.letterboxd_username") private var storedLetterboxdUsername: String = ""

    @Environment(\.appLanguage) private var appLanguage

    // MARK: - Navigation / Game State
    enum BoxMode: Equatable {
        case rootCategories
        case subInterests(category: InterestCategory)
    }

    @State private var mode: BoxMode = .rootCategories

    // AI synthesis state
    @State private var isSynthesizing: Bool = false
    @State private var isRefreshingSubInterests: Bool = false
    @State private var synthesisTaskId: UUID = UUID()
    @State private var currentSubInterests: [String] = []
    @State private var cachedSubInterestsByCategory: [String: [String]] = [:]
    @State private var prefetchedSubInterestsByCategory: [String: [String]] = [:]
    @State private var prefetchingCategoryIds: Set<String> = []
    @State private var revealedTilesCount: Int = 0
    @State private var justAddedInterest: String? = nil

    // Nested vertical scroll -> return to previous post handoff
    @State private var didScrollDeepInGrid: Bool = false
    @State private var hasTriggeredPullBack: Bool = false
    @State private var scrollResetTask: Task<Void, Never>?

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Optional "Back to previous post" button when user scrolled down from a post
            if hasExistingPosts {
                backToFeedBanner
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
            }

            // Header section (Title / Back button + Refresh / Cooldown indicator)
            headerSection
                .padding(.horizontal, 18)
                .padding(.top, hasExistingPosts ? 10 : 16)
                .padding(.bottom, 12)

            // Main Full-Page Bento Grid Canvas (Scrollable Categories or Sub-Topics)
            bentoGridCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 4)

            // Scroll hint caption (sub-topics only)
            if mode != .rootCategories {
                scrollHintBar
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 10)
            }

            // Bottom controls: Active interests ribbon
            if !allInterests.isEmpty || isLetterboxdActive {
                activeInterestsRibbon
                    .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .onChange(of: appLanguage) { _, newLang in
            cachedSubInterestsByCategory.removeAll()
            prefetchedSubInterestsByCategory.removeAll()
            prefetchingCategoryIds.removeAll()
            SubTopicDiscoveryStore.shared.prewarmAllCategories(language: newLang, userInterests: allInterests)
        }
        .task(id: appLanguage) {
            SubTopicDiscoveryStore.shared.prewarmAllCategories(language: appLanguage, userInterests: allInterests)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: mode)
    }

    // MARK: - Back to Feed Banner

    private var backToFeedBanner: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onScrollToLastPost?()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OmakaseTheme.ink)
                Text(l10n.bentoReturnToLastPost)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 42)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch mode {
            case .rootCategories:
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.bentoCategoriesTitle)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)

                        Text(l10n.bentoCategoriesSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 4)

                    statusBadge
                }

            case .subInterests(let category):
                HStack(spacing: 10) {
                    // Large, easy-to-tap Back Button (min 48pt height)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        resetGridScrollState()
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                            mode = .rootCategories
                            currentSubInterests = []
                            isRefreshingSubInterests = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .bold))
                            Image(systemName: category.iconName)
                                .font(.system(size: 16, weight: .semibold))
                            Text(category.localizedName(for: appLanguage))
                                .font(.system(size: 16, weight: .bold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: 48)
                        .background(
                            Capsule()
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(BentoRefreshButtonStyle())

                    Spacer(minLength: 4)

                    if isCooldownActive || isGenerating {
                        statusBadge
                    }

                    // Large, easy-to-tap Refresh Button (min 48pt height)
                    Button {
                        loadCategory(category, refresh: true)
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                                .rotationEffect(.degrees(isSynthesizing ? 360 : 0))
                                .animation(
                                    isSynthesizing
                                        ? .linear(duration: 0.85).repeatForever(autoreverses: false)
                                        : .spring(response: 0.3),
                                    value: isSynthesizing
                                )
                            Text(
                                isSynthesizing
                                    ? l10n.bentoRefreshing
                                    : l10n.bentoRefresh
                            )
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize()
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .frame(minHeight: 48)
                        .background(
                            Capsule()
                                .fill(isSynthesizing ? OmakaseTheme.ink.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isSynthesizing ? OmakaseTheme.ink.opacity(0.35) : Color.primary.opacity(0.14),
                                    lineWidth: 1
                                )
                        )
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(BentoRefreshButtonStyle())
                    .disabled(isSynthesizing || isGenerating)
                }

                Text(
                    isCooldownActive
                        ? l10n.bentoCooldownHint(seconds: cooldownRemaining)
                        : l10n.bentoSubtopicHint
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isGenerating {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text(l10n.bentoCooking)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(.secondary)
        } else if isCooldownActive {
            HStack(spacing: 6) {
                Image(systemName: "hourglass")
                    .font(.system(size: 13, weight: .bold))
                Text(l10n.shortSeconds(cooldownRemaining))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Bento Grid Canvas (2x6 Vertically Scrollable Categories & Sub-Topics)

    private var bentoGridCanvas: some View {
        ZStack {
            switch mode {
            case .rootCategories:
                verticalBentoScroll(id: "root", spacing: 12) {
                    ForEach(InterestCategory.presets) { category in
                        RootBentoTile(
                            category: category,
                            language: appLanguage,
                            isDisabled: isGenerating
                        ) {
                            openCategory(category)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.96).combined(with: .opacity),
                    removal: .scale(scale: 1.03).combined(with: .opacity)
                ))

            case .subInterests(let category):
                subInterestsBentoGrid(spacing: 10, category: category)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.04).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func verticalBentoScroll<Content: View>(
        id: String,
        spacing: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]

        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: spacing) {
                content()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 4)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: BentoGridScrollOffsetKey.self,
                            value: proxy.frame(in: .named("bentoGridScroll-\(id)")).minY
                        )
                }
            )
        }
        .id(id)
        .coordinateSpace(name: "bentoGridScroll-\(id)")
        .scrollBounceBehavior(.basedOnSize)
        .onPreferenceChange(BentoGridScrollOffsetKey.self) { minY in
            handleGridScrollOffset(minY)
        }
    }

    // MARK: - Sub-Interests Bento Grid (2x6 Vertical = 12 Total)

    private func subInterestsBentoGrid(
        spacing: CGFloat,
        category: InterestCategory
    ) -> some View {
        let isFilmCategory = (category.id == "film")
        let topicsCount = isFilmCategory ? 11 : 12
        let displayTopics = Array(currentSubInterests.prefix(topicsCount).enumerated())

        return verticalBentoScroll(id: "sub-\(category.id)", spacing: spacing) {
            if isFilmCategory {
                LetterboxdBentoTile(
                    username: storedLetterboxdUsername,
                    isDisabled: isGenerationDisabled,
                    l10n: l10n,
                    onTap: {
                        guard !isGenerationDisabled else { return }
                        let clean = storedLetterboxdUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                        if clean.isEmpty {
                            onPromptLetterboxdUsername?()
                        } else {
                            resetGridScrollState()
                            mode = .rootCategories
                            onSelectLetterboxdPost?()
                        }
                    },
                    onEditUsername: {
                        onPromptLetterboxdUsername?()
                    },
                    onDisconnectUsername: {
                        storedLetterboxdUsername = ""
                        isLetterboxdActive = false
                    }
                )
            }

            ForEach(displayTopics, id: \.element) { index, topic in
                let tileIndex = isFilmCategory ? (index + 1) : index
                SubInterestBentoTile(
                    title: topic,
                    isRevealed: tileIndex < revealedTilesCount,
                    isDisabled: isGenerationDisabled,
                    isRefreshing: isRefreshingSubInterests,
                    onTap: {
                        selectDedicatedTopic(topic)
                    }
                )
            }
        }
    }

    // MARK: - Scroll Hint Bar

    private var scrollHintBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.draw")
                .font(.caption.weight(.semibold))
            Text(
                mode == .rootCategories
                    ? l10n.bentoScrollCategoriesHint(count: InterestCategory.presets.count)
                    : l10n.bentoScrollSubtopicsHint
            )
            .font(.caption.weight(.medium))
            Spacer()
        }
        .foregroundStyle(.secondary)
    }

    private func resetGridScrollState() {
        scrollResetTask?.cancel()
        scrollResetTask = nil
        didScrollDeepInGrid = false
        hasTriggeredPullBack = false
    }

    private func handleGridScrollOffset(_ minY: CGFloat) {
        if minY < -18 {
            didScrollDeepInGrid = true
            scrollResetTask?.cancel()
            scrollResetTask = nil
            return
        }

        if minY >= -8 && minY <= 12 {
            hasTriggeredPullBack = false
            if didScrollDeepInGrid && scrollResetTask == nil {
                scrollResetTask = Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    guard !Task.isCancelled else { return }
                    didScrollDeepInGrid = false
                    scrollResetTask = nil
                }
            }
            return
        }

        if hasExistingPosts && !didScrollDeepInGrid && !hasTriggeredPullBack && minY > 56 {
            hasTriggeredPullBack = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onScrollToLastPost?()
        }
    }

    // MARK: - Active Interests Ribbon (Large Tappable Pills)

    private var activeInterestsRibbon: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Letterboxd pill if active
                if isLetterboxdActive {
                    HStack(spacing: 6) {
                        Image(systemName: "film.fill")
                            .font(.caption.weight(.semibold))
                        Text("Letterboxd")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(minHeight: 40)
                    .background(Color.green.opacity(0.16), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.green.opacity(0.45), lineWidth: 1))
                    .foregroundStyle(Color.green)
                }

                // Active User Interests
                ForEach(allInterests, id: \.self) { interest in
                    let isActive = activeInterests.contains(interest)

                    HStack(spacing: 4) {
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
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                                .padding(.leading, 14)
                                .padding(.trailing, 6)
                                .padding(.vertical, 9)
                        }
                        .buttonStyle(.plain)

                        // Large tap target for Remove 'x' button
                        Button {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                onRemoveInterest(interest)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(
                                    isActive
                                        ? OmakaseTheme.chipActiveText.opacity(0.75)
                                        : Color.secondary.opacity(0.8)
                                )
                                .frame(width: 34, height: 34)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 4)
                    }
                    .frame(minHeight: 40)
                    .background(
                        Capsule().fill(
                            isActive
                                ? OmakaseTheme.chipActiveFill
                                : Color(uiColor: .secondarySystemBackground)
                        )
                    )
                    .overlay(
                        Capsule().strokeBorder(
                            isActive ? Color.clear : Color.primary.opacity(0.14),
                            lineWidth: 1
                        )
                    )
                    .foregroundStyle(
                        isActive ? OmakaseTheme.chipActiveText : Color.primary
                    )
                }
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Game Mechanics & AI Synthesis

    private func openCategory(_ category: InterestCategory) {
        guard !isGenerating else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        resetGridScrollState()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            mode = .subInterests(category: category)
        }
        loadCategory(category)
    }

    private func loadCategory(_ category: InterestCategory, refresh: Bool = false) {
        let taskId = UUID()
        synthesisTaskId = taskId

        if refresh {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // 1. Instant 0ms Fast Path: serve pre-warmed or prefetched live AI batch from memory or disk
        if let readyMemoryBatch = prefetchedSubInterestsByCategory.removeValue(forKey: category.id), !readyMemoryBatch.isEmpty {
            SubTopicDiscoveryStore.shared.recordSeen(readyMemoryBatch, for: category.id, language: appLanguage)
            cachedSubInterestsByCategory[category.id] = readyMemoryBatch
            if refresh {
                withAnimation(.easeInOut(duration: 0.14)) {
                    currentSubInterests = readyMemoryBatch
                    revealedTilesCount = 0
                    isRefreshingSubInterests = false
                }
                animateStaggeredTiles(total: readyMemoryBatch.count)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                currentSubInterests = readyMemoryBatch
                revealedTilesCount = readyMemoryBatch.count
                isRefreshingSubInterests = false
            }
            isSynthesizing = false
            SubTopicDiscoveryStore.shared.replenishInBackground(
                for: category,
                language: appLanguage,
                additionalExcludes: allInterests + readyMemoryBatch
            )
            return
        }

        if let readyDiskBatch = SubTopicDiscoveryStore.shared.consumePrefetchedBatch(for: category.id, language: appLanguage), !readyDiskBatch.isEmpty {
            cachedSubInterestsByCategory[category.id] = readyDiskBatch
            if refresh {
                withAnimation(.easeInOut(duration: 0.14)) {
                    currentSubInterests = readyDiskBatch
                    revealedTilesCount = 0
                    isRefreshingSubInterests = false
                }
                animateStaggeredTiles(total: readyDiskBatch.count)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                currentSubInterests = readyDiskBatch
                revealedTilesCount = readyDiskBatch.count
                isRefreshingSubInterests = false
            }
            isSynthesizing = false
            SubTopicDiscoveryStore.shared.replenishInBackground(
                for: category,
                language: appLanguage,
                additionalExcludes: allInterests + readyDiskBatch
            )
            return
        }

        // 2. In-flight Live AI Path (if tapped in the first ~0.8s of launch before silent pre-warm completes):
        // Coalesces with the already-running launch pre-warm task, falling back to local 432 ONLY if offline/error.
        isSynthesizing = true
        withAnimation(.easeInOut(duration: 0.15)) {
            isRefreshingSubInterests = true
        }

        let excludeList = Array(Set(currentSubInterests + allInterests))

        Task {
            let liveBatch = await SubTopicDiscoveryStore.shared.consumeOrAwaitLiveBatch(
                for: category,
                language: appLanguage,
                additionalExcludes: excludeList
            )
            guard synthesisTaskId == taskId else { return }

            let resolvedTopics: [String]
            if let liveBatch, !liveBatch.isEmpty {
                resolvedTopics = liveBatch
            } else {
                // Offline-only backup: use local 432 curated pool only when network/API is unreachable
                resolvedTopics = SubTopicDiscoveryStore.shared.drawUnseenCuratedBatch(
                    for: category,
                    language: appLanguage,
                    additionalExcludes: excludeList,
                    count: 12
                )
            }

            await MainActor.run {
                cachedSubInterestsByCategory[category.id] = resolvedTopics
                withAnimation(.easeInOut(duration: 0.15)) {
                    currentSubInterests = resolvedTopics
                    revealedTilesCount = 0
                    isRefreshingSubInterests = false
                }
                animateStaggeredTiles(total: resolvedTopics.count)
                isSynthesizing = false
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    private func buildSubInterestBatch(
        for category: InterestCategory,
        excluding excludeList: [String]
    ) async -> [String] {
        var freshTopics: [String] = []
        do {
            let aiResults = try await CategoryExpansionService.expand(
                category: category.localizedName(for: appLanguage),
                existingInterests: excludeList,
                language: appLanguage
            )
            let lowerExcludes = Set(excludeList.map { $0.lowercased() })
            let appropriate = aiResults.filter {
                ContentModerationService.isAppropriate($0) && !lowerExcludes.contains($0.lowercased())
            }
            if appropriate.count >= 6 {
                freshTopics = Array(appropriate.prefix(12))
            }
        } catch {
            // Fall back to local unseen pool
        }

        if freshTopics.count < 12 {
            let needed = 12 - freshTopics.count
            let unseenFill = SubTopicDiscoveryStore.shared.drawUnseenCuratedBatch(
                for: category,
                language: appLanguage,
                additionalExcludes: excludeList + freshTopics,
                count: needed
            )
            freshTopics.append(contentsOf: unseenFill)
        }
        return freshTopics
    }

    private func prefetchNextSubInterests(for category: InterestCategory, currentShown: [String]) {
        guard prefetchedSubInterestsByCategory[category.id] == nil,
              !prefetchingCategoryIds.contains(category.id) else { return }
        prefetchingCategoryIds.insert(category.id)
        let seenHistory = SubTopicDiscoveryStore.shared.seenTopics(for: category.id, language: appLanguage)
        let excludeList = Array(Set(currentShown + allInterests + seenHistory))
        let catId = category.id
        let lang = appLanguage

        Task {
            let batch = await buildSubInterestBatch(for: category, excluding: excludeList)
            await MainActor.run {
                prefetchingCategoryIds.remove(catId)
                if !batch.isEmpty {
                    prefetchedSubInterestsByCategory[catId] = batch
                    SubTopicDiscoveryStore.shared.storePrefetchedBatch(batch, for: catId, language: lang)
                }
            }
        }
    }

    private func selectDedicatedTopic(_ topic: String) {
        guard !isGenerationDisabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let currentCatId: String?
        if case .subInterests(let category) = mode {
            currentCatId = category.id
        } else {
            currentCatId = InterestCategory.resolveMainCategory(tags: [topic], title: topic).id
        }
        resetGridScrollState()
        mode = .rootCategories
        onSelectDedicatedTopic?(topic, currentCatId)
    }

    private func animateStaggeredTiles(total: Int) {
        guard total > 0 else { return }
        for i in 1...total {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.015) {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
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
}

// MARK: - Root Bento Tile (Level 0 - 2x6 Grid Card)

private struct RootBentoTile: View {
    let category: InterestCategory
    let language: AppLanguage
    let isDisabled: Bool
    let onTap: () -> Void

    @State private var isPressed: Bool = false

    private var samplePreview: String {
        SubTopicDiscoveryStore.shared.rootPreview(for: category, language: language)
    }

    var body: some View {
        Button {
            guard !isDisabled else { return }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(OmakaseTheme.wash)
                            .frame(width: 36, height: 36)

                        Image(systemName: category.iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isDisabled ? Color.secondary.opacity(0.5) : OmakaseTheme.ink)
                    }
                    .scaleEffect(isPressed ? 1.08 : 1.0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressed)

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 26, height: 26)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(isPressed ? Color.primary : Color.secondary)
                    }
                    .offset(x: isPressed ? 2.5 : 0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressed)
                }

                Spacer(minLength: 4)

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.localizedName(for: language))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isDisabled ? Color.secondary : Color.primary)
                        .lineLimit(1)

                    Text(samplePreview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 100, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isPressed ? OmakaseTheme.ink.opacity(0.08) : Color(uiColor: .secondarySystemBackground).opacity(0.65))
                    .shadow(
                        color: .black.opacity(isPressed ? 0.01 : (isDisabled ? 0.01 : 0.04)),
                        radius: isPressed ? 1 : 4,
                        y: isPressed ? 0.5 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isPressed ? OmakaseTheme.ink.opacity(0.55) : Color.primary.opacity(isDisabled ? 0.06 : 0.13),
                        lineWidth: isPressed ? 1.6 : 1
                    )
            )
            .offset(y: isPressed ? 1.5 : 0)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isDisabled ? 0.45 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.68), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isDisabled)
        }
        .buttonStyle(BentoPressButtonStyle(isPressed: $isPressed))
        .disabled(isDisabled)
    }
}

// MARK: - Sub-Interest Bento Tile (2x6 Single-Shot Dedicated Post Generator)

private struct SubInterestBentoTile: View {
    let title: String
    let isRevealed: Bool
    let isDisabled: Bool
    let isRefreshing: Bool
    let onTap: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            guard !isDisabled && !isRefreshing else { return }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(isDisabled ? Color.secondary.opacity(0.5) : OmakaseTheme.ink.opacity(0.85))
                        .scaleEffect(isPressed ? 1.12 : 1.0)
                        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressed)

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 22, height: 22)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isDisabled ? Color.secondary.opacity(0.3) : Color.secondary)
                    }
                    .offset(x: isPressed ? 1.5 : 0, y: isPressed ? -1.5 : 0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressed)
                }

                Spacer(minLength: 0)

                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .lineSpacing(1.5)
                    .lineLimit(4)
                    .minimumScaleFactor(0.80)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(isDisabled ? Color.secondary : Color.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 98, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isPressed ? OmakaseTheme.ink.opacity(0.08) : Color(uiColor: .secondarySystemBackground).opacity(0.65))
                    .shadow(
                        color: .black.opacity(isPressed ? 0.01 : 0.03),
                        radius: isPressed ? 1 : 3,
                        y: isPressed ? 0.5 : 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isPressed ? OmakaseTheme.ink.opacity(0.55) : Color.primary.opacity(isDisabled ? 0.06 : 0.13),
                        lineWidth: isPressed ? 1.5 : 1
                    )
            )
            .offset(y: isPressed ? 1.5 : 0)
            .scaleEffect(isRefreshing ? 0.96 : (isRevealed ? (isPressed ? 0.96 : 1.0) : 0.78))
            .opacity(isRefreshing ? 0.45 : (isRevealed ? (isDisabled ? 0.45 : 1.0) : 0.0))
            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: isRevealed)
            .animation(.spring(response: 0.2, dampingFraction: 0.68), value: isPressed)
            .animation(.easeInOut(duration: 0.22), value: isRefreshing)
        }
        .buttonStyle(BentoPressButtonStyle(isPressed: $isPressed))
        .disabled(isDisabled || isRefreshing)
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

// MARK: - Bento Refresh Button Style

private struct BentoRefreshButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.78 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
    }
}

// MARK: - Letterboxd Distinct Bento Tile (Permanent Top-Left in Film Category)

private struct LetterboxdBentoTile: View {
    let username: String
    let isDisabled: Bool
    let l10n: L10n
    let onTap: () -> Void
    let onEditUsername: () -> Void
    let onDisconnectUsername: () -> Void

    @State private var isPressed: Bool = false

    private var isConnected: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Button {
            guard !isDisabled else { return }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: 0x00E054).opacity(0.18))
                            .frame(width: 32, height: 32)

                        Image(systemName: isConnected ? "popcorn.fill" : "film.stack.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x00E054))
                    }

                    HStack(spacing: 4) {
                        Text("LETTERBOXD")
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: 0x00E054))
                            .lineLimit(1)

                        if isConnected {
                            Circle()
                                .fill(Color(hex: 0x00E054))
                                .frame(width: 4, height: 4)
                        }
                    }

                    Spacer(minLength: 2)

                    Image(systemName: isConnected ? "sparkles" : "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x00E054).opacity(0.9))
                }

                Spacer(minLength: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isConnected ? l10n.letterboxdRecentFilms : l10n.letterboxdConnectDiary)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                        .lineLimit(2)

                    if isConnected {
                        Text("@\(username)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 98, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: 0x14181C))
                    .shadow(
                        color: Color(hex: 0x00E054).opacity(isPressed ? 0.25 : 0.12),
                        radius: isPressed ? 1 : 4,
                        y: isPressed ? 0.5 : 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(hex: 0x00E054).opacity(isPressed ? 0.95 : 0.65),
                                Color(hex: 0x00A83E).opacity(isPressed ? 0.8 : 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isPressed ? 1.5 : 1.1
                    )
            )
            .offset(y: isPressed ? 1.5 : 0)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.68), value: isPressed)
        }
        .buttonStyle(BentoPressButtonStyle(isPressed: $isPressed))
        .disabled(isDisabled)
        .contextMenu {
            Button {
                onEditUsername()
            } label: {
                Label(
                    isConnected
                        ? l10n.letterboxdChangeUsername
                        : l10n.letterboxdConnectAction,
                    systemImage: "person.crop.circle.badge.checkmark"
                )
            }

            if isConnected {
                Button(role: .destructive) {
                    onDisconnectUsername()
                } label: {
                    Label(
                        l10n.disconnectAction,
                        systemImage: "xmark.circle"
                    )
                }
            }
        }
    }
}

private struct BentoGridScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
