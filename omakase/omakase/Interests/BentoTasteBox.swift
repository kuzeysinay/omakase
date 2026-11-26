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
    var outerBottomOverscroll: CGFloat = 0
    var isOuterScrollDragging: Bool = false
    var onScrollToLastPost: (() -> Void)? = nil
    var onSelectDedicatedTopic: ((String, String?) -> Void)? = nil
    var onPromptLetterboxdUsername: (() -> Void)? = nil
    var onSelectLetterboxdPost: (() -> Void)? = nil
    var onTriggerChefPick: ((InterestCategory?, String) -> Void)? = nil
    var initialSubtopicCategory: InterestCategory? = nil
    var initialSubtopics: [String] = []
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

    // Nested vertical scroll -> return to previous post / bottom overscroll Chef's Pick
    @State private var didScrollDeepInGrid: Bool = false
    @State private var hasTriggeredPullBack: Bool = false
    @State private var bottomOverscroll: CGFloat = 0
    @State private var isInnerScrollDragging: Bool = false
    @State private var isChefPickArmed: Bool = false
    @State private var hasTriggeredChefPick: Bool = false
    @State private var scrollResetTask: Task<Void, Never>?
    private let chefPickDeadZone: CGFloat = 38
    private let chefPickThreshold: CGFloat = 155

    private var isDraggingScroll: Bool {
        isInnerScrollDragging || isOuterScrollDragging
    }

    private var effectiveBottomOverscroll: CGFloat {
        max(bottomOverscroll, outerBottomOverscroll)
    }

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
                    .padding(.bottom, 8)
            }

            // Thumb-zone frictionless Chef's Pick bar (tap or swipe up)
            if onTriggerChefPick != nil {
                chefPickBottomBar
                    .padding(.horizontal, 18)
                    .padding(.top, mode == .rootCategories ? 6 : 0)
                    .padding(.bottom, allInterests.isEmpty ? 16 : 10)
            }

            // Bottom controls: Active interests ribbon
            if !allInterests.isEmpty {
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
            if let initialSubtopicCategory, currentSubInterests.isEmpty {
                var noAnim = Transaction()
                noAnim.disablesAnimations = true
                withTransaction(noAnim) {
                    mode = .subInterests(category: initialSubtopicCategory)
                    let topics = initialSubtopics.isEmpty
                        ? initialSubtopicCategory.fallbackInterests(for: appLanguage)
                        : initialSubtopics
                    currentSubInterests = topics
                    revealedTilesCount = topics.count
                }
            }
            SubTopicDiscoveryStore.shared.prewarmAllCategories(language: appLanguage, userInterests: allInterests)
        }
        .onChange(of: outerBottomOverscroll) { _, _ in
            evaluateChefPickOverscroll()
        }
        .onChange(of: isOuterScrollDragging) { wasDragging, isDragging in
            handleDragStateTransition(wasDragging: wasDragging, isDragging: isDragging)
        }
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
                            .accessibilityIdentifier("bento.root.title")

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
                    .accessibilityIdentifier("bento.subtopics.backButton")

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
                    .accessibilityIdentifier("bento.subtopics.refreshButton")
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
        let builtContent = content()

        GeometryReader { viewportGeo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        builtContent
                    }

                    if onTriggerChefPick != nil {
                        chefPickOverscrollFooter
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
                .background(ImmediateTouchScrollConfigurator().allowsHitTesting(false))
                .background(
                    GeometryReader { proxy in
                        let frame = proxy.frame(in: .named("bentoGridScroll-\(id)"))
                        Color.clear
                            .preference(
                                key: BentoGridScrollMetricsKey.self,
                                value: BentoGridScrollMetrics(
                                    minY: frame.minY,
                                    maxY: frame.maxY,
                                    contentHeight: frame.height
                                )
                            )
                    }
                )
            }
            .id(id)
            .coordinateSpace(name: "bentoGridScroll-\(id)")
            .scrollBounceBehavior(.always, axes: .vertical)
            .onPreferenceChange(BentoGridScrollMetricsKey.self) { metrics in
                handleGridScrollMetrics(metrics, viewportHeight: viewportGeo.size.height)
            }
            .onBottomOverscrollChange { overscroll in
                guard onTriggerChefPick != nil else { return }
                bottomOverscroll = overscroll
                evaluateChefPickOverscroll()
            }
            .onScrollDraggingChange { dragging in
                let wasDragging = isInnerScrollDragging
                isInnerScrollDragging = dragging
                handleDragStateTransition(wasDragging: wasDragging, isDragging: dragging)
            }
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
                    isLimitReached: AccessManager.shared.isLetterboxdLimitReached,
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
                    identifier: "bento.subtopic.\(index)",
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
        bottomOverscroll = 0
        isInnerScrollDragging = false
        isChefPickArmed = false
        hasTriggeredChefPick = false
    }

    private func handleGridScrollMetrics(_ metrics: BentoGridScrollMetrics, viewportHeight: CGFloat) {
        handleGridScrollOffset(metrics.minY)

        if #available(iOS 18.0, *) {
            return
        }
        guard viewportHeight > 0, metrics.contentHeight > 0, onTriggerChefPick != nil else { return }
        let effectiveBottom = min(viewportHeight, metrics.contentHeight)
        bottomOverscroll = max(0, effectiveBottom - metrics.maxY)
        evaluateChefPickOverscroll()
    }

    private func evaluateChefPickOverscroll() {
        guard onTriggerChefPick != nil else { return }
        let overscroll = effectiveBottomOverscroll

        if !isDraggingScroll && !isChefPickArmed && overscroll < 8 {
            hasTriggeredChefPick = false
        }

        guard isDraggingScroll, !isGenerationDisabled else { return }

        if !isChefPickArmed && overscroll >= chefPickThreshold {
            isChefPickArmed = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else if isChefPickArmed && overscroll < chefPickThreshold * 0.78 {
            isChefPickArmed = false
        }
    }

    private func handleDragStateTransition(wasDragging: Bool, isDragging: Bool) {
        guard onTriggerChefPick != nil else { return }
        if wasDragging && !isDragging {
            if isChefPickArmed && !isGenerationDisabled && !hasTriggeredChefPick {
                hasTriggeredChefPick = true
                isChefPickArmed = false
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                triggerChefPick(source: "overscroll")
            } else {
                isChefPickArmed = false
            }
        }
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

    private func triggerChefPick(source: String) {
        guard !isGenerationDisabled else { return }
        let preferredCategory: InterestCategory?
        if case .subInterests(let category) = mode {
            preferredCategory = category
        } else {
            preferredCategory = nil
        }
        resetGridScrollState()
        mode = .rootCategories
        onTriggerChefPick?(preferredCategory, source)
    }

    private var chefPickPromptText: String {
        if case .subInterests(let category) = mode {
            return l10n.chefPickCategoryHint(category.localizedName(for: appLanguage))
        }
        return l10n.chefPickTitle
    }

    private var chefPickOverscrollFooter: some View {
        let visibleOverscroll = (isDraggingScroll || isChefPickArmed) ? effectiveBottomOverscroll : 0
        let isReady = isChefPickArmed
        let rawProgress = min(1, max(0, (visibleOverscroll - chefPickDeadZone) / max(1, chefPickThreshold - chefPickDeadZone)))
        let progress: CGFloat = isReady ? 1.0 : pow(rawProgress, 1.65)

        return Button {
            guard !isGenerationDisabled else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            triggerChefPick(source: "footer_tap")
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image("AppLogo")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(OmakaseTheme.ink)

                    Text(isReady ? l10n.chefPickReleaseHint : l10n.chefPickPullHint)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isReady ? OmakaseTheme.ink : .secondary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if isCooldownActive {
                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 11, weight: .bold))
                            Text(l10n.shortSeconds(cooldownRemaining))
                                .font(.caption2.weight(.bold).monospacedDigit())
                        }
                        .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: isReady ? "checkmark.circle.fill" : "arrow.down.circle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isReady ? OmakaseTheme.ink : .secondary)
                    }
                }

                GeometryReader { barGeo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(OmakaseTheme.ink.opacity(0.08))
                        Capsule()
                            .fill(OmakaseTheme.ink)
                            .frame(width: max(0, barGeo.size.width * progress))
                    }
                }
                .frame(height: 3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isReady ? OmakaseTheme.ink.opacity(0.45) : OmakaseTheme.stroke,
                        lineWidth: isReady ? 1.2 : 0.8
                    )
            )
            .opacity(isGenerationDisabled ? 0.5 : 1.0)
            .animation(.easeOut(duration: 0.14), value: isReady)
        }
        .buttonStyle(OmakaseChipButtonStyle())
        .disabled(isGenerationDisabled)
        .padding(.top, 2)
        .padding(.bottom, 8)
    }

    private var chefPickBottomBar: some View {
        Button {
            guard !isGenerationDisabled else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            triggerChefPick(source: "bar_tap")
        } label: {
            HStack(spacing: 10) {
                Image("AppLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(OmakaseTheme.ink)

                Text(chefPickPromptText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OmakaseTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 6)

                HStack(spacing: 5) {
                    if isGenerating {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(OmakaseTheme.chipActiveText)
                    } else if isCooldownActive {
                        Image(systemName: "hourglass")
                            .font(.system(size: 11, weight: .bold))
                        Text(l10n.shortSeconds(cooldownRemaining))
                            .font(.caption.weight(.bold).monospacedDigit())
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                        Text(l10n.chefPickButtonCTA)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(OmakaseTheme.chipActiveText)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(OmakaseTheme.chipActiveFill, in: Capsule())
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .padding(.vertical, 7)
            .background(OmakaseTheme.wash, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 0.9)
            )
            .opacity(isGenerationDisabled ? 0.55 : 1.0)
        }
        .buttonStyle(OmakaseChipButtonStyle())
        .disabled(isGenerationDisabled)
        .accessibilityIdentifier("bento.chefPickBar")
    }

    // MARK: - Active Interests Ribbon (Large Tappable Pills)

    private var activeInterestsRibbon: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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
        let pinnedPreviewTopics = refresh
            ? []
            : SubTopicDiscoveryStore.shared.rootPreviewTopics(for: category, language: appLanguage)

        if refresh {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // 1. Instant 0ms Fast Path: serve pre-warmed or prefetched live AI batch from memory or disk
        if let readyMemoryBatch = prefetchedSubInterestsByCategory.removeValue(forKey: category.id), !readyMemoryBatch.isEmpty {
            let resolvedBatch = refresh
                ? readyMemoryBatch
                : mergePreviewTopics(pinnedPreviewTopics, into: readyMemoryBatch)
            if refresh {
                SubTopicDiscoveryStore.shared.updateSessionPreview(
                    for: category.id,
                    language: appLanguage,
                    topics: resolvedBatch
                )
            }
            SubTopicDiscoveryStore.shared.recordSeen(resolvedBatch, for: category.id, language: appLanguage)
            cachedSubInterestsByCategory[category.id] = resolvedBatch
            if refresh {
                withAnimation(.easeInOut(duration: 0.14)) {
                    currentSubInterests = resolvedBatch
                    revealedTilesCount = 0
                    isRefreshingSubInterests = false
                }
                animateStaggeredTiles(total: resolvedBatch.count)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                currentSubInterests = resolvedBatch
                revealedTilesCount = resolvedBatch.count
                isRefreshingSubInterests = false
            }
            isSynthesizing = false
            SubTopicDiscoveryStore.shared.replenishInBackground(
                for: category,
                language: appLanguage,
                additionalExcludes: allInterests + resolvedBatch
            )
            return
        }

        if let readyDiskBatch = SubTopicDiscoveryStore.shared.consumePrefetchedBatch(for: category.id, language: appLanguage), !readyDiskBatch.isEmpty {
            let resolvedBatch = refresh
                ? readyDiskBatch
                : mergePreviewTopics(pinnedPreviewTopics, into: readyDiskBatch)
            if refresh {
                SubTopicDiscoveryStore.shared.updateSessionPreview(
                    for: category.id,
                    language: appLanguage,
                    topics: resolvedBatch
                )
            }
            cachedSubInterestsByCategory[category.id] = resolvedBatch
            if refresh {
                withAnimation(.easeInOut(duration: 0.14)) {
                    currentSubInterests = resolvedBatch
                    revealedTilesCount = 0
                    isRefreshingSubInterests = false
                }
                animateStaggeredTiles(total: resolvedBatch.count)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                currentSubInterests = resolvedBatch
                revealedTilesCount = resolvedBatch.count
                isRefreshingSubInterests = false
            }
            isSynthesizing = false
            SubTopicDiscoveryStore.shared.replenishInBackground(
                for: category,
                language: appLanguage,
                additionalExcludes: allInterests + resolvedBatch
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

            let rawTopics: [String]
            if let liveBatch, !liveBatch.isEmpty {
                rawTopics = liveBatch
            } else {
                // Offline-only backup: use local 432 curated pool only when network/API is unreachable
                rawTopics = SubTopicDiscoveryStore.shared.drawUnseenCuratedBatch(
                    for: category,
                    language: appLanguage,
                    additionalExcludes: excludeList,
                    count: 12
                )
            }
            let resolvedTopics = refresh
                ? rawTopics
                : mergePreviewTopics(pinnedPreviewTopics, into: rawTopics)

            await MainActor.run {
                if refresh {
                    SubTopicDiscoveryStore.shared.updateSessionPreview(
                        for: category.id,
                        language: appLanguage,
                        topics: resolvedTopics
                    )
                }
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

    private func mergePreviewTopics(_ previewTopics: [String], into batch: [String], limit: Int = 12) -> [String] {
        guard !previewTopics.isEmpty else { return Array(batch.prefix(limit)) }
        var merged: [String] = []
        var seenLower = Set<String>()
        for topic in previewTopics + batch {
            let clean = topic.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { continue }
            let lower = clean.lowercased()
            if seenLower.insert(lower).inserted {
                merged.append(clean)
                if merged.count >= limit { break }
            }
        }
        return merged
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
                            .fill(isPressed ? OmakaseTheme.ink.opacity(0.14) : OmakaseTheme.wash)
                            .frame(width: 36, height: 36)

                        Image(systemName: category.iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isDisabled ? Color.secondary.opacity(0.5) : OmakaseTheme.ink)
                    }
                    .scaleEffect(isPressed ? 1.06 : 1.0)
                    .animation(isPressed ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28), value: isPressed)

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(isPressed ? OmakaseTheme.ink.opacity(0.13) : Color.primary.opacity(0.05))
                            .frame(width: 26, height: 26)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(isPressed ? Color.primary : Color.secondary)
                    }
                    .offset(x: isPressed ? 2.0 : 0)
                    .animation(isPressed ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28), value: isPressed)
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
                    .fill(isPressed ? OmakaseTheme.ink.opacity(0.11) : Color(uiColor: .secondarySystemBackground).opacity(0.65))
                    .shadow(
                        color: .black.opacity(isPressed ? 0.03 : (isDisabled ? 0.01 : 0.04)),
                        radius: isPressed ? 4 : 4,
                        y: isPressed ? 1 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isPressed ? OmakaseTheme.ink.opacity(0.42) : Color.primary.opacity(isDisabled ? 0.06 : 0.13),
                        lineWidth: isPressed ? 1.4 : 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(isPressed ? 0.968 : 1.0)
            .opacity(isDisabled ? 0.45 : 1.0)
            .animation(isPressed ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isDisabled)
        }
        .buttonStyle(BentoPressButtonStyle(isPressed: $isPressed))
        .disabled(isDisabled)
        .accessibilityIdentifier("bento.category.\(category.id)")
    }
}

// MARK: - Sub-Interest Bento Tile (2x6 Single-Shot Dedicated Post Generator)

private struct SubInterestBentoTile: View {
    let title: String
    let identifier: String
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
                        .scaleEffect(isPressed ? 1.08 : 1.0)
                        .animation(isPressed ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28), value: isPressed)

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(isPressed ? OmakaseTheme.ink.opacity(0.13) : Color.primary.opacity(0.05))
                            .frame(width: 22, height: 22)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isDisabled ? Color.secondary.opacity(0.3) : (isPressed ? Color.primary : Color.secondary))
                    }
                    .offset(x: isPressed ? 1.5 : 0, y: isPressed ? -1.5 : 0)
                    .animation(isPressed ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28), value: isPressed)
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
                    .fill(isPressed ? OmakaseTheme.ink.opacity(0.11) : Color(uiColor: .secondarySystemBackground).opacity(0.65))
                    .shadow(
                        color: .black.opacity(isPressed ? 0.03 : 0.03),
                        radius: isPressed ? 4 : 3,
                        y: isPressed ? 1 : 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isPressed ? OmakaseTheme.ink.opacity(0.42) : Color.primary.opacity(isDisabled ? 0.06 : 0.13),
                        lineWidth: isPressed ? 1.4 : 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(isRefreshing ? 0.96 : (isRevealed ? (isPressed ? 0.968 : 1.0) : 0.78))
            .opacity(isRefreshing ? 0.45 : (isRevealed ? (isDisabled ? 0.45 : 1.0) : 0.0))
            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: isRevealed)
            .animation(isPressed ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28), value: isPressed)
            .animation(.easeInOut(duration: 0.22), value: isRefreshing)
        }
        .buttonStyle(BentoPressButtonStyle(isPressed: $isPressed))
        .disabled(isDisabled || isRefreshing)
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - Bento Press Button Style (Minimum Visible Dwell + Smooth Release)

private struct BentoPressButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    @State private var pressStartedAt: Date = .distantPast
    @State private var releaseTask: Task<Void, Never>?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    releaseTask?.cancel()
                    releaseTask = nil
                    pressStartedAt = Date()
                    isPressed = true
                } else {
                    let elapsed = Date().timeIntervalSince(pressStartedAt)
                    let minDwell: TimeInterval = 0.18
                    let remaining = max(0, minDwell - elapsed)
                    if remaining <= 0.01 {
                        isPressed = false
                    } else {
                        releaseTask?.cancel()
                        releaseTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(Int(remaining * 1000)))
                            guard !Task.isCancelled else { return }
                            isPressed = false
                            releaseTask = nil
                        }
                    }
                }
            }
    }
}

// MARK: - Immediate Touch All-Layers UIScrollView Configurator

private struct ImmediateTouchScrollConfigurator: UIViewRepresentable {
    func makeUIView(context: Context) -> ScrollConfigProbeView {
        ScrollConfigProbeView()
    }

    func updateUIView(_ uiView: ScrollConfigProbeView, context: Context) {
        uiView.configureAllEnclosingScrollViews()
    }

    final class ScrollConfigProbeView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            configureAllEnclosingScrollViews()
            DispatchQueue.main.async { [weak self] in
                self?.configureAllEnclosingScrollViews()
            }
        }

        func configureAllEnclosingScrollViews() {
            var ancestor: UIView? = superview
            while let current = ancestor {
                if let scrollView = current as? UIScrollView {
                    if scrollView.delaysContentTouches {
                        scrollView.delaysContentTouches = false
                    }
                    scrollView.canCancelContentTouches = true
                }
                ancestor = current.superview
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
    let isLimitReached: Bool
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
                            .fill(Color(hex: 0x00E054).opacity(isPressed ? 0.22 : 0.18))
                            .frame(width: 32, height: 32)

                        Image(systemName: isConnected ? "popcorn.fill" : "film.stack.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x00E054))
                    }
                    .scaleEffect(isPressed ? 1.06 : 1.0)
                    .animation(isPressed ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28), value: isPressed)

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

                    if isConnected && isLimitReached {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8.5, weight: .bold))
                            Text("PRO")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        }
                        .foregroundStyle(Color(hex: 0x00E054))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0x00E054).opacity(0.16), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color(hex: 0x00E054).opacity(0.45), lineWidth: 0.8)
                        )
                    } else {
                        Image(systemName: isConnected ? "sparkles" : "plus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x00E054).opacity(0.9))
                    }
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
                        color: Color(hex: 0x00E054).opacity(isPressed ? 0.22 : 0.12),
                        radius: isPressed ? 5 : 4,
                        y: isPressed ? 1 : 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(hex: 0x00E054).opacity(isPressed ? 0.85 : 0.65),
                                Color(hex: 0x00A83E).opacity(isPressed ? 0.70 : 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isPressed ? 1.4 : 1.1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(isPressed ? 0.968 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(isPressed ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28), value: isPressed)
        }
        .buttonStyle(BentoPressButtonStyle(isPressed: $isPressed))
        .disabled(isDisabled)
        .accessibilityIdentifier("bento.letterboxdTile")
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

private struct BentoGridScrollMetrics: Equatable {
    let minY: CGFloat
    let maxY: CGFloat
    let contentHeight: CGFloat
}

private struct BentoGridScrollMetricsKey: PreferenceKey {
    static var defaultValue = BentoGridScrollMetrics(minY: 0, maxY: 0, contentHeight: 0)
    static func reduce(value: inout BentoGridScrollMetrics, nextValue: () -> BentoGridScrollMetrics) {
        value = nextValue()
    }
}

extension View {
    @ViewBuilder
    func onBottomOverscrollChange(_ action: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18.0, *) {
            self.onScrollGeometryChange(for: CGFloat.self) { geo in
                guard geo.containerSize.height > 0, geo.contentSize.height > 0 else { return 0 }
                let maxOffset = max(
                    -geo.contentInsets.top,
                    geo.contentSize.height - geo.containerSize.height + geo.contentInsets.bottom
                )
                return max(0, geo.contentOffset.y - maxOffset)
            } action: { _, overscroll in
                action(overscroll)
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func onScrollDraggingChange(_ action: @escaping (Bool) -> Void) -> some View {
        if #available(iOS 18.0, *) {
            self.onScrollPhaseChange { _, newPhase in
                action(newPhase == .interacting)
            }
        } else {
            self
        }
    }
}
