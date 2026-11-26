#if DEBUG
//
//  UITestHarness.swift
//  omakase
//
//  Debug-only deterministic UI test harness launched via ProcessInfo launch arguments
//  so XCUITest suites can exercise every core screen offline without live Firebase or Gemini calls.
//

import SwiftUI

enum UITestRoute: String {
    case auth
    case onboarding
    case bento
    case feed
    case community
    case dailyLimit
}

struct UITestLaunchConfig {
    let route: UITestRoute
    let language: AppLanguage
    let colorScheme: ColorScheme

    static var shouldSkipSplash: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestSkipSplash")
    }

    static var current: UITestLaunchConfig? {
        let args = ProcessInfo.processInfo.arguments
        guard let routeIndex = args.firstIndex(of: "-UITestRoute"),
              routeIndex + 1 < args.count,
              let route = UITestRoute(rawValue: args[routeIndex + 1]) else {
            return nil
        }

        var lang: AppLanguage = .english
        if let langIndex = args.firstIndex(of: "-UITestLang"),
           langIndex + 1 < args.count,
           let parsed = AppLanguage(rawValue: args[langIndex + 1].lowercased()) {
            lang = parsed
        }

        var scheme: ColorScheme = .light
        if let schemeIndex = args.firstIndex(of: "-UITestScheme"),
           schemeIndex + 1 < args.count,
           args[schemeIndex + 1].lowercased() == "dark" {
            scheme = .dark
        }

        return UITestLaunchConfig(route: route, language: lang, colorScheme: scheme)
    }
}

struct UITestHarness: View {
    let config: UITestLaunchConfig

    @AppStorage("omakase.language") private var languageCode: String = AppLanguage.english.rawValue
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false

    @State private var authService = AuthService()
    @State private var feedViewModel = FeedViewModel(interests: [])
    @State private var bookmarkStore = BookmarkStore.shared
    @State private var activeInterests: Set<String> = ["History", "Cinema"]
    @State private var isLetterboxdActive = false
    @State private var toastMessage: String?
    @State private var selectedTab: AppTab
    @State private var showPaywall = false
    @State private var communityMode: Int = 0
    @State private var communitySearch: String = ""

    private static let heroPostID = UUID(uuidString: "A1B2C3D4-E5F6-4789-ABCD-000000000001")!
    private static var configuredLaunchKey: String?

    private var resolvedLanguage: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? config.language
    }

    private var l10n: L10n { L10n(lang: resolvedLanguage) }

    private var heroPost: Post {
        Post(
            id: Self.heroPostID,
            title: "Oxford University Is Older Than the Aztec Empire",
            text: """
            Lectures were already echoing through Oxford by **1096**, and the university had formal colleges by 1249—more than *two centuries before* the Aztecs founded Tenochtitlan in 1325.

            By the time the Aztec Empire formed in **1428**, Oxford had been graduating scholars for over 300 years.

            Source: L. W. B. Brockliss, The University of Oxford: A History (2016)
            """,
            isComplete: true,
            tags: ["History", "Timelines", "Culture"],
            categoryId: "history",
            postFormat: "TIMELINE",
            deepDiveText: """
            When the Aztec Triple Alliance united the Valley of Mexico in 1428, Oxford's oldest library was already expanding—and Machu Picchu wouldn't even be built for another twenty years.

            Source: Michael E. Smith, The Aztecs (2012)
            """,
            createdAt: Date().addingTimeInterval(-420)
        )
    }

    private var sampleCommunityPosts: [SharedPost] {
        [
            SharedPost(
                authorId: "u_mira",
                authorName: "Mira",
                authorUsername: "mira",
                title: "Kurosawa's Ink-Dyed Rain",
                text: """
                In Rashomon (1950), Kurosawa poured black ink into the rain so it would show on monochrome film.

                Source: Donald Richie, The Films of Akira Kurosawa (1965)
                """,
                tags: ["Cinema", "Craft"],
                originalCreatedAt: Date().addingTimeInterval(-3600),
                sharedAt: Date().addingTimeInterval(-1800),
                deepDiveText: "Kurosawa used fire engines to pump dyed water over the Rashomon gate set.",
                reactionCounts: ["like": 28],
                totalReactions: 28,
                commentCount: 5
            ),
            SharedPost(
                authorId: "u_kenji",
                authorName: "Kenji",
                authorUsername: "kenji",
                title: "Tokyo's Calm 7-Second Station Melodies",
                text: """
                Each Yamanote platform plays an original melody composed to lower commuter cortisol and stop platform rushes.

                Source: Minoru Mukaiya, Ongakukan Archives (2012)
                """,
                tags: ["Design", "Music"],
                originalCreatedAt: Date().addingTimeInterval(-7200),
                sharedAt: Date().addingTimeInterval(-5400),
                reactionCounts: ["like": 19],
                totalReactions: 19,
                commentCount: 3
            ),
            SharedPost(
                authorId: "u_elena",
                authorName: "Elena",
                authorUsername: "elena",
                title: "Why Roman Concrete Heals Its Own Cracks",
                text: """
                Quicklime clasts react with seawater to crystallize fresh calcite inside fractures over millennia.

                Source: Admir Masic et al., Science Advances (2023)
                """,
                tags: ["Architecture", "Science"],
                originalCreatedAt: Date().addingTimeInterval(-9800),
                sharedAt: Date().addingTimeInterval(-8100),
                reactionCounts: ["like": 42],
                totalReactions: 42,
                commentCount: 8
            )
        ]
    }

    private var filteredCommunityPosts: [SharedPost] {
        let query = communitySearch.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
        guard !query.isEmpty else { return sampleCommunityPosts }
        return sampleCommunityPosts.filter { post in
            post.title.localizedLowercase.contains(query)
                || post.text.localizedLowercase.contains(query)
                || post.authorName.localizedLowercase.contains(query)
                || (post.authorUsername?.localizedLowercase.contains(query) ?? false)
                || post.tags.contains(where: { $0.localizedLowercase.contains(query) })
        }
    }

    init(config: UITestLaunchConfig) {
        self.config = config
        let launchKey = "\(config.route.rawValue)|\(config.language.rawValue)"
        if Self.configuredLaunchKey != launchKey {
            Self.configuredLaunchKey = launchKey
            UserDefaults.standard.set(config.language.rawValue, forKey: "omakase.language")

            if config.route == .onboarding {
                UserDefaults.standard.set(false, forKey: "omakase.hasOnboarded")
            }

            if config.route == .bento {
                for category in InterestCategory.presets {
                    SubTopicDiscoveryStore.shared.storePrefetchedBatch(
                        category.fallbackInterests(for: config.language),
                        for: category.id,
                        language: config.language
                    )
                }
            }

            if config.route == .feed {
                BookmarkStore.shared.remove(id: Self.heroPostID)
            }
        }

        _languageCode = AppStorage(wrappedValue: config.language.rawValue, "omakase.language")
        _hasOnboarded = AppStorage(wrappedValue: config.route == .onboarding ? false : true, "omakase.hasOnboarded")
        _selectedTab = State(initialValue: config.route == .community ? .community : .feed)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.12)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        routeBody
            .environment(\.locale, Locale(identifier: resolvedLanguage.localeIdentifier))
            .environment(\.appLanguage, resolvedLanguage)
            .preferredColorScheme(config.colorScheme)
            .tint(OmakaseTheme.ink)
    }

    @ViewBuilder
    private var routeBody: some View {
        switch config.route {
        case .auth:
            AuthView(authService: authService)

        case .onboarding:
            if hasOnboarded {
                VStack(spacing: 12) {
                    Text("Onboarding Completed")
                        .font(.title3.bold())
                        .accessibilityIdentifier("uitest.onboarding.completed")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemBackground))
            } else {
                OnboardingView(authService: authService)
            }

        case .bento:
            NavigationStack {
                BentoTasteBox(
                    allInterests: Array(activeInterests).sorted(),
                    activeInterests: $activeInterests,
                    onAddInterest: { activeInterests.insert($0) },
                    onRemoveInterest: { activeInterests.remove($0) },
                    isLetterboxdActive: $isLetterboxdActive,
                    isGenerating: false,
                    isOffline: false,
                    isCooldownActive: false,
                    cooldownRemaining: 0,
                    cooldownTotal: 0,
                    hasExistingPosts: false,
                    onPromptLetterboxdUsername: {},
                    onSelectLetterboxdPost: {},
                    onTriggerChefPick: { _, _ in }
                )
                .toolbar(.hidden, for: .navigationBar)
            }

        case .feed, .community:
            TabView(selection: $selectedTab) {
                feedTabContent
                    .tag(AppTab.feed)
                    .tabItem {
                        Label(l10n.tabMyFeed, systemImage: "fork.knife")
                            .accessibilityIdentifier("tab.feed")
                    }

                communityTabContent
                    .tag(AppTab.community)
                    .tabItem {
                        Label(l10n.tabTimeline, systemImage: "person.2.fill")
                            .accessibilityIdentifier("tab.community")
                    }

                profileTabContent
                    .tag(AppTab.profile)
                    .tabItem {
                        Label(l10n.tabProfile, systemImage: "person.crop.circle")
                            .accessibilityIdentifier("tab.profile")
                    }
            }

        case .dailyLimit:
            DailyLimitCardView(
                resetsAt: Date().addingTimeInterval(3600 * 5),
                hasExistingPosts: true,
                onScrollToLastPost: {},
                onUpgrade: { showPaywall = true },
                onRemind: { toastMessage = l10n.limitCardRemindScheduledToast(timeText: "09:00") }
            )
            .toast(message: $toastMessage)
            .sheet(isPresented: $showPaywall) {
                OmakasePaywallView(source: .plateLimit)
                    .environment(\.appLanguage, resolvedLanguage)
                    .environment(\.locale, Locale(identifier: resolvedLanguage.localeIdentifier))
                    .preferredColorScheme(config.colorScheme)
                    .tint(OmakaseTheme.ink)
            }
        }
    }

    private var feedTabContent: some View {
        NavigationStack {
            ReelsPostCard(
                post: heroPost,
                isLastPost: true,
                bookmarkStore: bookmarkStore,
                authService: authService,
                viewModel: feedViewModel,
                toastMessage: $toastMessage,
                onDelete: {},
                onScrollToCategories: {}
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                feedHeaderBar
            }
            .toast(message: $toastMessage)
            .sheet(isPresented: $showPaywall) {
                OmakasePaywallView(source: .plateLimit)
                    .environment(\.appLanguage, resolvedLanguage)
                    .environment(\.locale, Locale(identifier: resolvedLanguage.localeIdentifier))
                    .preferredColorScheme(config.colorScheme)
                    .tint(OmakaseTheme.ink)
            }
        }
    }

    private var feedHeaderBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 7) {
                Image("AppLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.primary)
                Text(l10n.appTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .accessibilityIdentifier("feed.header.title")
            }
            .padding(.leading, 18)

            Spacer()

            Button {
                showPaywall = true
            } label: {
                Text(l10n.feedQuotaPlatesRemaining(remaining: 3, limit: 3))
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.07), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("feed.header.quotaPill")
            .padding(.trailing, 16)
        }
        .frame(height: 44)
        .background(Color(uiColor: .systemBackground))
    }

    private var communityTabContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                        TextField(l10n.communitySearchPlaceholder, text: $communitySearch)
                            .font(.subheadline)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .accessibilityIdentifier("community.searchField")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )

                    Picker("", selection: $communityMode) {
                        Text(l10n.timelineModeDiscover).tag(0)
                        Text(l10n.timelineModeFollowing).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("community.feedModePicker")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)

                Divider().opacity(0.12)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(filteredCommunityPosts.enumerated()), id: \.offset) { idx, post in
                            TimelinePostCard(
                                post: post,
                                authService: authService,
                                onAuthorTap: {},
                                isFollowingAuthor: false,
                                onToggleFollowAuthor: {}
                            )
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("community.postCard.\(idx)")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle(l10n.tabTimeline)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var profileTabContent: some View {
        VStack(spacing: 12) {
            Text("Profile")
                .font(.title3.bold())
                .accessibilityIdentifier("uitest.profile.marker")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}
#endif
