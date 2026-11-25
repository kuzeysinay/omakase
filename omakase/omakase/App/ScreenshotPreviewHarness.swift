#if DEBUG
//
//  ScreenshotPreviewHarness.swift
//  omakase
//
//  Debug-only deterministic UI harness for capturing localized App Store
//  screenshots across all 7 languages from the iOS Simulator.
//

import SwiftUI

enum ScreenshotScene: String {
    case feed
    case bento
    case subtopics
    case letterboxd
    case deepdive
    case export
    case cooldown
    case community
}

struct ScreenshotLaunchConfig {
    let scene: ScreenshotScene
    let language: AppLanguage
    let colorScheme: ColorScheme

    static var current: ScreenshotLaunchConfig? {
        let args = ProcessInfo.processInfo.arguments
        guard let sceneIndex = args.firstIndex(of: "-ScreenshotScene"),
              sceneIndex + 1 < args.count,
              let scene = ScreenshotScene(rawValue: args[sceneIndex + 1].lowercased()) else {
            return nil
        }

        var lang: AppLanguage = .english
        if let langIndex = args.firstIndex(of: "-ScreenshotLang"),
           langIndex + 1 < args.count,
           let parsed = AppLanguage(rawValue: args[langIndex + 1].lowercased()) {
            lang = parsed
        }

        var scheme: ColorScheme = .light
        if let schemeIndex = args.firstIndex(of: "-ScreenshotScheme"),
           schemeIndex + 1 < args.count,
           args[schemeIndex + 1].lowercased() == "dark" {
            scheme = .dark
        }

        return ScreenshotLaunchConfig(scene: scene, language: lang, colorScheme: scheme)
    }
}

struct ScreenshotPreviewHarness: View {
    let config: ScreenshotLaunchConfig

    @State private var authService = AuthService()
    @State private var feedViewModel = FeedViewModel(interests: [])
    @State private var bookmarkStore = BookmarkStore.shared
    @State private var activeInterests: Set<String> = []
    @State private var isLetterboxdActive = false
    @State private var toastMessage: String?
    @State private var selectedTab: AppTab = .feed
    @State private var showDeepDiveSheet = false
    @State private var showExportSheet = false

    private var l10n: L10n { L10n(lang: config.language) }
    private var content: LocalizedScreenshotContent { .forLanguage(config.language) }

    init(config: ScreenshotLaunchConfig) {
        self.config = config
        _selectedTab = State(initialValue: config.scene == .community ? .community : .feed)
        _showDeepDiveSheet = State(initialValue: config.scene == .deepdive)
        _showExportSheet = State(initialValue: config.scene == .export)
        if config.scene == .letterboxd {
            UserDefaults.standard.set("kuzey", forKey: "omakase.letterboxd_username")
        }
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.12)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            feedTabContent
                .tag(AppTab.feed)
                .tabItem {
                    Label(l10n.tabMyFeed, systemImage: "fork.knife")
                }

            communityTabContent
                .tag(AppTab.community)
                .tabItem {
                    Label(l10n.tabTimeline, systemImage: "person.2.fill")
                }

            Color(.systemBackground)
                .tag(AppTab.profile)
                .tabItem {
                    Label(l10n.tabProfile, systemImage: "person.crop.circle")
                }
        }
        .tint(OmakaseTheme.ink)
        .environment(\.locale, Locale(identifier: config.language.localeIdentifier))
        .environment(\.appLanguage, config.language)
        .preferredColorScheme(config.colorScheme)
        .onAppear {
            activeInterests = Set(content.activeChips)
        }
    }

    // MARK: - Feed / Bento / Deep Dive / Cooldown

    private var feedTabContent: some View {
        NavigationStack {
            Group {
                switch config.scene {
                case .feed, .deepdive, .export:
                    ReelsPostCard(
                        post: content.heroPost,
                        isLastPost: true,
                        bookmarkStore: bookmarkStore,
                        authService: authService,
                        viewModel: feedViewModel,
                        toastMessage: $toastMessage,
                        onDelete: {},
                        onScrollToCategories: {}
                    )
                case .bento:
                    BentoTasteBox(
                        allInterests: [],
                        activeInterests: $activeInterests,
                        onAddInterest: { _ in },
                        onRemoveInterest: { _ in },
                        isLetterboxdActive: $isLetterboxdActive,
                        isGenerating: false,
                        isOffline: false,
                        isCooldownActive: false,
                        cooldownRemaining: 0,
                        cooldownTotal: 0,
                        hasExistingPosts: true,
                        onTriggerChefPick: { _, _ in }
                    )
                case .subtopics:
                    BentoTasteBox(
                        allInterests: [],
                        activeInterests: $activeInterests,
                        onAddInterest: { _ in },
                        onRemoveInterest: { _ in },
                        isLetterboxdActive: $isLetterboxdActive,
                        isGenerating: false,
                        isOffline: false,
                        isCooldownActive: false,
                        cooldownRemaining: 0,
                        cooldownTotal: 0,
                        hasExistingPosts: true,
                        onTriggerChefPick: { _, _ in },
                        initialSubtopicCategory: InterestCategory.category(forId: "history") ?? InterestCategory.presets.first,
                        initialSubtopics: content.historySubtopics
                    )
                case .letterboxd:
                    BentoTasteBox(
                        allInterests: [],
                        activeInterests: $activeInterests,
                        onAddInterest: { _ in },
                        onRemoveInterest: { _ in },
                        isLetterboxdActive: $isLetterboxdActive,
                        isGenerating: false,
                        isOffline: false,
                        isCooldownActive: false,
                        cooldownRemaining: 0,
                        cooldownTotal: 0,
                        hasExistingPosts: true,
                        onPromptLetterboxdUsername: {},
                        onSelectLetterboxdPost: {},
                        onTriggerChefPick: { _, _ in },
                        initialSubtopicCategory: InterestCategory.category(forId: "film") ?? InterestCategory.presets.first,
                        initialSubtopics: content.filmSubtopics
                    )
                case .cooldown:
                    ReelsPostCard(
                        post: content.cooldownPost,
                        isLastPost: true,
                        bookmarkStore: bookmarkStore,
                        authService: authService,
                        viewModel: feedViewModel,
                        toastMessage: $toastMessage,
                        onDelete: {},
                        onScrollToCategories: {}
                    )
                case .community:
                    Color(.systemBackground)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                headerBar
            }
            .sheet(isPresented: $showDeepDiveSheet) {
                DeepDiveReaderSheet(
                    text: content.deepDiveBody,
                    title: l10n.deepDiveTitle
                )
                .environment(\.appLanguage, config.language)
                .environment(\.locale, Locale(identifier: config.language.localeIdentifier))
                .preferredColorScheme(config.colorScheme)
                .tint(OmakaseTheme.ink)
            }
            .sheet(isPresented: $showExportSheet) {
                ExportPostSheet(post: content.heroPost)
                    .environment(\.appLanguage, config.language)
                    .environment(\.locale, Locale(identifier: config.language.localeIdentifier))
                    .preferredColorScheme(config.colorScheme)
                    .tint(OmakaseTheme.ink)
            }
        }
    }

    private var headerBar: some View {
        VStack(spacing: 0) {
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
                }
                .padding(.leading, 18)

                Spacer()

                quotaPill
                    .padding(.trailing, 16)
            }
            .frame(height: 44)
            .background(Color(uiColor: .systemBackground))

            if config.scene == .cooldown {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.primary.opacity(0.08))
                        Rectangle()
                            .fill(OmakaseTheme.ink)
                            .frame(width: geo.size.width * 0.62)
                    }
                }
                .frame(height: 3.5)
            }
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var quotaPill: some View {
        let limit = 3
        let remaining = (config.scene == .cooldown) ? 2 : 3
        let isWarning = remaining == 2
        let accentColor: Color = isWarning ? .orange : .primary
        let fillColor: Color = isWarning ? Color.orange.opacity(0.14) : Color.primary.opacity(0.07)
        let strokeColor: Color = isWarning ? Color.orange.opacity(0.45) : Color.primary.opacity(0.14)

        return HStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(0..<limit, id: \.self) { index in
                    Circle()
                        .fill(index < remaining ? accentColor : Color.primary.opacity(0.16))
                        .frame(width: 5, height: 5)
                }
            }
            if isWarning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accentColor)
            }
            Text(l10n.feedQuotaPlatesRemaining(remaining: remaining, limit: limit))
                .font(.system(size: 11, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(accentColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(fillColor, in: Capsule())
        .overlay(Capsule().strokeBorder(strokeColor, lineWidth: 1))
    }

    // MARK: - Community Scene

    private var communityTabContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(l10n.communitySearchPlaceholder)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
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

                    Picker("", selection: .constant(0)) {
                        Text(l10n.timelineModeDiscover).tag(0)
                        Text(l10n.timelineModeFollowing).tag(1)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)

                Divider().opacity(0.12)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(content.communityPosts.enumerated()), id: \.offset) { _, post in
                            TimelinePostCard(
                                post: post,
                                authService: authService,
                                onAuthorTap: {},
                                isFollowingAuthor: false,
                                onToggleFollowAuthor: {}
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle(l10n.tabTimeline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "person.badge.plus")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.85))
                }
            }
        }
    }
}

// MARK: - Localized Sample Content (All 7 Languages)

private struct LocalizedScreenshotContent {
    let heroPost: Post
    let cooldownPost: Post
    let deepDiveBody: String
    let allChips: [String]
    let activeChips: [String]
    let historySubtopics: [String]
    let filmSubtopics: [String]
    let communityPosts: [SharedPost]

    static func forLanguage(_ lang: AppLanguage) -> LocalizedScreenshotContent {
        switch lang {
        case .english:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "Oxford University Is Older Than the Aztec Empire",
                    text: """
                    Lectures were already echoing through Oxford by **1096**, and the university had formal colleges by 1249—more than *two centuries before* the Aztecs founded Tenochtitlan in 1325.

                    By the time the Aztec Empire formed in **1428**, Oxford had been graduating scholars for over 300 years. History's timelines overlap in ways school textbooks rarely make feel real.

                    Source: L. W. B. Brockliss, The University of Oxford: A History (2016)
                    """,
                    isComplete: true,
                    tags: ["History", "Timelines", "Culture"],
                    categoryId: "history",
                    postFormat: "TIMELINE",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                cooldownPost: Post(
                    title: "How a Mini Ice Age Built the Stradivarius Sound",
                    text: """
                    Between 1645 and 1715, sunspots nearly vanished and Europe froze through the **Maunder Minimum**. Alpine spruce trees grew agonizingly slowly, packing razor-thin, hyper-dense growth rings into every centimeter of timber.

                    Antonio Stradivari carved his golden-period violins from that exact *climate-compressed wood*. Dendrochronologists proved in 2003 that the legendary resonance wasn't a secret varnish—it was winter itself frozen into the grain.

                    Source: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
                    """,
                    isComplete: true,
                    tags: ["Music", "Climate", "Craft"],
                    categoryId: "music",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-180)
                ),
                deepDiveBody: """
                When the Aztec Triple Alliance united the Valley of Mexico in 1428, Oxford's oldest library was already expanding—and Machu Picchu wouldn't even be built for another twenty years.

                Even earlier, the University of al-Qarawiyyin in Fez (859) and Bologna (1088) were already teaching students across continents, proving how compressed modern historical memory really is.

                Source: Michael E. Smith, The Aztecs (2012)
                """,
                allChips: ["Bauhaus", "Japanese Cinema", "Stoicism", "History"],
                activeChips: ["Bauhaus", "History"],
                historySubtopics: [
                    "1518 Dancing Plague", "Great Emu War", "38-Minute War",
                    "WWII Ghost Army", "Napoleon's Rabbits", "1904 Marathon Chaos",
                    "Roman Street Food", "Samurai & Fax Era", "Viking Runes in Istanbul",
                    "Ottoman Coffee Spies", "Tulip Mania Crash", "Lost Library Myths"
                ],
                filmSubtopics: [
                    "Kubrick f/0.7 Lens", "Kuleshov Effect", "Kurosawa's Ink Rain",
                    "Akira 24fps Cels", "1917 Single-Take Rig", "Foley Sound Secrets",
                    "Vertigo Dolly Zoom", "Tarkovsky Polaroids", "Ghibli Painted Skies",
                    "Leone Silence Pacing", "Neon Noir Lighting"
                ],
                communityPosts: [
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
            )

        case .turkish:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "Oxford Üniversitesi, Aztek İmparatorluğu'ndan Daha Eski",
                    text: """
                    Oxford'da dersler **1096** yılında zaten başlamıştı; 1249'da ise üniversitenin ilk resmi kolejleri kurulmuştu—Azteklerin Tenochtitlan'ı 1325'te kurmasından *iki yüzyıldan fazla* önce.

                    **1428**'de Aztek İmparatorluğu şekillenirken Oxford 300 yılı aşkın süredir mezun veriyordu. Tarihin zaman çizgileri, ders kitaplarının sandığından çok daha şaşırtıcı biçimde kesişir.

                    Kaynak: L. W. B. Brockliss, The University of Oxford: A History (2016)
                    """,
                    isComplete: true,
                    tags: ["Tarih", "Zaman Çizelgesi", "Kültür"],
                    categoryId: "history",
                    postFormat: "TIMELINE",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                cooldownPost: Post(
                    title: "Küçük Buzul Çağı Stradivarius Sesini Nasıl Yarattı?",
                    text: """
                    1645 ile 1715 arasında güneş lekeleri neredeyse yok oldu ve Avrupa **Maunder Minimumu** soğuğuna gömüldü. Alpler'deki ladin ağaçları çok yavaş büyüyerek her santimetreye olağanüstü sıkı yaş halkaları sıkıştırdı.

                    Antonio Stradivari altın dönem kemanlarını tam da bu *iklimle yoğunlaşmış ahşaptan* oydu. 2003'teki dendrokronoloji analizi, efsanevi tınının gizli bir cila değil, ağacın dokusuna hapsolmuş kış olduğunu kanıtladı.

                    Kaynak: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
                    """,
                    isComplete: true,
                    tags: ["Müzik", "İklim", "Zanaat"],
                    categoryId: "music",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-180)
                ),
                deepDiveBody: """
                1428'de Aztek Üçlü İttifakı Meksika Vadisi'ni birleştirdiğinde, Oxford'un en eski kütüphanesi çoktan genişletiliyordu ve Machu Picchu'nun inşasına bile henüz yirmi yıl vardı.

                Daha da geriye gidersek Fas'taki Karaviyyin Üniversitesi (859) ve Bologna (1088), kıtalar arasında yüzyıllardır öğrenci yetiştiriyordu; modern tarih hafızamızın ne kadar sıkışık olduğunu kanıtlarcasına.

                Kaynak: Michael E. Smith, The Aztecs (2012)
                """,
                allChips: ["Bauhaus", "Japon Sineması", "Stoacılık", "Tarih"],
                activeChips: ["Bauhaus", "Tarih"],
                historySubtopics: [
                    "1518 Dans Vebası", "Büyük Emu Savaşı", "38 Dakikalık Savaş",
                    "Şişme Hayalet Ordu", "Napolyon'un Tavşanları", "1904 Maraton Kaosu",
                    "Roma Sokak Yemekleri", "Samuray & Faks Çağı", "Ayasofya Viking Yazısı",
                    "Osmanlı Kahve Casusları", "Lale Çılgınlığı", "İskenderiye Mitleri"
                ],
                filmSubtopics: [
                    "Kubrick f/0.7 Lensi", "Kuleşov Etkisi", "Kurosawa Mürekkep Yağmuru",
                    "Akira 24fps Kareleri", "1917 Tek Plan Sistemi", "Foley Ses Sırları",
                    "Vertigo Dolly Zoom", "Tarkovski Polaroidleri", "Ghibli Gökyüzü Boyası",
                    "Leone Sessizlik Kurgusu", "Neon Noir Işıklandırma"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "Sude",
                        authorUsername: "sude",
                        title: "Kurosawa'nın Yağmuruna Karışan Mürekkep",
                        text: """
                        Kurosawa, Rashomon (1950) filminde su siyah-beyaz filmde görünmediği için yağmura mürekkep karıştırdı.

                        Kaynak: Donald Richie, The Films of Akira Kurosawa (1965)
                        """,
                        tags: ["Sinema", "Kurgu"],
                        originalCreatedAt: Date().addingTimeInterval(-3600),
                        sharedAt: Date().addingTimeInterval(-1800),
                        deepDiveText: "Kurosawa setteki itfaiye pompalarına siyah mürekkep karıştırarak yağmuru kamerada görünür kıldı.",
                        reactionCounts: ["like": 28],
                        totalReactions: 28,
                        commentCount: 5
                    ),
                    SharedPost(
                        authorId: "u_kenji",
                        authorName: "Kuzey",
                        authorUsername: "kuzey",
                        title: "Tokyo İstasyonlarının 7 Saniyelik Melodileri",
                        text: """
                        Yamanote hattındaki her peron, yolcu stresini azaltmak için bestelenmiş özgün bir hassha melodisi çalar.

                        Kaynak: Minoru Mukaiya, Ongakukan Arşivi (2012)
                        """,
                        tags: ["Tasarım", "Müzik"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    ),
                    SharedPost(
                        authorId: "u_elena",
                        authorName: "Selin",
                        authorUsername: "selin",
                        title: "Roma Betonu Çatlaklarını Nasıl Onarır?",
                        text: """
                        Sönmemiş kireç parçacıkları deniz suyuyla tepkimeye girerek çatlakları binlerce yıl içinde kendi kendine doldurur.

                        Kaynak: Admir Masic et al., Science Advances (2023)
                        """,
                        tags: ["Mimari", "Bilim"],
                        originalCreatedAt: Date().addingTimeInterval(-9800),
                        sharedAt: Date().addingTimeInterval(-8100),
                        reactionCounts: ["like": 42],
                        totalReactions: 42,
                        commentCount: 8
                    )
                ]
            )

        case .japanese:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "オックスフォード大学はアステカ帝国より古い",
                    text: """
                    オックスフォードで講義が始まったのは**1096年**ごろ。アステカ人がテノチティトランを建都した1325年より*2世紀以上も前*のことでした。

                    アステカ帝国が成立した**1428年**には、オックスフォードはすでに300年以上の歴史を誇っていたのです。年表を並べてみると、歴史の感覚は一気に塗り替わります。

                    出典: L. W. B. Brockliss, The University of Oxford: A History (2016)
                    """,
                    isComplete: true,
                    tags: ["歴史", "年表", "教養"],
                    categoryId: "history",
                    postFormat: "TIMELINE",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                cooldownPost: Post(
                    title: "小氷期が生んだストラディバリウスの響き",
                    text: """
                    1645年から1715年にかけて太陽黒点が激減し、欧州は**マウンダー極小期**の厳冬に包まれました。アルプスのトウヒは極端にゆっくり育ち、年輪が緻密に詰まった高密度な木材になったのです。

                    ストラディバリが黄金期の名器を削り出したのは、まさにその*厳冬が圧縮した木*でした。伝説の響きの正体は秘伝のニスではなく、木目に封じ込められた気候でした。

                    出典: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
                    """,
                    isComplete: true,
                    tags: ["音楽", "気候", "工芸"],
                    categoryId: "music",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-180)
                ),
                deepDiveBody: """
                1428年にアステカ三国同盟が誕生した頃、オックスフォードではすでに図書館の拡張が進んでおり、マチュピチュはまだ着工すらされていませんでした。

                さらに遡れば、フェズのカラウィーイーン大学（859年）やボローニャ大学（1088年）もそれ以前から学問を紡いでいました。

                出典: Michael E. Smith, The Aztecs (2012)
                """,
                allChips: ["バウハウス", "日本映画", "ストア派", "歴史"],
                activeChips: ["バウハウス", "歴史"],
                historySubtopics: [
                    "1518年踊るペスト", "エミュー戦争", "38分間戦争",
                    "空気注入の幽霊軍", "ナポレオンと兎", "1904年マラソン騒動",
                    "ローマの屋台飯", "侍とFAXの時代", "大聖堂のルーン文字",
                    "オスマン珈琲諜報", "チューリップバブル", "アレクサンドリア謎"
                ],
                filmSubtopics: [
                    "キューブリック f/0.7", "クレショフ効果", "黒澤の墨入り雨",
                    "AKIRA 24fps作画", "1917 ワンカット撮影", "フォーリー効果音の秘密",
                    "めまい ドリーズーム", "タルコフスキー写真", "ジブリの手描き空",
                    "レオーネの間の美学", "ネオン・ノワール照明"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "美咲",
                        authorUsername: "misaki",
                        title: "黒澤明『羅生門』の墨を混ぜた雨",
                        text: """
                        黒澤明は白黒フィルムに雨を映すため、放水に墨汁を混ぜて撮影しました。

                        出典: Donald Richie, The Films of Akira Kurosawa (1965)
                        """,
                        tags: ["映画", "演出"],
                        originalCreatedAt: Date().addingTimeInterval(-3600),
                        sharedAt: Date().addingTimeInterval(-1800),
                        deepDiveText: "撮影現場では消防ポンプ車を使い、墨を混ぜた雨を降らせました。",
                        reactionCounts: ["like": 28],
                        totalReactions: 28,
                        commentCount: 5
                    ),
                    SharedPost(
                        authorId: "u_kenji",
                        authorName: "健二",
                        authorUsername: "kenji",
                        title: "東京の発車メロディが急かさない理由",
                        text: """
                        山手線の各ホームで流れる7秒間のメロディは、乗客の焦りを和らげる音響心理学から設計されています。

                        出典: 向谷実 音楽館サウンドアーカイブ (2012)
                        """,
                        tags: ["デザイン", "音楽"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    ),
                    SharedPost(
                        authorId: "u_elena",
                        authorName: "陽菜",
                        authorUsername: "hina",
                        title: "自己修復する古代ローマコンクリート",
                        text: """
                        生石灰の粒が海水と反応し、ひび割れを数千年かけて自ら塞ぎ続けます。

                        出典: Admir Masic et al., Science Advances (2023)
                        """,
                        tags: ["建築", "科学"],
                        originalCreatedAt: Date().addingTimeInterval(-9800),
                        sharedAt: Date().addingTimeInterval(-8100),
                        reactionCounts: ["like": 42],
                        totalReactions: 42,
                        commentCount: 8
                    )
                ]
            )

        case .german:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "Die Universität Oxford ist älter als das Aztekenreich",
                    text: """
                    In Oxford wurde bereits um **1096** gelehrt – mehr als *zwei Jahrhunderte bevor* die Azteken 1325 ihre Hauptstadt Tenochtitlán gründeten.

                    Als das Aztekenreich **1428** entstand, blickte Oxford schon auf über 300 Jahre Universitätsgeschichte zurück. Zeitachsen überlappen sich oft ganz anders, als unser Gefühl es vermutet.

                    Quelle: L. W. B. Brockliss, The University of Oxford: A History (2016)
                    """,
                    isComplete: true,
                    tags: ["Geschichte", "Zeitleiste", "Kultur"],
                    categoryId: "history",
                    postFormat: "TIMELINE",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                cooldownPost: Post(
                    title: "Wie eine Kleine Eiszeit den Stradivari-Klang schuf",
                    text: """
                    Zwischen 1645 und 1715 erlebte Europa das eiskalte **Maunder-Minimum**. Alpenfichten wuchsen extrem langsam und bildeten ungewöhnlich dichte, feine Jahresringe.

                    Antonio Stradivari schnitzte seine berühmtesten Geigen aus genau diesem *klimaverdichteten Holz*. 2003 zeigten Baumringforscher: Das Geheimnis war kein Lack, sondern der Winter im Holz.

                    Quelle: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
                    """,
                    isComplete: true,
                    tags: ["Musik", "Klima", "Handwerk"],
                    categoryId: "music",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-180)
                ),
                deepDiveBody: """
                Als sich 1428 der aztekische Dreibund formte, wuchs Oxfords älteste Bibliothek bereits rasant – und Machu Picchu sollte erst zwanzig Jahre später erbaut werden.

                Noch früher lehrten bereits al-Qarawiyyin in Fès (859) und Bologna (1088) Generationen von Gelehrten.

                Quelle: Michael E. Smith, The Aztecs (2012)
                """,
                allChips: ["Bauhaus", "Japanisches Kino", "Stoizismus", "Geschichte"],
                activeChips: ["Bauhaus", "Geschichte"],
                historySubtopics: [
                    "Tanzwut von 1518", "Großer Emukrieg", "38-Minuten-Krieg",
                    "Aufblasbare Geisterarmee", "Napoleons Hasenjagd", "Marathon-Chaos 1904",
                    "Römisches Streetfood", "Samurai & Faxgerät", "Wikinger-Runen",
                    "Osmanische Kaffee-Spione", "Tulpenmanie", "Bibliothek-Mythen"
                ],
                filmSubtopics: [
                    "Kubrick f/0,7-Linse", "Kuleschow-Effekt", "Kurosawas Tinte-Regen",
                    "Akira 24fps-Cels", "1917 One-Shot-Rig", "Geheimnisse des Foley",
                    "Vertigo Dolly-Zoom", "Tarkowskis Polaroids", "Ghiblis Wolkenkunst",
                    "Leones Stille-Schnitt", "Neon-Noir-Licht"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "Clara",
                        authorUsername: "clara",
                        title: "Kurosawas Regen mit schwarzer Tinte",
                        text: """
                        Für Rashomon (1950) mischte Kurosawa schwarze Tinte ins Wasser, damit der Regen sichtbar blieb.

                        Quelle: Donald Richie, The Films of Akira Kurosawa (1965)
                        """,
                        tags: ["Film", "Handwerk"],
                        originalCreatedAt: Date().addingTimeInterval(-3600),
                        sharedAt: Date().addingTimeInterval(-1800),
                        deepDiveText: "Feuerwehrpumpen verteilten den gefärbten Regen über das Set.",
                        reactionCounts: ["like": 28],
                        totalReactions: 28,
                        commentCount: 5
                    ),
                    SharedPost(
                        authorId: "u_kenji",
                        authorName: "Lukas",
                        authorUsername: "lukas",
                        title: "Warum Tokios Bahnhöfe komponiert klingen",
                        text: """
                        Jeder Bahnsteig der Yamanote-Linie spielt eine eigene 7-Sekunden-Melodie gegen Stress und Gedränge.

                        Quelle: Minoru Mukaiya, Ongakukan Archives (2012)
                        """,
                        tags: ["Design", "Musik"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    ),
                    SharedPost(
                        authorId: "u_elena",
                        authorName: "Hannah",
                        authorUsername: "hannah",
                        title: "Warum römischer Beton sich selbst heilt",
                        text: """
                        Branntkalk-Einschlüsse reagieren mit Meerwasser und schließen Risse über Jahrtausende selbstständig.

                        Quelle: Admir Masic et al., Science Advances (2023)
                        """,
                        tags: ["Architektur", "Wissenschaft"],
                        originalCreatedAt: Date().addingTimeInterval(-9800),
                        sharedAt: Date().addingTimeInterval(-8100),
                        reactionCounts: ["like": 42],
                        totalReactions: 42,
                        commentCount: 8
                    )
                ]
            )

        case .french:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "L'université d'Oxford est plus ancienne que l'Empire aztèque",
                    text: """
                    On enseignait déjà à Oxford dès **1096**, plus de *deux siècles avant* que les Aztèques ne fondent Tenochtitlan en 1325.

                    Lorsque l'Empire aztèque se forma en **1428**, Oxford comptait déjà plus de 300 ans d'histoire académique. Les chronologies de l'histoire réservent des télescopages vertigineux.

                    Source : L. W. B. Brockliss, The University of Oxford: A History (2016)
                    """,
                    isComplete: true,
                    tags: ["Histoire", "Chronologie", "Culture"],
                    categoryId: "history",
                    postFormat: "TIMELINE",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                cooldownPost: Post(
                    title: "Comment un petit âge glaciaire a forgé le son Stradivarius",
                    text: """
                    Entre 1645 et 1715, l'Europe traverse le **minimum de Maunder**. Les épicéas alpins poussent si lentement que leurs cernes deviennent d'une densité exceptionnelle.

                    Antonio Stradivari façonna ses violons d'or dans ce *bois comprimé par le gel*. En 2003, la dendrochronologie prouva que la résonance venait de l'hiver lui-même, pas d'un vernis secret.

                    Source : Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
                    """,
                    isComplete: true,
                    tags: ["Musique", "Climat", "Artisanat"],
                    categoryId: "music",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-180)
                ),
                deepDiveBody: """
                En 1428, quand la Triple-Alliance aztèque vit le jour, Oxford agrandissait déjà sa bibliothèque — et le Machu Picchu ne serait bâti que vingt ans plus tard.

                Plus tôt encore, Al Quaraouiyine à Fès (859) et Bologne (1088) formaient déjà des savants depuis des siècles.

                Source : Michael E. Smith, The Aztecs (2012)
                """,
                allChips: ["Bauhaus", "Cinéma japonais", "Stoïcisme", "Histoire"],
                activeChips: ["Bauhaus", "Histoire"],
                historySubtopics: [
                    "Peste dansante 1518", "Guerre des émeus", "Guerre de 38 min",
                    "Armée fantôme 1944", "Lapins de Napoléon", "Marathon fou 1904",
                    "Street-food romaine", "Samouraïs & fax", "Runes à Istanbul",
                    "Espions des cafés", "Crise des tulipes", "Mythes d'Alexandrie"
                ],
                filmSubtopics: [
                    "Objectif Kubrick f/0.7", "Effet Koulechov", "Pluie d'encre Kurosawa",
                    "Akira 24 images/s", "Plan-séquence 1917", "Secrets du bruitage",
                    "Dolly-zoom Vertigo", "Polaroïds Tarkovski", "Ciels peints Ghibli",
                    "Silences de Sergio Leone", "Éclairage néon noir"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "Camille",
                        authorUsername: "camille",
                        title: "L'encre noire dans la pluie de Kurosawa",
                        text: """
                        Dans Rashomon (1950), Kurosawa teinta la pluie à l'encre noire pour la rendre visible à l'écran.

                        Source : Donald Richie, The Films of Akira Kurosawa (1965)
                        """,
                        tags: ["Cinéma", "Artisanat"],
                        originalCreatedAt: Date().addingTimeInterval(-3600),
                        sharedAt: Date().addingTimeInterval(-1800),
                        deepDiveText: "Des lances à incendie projetaient cette pluie sombre sur le décor.",
                        reactionCounts: ["like": 28],
                        totalReactions: 28,
                        commentCount: 5
                    ),
                    SharedPost(
                        authorId: "u_kenji",
                        authorName: "Théo",
                        authorUsername: "theo",
                        title: "Les mélodies apaisantes des quais de Tokyo",
                        text: """
                        Chaque quai de la ligne Yamanote diffuse un motif de 7 secondes pensé pour réduire le stress des voyageurs.

                        Source : Minoru Mukaiya, Archives Ongakukan (2012)
                        """,
                        tags: ["Design", "Musique"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    ),
                    SharedPost(
                        authorId: "u_elena",
                        authorName: "Inès",
                        authorUsername: "ines",
                        title: "Le béton romain qui répare ses fissures",
                        text: """
                        Des éclats de chaux vive réagissent avec l'eau de mer pour sceller les fissures au fil des siècles.

                        Source : Admir Masic et al., Science Advances (2023)
                        """,
                        tags: ["Architecture", "Science"],
                        originalCreatedAt: Date().addingTimeInterval(-9800),
                        sharedAt: Date().addingTimeInterval(-8100),
                        reactionCounts: ["like": 42],
                        totalReactions: 42,
                        commentCount: 8
                    )
                ]
            )

        case .spanish:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "La Universidad de Oxford es más antigua que el Imperio azteca",
                    text: """
                    En Oxford ya se impartían clases hacia **1096**, más de *dos siglos antes* de que los mexicas fundaran Tenochtitlan en 1325.

                    Cuando nació el Imperio azteca en **1428**, Oxford llevaba más de 300 años graduando estudiantes. Las líneas del tiempo históricas se cruzan de formas sorprendentes.

                    Fuente: L. W. B. Brockliss, The University of Oxford: A History (2016)
                    """,
                    isComplete: true,
                    tags: ["Historia", "Cronología", "Cultura"],
                    categoryId: "history",
                    postFormat: "TIMELINE",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                cooldownPost: Post(
                    title: "Cómo una pequeña edad de hielo creó el sonido Stradivarius",
                    text: """
                    Entre 1645 y 1715, Europa vivió el gélido **mínimo de Maunder**. Los abetos alpinos crecieron tan lento que sus anillos formaron una madera extraordinariamente densa.

                    Antonio Stradivari talló sus violines de oro con esa *madera comprimida por el frío*. En 2003, la dendrocronología probó que el secreto no era un barniz, sino el invierno atrapado en la veta.

                    Fuente: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
                    """,
                    isComplete: true,
                    tags: ["Música", "Clima", "Oficio"],
                    categoryId: "music",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-180)
                ),
                deepDiveBody: """
                En 1428, cuando surgió la Triple Alianza azteca, Oxford ya ampliaba su biblioteca y Machu Picchu todavía tardaría veinte años en construirse.

                Aún antes, Al-Qarawiyyin en Fez (859) y Bolonia (1088) ya llevaban siglos formando eruditos.

                Fuente: Michael E. Smith, The Aztecs (2012)
                """,
                allChips: ["Bauhaus", "Cine japonés", "Estoicismo", "Historia"],
                activeChips: ["Bauhaus", "Historia"],
                historySubtopics: [
                    "Plaga del baile 1518", "Guerra del Emú", "Guerra de 38 min",
                    "Ejército inflable", "Conejos de Napoleón", "Maratón caótico 1904",
                    "Comida callejera romana", "Samuráis y el fax", "Runas en Estambul",
                    "Espías del café otomano", "Fiebre de tulipanes", "Mitos de Alejandría"
                ],
                filmSubtopics: [
                    "Lente Kubrick f/0.7", "Efecto Kuleshov", "Lluvia tinta Kurosawa",
                    "Akira a 24 fps", "Plano secuencia 1917", "Secretos del foley",
                    "Dolly zoom de Vertigo", "Polaroids Tarkovski", "Cielos pintados Ghibli",
                    "Silencios de Leone", "Luz neón noir"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "Lucía",
                        authorUsername: "lucia",
                        title: "Tinta negra en la lluvia de Kurosawa",
                        text: """
                        En Rashomon (1950), Kurosawa tiñó la lluvia con tinta china para que resaltara en blanco y negro.

                        Fuente: Donald Richie, The Films of Akira Kurosawa (1965)
                        """,
                        tags: ["Cine", "Oficio"],
                        originalCreatedAt: Date().addingTimeInterval(-3600),
                        sharedAt: Date().addingTimeInterval(-1800),
                        deepDiveText: "Camiones de bomberos bombeaban el agua teñida sobre el decorado.",
                        reactionCounts: ["like": 28],
                        totalReactions: 28,
                        commentCount: 5
                    ),
                    SharedPost(
                        authorId: "u_kenji",
                        authorName: "Mateo",
                        authorUsername: "mateo",
                        title: "Las melodías únicas del metro de Tokio",
                        text: """
                        Cada andén de la línea Yamanote reproduce un motivo de 7 segundos diseñado para reducir el estrés.

                        Fuente: Minoru Mukaiya, Archivos Ongakukan (2012)
                        """,
                        tags: ["Diseño", "Música"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    ),
                    SharedPost(
                        authorId: "u_elena",
                        authorName: "Sofía",
                        authorUsername: "sofia",
                        title: "Por qué el hormigón romano se autorrepara",
                        text: """
                        Pequeños fragmentos de cal viva reaccionan con el agua marina y sellan las grietas durante milenios.

                        Fuente: Admir Masic et al., Science Advances (2023)
                        """,
                        tags: ["Arquitectura", "Ciencia"],
                        originalCreatedAt: Date().addingTimeInterval(-9800),
                        sharedAt: Date().addingTimeInterval(-8100),
                        reactionCounts: ["like": 42],
                        totalReactions: 42,
                        commentCount: 8
                    )
                ]
            )

        case .korean:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "옥스퍼드 대학교는 아즈텍 제국보다 오래됐다",
                    text: """
                    옥스퍼드에서 강의가 시작된 것은 **1096년** 무렵입니다. 아즈텍인이 테노치티틀란을 세운 1325년보다 *200년 이상* 앞선 시기였죠.

                    **1428년** 아즈텍 제국이 성립했을 때, 옥스퍼드는 이미 300년 넘게 학자를 배출해 온 대학이었습니다. 연표를 나란히 놓고 보면 역사의 시간 감각이 완전히 달라집니다.

                    출처: L. W. B. Brockliss, The University of Oxford: A History (2016)
                    """,
                    isComplete: true,
                    tags: ["역사", "연대기", "교양"],
                    categoryId: "history",
                    postFormat: "TIMELINE",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                cooldownPost: Post(
                    title: "소빙하기가 빚어낸 스트라디바리우스의 울림",
                    text: """
                    1645년부터 1715년 사이 유럽은 **마운더 극소기**의 혹한을 겪었습니다. 알프스 가문비나무가 극도로 느리게 자라며 나이테가 촘촘히 압축된 고밀도 목재가 탄생했습니다.

                    스트라디바리는 바로 그 *기후가 압축한 나무*로 황금기 바이올린을 깎았습니다. 전설의 음색은 비밀 바니시가 아니라 나무결에 새겨진 겨울이었습니다.

                    출처: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
                    """,
                    isComplete: true,
                    tags: ["음악", "기후", "공예"],
                    categoryId: "music",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-180)
                ),
                deepDiveBody: """
                1428년 아즈텍 삼국 동맹이 출범했을 때 옥스퍼드는 이미 도서관을 확장 중이었고, 마추픽추는 아직 지어지지도 않은 상태였습니다.

                그보다 앞서 모로코 페스의 알카라위인(859년)과 볼로냐 대학교(1088년)도 이미 수세기째 학문을 이어오고 있었습니다.

                출처: Michael E. Smith, The Aztecs (2012)
                """,
                allChips: ["바우하우스", "일본 영화", "스토아 철학", "역사"],
                activeChips: ["바우하우스", "역사"],
                historySubtopics: [
                    "1518년 춤추는 역병", "호주 에뮤 전쟁", "38분 전쟁",
                    "풍선 유령 군대", "나폴레옹과 토끼", "1904 마라톤 대혼란",
                    "고대 로마 길거리 음식", "사무라이와 팩스", "아야 소피아 룬 문자",
                    "오스만 커피하우스 첩보", "튤립 광풍", "알렉산드리아 미스터리"
                ],
                filmSubtopics: [
                    "큐브릭 f/0.7 렌즈", "쿨레쇼프 효과", "구로사와 먹물 비",
                    "아키라 24fps 작화", "1917 원테이크 리그", "폴리 사운드 비밀",
                    "현기증 달리 줌", "타르콥스키 폴라로이드", "지브리 수채화 하늘",
                    "레오네의 정적 편집", "네온 누아르 조명"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "서연",
                        authorUsername: "seoyeon",
                        title: "구로사와 아키라가 비에 먹물을 섞은 이유",
                        text: """
                        영화 <라쇼몽>에서 맑은 물이 흑백 필름에 찍히지 않자 인공 비에 먹물을 섞었습니다.

                        출처: Donald Richie, The Films of Akira Kurosawa (1965)
                        """,
                        tags: ["영화", "연출"],
                        originalCreatedAt: Date().addingTimeInterval(-3600),
                        sharedAt: Date().addingTimeInterval(-1800),
                        deepDiveText: "소방차 펌프로 먹물을 섞은 비를 세트에 뿌렸습니다.",
                        reactionCounts: ["like": 28],
                        totalReactions: 28,
                        commentCount: 5
                    ),
                    SharedPost(
                        authorId: "u_kenji",
                        authorName: "민준",
                        authorUsername: "minjun",
                        title: "도쿄 지하철 승강장의 7초 멜로디",
                        text: """
                        야마노테선 각 승강장은 승객의 스트레스를 낮추기 위해 작곡된 고유의 출발 멜로디를 들려줍니다.

                        출처: 무카이야 미노루 온가쿠칸 아카이브 (2012)
                        """,
                        tags: ["디자인", "음악"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    ),
                    SharedPost(
                        authorId: "u_elena",
                        authorName: "지우",
                        authorUsername: "jiwoo",
                        title: "스스로 균열을 치유하는 로마 콘크리트",
                        text: """
                        생석회 입자가 바닷물과 반응해 수천 년 동안 균열을 스스로 메워 나갑니다.

                        출처: Admir Masic et al., Science Advances (2023)
                        """,
                        tags: ["건축", "과학"],
                        originalCreatedAt: Date().addingTimeInterval(-9800),
                        sharedAt: Date().addingTimeInterval(-8100),
                        reactionCounts: ["like": 42],
                        totalReactions: 42,
                        commentCount: 8
                    )
                ]
            )
        }
    }
}
#endif
