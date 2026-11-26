//
//  WidgetTopicCatalog.swift
//  omakaseWidget
//
//  Lightweight shared App Group reader and 7-language subtopic catalog for Omakase widgets.
//

import Foundation

enum WidgetLanguage: String, CaseIterable {
    case english = "en"
    case turkish = "tr"
    case japanese = "ja"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case korean = "ko"

    static func resolved(from defaults: UserDefaults?) -> WidgetLanguage {
        if let code = defaults?.string(forKey: "omakase.widget.language"),
           let stored = WidgetLanguage(rawValue: code) {
            return stored
        }
        for preferred in Locale.preferredLanguages {
            let lower = preferred.lowercased()
            let base = lower.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? lower
            if let match = WidgetLanguage(rawValue: base) {
                return match
            }
        }
        return .english
    }

    func monthlyReadLabel(count: Int, compact: Bool = false) -> String {
        switch self {
        case .turkish:
            return compact ? "Bu ay \(count)" : "Bu ay \(count) post"
        case .japanese:
            return compact ? "今月 \(count)" : "今月 \(count)件"
        case .german:
            return compact ? "Monat: \(count)" : "Diesen Monat \(count)"
        case .french:
            return compact ? "Ce mois : \(count)" : "\(count) ce mois-ci"
        case .spanish:
            return compact ? "Mes: \(count)" : "\(count) este mes"
        case .korean:
            return compact ? "이번 달 \(count)" : "이번 달 \(count)편"
        case .english:
            return compact ? "\(count) / mo" : "\(count) this month"
        }
    }

    var widgetDisplayName: String {
        switch self {
        case .turkish: return "Günün Tadımları"
        case .japanese: return "本日のトピック"
        case .german: return "Themen des Tages"
        case .french: return "Sujets du jour"
        case .spanish: return "Temas del día"
        case .korean: return "오늘의 주제"
        case .english: return "Daily Tastes"
        }
    }

    var widgetDescription: String {
        switch self {
        case .turkish: return "Rastgele alt konulara dokun, doğrudan birincil kaynakçalı hikaye üret."
        case .japanese: return "気になるトピックをタップして、一次資料付きストーリーをすぐに読む。"
        case .german: return "Tippe auf ein Thema, um sofort eine Kurzgeschichte mit Primärquelle zu lesen."
        case .french: return "Touchez un sujet pour générer un micro-récit avec source primaire."
        case .spanish: return "Toca cualquier tema para leer una microhistoria con fuente primaria."
        case .korean: return "주제를 탭하면 1차 출처 기반 이야기를 바로 생성해 읽어줍니다."
        case .english: return "Tap any subtopic to jump straight into a sourced micro-story."
        }
    }
}

struct WidgetTopicItem: Identifiable, Hashable {
    let id: String
    let categoryId: String
    let categoryName: String
    let symbolName: String
    let topic: String

    var deepLinkURL: URL {
        var components = URLComponents()
        components.scheme = "omakase"
        components.host = "topic"
        components.queryItems = [
            URLQueryItem(name: "topic", value: topic),
            URLQueryItem(name: "category", value: categoryId)
        ]
        return components.url ?? URL(string: "omakase://feed")!
    }
}

enum WidgetSharedStore {
    static let appGroupID = "group.kuzeysinay.omakase"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func currentMonthKey(for date: Date = Date()) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        return String(format: "%04d-%02d", year, month)
    }

    static func monthlyReadCount(for date: Date = Date()) -> Int {
        guard let defaults else { return 0 }
        guard defaults.string(forKey: "omakase.widget.monthKey") == currentMonthKey(for: date) else {
            return 0
        }
        return max(0, defaults.integer(forKey: "omakase.widget.monthlyReadCount"))
    }

    static func syncedSubtopics() -> [String: [String]] {
        guard let defaults,
              let data = defaults.data(forKey: "omakase.widget.subtopicsByCategory"),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return decoded
    }
}

enum WidgetTopicCatalog {

    struct CategorySpec {
        let id: String
        let symbolName: String
        let names: [WidgetLanguage: String]
        let subtopics: [WidgetLanguage: [String]]
    }

    static func sampleTopics(
        count: Int,
        language: WidgetLanguage,
        syncedByCategory: [String: [String]] = [:]
    ) -> [WidgetTopicItem] {
        let shuffledCategories = categories.shuffled()
        var results: [WidgetTopicItem] = []

        for category in shuffledCategories.prefix(count) {
            let syncedPool = syncedByCategory[category.id] ?? []
            let fallbackPool = category.subtopics[language] ?? category.subtopics[.english] ?? []
            let pool = !syncedPool.isEmpty ? syncedPool : fallbackPool
            guard let pickedTopic = pool.randomElement() else { continue }

            let catName = category.names[language] ?? category.names[.english] ?? category.id
            results.append(
                WidgetTopicItem(
                    id: "\(category.id):\(pickedTopic)",
                    categoryId: category.id,
                    categoryName: catName,
                    symbolName: category.symbolName,
                    topic: pickedTopic
                )
            )
        }
        return results
    }

    static func previewTopics(count: Int, language: WidgetLanguage) -> [WidgetTopicItem] {
        var results: [WidgetTopicItem] = []
        for category in categories.prefix(count) {
            let pool = category.subtopics[language] ?? category.subtopics[.english] ?? []
            guard let pickedTopic = pool.first else { continue }
            let catName = category.names[language] ?? category.names[.english] ?? category.id
            results.append(
                WidgetTopicItem(
                    id: "\(category.id):\(pickedTopic)",
                    categoryId: category.id,
                    categoryName: catName,
                    symbolName: category.symbolName,
                    topic: pickedTopic
                )
            )
        }
        return results
    }

    private static let categories: [CategorySpec] = [
        CategorySpec(
            id: "film",
            symbolName: "film",
            names: [
                .english: "Film", .turkish: "Sinema", .japanese: "映画",
                .german: "Film", .french: "Cinéma", .spanish: "Cine", .korean: "영화"
            ],
            subtopics: [
                .english: ["Kubrick f/0.7 Lens", "Kurosawa's Ink Rain", "Akira 24fps Cels", "Vertigo Dolly Zoom", "Foley Sound Secrets"],
                .turkish: ["Kubrick f/0.7 Lensi", "Kurosawa Mürekkep Yağmuru", "Akira 24fps Kareleri", "Vertigo Dolly Zoom", "Foley Ses Sırları"],
                .japanese: ["キューブリック f/0.7", "黒澤の墨入り雨", "AKIRA 24fps作画", "めまい ドリーズーム", "フォーリー効果音"],
                .german: ["Kubrick f/0,7-Linse", "Kurosawas Tinte-Regen", "Akira 24fps-Cels", "Vertigo Dolly-Zoom", "Foley-Sounddesign"],
                .french: ["Objectif Kubrick f/0,7", "Pluie d'encre Kurosawa", "Akira 24 i/s", "Travelling compensé", "Secrets du bruitage"],
                .spanish: ["Lente Kubrick f/0.7", "Lluvia de tinta Kurosawa", "Cels de Akira 24fps", "Dolly Zoom de Vértigo", "Secretos del Foley"],
                .korean: ["큐브릭 f/0.7 렌즈", "구로사와 먹물 비", "아키라 24fps 작화", "현기증 달리 줌", "폴리 음향의 비밀"]
            ]
        ),
        CategorySpec(
            id: "music",
            symbolName: "music.note",
            names: [
                .english: "Music", .turkish: "Müzik", .japanese: "音楽",
                .german: "Musik", .french: "Musique", .spanish: "Música", .korean: "음악"
            ],
            subtopics: [
                .english: ["Stradivarius Ice Age Wood", "Tokyo Station Melodies", "X-Ray Jazz Bootlegs", "432 Hz Myth", "Roland TR-808"],
                .turkish: ["Stradivarius Buzul Ahşabı", "Tokyo İstasyon Melodileri", "Röntgen Plak Caz", "432 Hz Efsanesi", "Roland TR-808"],
                .japanese: ["ストラディバリ小氷期材", "駅の発車メロディ", "X線フィルムの密造ジャズ", "432Hz神話", "Roland TR-808"],
                .german: ["Stradivari-Eiszeitholz", "Tokios Bahnhofsmelodien", "Röntgen-Jazz-Platten", "432-Hz-Mythos", "Roland TR-808"],
                .french: ["Bois glaciaire Stradivarius", "Mélodies des gares Tokyo", "Disques de jazz sur radio", "Mythe du 432 Hz", "Roland TR-808"],
                .spanish: ["Madera Stradivarius", "Melodías de Tokio", "Jazz en radiografías", "Mito de los 432 Hz", "Roland TR-808"],
                .korean: ["스트라디바리 소빙기 목재", "도쿄역 발차 멜로디", "엑스레이 재즈 음반", "432Hz 신화", "롤랜드 TR-808"]
            ]
        ),
        CategorySpec(
            id: "science",
            symbolName: "atom",
            names: [
                .english: "Science", .turkish: "Bilim", .japanese: "科学",
                .german: "Wissenschaft", .french: "Sciences", .spanish: "Ciencia", .korean: "과학"
            ],
            subtopics: [
                .english: ["Self-Healing Roman Concrete", "Tardigrades in Space", "Voyager Golden Record", "Blue Whales' Earwax", "Quantum Tunneling"],
                .turkish: ["Kendini Onaran Roma Betonu", "Uzayda Tardigradlar", "Voyager Altın Plağı", "Mavi Balina Kulak Kiri", "Kuantum Tünelleme"],
                .japanese: ["自己修復ローマコンクリート", "宇宙のクマムシ", "ボイジャーのゴールデンレコード", "シロナガスクジラの耳垢", "量子トンネル効果"],
                .german: ["Selbstheilender Römerbeton", "Bärtierchen im All", "Voyager Golden Record", "Blauwal-Ohrschmalz", "Quantentunneln"],
                .french: ["Béton romain auto-cicatrisant", "Tardigrades dans l'espace", "Disque d'or Voyager", "Cérumen des rorquals", "Effet tunnel quantique"],
                .spanish: ["Hormigón romano autorreparable", "Tardígrados en el espacio", "Disco de Oro Voyager", "Cerumen de ballena azul", "Efecto túnel cuántico"],
                .korean: ["자가 치유 로마 콘크리트", "우주의 완보동물", "보이저 골든 레코드", "대왕고래 귀지의 나이테", "양자 터널링"]
            ]
        ),
        CategorySpec(
            id: "food",
            symbolName: "fork.knife",
            names: [
                .english: "Food", .turkish: "Yemek", .japanese: "食",
                .german: "Küche", .french: "Gastronomie", .spanish: "Gastronomía", .korean: "미식"
            ],
            subtopics: [
                .english: ["Roman Garum Sauce", "Fake Wasabi Horseradish", "120-Year Sourdough", "Saffron's Harvest Math", "Astronaut Espresso"],
                .turkish: ["Roma Garum Sosu", "Sahte Wasabi Turpu", "120 Yıllık Ekşi Maya", "Safran Hasat Matematiği", "Uzayda Espresso"],
                .japanese: ["古代ローマの魚醤ガルム", "本物と偽物のわさび", "120年もののサワードウ", "サフラン収穫の手間", "宇宙のエスプレッソ"],
                .german: ["Römisches Garum", "Echter vs. falscher Wasabi", "120-jähriger Sauerteig", "Safran-Ernte-Mathe", "Espresso im All"],
                .french: ["Garum de la Rome antique", "Vrai et faux wasabi", "Levain de 120 ans", "Économie du safran", "Expresso spatial"],
                .spanish: ["Salsa garum romana", "Wasabi real vs. rábano", "Masa madre de 120 años", "Matemática del azafrán", "Espresso espacial"],
                .korean: ["고대 로마 가룸 소스", "진짜 와사비와 서양고추냉이", "120년 된 사워도우", "사프란 수확의 비밀", "우주 정거장 에스프레소"]
            ]
        ),
        CategorySpec(
            id: "history",
            symbolName: "clock.arrow.circlepath",
            names: [
                .english: "History", .turkish: "Tarih", .japanese: "歴史",
                .german: "Geschichte", .french: "Histoire", .spanish: "Historia", .korean: "역사"
            ],
            subtopics: [
                .english: ["Oxford vs. Aztec Empire", "1518 Dancing Plague", "38-Minute War", "Viking Runes in Istanbul", "WWII Ghost Army"],
                .turkish: ["Oxford ve Aztekler", "1518 Dans Vebası", "38 Dakikalık Savaş", "Ayasofya Viking Yazısı", "Şişme Hayalet Ordu"],
                .japanese: ["オックスフォードとアステカ", "1518年踊るペスト", "38分間戦争", "大聖堂のルーン文字", "空気注入の幽霊軍"],
                .german: ["Oxford vs. Aztekenreich", "Tanzwut von 1518", "38-Minuten-Krieg", "Wikinger-Runen", "Geisterarmee im 2. WK"],
                .french: ["Oxford vs Empire aztèque", "Peste dansante de 1518", "Guerre de 38 minutes", "Runes vikings à Istanbul", "Armée fantôme"],
                .spanish: ["Oxford vs. Imperio azteca", "Peste del baile de 1518", "Guerra de 38 minutos", "Runas vikingas", "Ejército fantasma"],
                .korean: ["옥스퍼드 vs 아즈텍", "1518년 춤추는 전염병", "38분 전쟁", "이스탄불의 바이킹 룬", "2차 대전 유령 부대"]
            ]
        ),
        CategorySpec(
            id: "sports",
            symbolName: "figure.run",
            names: [
                .english: "Sports", .turkish: "Spor", .japanese: "スポーツ",
                .german: "Sport", .french: "Sport", .spanish: "Deportes", .korean: "스포츠"
            ],
            subtopics: [
                .english: ["1904 Olympic Marathon", "Fosbury Flop Revolution", "1974 East-West Derby", "Tennis 15-30-40 Origin", "Sumo Salt Ritual"],
                .turkish: ["1904 Olimpiyat Maratonu", "Fosbury Flop Devrimi", "1974 Doğu-Batı Derbisi", "Teniste 15-30-40 Kökeni", "Sumo Tuz Ritüeli"],
                .japanese: ["1904年五輪マラソン", "背面跳び革命", "1974年東西ドイツ戦", "テニスの15-30-40", "大相撲の塩まき"],
                .german: ["Olympia-Marathon 1904", "Fosbury-Flop-Revolution", "Derby BRD–DDR 1974", "Tennis-Zählweise 15-30-40", "Sumo-Salzritual"],
                .french: ["Marathon olympique 1904", "Révolution Fosbury Flop", "Derby RFA–RDA 1974", "Origine du 15-30-40", "Rituel du sel au sumo"],
                .spanish: ["Maratón olímpico 1904", "Revolución Fosbury Flop", "Derbi Alemania 1974", "Origen del 15-30-40", "Ritual de la sal en sumo"],
                .korean: ["1904년 올림픽 마라톤", "포스베리 플롭 혁명", "1974년 동서독 더비", "테니스 15-30-40 유래", "스모의 소금 의식"]
            ]
        ),
        CategorySpec(
            id: "tech",
            symbolName: "cpu",
            names: [
                .english: "Tech", .turkish: "Teknoloji", .japanese: "テクノロジー",
                .german: "Technik", .french: "Tech", .spanish: "Tecnología", .korean: "테크"
            ],
            subtopics: [
                .english: ["1947 First Moth Bug", "Apollo Rope Memory", "Undersea Fiber Sharks", "RSA Prime Security", "UNIX Epoch 1970"],
                .turkish: ["1947 İlk Güve Böceği", "Apollo İp Bellek", "Denizaltı Kablo Köpekbalığı", "RSA Asal Güvenliği", "UNIX 1970 Çağı"],
                .japanese: ["1947年最初のバグ", "アポロのコアロープメモリ", "海底ケーブルとサメ", "RSA素数暗号", "UNIXエポック1970"],
                .german: ["Erster Moth-Bug 1947", "Apollo-Seilspeicher", "Haie & Seekabel", "RSA-Primzahlen", "UNIX-Epoche 1970"],
                .french: ["Premier bug de 1947", "Mémoire tissée Apollo", "Requins et câbles marins", "Nombres premiers RSA", "Époque UNIX 1970"],
                .spanish: ["Primer bug de 1947", "Memoria tejida Apollo", "Tiburones y cables", "Primos RSA", "Época UNIX 1970"],
                .korean: ["1947년 최초의 버그", "아폴로 코어 로프 메모리", "해저 케이블과 상어", "RSA 소수 암호", "유닉스 에포크 1970"]
            ]
        ),
        CategorySpec(
            id: "nature",
            symbolName: "leaf",
            names: [
                .english: "Nature", .turkish: "Doğa", .japanese: "自然",
                .german: "Natur", .french: "Nature", .spanish: "Naturaleza", .korean: "자연"
            ],
            subtopics: [
                .english: ["Wood Wide Web Fungi", "Octopus Three Hearts", "Immortal Jellyfish", "Whale Fall Ecosystems", "Sahara Rain Cycles"],
                .turkish: ["Orman Mantar Ağı", "Ahtapotun Üç Kalbi", "Ölümsüz Denizanası", "Balina Düşüşü Ekosistemi", "Sahra Yağmur Döngüsü"],
                .japanese: ["森の菌類ネットワーク", "タコの3つの心臓", "ベニクラゲの若返り", "鯨骨生物群集", "サハラの緑化周期"],
                .german: ["Wood Wide Web Pilze", "Drei Herzen des Oktopus", "Unsterbliche Qualle", "Walsturz-Ökosysteme", "Sahara-Regenzyklen"],
                .french: ["Réseau mycorhizien", "Trois cœurs du poulpe", "Méduse immortelle", "Écosystème des chutes", "Cycles verts du Sahara"],
                .spanish: ["Red fúngica del bosque", "Tres corazones del pulpo", "Medusa inmortal", "Caída de ballenas", "Ciclos del Sahara"],
                .korean: ["숲속 균사 네트워크", "문어의 세 개의 심장", "불멸의 해파리", "고래 사체 생태계", "사하라 사막의 녹화 주기"]
            ]
        ),
        CategorySpec(
            id: "art",
            symbolName: "paintpalette",
            names: [
                .english: "Art", .turkish: "Sanat", .japanese: "アート",
                .german: "Kunst", .french: "Art", .spanish: "Arte", .korean: "예술"
            ],
            subtopics: [
                .english: ["Kintsugi Gold Joinery", "Ultramarine Lapis Lazuli", "Brunelleschi's Dome", "Bauhaus Color Theory", "Vermeer Camera Obscura"],
                .turkish: ["Kintsugi Altın Onarım", "Laciverttaşı Ultramarin", "Brunelleschi Kubbesi", "Bauhaus Renk Kuramı", "Vermeer Karanlık Oda"],
                .japanese: ["金継ぎの美学", "ラピスラズリの青", "ブルネレスキの穹窿", "バウハウスの色彩論", "フェルメールの暗箱"],
                .german: ["Kintsugi-Goldreparatur", "Ultramarin aus Lapislazuli", "Brunelleschis Kuppel", "Bauhaus-Farbenlehre", "Vermeers Camera obscura"],
                .french: ["L'art du kintsugi", "Bleu outremer lapis-lazuli", "Dôme de Brunelleschi", "Couleurs du Bauhaus", "Chambre noire de Vermeer"],
                .spanish: ["Arte del kintsugi", "Azul ultramar lapislázuli", "Cúpula de Brunelleschi", "Teoría del color Bauhaus", "Cámara oscura de Vermeer"],
                .korean: ["킨츠기 황금 수선", "청금석 울트라마린", "브루넬레스키의 돔", "바우하우스 색채 이론", "베르메르 카메라 옵스큐라"]
            ]
        ),
        CategorySpec(
            id: "philosophy",
            symbolName: "brain.head.profile",
            names: [
                .english: "Philosophy", .turkish: "Felsefe", .japanese: "哲学",
                .german: "Philosophie", .french: "Philosophie", .spanish: "Filosofía", .korean: "철학"
            ],
            subtopics: [
                .english: ["Ship of Theseus", "Diogenes & Alexander", "Wittgenstein's Beetle", "Stoic Premeditatio", "Mary's Black-White Room"],
                .turkish: ["Theseus'un Gemisi", "Diyojen ve İskender", "Wittgenstein'ın Böceği", "Stoacı Kötümserlik", "Mary'nin Siyah-Beyaz Odası"],
                .japanese: ["テセウスの船", "ディオゲネスと大王", "ウィトゲンシュタインの箱", "ストア派の事前熟考", "メアリーの部屋"],
                .german: ["Schiff des Theseus", "Diogenes & Alexander", "Wittgensteins Käfer", "Stoische Praemeditatio", "Marys Schwarz-Weiß-Raum"],
                .french: ["Bateau de Thésée", "Diogène et Alexandre", "Scarabée de Wittgenstein", "Praemeditatio stoïcienne", "Chambre de Mary"],
                .spanish: ["Barco de Teseo", "Diógenes y Alejandro", "Escarabajo Wittgenstein", "Premeditación estoica", "La habitación de Mary"],
                .korean: ["테세우스의 배", "디오게네스와 알렉산더", "비트겐슈타인의 딱정벌레", "스토아의 사전 숙고", "메리의 흑백 방"]
            ]
        ),
        CategorySpec(
            id: "travel",
            symbolName: "globe.americas",
            names: [
                .english: "Travel", .turkish: "Seyahat", .japanese: "旅",
                .german: "Reisen", .french: "Voyage", .spanish: "Viajes", .korean: "여행"
            ],
            subtopics: [
                .english: ["Derinkuyu Underground City", "Diomede 21-Hour Border", "Svalbard Seed Vault", "Venice Wooden Piles", "Chongqing Monorail Building"],
                .turkish: ["Derinkuyu Yeraltı Şehri", "Diomede 21 Saat Sınırı", "Svalbard Tohum Deposu", "Venedik Kazık Temelleri", "Bina İçinden Geçen Tren"],
                .japanese: ["デリンクユ地下都市", "ダイオミード諸島の時差", "スヴァールバル種子貯蔵庫", "ヴェネツィアの木杭基礎", "ビルを貫くモノレール"],
                .german: ["Untergrundstadt Derinkuyu", "21-Stunden-Grenze Diomede", "Svalbard-Saatguttresor", "Venedigs Holzpfähle", "Chongqings Haus-Bahn"],
                .french: ["Cité souterraine Derinkuyu", "Décalage îles Diomède", "Réserve de Svalbard", "Pilotis de Venise", "Monorail de Chongqing"],
                .spanish: ["Ciudad subterránea Derinkuyu", "Frontera Diómedes 21h", "Bóveda de Svalbard", "Pilotes de Venecia", "Monorraíl en edificio"],
                .korean: ["데린쿠유 지하 도시", "다이오미드 21시간 시차", "스발바르 종자 저장고", "베네치아 나무 말뚝", "건물을 관통하는 모노레일"]
            ]
        ),
        CategorySpec(
            id: "gaming",
            symbolName: "gamecontroller",
            names: [
                .english: "Gaming", .turkish: "Oyun", .japanese: "ゲーム",
                .german: "Gaming", .french: "Jeux vidéo", .spanish: "Videojuegos", .korean: "게임"
            ],
            subtopics: [
                .english: ["Fast Inverse Square Root", "Space Invaders Speedup", "Crash Bandicoot RAM Hack", "Pac-Man Kill Screen", "Tetris Soviet Journey"],
                .turkish: ["Hızlı Ters Karekök", "Space Invaders Hızlanması", "Crash Bandicoot RAM Hilesi", "Pac-Man 256. Seviye Hatası", "Tetris'in Sovyet Yolculuğu"],
                .japanese: ["高速逆平方根アルゴリズム", "インベーダー加速の偶然", "クラッシュのメモリ術", "パックマン256面バグ", "テトリスの誕生秘話"],
                .german: ["Fast Inverse Square Root", "Space-Invaders-Speedup", "Crash-Bandicoot-RAM-Trick", "Pac-Man Level-256-Bug", "Tetris aus der Sowjetunion"],
                .french: ["Racine carrée inverse rapide", "Accélération Space Invaders", "Astuce RAM Crash Bandicoot", "Bug niveau 256 Pac-Man", "Histoire soviétique Tetris"],
                .spanish: ["Raíz inversa rápida", "Aceleración Space Invaders", "Truco RAM Crash Bandicoot", "Pantalla rota Pac-Man", "Viaje soviético de Tetris"],
                .korean: ["고속 역제곱근 트릭", "스페이스 인베이더 가속", "크래시 밴디쿳 램 해킹", "팩맨 256레벨 오류", "테트리스의 소련 여정"]
            ]
        )
    ]
}
