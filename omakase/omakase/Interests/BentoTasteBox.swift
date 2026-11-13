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
    var isCooldownActive: Bool = false
    var cooldownRemaining: Int = 0
    var cooldownTotal: Int = 0
    var hasExistingPosts: Bool = false
    var onScrollToLastPost: (() -> Void)? = nil
    var onSelectDedicatedTopic: ((String) -> Void)? = nil
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
    @State private var revealedTilesCount: Int = 0
    @State private var justAddedInterest: String? = nil

    // Manual text entry
    @State private var manualText: String = ""
    @FocusState private var isManualFieldFocused: Bool

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

            // Scroll hint caption
            scrollHintBar
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 10)

            // Bottom controls: Active interests ribbon + Custom topic input bar
            VStack(spacing: 10) {
                if !allInterests.isEmpty || isLetterboxdActive {
                    activeInterestsRibbon
                }

                manualInputBar
                    .padding(.horizontal, 18)
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            if isManualFieldFocused {
                isManualFieldFocused = false
            }
        }
        .onChange(of: appLanguage) { _, _ in
            cachedSubInterestsByCategory.removeAll()
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: mode)
    }

    // MARK: - Back to Feed Banner

    private var backToFeedBanner: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            isManualFieldFocused = false
            onScrollToLastPost?()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OmakaseTheme.ink)
                Text(appLanguage == .turkish ? "Son gönderiye dönmek için yukarı kaydır veya dokun" : "Swipe up or tap to return to last post")
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
                        Text(appLanguage == .turkish ? "Kategoriler" : "Categories")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)

                        Text(
                            appLanguage == .turkish
                                ? "Bir kategori seç ve alt konuya dokunarak yeni post üret"
                                : "Select a category and tap a subtopic to craft a new post"
                        )
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
                                    ? (appLanguage == .turkish ? "Yenileniyor…" : "Refreshing…")
                                    : (appLanguage == .turkish ? "Yenile" : "Refresh")
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
                        ? (appLanguage == .turkish
                            ? "Okuma süresi (\(cooldownRemaining) sn) tamamlandığında bir alt konuya dokunarak post üretebilirsin."
                            : "Once reading cooldown (\(cooldownRemaining)s) ends, tap any subtopic to generate a post.")
                        : (appLanguage == .turkish
                            ? "Post üretmek için aşağıdaki alt konulardan birine dokun"
                            : "Tap any subtopic below to generate a dedicated post")
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
                Text(appLanguage == .turkish ? "Hazırlanıyor…" : "Cooking…")
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
                Text(appLanguage == .turkish ? "\(cooldownRemaining) sn" : "\(cooldownRemaining)s")
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
                    isDisabled: isGenerating || isCooldownActive,
                    l10n: l10n,
                    onTap: {
                        guard !isGenerating && !isCooldownActive else { return }
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
                    isDisabled: isGenerating || isCooldownActive,
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
                    ? (appLanguage == .turkish
                        ? "Tüm kategorileri görmek için aşağı kaydır (\(InterestCategory.presets.count) kategori)"
                        : "Scroll down to browse all \(InterestCategory.presets.count) categories")
                    : (appLanguage == .turkish
                        ? "Daha fazla alt konu için aşağı kaydır"
                        : "Scroll down for more subtopics")
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
            isManualFieldFocused = false
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

    // MARK: - Manual Input Bar (Large & Easy to Tap)

    private var manualInputBar: some View {
        let trimmed = manualText.trimmingCharacters(in: .whitespacesAndNewlines)
        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            TextField(
                appLanguage == .turkish ? "Kendi konunu yaz veya ilgi ekle…" : "Type a custom topic or add taste…",
                text: $manualText
            )
            .font(.body)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($isManualFieldFocused)
            .submitLabel(.go)
            .onSubmit {
                if !trimmed.isEmpty {
                    if !isGenerating && !isCooldownActive {
                        submitCustomTopicForPost()
                    } else {
                        commitManualInput()
                    }
                }
            }

            if !trimmed.isEmpty {
                // Add to tastes button (44x44 tap target)
                Button(action: commitManualInput) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Generate dedicated post on this custom topic
                Button(action: submitCustomTopicForPost) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.bold))
                        Text(appLanguage == .turkish ? "Üret" : "Create")
                            .font(.subheadline.weight(.bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(OmakaseTheme.chipActiveFill, in: Capsule())
                    .foregroundStyle(OmakaseTheme.chipActiveText)
                }
                .buttonStyle(.plain)
                .disabled(isGenerating || isCooldownActive)
                .opacity((isGenerating || isCooldownActive) ? 0.45 : 1.0)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minHeight: 50)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
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
            isSynthesizing = true
            withAnimation(.easeInOut(duration: 0.22)) {
                isRefreshingSubInterests = true
            }

            let startTime = CACurrentMediaTime()
            let excludeList = Array(Set(currentSubInterests + allInterests))

            Task {
                var freshTopics: [String] = []

                do {
                    let aiResults = try await CategoryExpansionService.expand(
                        category: category.localizedName(for: appLanguage),
                        existingInterests: excludeList,
                        language: appLanguage
                    )
                    guard synthesisTaskId == taskId else { return }

                    let appropriate = aiResults.filter { ContentModerationService.isAppropriate($0) }
                    if appropriate.count >= 6 {
                        freshTopics = Array(appropriate.prefix(12))
                    }
                } catch {
                    // Fall back to local pool
                }

                guard synthesisTaskId == taskId else { return }

                // Ensure we have 12 topics for the 2x6 grid, topping up from fallback pool if needed
                if freshTopics.count < 12 {
                    var pool = category.fallbackInterests(for: appLanguage).filter {
                        !currentSubInterests.contains($0) && !freshTopics.contains($0)
                    }
                    pool.shuffle()
                    freshTopics.append(contentsOf: pool.prefix(12 - freshTopics.count))
                    if freshTopics.count < 12 {
                        let fallbackAll = category.fallbackInterests(for: appLanguage).filter { !freshTopics.contains($0) }.shuffled()
                        freshTopics.append(contentsOf: fallbackAll.prefix(12 - freshTopics.count))
                    }
                }

                // Guarantee a perceptible, comfortable transition window (min 450ms)
                let elapsed = CACurrentMediaTime() - startTime
                if elapsed < 0.45 {
                    try? await Task.sleep(nanoseconds: UInt64((0.45 - elapsed) * 1_000_000_000))
                }
                guard synthesisTaskId == taskId else { return }

                await MainActor.run {
                    cachedSubInterestsByCategory[category.id] = freshTopics
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentSubInterests = freshTopics
                        revealedTilesCount = 0
                        isRefreshingSubInterests = false
                    }
                    animateStaggeredTiles(total: freshTopics.count)
                    isSynthesizing = false
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        } else {
            // Do not auto-refresh on category open; keep existing subtopics as-is
            let existingTopics: [String]
            if let cached = cachedSubInterestsByCategory[category.id], !cached.isEmpty {
                existingTopics = cached
            } else {
                let initial12 = Array(category.fallbackInterests(for: appLanguage).prefix(12))
                cachedSubInterestsByCategory[category.id] = initial12
                existingTopics = initial12
            }
            currentSubInterests = existingTopics
            revealedTilesCount = existingTopics.count
            isSynthesizing = false
            isRefreshingSubInterests = false
        }
    }

    private func selectDedicatedTopic(_ topic: String) {
        guard !isGenerating && !isCooldownActive else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isManualFieldFocused = false
        resetGridScrollState()
        mode = .rootCategories
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
    }

    private func submitCustomTopicForPost() {
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
        if !isGenerating && !isCooldownActive {
            selectDedicatedTopic(trimmed)
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
        Array(category.fallbackInterests(for: language).prefix(2)).joined(separator: " · ")
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.localizedName(for: language))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isDisabled ? Color.secondary : Color.primary)
                        .lineLimit(1)

                    Text(samplePreview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 96, maxHeight: .infinity, alignment: .leading)
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
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(OmakaseTheme.wash)
                            .frame(width: 32, height: 32)

                        Image(systemName: "sparkles")
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(isDisabled ? Color.secondary.opacity(0.6) : OmakaseTheme.ink)
                    }
                    .scaleEffect(isPressed ? 1.12 : 1.0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressed)

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 26, height: 26)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isDisabled ? Color.secondary.opacity(0.3) : Color.secondary)
                    }
                    .offset(x: isPressed ? 1.5 : 0, y: isPressed ? -1.5 : 0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.65), value: isPressed)
                }

                Spacer(minLength: 4)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(isDisabled ? Color.secondary : Color.primary)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 94, maxHeight: .infinity, alignment: .leading)
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
            .frame(maxWidth: .infinity, minHeight: 94, maxHeight: .infinity, alignment: .leading)
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
                        ? (l10n.lang == .turkish ? "Kullanıcı Adını Değiştir" : "Change Username")
                        : (l10n.lang == .turkish ? "Letterboxd Hesabı Bağla" : "Connect Letterboxd"),
                    systemImage: "person.crop.circle.badge.checkmark"
                )
            }

            if isConnected {
                Button(role: .destructive) {
                    onDisconnectUsername()
                } label: {
                    Label(
                        l10n.lang == .turkish ? "Bağlantıyı Kaldır" : "Disconnect",
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
