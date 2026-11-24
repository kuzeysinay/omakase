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
    case deepdive
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

    private var l10n: L10n { L10n(lang: config.language) }
    private var content: LocalizedScreenshotContent { .forLanguage(config.language) }

    init(config: ScreenshotLaunchConfig) {
        self.config = config
        _selectedTab = State(initialValue: config.scene == .community ? .community : .feed)
        _showDeepDiveSheet = State(initialValue: config.scene == .deepdive)
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
                case .feed, .deepdive:
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
                        allInterests: content.allChips,
                        activeInterests: $activeInterests,
                        onAddInterest: { _ in },
                        onRemoveInterest: { _ in },
                        isLetterboxdActive: $isLetterboxdActive,
                        isGenerating: false,
                        isOffline: false,
                        isCooldownActive: false,
                        cooldownRemaining: 0,
                        cooldownTotal: 0,
                        hasExistingPosts: true
                    )
                case .cooldown:
                    BentoTasteBox(
                        allInterests: content.allChips,
                        activeInterests: $activeInterests,
                        onAddInterest: { _ in },
                        onRemoveInterest: { _ in },
                        isLetterboxdActive: $isLetterboxdActive,
                        isGenerating: false,
                        isOffline: false,
                        isCooldownActive: true,
                        cooldownRemaining: 16,
                        cooldownTotal: 20,
                        hasExistingPosts: true,
                        initialSubtopicCategory: InterestCategory.category(forId: "science") ?? InterestCategory.presets.first,
                        initialSubtopics: content.scienceSubtopics
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
                            .frame(width: geo.size.width * 0.78)
                    }
                }
                .frame(height: 3.0)
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
                    LazyVStack(spacing: 14) {
                        ForEach(content.communityPosts) { post in
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
                    .padding(.vertical, 14)
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
    let deepDiveBody: String
    let allChips: [String]
    let activeChips: [String]
    let scienceSubtopics: [String]
    let communityPosts: [SharedPost]

    static func forLanguage(_ lang: AppLanguage) -> LocalizedScreenshotContent {
        switch lang {
        case .english:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "Why Gothic Cathedrals Can Whisper Across 30 Meters",
                    text: """
                    Walk into the dome of St. Paul's Cathedral in London, press your ear to the stone wall, and someone whispering *thirty meters away* will sound as clear as if they stood beside you.

                    Architects didn't discover this by accident—they stumbled onto **acoustic creeping waves**. Sound refuses to bounce straight across a smooth concave wall; instead, it hugs the masonry curve, losing almost no energy along the circumference. Lord Rayleigh proved the physics in 1878, centuries after masons built the stone curves by eye.

                    Source: John William Strutt (Lord Rayleigh), The Theory of Sound, Vol. II (1878)
                    """,
                    isComplete: true,
                    tags: ["Architecture", "Acoustics", "History"],
                    categoryId: "art",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                deepDiveBody: """
                When Christopher Wren raised St. Paul's dome above London in 1708, he angled its interior masonry ring slightly inward by seven degrees. That subtle tilt prevents sound from leaking upward, trapping spoken syllables in a circular acoustic rail.

                Two centuries later, physicists realized the exact same geometry governs optical microresonators—bouncing laser light inside glass spheres to build atomic clocks.

                Source: Lord Rayleigh, Philosophical Magazine (1910)
                """,
                allChips: ["Bauhaus", "Japanese Cinema", "Stoicism", "Acoustics"],
                activeChips: ["Bauhaus", "Acoustics"],
                scienceSubtopics: [
                    "Whispering Galleries", "Bioluminescence", "Rogue Waves",
                    "Antikythera Gear", "Mycelium Networks", "Chronobiology",
                    "Glass Acoustics", "Orbital Resonance", "Cryogenic Ice",
                    "Fermat's Optics", "Fermentation Math", "Deep Sea Vents"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "Mira",
                        authorUsername: "mira",
                        title: "Kurosawa's Ink-Dyed Rain",
                        text: """
                        In Rashomon (1950), Akira Kurosawa poured black ink into the artificial rain because clear water vanished against monochrome film stock.

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
                        title: "Why Tokyo Stations Play Original Melodies",
                        text: """
                        Each Yamanote platform plays a 7-second hassha melody composed to lower commuter cortisol and reduce platform rushes.

                        Source: Minoru Mukaiya, Ongakukan Archives (2012)
                        """,
                        tags: ["Design", "Music"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    )
                ]
            )

        case .turkish:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "Gotik Katedraller 30 Metreden Nasıl Fısıldar?",
                    text: """
                    Londra'daki St. Paul Katedrali'nin kubbe duvarına kulağınızı dayadığınızda, *otuz metre ötedeki* bir fısıltıyı tam yanınızdaymış gibi net duyarsınız.

                    Ortaçağ taş ustalarının göz kararı ördüğü bu içbükey eğri, ses dalgalarını **sürünen akustik dalgalara** dönüştürür. Ses boşlukta dağılmak yerine duvarın kavisine tutunarak neredeyse hiç enerji kaybetmeden çevreyi dolaşır. Lord Rayleigh bu etkiyi ancak 1878'de matematiksel olarak kanıtlayabildi.

                    Kaynak: John William Strutt (Lord Rayleigh), The Theory of Sound, Cilt II (1878)
                    """,
                    isComplete: true,
                    tags: ["Mimari", "Akustik", "Tarih"],
                    categoryId: "art",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                deepDiveBody: """
                Christopher Wren 1708'de St. Paul kubbesini inşa ederken iç taş halkayı yukarıya doğru yedi derece eğimli tasarladı. Bu küçük açı, sesin kaçmasını engelleyip fısıltıyı dairesel bir raya hapseder.

                İki yüzyıl sonra fizikçiler aynı geometrinin optik mikro-rezonatörler için de geçerli olduğunu ve lazer ışığını atom saatlerinde hapsedebildiğini keşfetti.

                Kaynak: Lord Rayleigh, Philosophical Magazine (1910)
                """,
                allChips: ["Bauhaus", "Japon Sineması", "Stoacılık", "Akustik"],
                activeChips: ["Bauhaus", "Akustik"],
                scienceSubtopics: [
                    "Fısıltı Galerileri", "Biyolüminesans", "Dev Dalgalar",
                    "Antikythera Çarkı", "Misel Ağları", "Kronobiyoloji",
                    "Cam Akustiği", "Yörünge Rezonansı", "Kriyojenik Buz",
                    "Fermat Optiği", "Fermentasyon", "Derin Deniz Bacaları"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "Defne",
                        authorUsername: "defne",
                        title: "Kurosawa'nın Yağmuruna Karışan Mürekkep",
                        text: """
                        Akira Kurosawa Rashomon (1950) filminde şeffaf su siyah-beyaz filmde görünmediği için yapay yağmura siyah mürekkep karıştırdı.

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
                        authorName: "Emre",
                        authorUsername: "emre",
                        title: "Tokyo İstasyonlarının Özgün Kalkış Melodileri",
                        text: """
                        Yamanote hattındaki her peron, yolcu stresini azaltmak için bestelenmiş 7 saniyelik özgün bir hassha melodisi çalar.

                        Kaynak: Minoru Mukaiya, Ongakukan Arşivi (2012)
                        """,
                        tags: ["Tasarım", "Müzik"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    )
                ]
            )

        case .japanese:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "30メートル先の囁きが届く大聖堂の秘密",
                    text: """
                    ロンドンのセント・ポール大聖堂の回廊で壁に耳を当てると、*30メートル離れた*場所の小さな囁きが、すぐ隣にいるかのように鮮明に聞こえます。

                    石工が経験則で築いた滑らかな凹面は、音波を空間に拡散させず**回廊の壁沿いに這わせる**現象を生みます。エネルギーをほとんど失わずに進むこの物理法則は、完成から約2世紀後の1878年にレイリー卿によって解明されました。

                    出典: John William Strutt (Lord Rayleigh), The Theory of Sound, Vol. II (1878)
                    """,
                    isComplete: true,
                    tags: ["建築", "音響", "歴史"],
                    categoryId: "art",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                deepDiveBody: """
                1708年、建築家クリストファー・レンはドーム内壁をわずかに7度内傾させました。この繊細な傾きが音の上方への拡散を防ぎ、囁きを円形の軌道に閉じ込めます。

                二世紀後、物理学者たちは同じ幾何学が光マイクロ共振器や原子時計にも応用できることに気づきました。

                出典: Lord Rayleigh, Philosophical Magazine (1910)
                """,
                allChips: ["バウハウス", "日本映画", "ストア派", "音響学"],
                activeChips: ["バウハウス", "音響学"],
                scienceSubtopics: [
                    "囁きの回廊", "生物発光", "三角波",
                    "アンティキティラ", "菌糸ネットワーク", "時間生物学",
                    "ガラス音響", "軌道共鳴", "極低温氷",
                    "フェルマーの原理", "発酵の数理", "熱水噴出孔"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "美咲",
                        authorUsername: "misaki",
                        title: "黒澤明『羅生門』の墨を混ぜた雨",
                        text: """
                        1950年の映画『羅生門』で、黒澤明は透明な水がモノクロフィルムに映らないため、放水に墨汁を混ぜて雨を撮りました。

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
                        山手線の各ホームで流れる7秒間の発車メロディは、乗客の焦りを和らげる音響心理学から設計されています。

                        出典: 向谷実 音楽館サウンドアーカイブ (2012)
                        """,
                        tags: ["デザイン", "音楽"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    )
                ]
            )

        case .german:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "Wie Kathedralen über 30 Meter flüstern",
                    text: """
                    Lehnt man das Ohr an die Innenwand der Londoner St. Paul's Cathedral, klingt ein Flüstern aus *dreißig Metern Entfernung* so klar, als stünde jemand direkt daneben.

                    Die glatte Rundung lenkt Schall als **Flüstergalerie-Welle** entlang des Mauerwerks, statt ihn im Raum zu verlieren. Lord Rayleigh bewies die Physik dahinter 1878 – Jahrhunderte nach den Steinmetzen.

                    Quelle: John William Strutt (Lord Rayleigh), The Theory of Sound, Bd. II (1878)
                    """,
                    isComplete: true,
                    tags: ["Architektur", "Akustik", "Geschichte"],
                    categoryId: "art",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                deepDiveBody: """
                Als Christopher Wren 1708 die Kuppel vollendete, neigte er den inneren Steinring um exakt sieben Grad nach innen. Diese Neigung hält Schallwellen auf einer kreisförmigen Bahn.

                Zwei Jahrhunderte später nutzte die Photonik dieselbe Geometrie für optische Mikroresonatoren in Atomuhren.

                Quelle: Lord Rayleigh, Philosophical Magazine (1910)
                """,
                allChips: ["Bauhaus", "Japanisches Kino", "Stoizismus", "Akustik"],
                activeChips: ["Bauhaus", "Akustik"],
                scienceSubtopics: [
                    "Flüstergalerien", "Biolumineszenz", "Monsterwellen",
                    "Antikythera", "Myzel-Netze", "Chronobiologie",
                    "Glasakustik", "Bahnresonanz", "Kryo-Eis",
                    "Fermat-Optik", "Fermentation", "Tiefseeschlote"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "Clara",
                        authorUsername: "clara",
                        title: "Kurosawas Regen mit schwarzer Tinte",
                        text: """
                        Für Rashomon (1950) mischte Akira Kurosawa schwarze Tinte ins Wasser, weil klarer Regen auf Schwarzweißfilm unsichtbar blieb.

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
                        Jeder Bahnsteig der Yamanote-Linie spielt eine eigene 7-Sekunden-Melodie, die Stress abbaut und Gedränge reduziert.

                        Quelle: Minoru Mukaiya, Ongakukan Archives (2012)
                        """,
                        tags: ["Design", "Musik"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    )
                ]
            )

        case .french:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "Le secret des voûtes qui chuchotent à 30 mètres",
                    text: """
                    Dans la coupole de Saint-Paul à Londres, collez votre oreille contre la pierre : un murmure prononcé à *trente mètres* vous parvient avec une netteté saisissante.

                    La courbe concave piège le son en **ondes rampantes** qui longent la maçonnerie sans se dissiper. Lord Rayleigh en démontra la physique en 1878, bien après les bâtisseurs.

                    Source : John William Strutt (Lord Rayleigh), The Theory of Sound, Vol. II (1878)
                    """,
                    isComplete: true,
                    tags: ["Architecture", "Acoustique", "Histoire"],
                    categoryId: "art",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                deepDiveBody: """
                En 1708, Christopher Wren inclina l'anneau intérieur de la coupole de sept degrés vers l'intérieur. Cette inclinaison maintient les voix sur un rail circulaire.

                Deux siècles plus tard, la photonique reprit la même géométrie pour piéger la lumière laser dans des microrésonateurs optiques.

                Source : Lord Rayleigh, Philosophical Magazine (1910)
                """,
                allChips: ["Bauhaus", "Cinéma japonais", "Stoïcisme", "Acoustique"],
                activeChips: ["Bauhaus", "Acoustique"],
                scienceSubtopics: [
                    "Galeries d'écho", "Bioluminescence", "Vagues scélérates",
                    "Anticythère", "Mycélium", "Chronobiologie",
                    "Acoustique du verre", "Résonance", "Glace cryogénique",
                    "Optique de Fermat", "Fermentation", "Sources abyssales"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "Camille",
                        authorUsername: "camille",
                        title: "L'encre noire dans la pluie de Kurosawa",
                        text: """
                        Dans Rashomon (1950), Akira Kurosawa teinta l'eau de pluie à l'encre noire pour qu'elle reste visible sur la pellicule monochrome.

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
                        Chaque quai de la ligne Yamanote diffuse un motif de 7 secondes conçu pour réduire l'anxiété des voyageurs sans hausser le volume.

                        Source : Minoru Mukaiya, Archives Ongakukan (2012)
                        """,
                        tags: ["Design", "Musique"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    )
                ]
            )

        case .spanish:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "Por qué las catedrales susurran a 30 metros",
                    text: """
                    Pega el oído al muro de la cúpula de San Pablo en Londres: un susurro emitido a *treinta metros* llega con la claridad de quien habla justo a tu lado.

                    La curva de piedra guía el sonido como **ondas acústicas rasantes** que abrazan la pared sin perder energía. Lord Rayleigh demostró la física en 1878, siglos después de sus constructores.

                    Fuente: John William Strutt (Lord Rayleigh), The Theory of Sound, Vol. II (1878)
                    """,
                    isComplete: true,
                    tags: ["Arquitectura", "Acústica", "Historia"],
                    categoryId: "art",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                deepDiveBody: """
                En 1708, Christopher Wren inclinó siete grados hacia adentro el anillo de piedra de la cúpula. Ese giro sutil evita que el sonido escape y lo mantiene girando en un riel circular.

                Dos siglos después, la fotónica aplicó la misma geometría en microrresonadores ópticos para construir relojes atómicos.

                Fuente: Lord Rayleigh, Philosophical Magazine (1910)
                """,
                allChips: ["Bauhaus", "Cine japonés", "Estoicismo", "Acústica"],
                activeChips: ["Bauhaus", "Acústica"],
                scienceSubtopics: [
                    "Galerías de eco", "Bioluminiscencia", "Olas gigantes",
                    "Anticitera", "Redes de micelio", "Cronobiología",
                    "Acústica vítrea", "Resonancia orbital", "Hielo criogénico",
                    "Óptica de Fermat", "Fermentación", "Fumarolas abisales"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "Lucía",
                        authorUsername: "lucia",
                        title: "Tinta negra en la lluvia de Kurosawa",
                        text: """
                        En Rashomon (1950), Akira Kurosawa tiñó la lluvia artificial con tinta china porque el agua limpia desaparecía en el blanco y negro.

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
                        Cada andén de la línea Yamanote reproduce un motivo de 7 segundos diseñado para reducir el estrés sin aumentar el ruido.

                        Fuente: Minoru Mukaiya, Archivos Ongakukan (2012)
                        """,
                        tags: ["Diseño", "Música"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    )
                ]
            )

        case .korean:
            return LocalizedScreenshotContent(
                heroPost: Post(
                    title: "30미터 밖 속삭임이 들리는 대성당의 비밀",
                    text: """
                    런던 세인트폴 대성당 돔 벽에 귀를 대면 *30미터 떨어진* 곳의 작은 속삭임도 바로 옆에서 말하듯 선명하게 들립니다.

                    매끄러운 오목 곡면이 소리를 공간으로 흩어뜨리지 않고 **벽을 따라 기어가는 음파**로 바꾸기 때문입니다. 1878년 레일리 경이 물리 법칙으로 증명하기 수세기 전, 석공들은 이미 감각으로 이 곡선을 쌓아 올렸습니다.

                    출처: John William Strutt (Lord Rayleigh), The Theory of Sound, Vol. II (1878)
                    """,
                    isComplete: true,
                    tags: ["건축", "음향학", "역사"],
                    categoryId: "art",
                    postFormat: "UNLIKELY CONNECTION",
                    createdAt: Date().addingTimeInterval(-420)
                ),
                deepDiveBody: """
                1708년 크리스토퍼 렌은 돔 내벽을 안쪽으로 7도 기울여 설계했습니다. 이 미세한 기울기가 소리가 위로 새어 나가는 것을 막고 원형 궤도에 가둡니다.

                200년 뒤 물리학자들은 같은 기하학이 원자시계용 광 마이크로 공진기에도 적용됨을 발견했습니다.

                출처: Lord Rayleigh, Philosophical Magazine (1910)
                """,
                allChips: ["바우하우스", "일본 영화", "스토아 철학", "음향학"],
                activeChips: ["바우하우스", "음향학"],
                scienceSubtopics: [
                    "속삭임의 회랑", "생물 발광", "괴물 파도",
                    "안티키테라", "균사체 네트워크", "시간생물학",
                    "유리 음향", "궤도 공명", "극저온 얼음",
                    "페르마 광학", "발효의 수학", "심해 열수구"
                ],
                communityPosts: [
                    SharedPost(
                        authorId: "u_mira",
                        authorName: "서연",
                        authorUsername: "seoyeon",
                        title: "구로사와 아키라가 비에 먹물을 섞은 이유",
                        text: """
                        1950년 영화 <라쇼몽>에서 구로사와 아키라는 맑은 물이 흑백 필름에 찍히지 않자 인공 비에 검은 먹물을 섞었습니다.

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
                        야마노테선 각 승강장은 승객의 스트레스를 낮추기 위해 음향 심리학으로 작곡된 고유의 출발 멜로디를 들려줍니다.

                        출처: 무카이야 미노루 온가쿠칸 아카이브 (2012)
                        """,
                        tags: ["디자인", "음악"],
                        originalCreatedAt: Date().addingTimeInterval(-7200),
                        sharedAt: Date().addingTimeInterval(-5400),
                        reactionCounts: ["like": 19],
                        totalReactions: 19,
                        commentCount: 3
                    )
                ]
            )
        }
    }
}
#endif
