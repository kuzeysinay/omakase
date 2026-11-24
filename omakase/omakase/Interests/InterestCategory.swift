//
//  InterestCategory.swift
//  omakase
//
//  Static data model and persistent cross-launch rotation store for
//  interest categories and hyper-specific "Wait, what is that?!" sub-topics.
//

import Observation
import SwiftUI

struct InterestCategory: Identifiable, Hashable {
    let id: String          // machine key, e.g. "film"
    let iconName: String    // SF Symbol name, e.g. "film"
    let emoji: String
    let nameEN: String
    let nameTR: String
    let hue: Double         // 0…1, drives subtle tint
    let fallbackInterestsEN: [String]
    let fallbackInterestsTR: [String]

    func localizedName(for lang: AppLanguage) -> String {
        switch lang {
        case .english: return nameEN
        case .turkish: return nameTR
        default: return Self.extraNames[id]?[lang] ?? nameEN
        }
    }

    func fallbackInterests(for lang: AppLanguage) -> [String] {
        switch lang {
        case .english: return fallbackInterestsEN
        case .turkish: return fallbackInterestsTR
        default: return Self.extraFallbacks[id]?[lang] ?? fallbackInterestsEN
        }
    }

    private var allLocalizedNames: [String] {
        [nameEN, nameTR] + Array(Self.extraNames[id]?.values ?? [:].values)
    }

    private var allFallbackInterests: [String] {
        var combined = fallbackInterestsEN + fallbackInterestsTR
        if let extras = Self.extraFallbacks[id]?.values {
            for list in extras {
                combined.append(contentsOf: list)
            }
        }
        return combined
    }

    static func category(forId id: String) -> InterestCategory? {
        presets.first { $0.id.caseInsensitiveCompare(id) == .orderedSame }
    }

    /// Deterministically resolves which of the 12 Main Subjects (`InterestCategory.presets`)
    /// a post or bookmark belongs to, using explicit `categoryId`, preset sub-topic lists,
    /// and multilingual domain keyword scoring.
    static func resolveMainCategory(
        categoryId: String? = nil,
        tags: [String] = [],
        title: String = "",
        text: String = "",
        legacyCollectionName: String? = nil
    ) -> InterestCategory {
        // 1. Direct match on categoryId
        if let cid = categoryId?.trimmingCharacters(in: .whitespacesAndNewlines),
           let direct = category(forId: cid) {
            return direct
        }

        // 2. Direct match on legacyCollectionName or tags against preset IDs or localized names
        let allFolderLabels: Set<String> = [
            "all", "tümü", "すべて", "alle", "tout", "todo", "전체"
        ]
        let candidateTokens = ([legacyCollectionName].compactMap { $0 } + tags)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !allFolderLabels.contains($0.lowercased()) }

        for token in candidateTokens {
            if let match = presets.first(where: { cat in
                cat.id.caseInsensitiveCompare(token) == .orderedSame ||
                cat.allLocalizedNames.contains { $0.caseInsensitiveCompare(token) == .orderedSame }
            }) {
                return match
            }
        }

        // 3. Match against curated sub-topics in each preset (all 7 languages)
        for token in candidateTokens {
            let lowerToken = token.lowercased()
            if let match = presets.first(where: { cat in
                cat.allFallbackInterests.contains { $0.lowercased() == lowerToken }
            }) {
                return match
            }
        }

        // 4. Keyword scoring across tags, legacyCollectionName, title, and body text
        let tagBlob = candidateTokens.joined(separator: " ").lowercased()
        let contentBlob = (title + " " + text).lowercased()

        let domainKeywords: [String: [String]] = [
            "film": [
                "film", "sinema", "movie", "cinema", "yönetmen", "director", "kamera", "lens", "sahne",
                "hollywood", "oscar", "aktör", "oyuncu", "senaryo", "letterboxd", "kurosawa", "kubrick",
                "nolan", "tarantino", "hitchcock", "tarkovski", "scorsese", "fincher", "villeneuve",
                "a24", "giallo", "belgesel", "animasyon", "ghibli", "kurgu", "kadraj", "imax", "technicolor",
                "映画", "シネマ", "監督", "アニメ", "kino", "regisseur", "drehbuch", "cinéma", "réalisateur",
                "película", "cine", "guion", "영화", "감독", "시네마", "촬영"
            ],
            "music": [
                "müzik", "music", "şarkı", "piyano", "gitar", "davul", "akort", "senfoni", "orkestra",
                "caz", "jazz", "rock", "plak", "albüm", "frekans", "beste", "enstrüman", "nota", "koro",
                "melodi", "sentezleyici", "synth", "theremin", "reverb", "vokal", "tını", "konser", "radiohead",
                "音楽", "ピアノ", "楽器", "作曲", "musik", "klavier", "symphonie", "musique", "chanson",
                "música", "canción", "guitarra", "음악", "피아노", "악기", "노래", "재즈"
            ],
            "science": [
                "bilim", "science", "fizik", "kimya", "biyoloji", "atom", "molekül", "gen", "dna", "hücre",
                "deney", "kuantum", "quantum", "crispr", "uzay", "gezegen", "yıldız", "nötron", "nötrino",
                "radyasyon", "reaktör", "evrim", "nöron", "nörobilim", "izotop", "bakteri", "enzim",
                "teleskop", "termodinamik", "foton", "plazma", "helyum", "tardigrad", "astronomi", "astrofizik",
                "科学", "物理", "化学", "生物", "宇宙", "量子", "wissenschaft", "physik", "chemie", "quanten",
                "science", "physique", "chimie", "ciencia", "física", "química", "과학", "물리", "화학", "생물", "우주"
            ],
            "food": [
                "yemek", "food", "mutfak", "cuisine", "ekmek", "bread", "sourdough", "ekşi maya", "peynir",
                "cheese", "şarap", "wine", "kahve", "coffee", "bira", "beer", "sos", "sauce", "garum",
                "pişirme", "restoran", "aşçı", "lezzet", "baharat", "çikolata", "balık", "gastronomi",
                "fermentasyon", "fermentation", "maya", "tuz", "şeker", "çay", "ramen", "kimçi", "trüf",
                "safran", "viski", "şampanya", "fugu", "cheesecake", "ortolan", "zeytinyağı", "makarna",
                "食", "料理", "発酵", "グルメ", "essen", "küche", "wein", "käse", "gastronomie",
                "nourriture", "vin", "fromage", "comida", "cocina", "vino", "음식", "요리", "발효", "미식"
            ],
            "history": [
                "tarih", "history", "imparatorluk", "empire", "savaş", "war", "antik", "ancient", "ortaçağ",
                "medieval", "kral", "padişah", "osmanlı", "ottoman", "roma", "roman", "bizans", "byzantine",
                "mısır", "egypt", "devrim", "antlaşma", "kuşatma", "arkeoloji", "uygarlık", "hanedan",
                "viking", "samuray", "mezopotamya", "inquisition", "veba", "plague", "mÖ", "milattan",
                "歴史", "帝国", "古代", "戦争", "geschichte", "kaiser", "antike", "histoire", "guerre",
                "historia", "imperio", "guerra", "역사", "제국", "고대", "전쟁", "문명"
            ],
            "sports": [
                "spor", "sport", "futbol", "football", "soccer", "basketbol", "formula 1", "f1", "olimpiyat",
                "olympic", "maraton", "koşu", "tenis", "maç", "şampiyon", "rekor", "atlet", "yüzme",
                "boks", "satranç", "chess", "bisiklet", "stadyum", "penaltı", "gol", "nba", "premier lig",
                "sumo", "curling", "kriket", "tırmanış",
                "スポーツ", "サッカー", "オリンピック", "相撲", "fußball", "olympia", "rennen",
                "sport", "football", "marathon", "deportes", "fútbol", "스포츠", "축구", "올림픽", "마라톤"
            ],
            "tech": [
                "teknoloji", "technology", "tech", "bilgisayar", "computer", "yazılım", "software", "algoritma",
                "kod", "internet", "işlemci", "çip", "siber", "şifreleme", "robot", "yapay zeka", "yapay zekâ",
                "ai", "veri", "bellek", "uydu", "lazer", "donanım", "sunucu", "unix", "linux", "transistör",
                "kablo", "derleyici", "rust", "apple", "kuantum bilişim", "blockchain",
                "テクノロジー", "技術", "コンピュータ", "暗号", "technologie", "technik", "informatik",
                "technologie", "informatique", "tecnología", "informática", "기술", "테크", "컴퓨터", "알고리즘"
            ],
            "nature": [
                "doğa", "nature", "hayvan", "bitki", "ağaç", "orman", "okyanus", "deniz", "göl", "çöl",
                "yanardağ", "kuş", "balina", "karınca", "mantar", "ekosistem", "buzul", "mercan",
                "kelebek", "ahtapot", "köpekbalığı", "fosil", "jeoloji", "biyolüminesans", "ekoloji", "kutup",
                "自然", "動物", "深海", "森林", "natur", "tier", "ozean", "wald", "nature", "océan",
                "naturaleza", "océano", "bosque", "자연", "동물", "바다", "생태"
            ],
            "art": [
                "sanat", "art", "tablo", "painting", "resim", "heykel", "sculpture", "mimari", "architecture",
                "müze", "boya", "pigment", "fresk", "seramik", "tasarım", "kubbe", "galeri", "ressam",
                "tuval", "vitray", "baskı", "rönesans", "bauhaus", "brütalizm", "kaligrafi", "tipografi",
                "mona lisa", "michelangelo", "vermeer", "banksy", "kintsugi",
                "アート", "芸術", "絵画", "建築", "kunst", "gemälde", "architektur", "art", "peinture",
                "arte", "pintura", "arquitectura", "예술", "미술", "회화", "건축"
            ],
            "philosophy": [
                "felsefe", "philosophy", "paradoks", "paradox", "etik", "ethics", "ahlak", "bilinç",
                "consciousness", "zihin", "mantık", "düşünce deneyi", "varoluş", "özgür irade", "sokrates",
                "platon", "kant", "nietzsche", "diyojen", "stoacılık", "stoicism", "epistemoloji", "qualıa",
                "qualia", "determinizm", "theseus", "schopenhauer", "foucault", "wittgenstein",
                "哲学", "パラドックス", "思考実験", "philosophie", "paradoxon", "ethik",
                "philosophie", "paradoxe", "filosofía", "paradoja", "철학", "역설", "윤리", "사유"
            ],
            "travel": [
                "seyahat", "travel", "ada", "island", "kasaba", "şehir", "köy", "ülke", "sınır", "coğrafya",
                "rota", "kanyon", "nehir", "tapınak", "manastır", "yeraltı şehri", "svalbard", "patagonya",
                "izlanda", "kyoto", "derinkuyu", "kapadokya", "fiyort", "krater",
                "旅", "旅行", "秘境", "島", "reisen", "insel", "stadt", "voyage", "île",
                "viajes", "isla", "ciudad", "여행", "섬", "지리", "도시"
            ],
            "gaming": [
                "oyun", "game", "gaming", "oyuncu", "konsol", "atari", "playstation", "ps1", "ps2",
                "nintendo", "arcade", "speedrun", "boss", "piksel", "fps", "rpg", "minecraft", "mario",
                "zelda", "tetris", "doom", "quake", "pac-man", "street fighter", "warcraft", "pokemon", "pokémon",
                "ゲーム", "任天堂", "レトロゲーム", "gaming", "spiele", "videospiel", "jeux vidéo",
                "videojuegos", "juegos", "게임", "비디오 게임", "닌텐도"
            ]
        ]

        var bestCategory = presets[2] // default fallback: Science ("science")
        var bestScore = 0

        for cat in presets {
            guard let keywords = domainKeywords[cat.id] else { continue }
            var score = 0
            for kw in keywords {
                if tagBlob.contains(kw) {
                    score += 5 // high weight for tags / legacy collection name
                }
                if contentBlob.contains(kw) {
                    score += 1
                }
            }
            if score > bestScore {
                bestScore = score
                bestCategory = cat
            }
        }

        return bestCategory
    }
}

// MARK: - Persistent Cross-Launch Sub-Topic Rotation & AI Prefetch Store

@Observable
@MainActor
final class SubTopicDiscoveryStore {
    static let shared = SubTopicDiscoveryStore()

    @ObservationIgnored private let seenDefaultsKey = "omakase.seen_subtopics.v4"
    @ObservationIgnored private let prefetchedDefaultsKey = "omakase.prefetched_ai_subtopics.v4"
    @ObservationIgnored private let maxSeenHistoryPerCategory = 60

    /// Keyed by "\(categoryId)_\(lang.rawValue)" -> ordered list of recently shown sub-topics.
    private var seenByKey: [String: [String]] = [:]
    /// Keyed by "\(categoryId)_\(lang.rawValue)" -> ready-to-serve AI-generated batch of 12 sub-topics.
    private var prefetchedByKey: [String: [String]] = [:]
    /// Session-stable 2-item preview per category so RootBentoTile subtitles vary every launch without flickering mid-scroll.
    private var sessionPreviewByKey: [String: String] = [:]
    /// Tracks active in-flight AI expansion requests per "\(categoryId)_\(lang.rawValue)" so launch pre-warm and user taps coalesce without duplicate calls.
    @ObservationIgnored private var inFlightTasksByKey: [String: Task<[String]?, Never>] = [:]
    @ObservationIgnored private var activePrewarmLanguage: AppLanguage?

    private init() {
        loadFromDisk()
    }

    private func storageKey(categoryId: String, language: AppLanguage) -> String {
        "\(categoryId)_\(language.rawValue)"
    }

    /// Returns a 2-item preview string for the root category tile, preferring pre-warmed live AI topics.
    func rootPreview(for category: InterestCategory, language: AppLanguage) -> String {
        let key = storageKey(categoryId: category.id, language: language)
        if let existing = sessionPreviewByKey[key] {
            return existing
        }
        // Prefer pre-warmed live AI sub-topics if already available on disk or memory
        if let aiBatch = prefetchedByKey[key], aiBatch.count >= 2 {
            let preview = Array(aiBatch.prefix(2)).joined(separator: " · ")
            sessionPreviewByKey[key] = preview
            return preview
        }
        // Offline / initial cold-start fallback until background pre-warm completes
        let pool = category.fallbackInterests(for: language)
        let seen = Set(seenByKey[key] ?? [])
        var unseen = pool.filter { !seen.contains($0) }.shuffled()
        if unseen.count < 2 {
            unseen = pool.shuffled()
        }
        let preview = Array(unseen.prefix(2)).joined(separator: " · ")
        sessionPreviewByKey[key] = preview
        return preview
    }

    /// Returns all recently seen sub-topics for a category (used as exclusion list for both local sampling and AI expansion).
    func seenTopics(for categoryId: String, language: AppLanguage) -> [String] {
        let key = storageKey(categoryId: categoryId, language: language)
        return seenByKey[key] ?? []
    }

    /// Consumes and returns a prefetched AI batch if one is waiting (from launch pre-warm, earlier in this session, or persisted from a previous launch).
    func consumePrefetchedBatch(for categoryId: String, language: AppLanguage) -> [String]? {
        let key = storageKey(categoryId: categoryId, language: language)
        guard let batch = prefetchedByKey.removeValue(forKey: key), !batch.isEmpty else {
            return nil
        }
        savePrefetchedToDisk()
        recordSeen(batch, for: categoryId, language: language)
        return batch
    }

    /// Checks whether a prefetched AI batch is already waiting for this category + language.
    func hasPrefetchedBatch(for categoryId: String, language: AppLanguage) -> Bool {
        let key = storageKey(categoryId: categoryId, language: language)
        if let batch = prefetchedByKey[key], !batch.isEmpty {
            return true
        }
        return false
    }

    /// Stores a newly fetched AI batch to memory and disk so the very first open or next refresh is instant.
    func storePrefetchedBatch(_ batch: [String], for categoryId: String, language: AppLanguage) {
        guard !batch.isEmpty else { return }
        let key = storageKey(categoryId: categoryId, language: language)
        prefetchedByKey[key] = batch
        if batch.count >= 2 {
            sessionPreviewByKey[key] = Array(batch.shuffled().prefix(2)).joined(separator: " · ")
        }
        savePrefetchedToDisk()
    }

    /// Silently pre-warms live AI sub-topics for all categories on app launch so even the 1st tap serves unique AI topics in 0ms.
    func prewarmAllCategories(language: AppLanguage, userInterests: [String] = []) {
        let categoriesToWarm = InterestCategory.presets.filter {
            !hasPrefetchedBatch(for: $0.id, language: language)
        }
        guard !categoriesToWarm.isEmpty else { return }
        guard activePrewarmLanguage != language else { return }
        activePrewarmLanguage = language

        Task { @MainActor in
            defer {
                if self.activePrewarmLanguage == language {
                    self.activePrewarmLanguage = nil
                }
            }
            // Warm in bounded waves of 4 so all categories finish quickly (~1.5s) without saturating connections
            let chunkSize = 4
            for startIndex in stride(from: 0, to: categoriesToWarm.count, by: chunkSize) {
                let endIndex = min(startIndex + chunkSize, categoriesToWarm.count)
                let slice = Array(categoriesToWarm[startIndex..<endIndex])
                await withTaskGroup(of: Void.self) { group in
                    for category in slice {
                        group.addTask { @MainActor in
                            _ = await self.ensureLiveBatch(
                                for: category,
                                language: language,
                                additionalExcludes: userInterests
                            )
                        }
                    }
                }
            }
        }
    }

    /// Ensures a live AI batch is prefetched for `category` (coalescing with any in-flight request). Returns nil only if offline / API error.
    @discardableResult
    func ensureLiveBatch(
        for category: InterestCategory,
        language: AppLanguage,
        additionalExcludes: [String] = []
    ) async -> [String]? {
        let key = storageKey(categoryId: category.id, language: language)
        if let existing = prefetchedByKey[key], !existing.isEmpty {
            return existing
        }
        if let inFlight = inFlightTasksByKey[key] {
            return await inFlight.value
        }

        let seenHistory = seenTopics(for: category.id, language: language)
        let localSample = Array(category.fallbackInterests(for: language).shuffled().prefix(14))
        let combinedExcludes = Array(Set(seenHistory + additionalExcludes + localSample).prefix(65))
        let localizedCategoryName = category.localizedName(for: language)

        let task = Task<[String]?, Never> { @MainActor in
            defer { self.inFlightTasksByKey.removeValue(forKey: key) }
            do {
                let aiResults = try await CategoryExpansionService.expand(
                    category: localizedCategoryName,
                    existingInterests: combinedExcludes,
                    language: language
                )
                let lowerExcludes = Set((seenHistory + additionalExcludes).map { $0.lowercased() })
                let appropriate = aiResults.filter {
                    ContentModerationService.isAppropriate($0) && !lowerExcludes.contains($0.lowercased())
                }
                guard appropriate.count >= 6 else { return nil }
                let batch = Array(appropriate.prefix(12))
                self.storePrefetchedBatch(batch, for: category.id, language: language)
                return batch
            } catch {
                return nil
            }
        }

        inFlightTasksByKey[key] = task
        return await task.value
    }

    /// Consumes a pre-warmed live AI batch immediately (0ms) or awaits the in-flight live AI request, then replenishes the next batch in the background.
    /// Returns `nil` ONLY when offline or if the backend request fails.
    func consumeOrAwaitLiveBatch(
        for category: InterestCategory,
        language: AppLanguage,
        additionalExcludes: [String] = []
    ) async -> [String]? {
        if let ready = consumePrefetchedBatch(for: category.id, language: language) {
            replenishInBackground(
                for: category,
                language: language,
                additionalExcludes: additionalExcludes + ready
            )
            return ready
        }
        guard await ensureLiveBatch(
            for: category,
            language: language,
            additionalExcludes: additionalExcludes
        ) != nil else {
            return nil
        }
        if let fetched = consumePrefetchedBatch(for: category.id, language: language) {
            replenishInBackground(
                for: category,
                language: language,
                additionalExcludes: additionalExcludes + fetched
            )
            return fetched
        }
        return nil
    }

    /// Replenishes a fresh live AI batch in the background after the user consumes the current one.
    func replenishInBackground(
        for category: InterestCategory,
        language: AppLanguage,
        additionalExcludes: [String] = []
    ) {
        guard !hasPrefetchedBatch(for: category.id, language: language) else { return }
        Task { @MainActor in
            _ = await self.ensureLiveBatch(
                for: category,
                language: language,
                additionalExcludes: additionalExcludes
            )
        }
    }

    /// Offline-only fallback: draws `count` unseen, randomized sub-topics from the category's local 432 pool when network is unavailable.
    func drawUnseenCuratedBatch(
        for category: InterestCategory,
        language: AppLanguage,
        additionalExcludes: [String] = [],
        count: Int = 12
    ) -> [String] {
        let key = storageKey(categoryId: category.id, language: language)
        let pool = category.fallbackInterests(for: language)
        let seenHistory = seenByKey[key] ?? []
        let hardExclude = Set(additionalExcludes.map { $0.lowercased() })
        let seenSet = Set(seenHistory.map { $0.lowercased() })

        // 1. Prefer items neither in seenHistory nor in additionalExcludes
        var candidates = pool.filter {
            let lower = $0.lowercased()
            return !seenSet.contains(lower) && !hardExclude.contains(lower)
        }.shuffled()

        // 2. If fewer than `count` unseen remain, recycle oldest seen items first (excluding currently visible `additionalExcludes`)
        if candidates.count < count {
            let recycled = pool.filter { item in
                let lower = item.lowercased()
                return !hardExclude.contains(lower) && !candidates.contains(where: { $0.lowercased() == lower })
            }.shuffled()
            candidates.append(contentsOf: recycled.prefix(count - candidates.count))
        }

        // 3. Final safety fallback
        if candidates.count < count {
            let remainder = pool.filter { item in
                !candidates.contains(where: { $0.lowercased() == item.lowercased() })
            }.shuffled()
            candidates.append(contentsOf: remainder.prefix(count - candidates.count))
        }

        let selected = Array(candidates.prefix(count))
        recordSeen(selected, for: category.id, language: language)
        return selected
    }

    /// Records displayed topics into the persistent ring buffer so they won't immediately repeat on next open/launch.
    func recordSeen(_ topics: [String], for categoryId: String, language: AppLanguage) {
        guard !topics.isEmpty else { return }
        let key = storageKey(categoryId: categoryId, language: language)
        var history = seenByKey[key] ?? []
        for topic in topics {
            history.removeAll { $0.caseInsensitiveCompare(topic) == .orderedSame }
            history.append(topic)
        }
        if history.count > maxSeenHistoryPerCategory {
            history = Array(history.suffix(maxSeenHistoryPerCategory))
        }
        seenByKey[key] = history
        saveSeenToDisk()
    }

    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: seenDefaultsKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            seenByKey = decoded
        }
        if let data = UserDefaults.standard.data(forKey: prefetchedDefaultsKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            prefetchedByKey = decoded
        }
    }

    private func saveSeenToDisk() {
        if let data = try? JSONEncoder().encode(seenByKey) {
            UserDefaults.standard.set(data, forKey: seenDefaultsKey)
        }
    }

    private func savePrefetchedToDisk() {
        if let data = try? JSONEncoder().encode(prefetchedByKey) {
            UserDefaults.standard.set(data, forKey: prefetchedDefaultsKey)
        }
    }
}

// MARK: - Preset Categories (36 Hyper-Specific "Wait, What Is That?!" Rabbit Holes per Category)

extension InterestCategory {

    static let presets: [InterestCategory] = [
        InterestCategory(
            id: "film",
            iconName: "film",
            emoji: "🎬",
            nameEN: "Film",
            nameTR: "Film",
            hue: 0.0,
            fallbackInterestsEN: [
                "Kuleshov Effect Mechanics", "Kubrick's NASA f/0.7 Lenses", "Jodorowsky's Unbuilt Dune",
                "Foley Sound Coconut Tricks", "Wilhelm Scream Archive", "Hitchcock's Dolly Zoom",
                "Technicolor Three-Strip Dye", "1927 Metropolis Miniatures", "Tarkovsky's Polaroid Stills",
                "Buster Keaton Stunt Physics", "Spaghetti Western Ennio Scores", "Schüfftan Mirror Illusion",
                "Apocalypse Now Typhoon Shoot", "70mm IMAX Film Grain", "French Poetic Realism",
                "Kurosawa's Weather Machines", "Czechoslovak New Wave", "Matte Painting on Glass",
                "1896 Train Arrival Panic Myth", "Orson Welles Fake Documentary", "Hong Kong Wire-Fu Rigging",
                "Split-Diopter Deep Focus", "Silent Film Nitrate Fires", "Anamorphic Lens Flare History",
                "24 Frames Per Second Standard", "Stop-Motion Replacement Faces", "Giallo Color Gel Lighting",
                "Dogme 95 Vow of Chastity", "Practical Animatronic Skin", "Lost Reel in a Salt Mine",
                "Soviet Montage Theory", "Optical Printer Star Wars Compositing", "Pre-Code Hollywood Loopholes",
                "One-Take Steadicam Choreography", "Akira 24fps Cel Painting", "Cannes 1968 Curtain Protest"
            ],
            fallbackInterestsTR: [
                "Kuleşov Etkisi Deneyi", "Kubrick'in NASA f/0.7 Lensi", "Jodorowsky'nin Kayıp Dune'u",
                "Foley Ses Efekti Sırları", "Wilhelm Çığlığı Arşivi", "Hitchcock Vertigo Kamerası",
                "Üç Şeritli Technicolor", "1927 Metropolis Ayna Hilesi", "Tarkovski Polaroid Kadrajları",
                "Buster Keaton Dublör Fiziği", "Schüfftan Ayna Tekniği", "Apocalypse Now Set Kaosu",
                "70mm IMAX Şerit Fiziği", "Kurosawa Yapay Fırtınaları", "Çekoslovak Yeni Dalgası",
                "Cam Üzeri Matte Boyama", "Nitrat Film Yangınları", "Split-Diopter Çift Odak",
                "Orson Welles Sahte Belgeseli", "Hong Kong Telli Dövüşü", "Anamorfik Lens Kırılması",
                "Neden Saniyede 24 Kare?", "Dogme 95 Saflık Yemini", "Tuz Madenindeki Kayıp Filmler",
                "Akira: 160 Bin El Çizimi", "Pre-Code Hollywood Sansürü", "Steadicam Jiroskop İcadı",
                "Optik Yazıcı Efektleri", "Sessiz Sinema Canlı Orkestrası", "Giallo Renk Filtreleri",
                "1968 Cannes Perde Eylemi", "Stop-Motion Yüz Değiştirme", "Sovyet Montaj Çarpışması",
                "1902 El Boyaması Ay Filmi", "Psycho'da Çikolata Şurubu Kan", "Gümüş Halojenür Karanlık Oda"
            ]
        ),
        InterestCategory(
            id: "music",
            iconName: "music.note",
            emoji: "🎵",
            nameEN: "Music",
            nameTR: "Müzik",
            hue: 0.08,
            fallbackInterestsEN: [
                "Soviet Bone X-Ray Records", "Stradivarius Ice-Age Wood", "John Cage's 4'33\" Premise",
                "Amen Break 6-Second Loop", "Theremin EM-Field Control", "Brian Eno's Airport Music",
                "Wall of Sound Echo Chambers", "Shepard Tone Illusion", "Voyager Golden Record Bach",
                "TR-808 Transistor Accident", "Delia Derbyshire Tape Art", "Tuvan Throat Overtones",
                "Jarrett's Broken Köln Piano", "432 Hz vs 440 Hz Debate", "Gamelan Metallophone Scales",
                "Fairlight CMI Page R", "Abbey Road ADT Tape Trick", "Pythagorean Comma Paradox",
                "12-Foot Octobass Sub-Notes", "Glass Armonica Hysteria", "Mellotron Tape-Strip Keys",
                "Nancarrow's Player Pianos", "Hurdy-Gurdy Drone Wheel", "Aphex Twin Spectrogram Face",
                "1913 Rite of Spring Riot", "Microtonal Fretless Guitars", "Castrato Acoustic Power",
                "Minimoog Pitch-Wheel Fluke", "Japanese Kankyo Ongaku", "Les Paul's Log Prototype",
                "Two-Ton Steel Plate Reverb", "Edison Wax Cylinder Grooves", "Georgian Polyphonic Chords",
                "Talk Box Tube Mechanics", "Prepared Piano Bolt Timbres", "Sonar Whale Song Tapes"
            ],
            fallbackInterestsTR: [
                "Sovyet Röntgen Plakları", "Stradivarius Buzul Çağı Ağacı", "Amen Break: 6 Saniyelik Loop",
                "Shepard Tonu Yanılsaması", "Bozuk Köln Konser Piyanosu", "Theremin Elektromanyetik Sesi",
                "TR-808 Bozuk Transistör Sesi", "Tuva Gırtlak Müziği Fiziği", "Delia Derbyshire Bant Sanatı",
                "1913 Bahar Ayini İsyanı", "Yasaklanan Cam Armonika", "Mellotron Kasetli Klavyesi",
                "İki Tonluk Çelik Reverb", "Pisagor Komması Çıkmazı", "Şarkıdaki Gizli Aphex Yüzü",
                "John Cage 4'33\" Deneyi", "80'ler Japon Kankyo Ongaku", "Nancarrow Mekanik Piyanosu",
                "Vidalı Hazırlanmış Piyano", "440 Hz Standart Akort Krizi", "Octobass: Dev Kontrbas",
                "Abbey Road ADT Bant Hilesi", "Endonezya Gamelan Akordu", "Edison Balmumu Silindirleri",
                "Talk Box Hortumlu Gitar", "Gürcü Çok Sesli Korosu", "Brian Eno Havaalanı Müziği",
                "Fairlight CMI İlk Sampler", "Mikrotonal Perdesiz Gitar", "Hurdy-Gurdy Çarklı Liri",
                "Voyager Altın Plak Kaydı", "Yankı Odası Mimarisi", "Minimoog Pitch Tekerleği",
                "Plak Yivleri Mikroskobisi", "Katedral Akustiği ve İlahi", "Balinaların Oktav Değişimi"
            ]
        ),
        InterestCategory(
            id: "science",
            iconName: "atom",
            emoji: "🔬",
            nameEN: "Science",
            nameTR: "Bilim",
            hue: 0.55,
            fallbackInterestsEN: [
                "Oklo Natural Nuclear Reactor", "Chernobyl Radiotrophic Fungi", "Tardigrade Glass Vitrification",
                "Mpemba Hot-Water Freezing", "Immortal Jellyfish Reversal", "Mercury Beating Heart Drop",
                "97-Year Pitch Drop Funnel", "Mantis Shrimp Cavitation", "Superfluid Helium Climbing",
                "Sonoluminescence Star Jar", "Slime Mold Rail Solver", "Pando 80,000-Year Single Tree",
                "Kessler Orbital Cascade", "Prince Rupert's Drop Physics", "Non-Equilibrium Time Crystals",
                "Ball Lightning Plasma Mystery", "Antikythera Gear Calculus", "IceCube Neutrino Telescope",
                "Prion Misfolding Cascade", "Avian Quantum Compass", "Acoustic Levitation Traps",
                "Biefeld-Brown Ionic Wind", "Sticky-Tape X-Ray Emission", "Lake Nyos CO₂ Eruption",
                "Vantablack Nanotube Forest", "Human Twin DNA Chimerism", "Leidenfrost Vapor Cushion",
                "Muon Time-Dilation Proof", "Deep-Sea Brine Pool Lakes", "Rogue Wave Constructive Math",
                "1910 Halley Cyanide Panic", "Jupiter Metallic Hydrogen", "Blind Cavefish Eye Genetics",
                "1859 Carrington Solar Storm", "Aerogel Frozen Smoke", "Epigenetic Famine Memory"
            ],
            fallbackInterestsTR: [
                "Oklo Doğal Nükleer Reaktörü", "Çernobil Radyotropik Mantarı", "Tardigrad Camsı Kriptobiyozu",
                "Mpemba Sıcak Su Paradoksu", "Ölümsüz Denizanası Döngüsü", "Cıva Kalp Atışı Deneyi",
                "97 Yıllık Zift Damlası", "Mantis Karidesi Kavitasyonu", "Tırmanan Süperakışkan Helyum",
                "Sonolüminesans: Sudan Işık", "Metro Ağı Çözen Cıvık Mantar", "Prens Rupert Damlası Fiziği",
                "Koli Bandından X-Işını", "Kessler Yörünge Sendromu", "Güney Kutbu Nötrino Avı",
                "Nyos Gölü CO₂ Patlaması", "Kuşlarda Kuantum Pusulası", "Sesle Akustik Levitasyon",
                "Leidenfrost Buhar Yastığı", "1859 Carrington Fırtınası", "Okyanus Dibi Tuz Gölleri",
                "İnsan Kimerizmi Çift DNA", "Zaman Kristalleri Fiziği", "Prion Protein Katlanması",
                "Yıldırım Topu Plazma Sırrı", "Pando: 80 Bin Yıllık Ağaç", "Aerojel: Dondurulmuş Duman",
                "Vantablack Karbon Nanotüpü", "Mağara Balığı Göz Evrimi", "1910 Halley Gazı Paniği",
                "Jüpiter Metalik Hidrojeni", "Kozmik Müon Zaman Bükülmesi", "Epigenetik Kıtlık Hafızası",
                "Dev Hayalet Dalga Fiziği", "Antikythera Dişli Bilgisayarı", "Biyolüminesan Luciferin"
            ]
        ),
        InterestCategory(
            id: "food",
            iconName: "fork.knife",
            emoji: "🍳",
            nameEN: "Food",
            nameTR: "Yemek",
            hue: 0.1,
            fallbackInterestsEN: [
                "1814 London Beer Flood", "Garum Roman Fish Sauce", "Ortolan Napkin Ritual",
                "Miracle Berry Taste Hack", "1976 Paris Blind Wine Shock", "Fugu Tetrodotoxin License",
                "3,000-Year Tomb Honey", "Can Opener's 48-Year Delay", "Casu Marzu Maggot Cheese",
                "Kopi Luwak Enzyme Chemistry", "Maillard Crust Chemistry", "Burnt Basque Tart Accident",
                "Fake Wasabi Horseradish", "Submarine Galley Logistics", "Natto Bacillus Threads",
                "Svalbard Ancient Grains", "Angels' Share Evaporation", "Nutmeg for Manhattan Swap",
                "Champagne 90-PSI Physics", "Koji Aspergillus Mold", "Century Egg Alkaline Gel",
                "French Gabelle Salt Revolt", "Ottoman Helvahane Ledgers", "Capsaicin TRPV1 Heat Trick",
                "Peking Duck Air-Pump Skin", "Escoffier Kitchen Brigade", "Ergot Rye Bread Madness",
                "Truffle Pig Pheromones", "Roquefort Cave Penicillium", "Saffron Stigma Harvesting",
                "Arctic Pemmican Rations", "Pine Mouth Metal Syndrome", "Aztec Corn Nixtamalization",
                "Worcestershire Barrel Fluke", "Coca-Cola's Kola Nut Roots", "Zero-G Space Crumb Hazard"
            ],
            fallbackInterestsTR: [
                "1814 Londra Bira Tufanı", "Garum: Antik Balık Sosu", "Ortolan Kuşu Ritüeli",
                "Miracle Berry Tat Hilesi", "1976 Paris Şarap Şoku", "Fugu Tetrodotoksin Lisansı",
                "Mezardan Çıkan 3000 Yıllık Bal", "Konservenin 48 Yıl Geç Açacağı", "Casu Marzu Peyniri Biyolojisi",
                "Kopi Luwak Enzim Kimyası", "Maillard Kabuk Tepkimesi", "Yanık Cheesecake Kazası",
                "Yaban Turpundan Sahte Wasabi", "Denizaltı Mutfağı Lojistiği", "Manhattan'la Takaslı Muskat",
                "Viskide Meleklerin Payı", "Şampanya Şişesi 6 Bar Basınç", "Yüzyıllık Yumurta Kimyası",
                "Osmanlı Helvahane Defterleri", "Kapsaisin Yanma Yanılsaması", "Şişirilen Pekin Ördeği Derisi",
                "Çavdar Mahmuzu Halüsinasyonu", "Trüf Domuzu Feromon Sırrı", "Rokfor Mağarası Küf Efsanesi",
                "1 Gram Safran: 150 Çiçek", "Çam Fıstığı Metalik Tat Krizi", "Aztek Mısır Kireçlemesi",
                "Unutulan Worcestershire Fıçısı", "Uzayda Ekmek Kırıntısı Yasağı", "Fransız Tuz Vergisi İsyanı",
                "Koji Küfü ve Umami Sentezi", "Escoffier Mutfak Tugayı", "Kutup Pemmican Kumanyası",
                "Paris'in İlk Restoran Et Suyu", "Banda Adaları Karanfil Tekeli", "Sıvı Azotlu Dondurma Fiziği"
            ]
        ),
        InterestCategory(
            id: "history",
            iconName: "clock.arrow.circlepath",
            emoji: "📜",
            nameEN: "History",
            nameTR: "Tarih",
            hue: 0.12,
            fallbackInterestsEN: [
                "1518 Dancing Plague", "1932 Great Emu War", "WWII Inflatable Ghost Army",
                "1816 Year Without Summer", "Uncracked Voynich Script", "Byzantine Greek Fire Siphons",
                "Petrov's 1983 Radar Call", "1637 Tulip Futures Crash", "Operation Mincemeat Decoy",
                "Ashurbanipal Clay Library", "Defenestrations of Prague", "1904 Olympic Marathon Chaos",
                "Scotland's Darien Ruin", "1204 Crusade Diversion", "Bronze Age Sea Peoples",
                "Mansa Musa's Gold Crash", "Tang Dynasty Rocket Arrows", "Self-Healing Roman Concrete",
                "1919 Boston Molasses Flood", "Pony Express 18-Month Run", "Hanseatic Merchant Kontors",
                "Inca Quipu String Ledgers", "CIA Acoustic Kitty Fiasco", "1212 Children's Crusade",
                "Zheng He's Treasure Fleet", "1752 Missing 11 Days Riot", "897 Cadaver Papal Trial",
                "Vanished Nazi Amber Room", "Sunken Doggerland Plains", "1739 War of Jenkins' Ear",
                "Eratosthenes' Shadow Math", "Carthage Secret Cothon Port", "1346 Caffa Plague Catapults",
                "Tordesillas Papal Line", "Baghdad Battery Debate", "Svalbard Demilitarized Pact"
            ],
            fallbackInterestsTR: [
                "1518 Strazburg Dans Vebası", "1932 Avustralya Emu Savaşı", "2. Dünya Savaşı Şişme Tankları",
                "1816 Tambora Yazsız Yılı", "Çözülemeyen Voynich Yazması", "Bizans'ın Rum Ateşi Sırrı",
                "1983 Stanislav Petrov Kararı", "1637 Hollanda Lale Çöküşü", "Kıyma Harekâtı Sahte Binbaşı",
                "Prag Camdan Atma Vakaları", "1904 Olimpiyat Maratonu Kaosu", "İskoçya'yı Batıran Darien",
                "Mansa Musa Altın Enflasyonu", "Kendini Onaran Roma Betonu", "1919 Boston Pekmez Tufanı",
                "İnka Düğümlü İp Kayıtları", "CIA Casus Kedi Fiyaskosu", "Zheng He Hazine Gemileri",
                "897 Kadavra Sinodu Davası", "Batık Kıta Doggerland", "Gölgeyle Dünya Çapı Ölçümü",
                "Kartaca Dairesel Savaş Limanı", "1752 Silinen 11 Gün İsyanı", "Asurbanipal Kil Kütüphanesi",
                "Tunç Çağı Deniz Kavimleri", "Kayıp Kehribar Odası Gizemi", "Hansa Tüccar Devlet Ağı",
                "1739 Jenkins'in Kulağı Savaşı", "Dünyayı Bölen Tordesillas", "Pony Express'in 18 Ay Ömrü",
                "1453 Kızaklı Gemiler Lojistiği", "Lagari Hasan Roket Barutu", "Babil Bakır Şikayet Tableti",
                "Piri Reis Kaynak Haritaları", "Venedik Lazzaretto Karantinası", "İzlanda Althing Parlamentosu"
            ]
        ),
        InterestCategory(
            id: "sports",
            iconName: "figure.run",
            emoji: "⚽",
            nameEN: "Sports",
            nameTR: "Spor",
            hue: 0.33,
            fallbackInterestsEN: [
                "Fosbury Flop High-Jump", "Lotus 79 Ground-Effect Skirt", "Florentine Calcio Storico",
                "Knuckleball Magnus Physics", "1968 Thin-Air World Records", "Brabham BT46B Fan Car",
                "Oakland A's Moneyball Math", "Brawn GP Double Diffuser", "Kipchoge's Pacemaker Wedge",
                "Barkley Book-Page Checkpoints", "1916 Georgia Tech 222–0", "Sepak Takraw Rattan Volley",
                "2008 Polyurethane Suit Ban", "149–0 Own-Goal Protest", "Deep Blue's Game 2 Bug",
                "Panenka Penalty Psychology", "1955 Le Mans Magnesium Fire", "2010 Jabulani Seam Knuckling",
                "Tour de France Crosswinds", "1972 Olympic Final 3 Seconds", "Buzkashi Nomad Goat Polo",
                "Sumo Salt-Purifying Dohyo", "1992 Denmark Euro Miracle", "Curling Pebble Ice Physics",
                "Six-Wheeled Tyrrell P34 F1", "Badwater 135 Death Valley", "1950 USA vs England Shock",
                "Ping-Pong Sponge Revolution", "El Capitan Finger Locks", "America's Cup Hydrofoils",
                "Cricket Reverse Swing Physics", "1980 Miracle on Ice Bench", "Fiberglass Pole Vault Return",
                "Isle of Man 200mph Roads", "Jai Alai 180mph Cesta", "Biathlon Pulse-Drop Shooting"
            ],
            fallbackInterestsTR: [
                "Fosbury Sırtüstü Atlama", "Brabham Fanlı F1 Aracı", "Floransa Calcio Storico",
                "2010 Jabulani Aerodinamiği", "Barkley Kitap Sayfası Maratonu", "Yasaklanan Poliüretan Mayolar",
                "Brawn GP Çift Difüzör Hilesi", "Altı Tekerlekli F1: Tyrrell", "149-0 Kendi Kalesine Protesto",
                "Deep Blue Satranç Hatası", "Panenka Penaltı Psikolojisi", "1968 Meksika İnce Hava Rekoru",
                "Curling Buz Çakılı Fiziği", "1992 Danimarka Plaj Mucizesi", "Kipchoge Rüzgar Kalkanı",
                "Sepak Takraw Röveşata Ağı", "Sünger Masa Tenisi Raketi", "300 km Hızlı Jai Alai Topu",
                "Biatlon Nabız Düşürme Tekniği", "Man Adası TT Sokak Yarışı", "Bisiklette Çapraz Rüzgar Ağı",
                "1972 Basketbol Son 3 Saniye", "Sumo Dohyo Tuz Ritüeli", "Kriket Ters Salınım Fiziği",
                "Fiberglas Sırık Enerjisi", "Lotus 79 Yer Etkisi Etekleri", "El Capitan Parmak Kilitleri",
                "Uçan Hidrofoil Yelkenliler", "1904 Otostopçu Maratoncu", "1872 İskoç Pas Oyunu Devrimi",
                "52 Derecede Badwater Yarışı", "Orta Asya Buzkashi Oyunu", "Satrançta Zugzwang Tuzağı",
                "F1 1000 Derece Karbon Fren", "Neden Tam 42.195 Metre?", "1954 Bern Vidalı Kramponlar"
            ]
        ),
        InterestCategory(
            id: "tech",
            iconName: "cpu",
            emoji: "💻",
            nameEN: "Technology",
            nameTR: "Teknoloji",
            hue: 0.6,
            fallbackInterestsEN: [
                "Apollo 11 Woven Rope Memory", "Cloudflare Lava Lamp Entropy", "1947 Harvard Moth Bug",
                "ASML Tin-Droplet EUV Plasma", "Undersea Cable Shark Bites", "Y2K38 32-Bit Clock Overflow",
                "Cosmic-Ray Election Bit Flip", "Therac-25 Race Condition", "Stuxnet Centrifuge Sabotage",
                "Voyager 1 69KB Assembly", "Quake III 0x5f3759df Math", "Xerox PARC Alto GUI",
                "Hopper's Nanosecond Wire", "1983 ARPANET Flag Day", "BGP Route Leak Outages",
                "1770 Mechanical Turk Hoax", "QR Code Go-Board Origin", "reCAPTCHA Book Digitizing",
                "Enigma Plugboard Math", "Mars Orbiter Metric Bug", "Sony Rootkit CD Scandal",
                "2600 Hz Cap'n Crunch Whistle", "1858 Gutta-Percha Sea Cable", "Bell Labs First Transistor",
                "Zero-Knowledge Cave Proof", "RAID Disk Parity Math", "UTF-8 Diner Napkin Design",
                "Rolling Shutter Propellers", "GPS Relativistic Clock Drift", "Paris Pneumatic Tube Mail",
                "Hand-Sewn Ferrite Core RAM", "Brick-Wall USB Dead Drops", "2010 Wall Street Flash Crash",
                "Shazam Audio Spectrograms", "Babbage's Analytical Gears", "CD-ROM 74-Minute Beethoven"
            ],
            fallbackInterestsTR: [
                "Apollo 11 Dokuma İp Belleği", "Cloudflare Lav Lambası Şifresi", "ASML Kalay Damlası Lazeri",
                "Seçim Değiştiren Kozmik Işın", "Kablo Isıran Köpekbalıkları", "Quake 0x5f3759df Karekök Kodu",
                "2600 Hz Düdükle Telefon Hack'i", "Go Tahtasından Doğan QR Kod", "2038 Unix Saat Taşması",
                "Shazam Ses Parmak İzi", "Mars Sondası İnç-Metre Hatası", "Peçetede Yazılan UTF-8",
                "Voyager 1'in 69 KB Belleği", "GPS Görelilik Zaman Kayması", "1947 İlk Gerçek Böcek (Bug)",
                "Xerox PARC Grafik Arayüzü", "Therac-25 Yarış Durumu Hatası", "Enigma Fiyli Kombinasyonu",
                "Paris Pnömatik Mektup Borusu", "1770 Mekanik Türk Hilesi", "Rolling Shutter Pervane Bükümü",
                "reCAPTCHA Kitap Çeviri Ağı", "BGP Hatasıyla Çöken İnternet", "Stuxnet Santrifüj Sabotajı",
                "Grace Hopper Nanosaniye Teli", "2010 Borsa Flash Çöküşü", "Bell Labs İlk Transistörü",
                "Sıfır Bilgi İspatı Mağarası", "1858 Atlantik Telgraf Kablosu", "Çöle Gömülen Atari E.T.",
                "CD'nin 74 Dakika Sınırı", "Kral Harald ve Bluetooth Adı", "Disk Kafası Uçuş Fiziği",
                "Palette Swapping Renk Hilesi", "İlk Webcam: Kahve Makinesi", "Babbage Analitik Makinesi"
            ]
        ),
        InterestCategory(
            id: "nature",
            iconName: "leaf",
            emoji: "🌿",
            nameEN: "Nature",
            nameTR: "Doğa",
            hue: 0.38,
            fallbackInterestsEN: [
                "Crown Shyness Canopy Gaps", "Cordyceps Zombie Ant Fungus", "Maracaibo Eternal Lightning",
                "Death Valley Sailing Stones", "Mycorrhizal Wood Wide Web", "Pistol Shrimp 4,700°C Snap",
                "Honeyguide Bird Whistle Pact", "Baikal Freshwater Seals", "Brinicle Seafloor Ice Finger",
                "2,000-Year Welwitschia Plant", "Lyrebird Chainsaw Mimicry", "Sardine Run Super-Pods",
                "Socotra Dragon's Blood Trees", "4-Generation Monarch Relay", "Self-Igniting Eucalyptus Oil",
                "Bombardier Beetle Cannon", "Surinam Toad Back Hatching", "Waitomo Glowworm Silk Traps",
                "Oxygen-Free Naked Mole-Rats", "Namib Desert Fairy Circles", "Sealed Movile Sulfur Cave",
                "Axolotl Brain Regeneration", "Fire-Activated Sequoia Cones", "Sahara Dust Feeding Amazon",
                "15-Species Mimic Octopus", "Cuckoo Egg Forgery Race", "Whale Fibonacci Bubble-Nets",
                "Thermal Corpse Flower Plume", "Archerfish Refraction Math", "Vertical Sleeping Whales",
                "Fig Wasp Mutual Sacrifice", "Ant Mill Pheromone Spiral", "Antarctic Blood Falls Rust",
                "Siphonophore Colonial Animal", "Transparent Barreleye Skull", "120-Year Bamboo Flowering"
            ],
            fallbackInterestsTR: [
                "Ağaçlarda Taç Utangaçlığı", "Zombi Karınca Mantarı", "Maracaibo Dinmeyen Yıldırımı",
                "Ölüm Vadisi Yürüyen Taşları", "Ormanların Mantar İnterneti", "4700 Derece Karides Yumruğu",
                "İnsanla Islıklaşan Bal Kuşu", "Okyanus Ölüm Parmağı Buzulu", "Testere Sesli Lir Kuşu",
                "120 Yılda Açan Bambular", "Mühürlü Movile Kükürt Mağarası", "Amazon'u Besleyen Sahra Tozu",
                "Dikey Uyuyan Balinalar", "Balina Fibonacci Baloncuk Ağı", "Şeffaf Kafalı Barreleye Balığı",
                "Bombardıman Böceği Kimyası", "İncir Arısı Fedakârlık Paktı", "Kırılma Hesaplayan Okçu Balığı",
                "Karınca Ölüm Sarmalı Hatası", "Antarktika Kan Şelalesi", "Oksijensiz Yaşayan Körfare",
                "4 Nesillik Kelebek Göçü", "Sokotra Ejderha Kanı Ağacı", "Guguk Kuşu Yumurta Kalpazanı",
                "15 Kılıklı Taklitçi Ahtapot", "2000 Yıllık İki Yapraklı Bitki", "Waitomo Işıklı İpek Tuzağı",
                "Baykal Gölü Tatlı Su Foku", "Namib Çölü Peri Çemberleri", "Kendini Isıtan Ceset Çiçeği",
                "Yangınla Açılan Sekoya Kozalağı", "Aksolotl Beyin Yenilemesi", "Yangın Çıkaran Okaliptüs",
                "Koloni Canlısı Sifonofor", "Mercanların Dolunay Üremesi", "Yunusların İmza Islıkları"
            ]
        ),
        InterestCategory(
            id: "art",
            iconName: "paintpalette",
            emoji: "🎨",
            nameEN: "Art",
            nameTR: "Sanat",
            hue: 0.75,
            fallbackInterestsEN: [
                "Mummy Brown Egyptian Pigment", "Holbein's Anamorphic Skull", "Patented Yves Klein Blue",
                "1911 Mona Lisa Coat Heist", "Vermeer's Camera Obscura", "Kintsugi Gold-Seam Repair",
                "Arsenic Scheele's Green", "Gardner Museum Empty Frames", "Rothko Chapel Color Fields",
                "Banksy's Shredder Frame", "Lascaux Ice-Age Scaffolds", "Manzoni's 90 Artist Cans",
                "Hokusai's Prussian Blue", "Pantheon Unreinforced Dome", "Jansen's Wind Strandbeests",
                "Michelangelo's Hidden Brain", "Van Meegeren's Fake Vermeers", "Duchamp's 1917 Urinal",
                "1966 Florence Flood Rescue", "Mango-Fed Cow Indian Yellow", "Bilbao Titanium Curves",
                "Caravaggio's Fugitive Years", "Donald Judd's Marfa Boxes", "Giotto's Freehand Red O",
                "Gaudí's Hanging Chain Arch", "Christo's Wrapped Reichstag", "Ukiyo-e Bokashi Shading",
                "12,000-Snail Tyrian Purple", "Kapoor vs Semple Pink War", "Pompeii Mystery Frescoes",
                "Dürer's Unseen Rhinoceros", "Turrell's Crater Sky Vault", "70-Meter Bayeux Tapestry",
                "Elgin Marbles Custody Clash", "Da Vinci's Flaking Fresco", "Mondrian's Colored Tapes"
            ],
            fallbackInterestsTR: [
                "Gerçek Mumyadan Kahverengi Boya", "Holbein Anamorfik Kafatası", "Arsenikli Scheele Yeşili",
                "En Siyah Boya Patent Savaşı", "Gaudí Ters Zincir Mimarisi", "Sistina Tavanındaki Gizli Beyin",
                "12 Bin Salyangozdan Sur Moru", "Kendini Doğrayan Banksy", "Göring'i Kandıran Sahte Vermeer",
                "Kintsugi Altın Kırık Onarımı", "Rüzgarla Yürüyen Heykeller", "1911 Mona Lisa Hırsızlığı",
                "Dürer'in Görmediği Gergedan", "Yanardağ İçinde Işık Tapınağı", "Çeliksiz Pantheon Kubbesi",
                "Hokusai ve Prusya Mavisi", "Gardner Müzesi Boş Çerçeveleri", "Vermeer Camera Obscura Sırrı",
                "Da Vinci'nin Dökülen Freski", "Patentli Yves Klein Mavisi", "Caravaggio'nun Kaçak Yılları",
                "Mango Yiyen İnek Sarısı", "Duchamp 1917 Pisuvar Skandalı", "Lascaux Mağarası İskeleleri",
                "Giotto'nun Kusursuz Çemberi", "Mondrian'ın Renkli Bantları", "Kumaşla Paketlenen Reichstag",
                "Ukiyo-e Bokashi Gölgelemesi", "Süleymaniye Devekuşu Yumurtası", "Süleymaniye İs Odası Akustiği",
                "70 Metrelik Bayeux İşlemesi", "Pompeii Sırlar Villası", "Marfa Çölündeki Beton Kutular",
                "Rothko Şapeli Renk Algısı", "Guggenheim Titanyum Pulları", "Velázquez Nedimeler Aynası"
            ]
        ),
        InterestCategory(
            id: "philosophy",
            iconName: "brain.head.profile",
            emoji: "🧠",
            nameEN: "Philosophy",
            nameTR: "Felsefe",
            hue: 0.82,
            fallbackInterestsEN: [
                "Ship of Theseus Paradox", "Mary's Black-and-White Room", "Searle's Chinese Room",
                "Newcomb's Predictor Box", "Diogenes' Plucked Chicken", "Nozick's Experience Machine",
                "Sorites Heap of Sand", "Boltzmann Brain Fluctuation", "Pascal's Infinite Wager",
                "Footbridge Trolley Variant", "Zeno's Tortoise Paradox", "Rawls' Veil of Ignorance",
                "Wittgenstein's Boxed Beetle", "Gettier's Lucky Truths", "Buridan's Starving Donkey",
                "Parfit's Mars Teleporter", "Panpsychism Conscious Atoms", "Russell's Orbiting Teapot",
                "Euthyphro Piety Dilemma", "Foucault's Panopticon Gaze", "Roko's Future AI Basilisk",
                "Zhuangzi's Butterfly Dream", "Putnam's Brain in a Vat", "Plank of Carneades Ethics",
                "Unexpected Hanging Paradox", "Davidson's Lightning Swampman", "Qualia-Free Zombie Minds",
                "Laplace's Deterministic Demon", "Black Swan Induction Flaw", "Meno's Inquiry Paradox",
                "Leibniz's Walk-In Mill", "Ulysses Self-Binding Pact", "Schopenhauer's Hedgehogs",
                "Goodhart's Corrupted Metric", "Chesterton's Fence Rule", "Kierkegaard's Leap of Faith"
            ],
            fallbackInterestsTR: [
                "Theseus'un Gemisi Paradoksu", "Siyah-Beyaz Odadaki Mary", "Searle'ün Çince Odası",
                "Diyojen'in Yolunmuş Tavuğu", "Nozick Deneyim Makinesi", "Boltzmann Boşluk Beyni",
                "Wittgenstein'ın Kutudaki Böceği", "Parfit Mars Işınlanma Klonu", "Newcomb Tahminci Kutusu",
                "Buridan'ın Aç Kalan Eşeği", "Rawls Bilgisizlik Peçesi", "Beklenmeyen İdam Paradoksu",
                "Panoptikon Gözetim Kulesi", "Zhuangzi Kelebek Rüyası", "Gettier Şanslı Bilgi Sorunu",
                "Yıldırım Kopyası Bataklık Adam", "Karneades Kazazede Tahtası", "Sorites Kum Yığını Sorunu",
                "Üşüyen Kirpiler İkilemi", "Chesterton'ın Çiti Kuralı", "Leibniz'in Bilinç Değirmeni",
                "Ulysses Siren Bağlanma Paktı", "Felsefi Zombiler ve Qualia", "Russell'ın Uzay Çaydanlığı",
                "Laplace'ın Determinist Şeytanı", "Goodhart Ölçüt Bozulması", "Zenon Aşil ve Kaplumbağa",
                "Kavanozdaki Beyin Şüphesi", "Euthyphron İyilik İkilemi", "İbn Sînâ Uçan Adam Deneyi",
                "Gazâlî Pamuk ve Ateş Kuramı", "Kierkegaard İman Şövalyesi", "Atomlarda Bilinç: Panpsişizm",
                "Diyojen ve İskender'in Gölgesi", "Meno Arama Paradoksu", "Siyah Kuğu Tümevarım Hatası"
            ]
        ),
        InterestCategory(
            id: "travel",
            iconName: "globe.americas",
            emoji: "✈️",
            nameEN: "Travel",
            nameTR: "Seyahat",
            hue: 0.48,
            fallbackInterestsEN: [
                "Baarle Border-Split Cafés", "Diomede 21-Hour Time Walk", "Svalbard's No-Death Law",
                "Point Nemo Space Graveyard", "Kowloon Walled City Maze", "Coober Pedy Dugout Homes",
                "Mount Athos 1,000-Year Ban", "Darvaza Burning Gas Crater", "Hashima Battleship Ruins",
                "Six-Month Pheasant Island", "Centralia Underground Fire", "Tristan da Cunha Outpost",
                "Derinkuyu 18-Level City", "Setenil Cliff-Roof Streets", "Socotra Alien Archipelago",
                "Maunsell Sea Defense Forts", "Whittier One-Building Town", "Chongqing Apartment Train",
                "Chefchaouen Blue Alleys", "Bodie Frozen Ghost Town", "Roadless Giethoorn Canals",
                "Shibam Mud-Brick Highrises", "Meteora Sky Pillar Abbeys", "Dallol Acid Sulfur Pools",
                "Uyuni Mirror Salt Flats", "Tsingy Razor Stone Forest", "Palermo Mummy Catacombs",
                "2,197m Krubera Deep Cave", "Brazil's Forbidden Snake Isle", "Unclaimed Bir Tawil Desert",
                "Rjukan Valley Sun-Mirrors", "Kandy Sacred Tooth Temple", "Lalibela Rock-Hewn Churches",
                "Meghalaya Living Root Bridges", "Dargavs Valley of Crypts", "Wuppertal Hanging Monorail"
            ],
            fallbackInterestsTR: [
                "Baarle: Ev İçi Ülke Sınırı", "Diomede: 21 Saatlik Yürüyüş", "Svalbard'da Ölme Yasağı",
                "6 Ayda Ülke Değiştiren Ada", "Tek Apartmanlı Kasaba Whittier", "Point Nemo Uzay Mezarlığı",
                "Coober Pedy Yeraltı Şehri", "1971'den Beri Yanan Krater", "Apartman İçi Chongqing Treni",
                "Şibam Çamurdan Gökdelenler", "Canlı Ağaç Kökü Köprüleri", "Kayaların Altındaki Setenil",
                "Sahipsiz Toprak: Bir Tawil", "Derinkuyu 18 Katlı Şehir", "Kowloon Dikey Şehir Labirenti",
                "Tek Kayadan Lalibela Kilisesi", "En Uzak Ada Tristan da Cunha", "Terk Edilmiş Ada Hashima",
                "Yolsuz Köy Giethoorn Kanalları", "60 Yıldır Yanan Centralia", "Ters Asılı Wuppertal Treni",
                "Tsingy Jilet Taş Ormanı", "Dallol Asit ve Kükürt Gölü", "Dağ Aynalı Rjukan Kasabası",
                "Deniz Ortasında Maunsell Kalesi", "Palermo Yeraltı Mumyaları", "Yasaklı Yılan Adası Queimada",
                "Salar de Uyuni Ayna Çölü", "2200m Krubera Derin Mağarası", "Meteora Bulut Manastırları",
                "Aynoroz 1000 Yıllık Yasak", "Yürütülen Paskalya Heykelleri", "Venedik'in Kızılağaç Kazıkları",
                "Bodie Hayalet Altın Kasabası", "Oymyakon Kışın Sönmeyen Motor", "İki Kıta Arasında Yüzmek"
            ]
        ),
        InterestCategory(
            id: "gaming",
            iconName: "gamecontroller",
            emoji: "🎮",
            nameEN: "Gaming",
            nameTR: "Oyun",
            hue: 0.7,
            fallbackInterestsEN: [
                "WoW Corrupted Blood Plague", "Mario 64 Half-A-Press Math", "Civilization Nuclear Gandhi",
                "Silent Hill's PS1 Fog Trick", "Space Invaders Lag Speed-Up", "Pokémon MissingNo. Overflow",
                "1981 Polybius Arcade Myth", "EVE Online $300K Bloodbath", "Crash Bandicoot CD Hacking",
                "Pac-Man Level 256 Kill Screen", "Doom 386 BSP Tree Math", "Street Fighter II Bug Combos",
                "Assembly-Coded RollerCoaster", "EarthBound Piracy Boss Wipe", "Forgotten Konami Debug Code",
                "Last-Minute GoldenEye Split", "Colossus Fake PS2 HDR", "Moscow Tetris Rights Battle",
                "Dwarf Fortress Drunk Cats", "Minecraft Far Lands Glitch", "Mortal Kombat Clay Sprites",
                "P.T. Final Microphone Puzzle", "StarCraft Dragoon Pathing", "Lord British's Assassination",
                "Half-Life Cockroach Smell AI", "TASBot Sub-Frame Inputs", "Quake Rocket Jump Accident",
                "SimCity 2000 Tax Zoning Bias", "Psycho Mantis Memory Read", "OutRun Sprite Road Scaling",
                "Ocarina Wrong-Warp Glitch", "NetHack DevTeam Edge Cases", "1984 Elite 22KB Galaxies",
                "Demon's Souls Bloodstains", "Spelunky Anti-Stall Ghost", "Coyote Time Jump Frames"
            ],
            fallbackInterestsTR: [
                "WoW Kan Salgını Vakası", "Silent Hill PS1 Sis Hilesi", "Space Invaders Hızlanma Hatası",
                "Assembly İle Yazılan Lunapark", "Dwarf Fortress Sarhoş Kedileri", "Hata Eseri Doğan SF2 Kombosu",
                "Crash Bandicoot Bellek Hack'i", "Psycho Mantis Hafıza Okuması", "Pac-Man 256. Seviye Çöküşü",
                "Havada Zıplatan Coyote Time", "EVE Online 300 Bin $ Savaşı", "EarthBound Korsan Silme Tuzağı",
                "Unutulan Test Kodu: Konami", "Pokémon Kıyı Hatası MissingNo.", "Zıplamadan Mario 64 Bitirmek",
                "Lord British Oyun İçi Suikastı", "Doom'un 3B BSP Matematiği", "Nükleer Gandhi Efsanesi",
                "22 KB'ta 8 Galaksi: Elite", "Half-Life Hamamböceği Zekâsı", "Zelda Wrong Warp Sıçraması",
                "Moskova Tetris Telif Savaşı", "Minecraft Far Lands Sınırı", "Son Dakika GoldenEye Modu",
                "Quake Fizik Hatası Rocket Jump", "Son Merminin Ekstra Gücü", "Ekran Dışı Ateş Etmeme Kuralı",
                "OutRun Sahte 3B Yol Hilesi", "PS2'de Sahte HDR Işık Hilesi", "P.T. Demosu Son Bulmacası",
                "TASBot Kusursuz Robot Koşusu", "Mortal Kombat Aktör Kesimi", "Spelunky Hayalet Sayacı",
                "BioShock İlk Mermi Iskası", "1981 Polybius Atari Efsanesi", "SimCity Trafik Matematiği"
            ]
        ),
    ]

    private static let extraNames: [String: [AppLanguage: String]] = [
        "film": [.japanese: "映画", .german: "Film", .french: "Cinéma", .spanish: "Cine", .korean: "영화"],
        "music": [.japanese: "音楽", .german: "Musik", .french: "Musique", .spanish: "Música", .korean: "음악"],
        "science": [.japanese: "科学", .german: "Wissenschaft", .french: "Science", .spanish: "Ciencia", .korean: "과학"],
        "food": [.japanese: "食と料理", .german: "Essen", .french: "Gastronomie", .spanish: "Gastronomía", .korean: "음식"],
        "history": [.japanese: "歴史", .german: "Geschichte", .french: "Histoire", .spanish: "Historia", .korean: "역사"],
        "sports": [.japanese: "スポーツ", .german: "Sport", .french: "Sport", .spanish: "Deportes", .korean: "스포츠"],
        "tech": [.japanese: "テクノロジー", .german: "Technologie", .french: "Technologie", .spanish: "Tecnología", .korean: "기술"],
        "nature": [.japanese: "自然", .german: "Natur", .french: "Nature", .spanish: "Naturaleza", .korean: "자연"],
        "art": [.japanese: "アート", .german: "Kunst", .french: "Art", .spanish: "Arte", .korean: "예술"],
        "philosophy": [.japanese: "哲学", .german: "Philosophie", .french: "Philosophie", .spanish: "Filosofía", .korean: "철학"],
        "travel": [.japanese: "旅", .german: "Reisen", .french: "Voyage", .spanish: "Viajes", .korean: "여행"],
        "gaming": [.japanese: "ゲーム", .german: "Gaming", .french: "Jeux vidéo", .spanish: "Videojuegos", .korean: "게임"],
    ]

    private static let extraFallbacks: [String: [AppLanguage: [String]]] = [
        "film": [
            .japanese: [
                "クレショフ効果の実験", "NASA特注f/0.7レンズ", "幻のホドロフスキー版デューン", "フォーリー音響のココナッツ",
                "ヴィルヘルムの叫び", "ヒッチコックのドリーズーム", "3色テクニカラー", "1927年メトロポリス特撮",
                "黒澤明の人工暴風雨", "ガラス上のマットペイント", "AKIRA 24コマ作画", "無声映画の硝酸フィルム火災",
                "香港ワイヤーアクション", "ドグマ95純潔の誓い"
            ],
            .german: [
                "Kuleschow-Effekt", "Kubricks NASA-Objektiv", "Jodorowskys verlorener Dune", "Foley-Kokosnuss-Tricks",
                "Wilhelmsschrei-Archiv", "Hitchcocks Dolly-Zoom", "Drei-Streifen-Technicolor", "Metropolis-Spiegeltrick",
                "Kurosawas Wettermaschinen", "Nitratfilm-Brände", "Dogme-95-Keuschheitsgelübde", "Sowjetische Montagetheorie",
                "Optischer Drucker Star Wars", "Akira in 24 Bildern"
            ],
            .french: [
                "Effet Koulechov", "Objectif NASA de Kubrick", "Le Dune perdu de Jodorowsky", "Bruitages à la noix de coco",
                "Cri Wilhelm", "Travelling compensé", "Technicolor trichrome", "Effet Schüfftan (Metropolis)",
                "Tempêtes de Kurosawa", "Incendies de films nitrate", "Vœu du Dogme 95", "Montage soviétique",
                "Tireuse optique Star Wars", "Cellulos d'Akira 24 i/s"
            ],
            .spanish: [
                "Efecto Kuleshov", "Lente NASA de Kubrick", "El Dune perdido", "Trucos Foley con coco",
                "Archivo del grito Wilhelm", "Zoom vértigo de Hitchcock", "Technicolor de tres tiras", "Espejo de Metrópolis",
                "Tormentas de Kurosawa", "Incendios de nitrato", "Voto de Dogma 95", "Montaje soviético",
                "Impresora óptica Star Wars", "Animación cel de Akira"
            ],
            .korean: [
                "쿨레쇼프 효과 실험", "큐브릭의 NASA f/0.7 렌즈", "조도로프스키 미완성 듄", "폴리 사운드 코코넛 트릭",
                "빌헬름의 비명 아카이브", "히치콕 돌리 줌 기법", "3색 테크니컬러 공정", "메트로폴리스 거울 트릭",
                "구로사와 인공 폭풍우", "질산염 필름 화재사", "도그마 95 순결 서약", "소련 몽타주 이론",
                "아키라 24프레임 작화", "칸 1968 커튼 시위"
            ]
        ],
        "music": [
            .japanese: [
                "ソ連のレントゲン海賊盤", "ストラディヴァリ氷河期木材", "ジョン・ケージ4分33秒", "アーメン・ブレイク6秒",
                "テルミンの電磁場演奏", "ブライアン・イーノ空港音楽", "シェパード音階の錯覚", "ボイジャーの金のレコード",
                "TR-808故障トランジスタ", "トゥヴァの喉歌倍音", "ケルンの壊れたピアノ", "432Hz対440Hz論争",
                "日本環境音楽の源流", "アビーロードADT効果"
            ],
            .german: [
                "Sowjetische Röntgen-Platten", "Stradivari-Eiszeit-Holz", "John Cages 4'33\"", "Amen-Break 6-Sekunden-Loop",
                "Theremin-Magnetfeld", "Brian Enos Flughafenmusik", "Shepard-Ton-Illusion", "Voyager Golden Record",
                "TR-808 Transistor-Zufall", "Tuwinischer Kehlkopfgesang", "Jarretts kaputtes Köln-Klavier", "432 Hz vs. 440 Hz",
                "Abbey-Road-ADT-Trick", "Japanische Kankyō Ongaku"
            ],
            .french: [
                "Disques sur radios soviétiques", "Bois glaciaire de Stradivarius", "4'33\" de John Cage", "Boucle Amen Break",
                "Thérémine magnétique", "Musique d'aéroport d'Eno", "Illusion de Shepard", "Disque d'or de Voyager",
                "Transistor accidentel TR-808", "Chant diphonique de Touva", "Piano cassé de Cologne", "Débat 432 Hz vs 440 Hz",
                "Effet ADT d'Abbey Road", "Kankyō Ongaku japonais"
            ],
            .spanish: [
                "Discos en radiografías", "Madera glaciar Stradivarius", "4'33\" de John Cage", "Bucle Amen Break",
                "Termín electromagnético", "Música de aeropuerto Eno", "Ilusión tono de Shepard", "Disco de Oro Voyager",
                "Fallo del transistor TR-808", "Canto difónico tuvano", "Piano roto de Colonia", "Debate 432 Hz vs 440 Hz",
                "Truco ADT Abbey Road", "Kankyō Ongaku japonés"
            ],
            .korean: [
                "소련 엑스레이 해적판 음반", "스트라디바리 빙하기 목재", "존 케이지 4분 33초", "아멘 브레이크 6초 루프",
                "테레민 전자기장 연주", "브라이언 이노 공항 음악", "셰퍼드 톤 청각 착시", "보이저 골든 레코드",
                "TR-808 트랜지스터 사고", "투바 후두창 배음 물리", "쾰른의 고장 난 피아노", "432Hz 대 440Hz 논쟁",
                "애비 로드 ADT 테이프 트릭", "일본 환경음악 칸쿄 온가쿠"
            ]
        ],
        "science": [
            .japanese: [
                "オクロの天然原子炉", "チェルノブイリ放射線菌", "クマムシのガラス化", "ムペンバ高温水凍結",
                "ベニクラゲの若返り", "水銀の鼓動する心臓", "97年続くピッチ滴下実験", "モンハナシャコの空洞現象",
                "超流動ヘリウムの壁登り", "粘菌の鉄道網最適化", "樹齢8万年パンドの森", "プリンスルパートの涙",
                "アンティキティラの歯車", "セロテープのX線発光"
            ],
            .german: [
                "Naturreaktor Oklo", "Tschernobyl-Strahlenpilze", "Bärtierchen-Verglasung", "Mpemba-Heißwasser-Effekt",
                "Unsterbliche Qualle", "Schlagendes Quecksilberherz", "97-Jahre-Pechtropfen", "Fangschreckenkrebs-Kavitation",
                "Suprafluides Helium", "Schleimpilz-Bahnnetz", "Pando: 80.000-Jahre-Baum", "Prinz-Rupert-Tropfen",
                "Antikythera-Mechanismus", "Röntgenlicht aus Klebeband"
            ],
            .french: [
                "Réacteur naturel d'Oklo", "Champignons de Tchernobyl", "Vitrification du tardigrade", "Paradoxe de Mpemba",
                "Méduse immortelle", "Cœur battant au mercure", "Expérience de la goutte de poix", "Cavitation de la crevette-mante",
                "Hélium superfluide grimpeur", "Réseau ferré par un blob", "Pando, arbre de 80 000 ans", "Larmes du prince Rupert",
                "Machine d'Anticythère", "Rayons X au ruban adhésif"
            ],
            .spanish: [
                "Reactor natural de Oklo", "Hongos de Chernóbil", "Vitrificación de tardígrados", "Efecto Mpemba",
                "Medusa inmortal", "Corazón pulsante de mercurio", "Gota de brea de 97 años", "Cavitación del camarón mantis",
                "Helio superfluido trepador", "Moho mucilaginoso ferroviario", "Pando, árbol de 80.000 años", "Gotas del príncipe Rupert",
                "Mecanismo de Anticitera", "Rayos X con cinta adhesiva"
            ],
            .korean: [
                "오클로 천연 원자로", "체르노빌 방사선 영양 곰팡이", "물곰의 유리화 휴면", "뜨거운 물 음펨바 효과",
                "불멸의 해파리 역노화", "수은 박동 심장 실험", "97년째 피치 낙하 실험", "사마귀새우 공동 현상",
                "초유체 헬륨 벽 오르기", "점균류 철도망 설계", "8만 년 산 단일 나무 판도", "루퍼트 왕자의 눈물 물리",
                "안티키티라 톱니바퀴", "스카치테이프 엑스선 방출"
            ]
        ],
        "food": [
            .japanese: [
                "1814年ロンドンビール洪水", "古代ローマの魚醤ガルム", "オルトランのナプキン儀礼", "ミラクルフルーツの味覚錯覚",
                "1976年パリワインの審判", "ふぐテトロドトキシン免許", "3000年前の墓の蜂蜜", "缶詰と缶切りの48年差",
                "カース・マルツゥ発酵", "コピ・ルアク酵素化学", "メイラード反応の香気", "マンハッタンとナツメグ交換",
                "麹カビと旨味合成", "無重力とパン屑禁止令"
            ],
            .german: [
                "Londoner Bierflut 1814", "Garum: Römische Fischsauce", "Ortolan-Servietten-Ritual", "Wunderbeere-Geschmackshack",
                "Weinprobe von Paris 1976", "Fugu-Tetrodotoxin-Lizenz", "3.000 Jahre alter Grabhonig", "48 Jahre bis zum Dosenöffner",
                "Casu Marzu Madenkäse", "Kopi-Luwak-Enzymchemie", "Maillard-Krustenreaktion", "Muskatnuss gegen Manhattan",
                "Koji-Schimmel & Umami", "Brotkrümelverbot im All"
            ],
            .french: [
                "Inondation de bière 1814", "Garum : sauce romaine", "Rituel de l'ortolan", "Baie miracle et goût",
                "Jugement de Paris 1976", "Licence fugu tétrodotoxine", "Miel de tombe de 3 000 ans", "Ouvre-boîte né 48 ans tard",
                "Fromage Casu Marzu", "Enzymes du Kopi Luwak", "Réaction de Maillard", "Muscade contre Manhattan",
                "Moisissure Koji et umami", "Miettes interdites en orbite"
            ],
            .spanish: [
                "Inundación cerveza Londres 1814", "Garum: salsa romana", "Ritual del hortelano", "Fruta milagrosa del gusto",
                "Juicio de París 1976", "Licencia fugu tetrodotoxina", "Miel egipcia de 3.000 años", "Abrelatas 48 años después",
                "Queso Casu Marzu", "Química del Kopi Luwak", "Reacción de Maillard", "Nuez moscada por Manhattan",
                "Hongo Koji y umami", "Migas prohibidas en el espacio"
            ],
            .korean: [
                "1814년 런던 맥주 홍수", "로마 어장 가룸 소스", "오르톨랑 냅킨 의식", "미라클 베리 미각 착각",
                "1976년 파리의 심판 와인", "복어 테트로도톡신 면허", "3천 년 된 무덤 속 꿀", "통조림과 48년 늦은 따개",
                "카수 마르추 구더기 치즈", "코피 루왁 효소 화학", "마이야르 반응 풍미", "맨해튼과 육두구 맞교환",
                "누룩곰팡이와 감칠맛", "무중력 우주선 빵가루 금지"
            ]
        ],
        "history": [
            .japanese: [
                "1518年ストラスブール踊りの疫病", "1932年エミュー戦争", "連合軍の空気注入式戦車", "1816年夏のない年",
                "未解読ヴォイニッチ手稿", "ビザンツのギリシャ火薬", "1983年ペトロフの核警報判断", "1637年チューリップバブル",
                "ミンスミート作戦の偽装", "1904年五輪マラソン大混乱", "ローマ自己修復コンクリート", "1919年ボストン糖蜜災害",
                "インカの縄文字キープ", "CIAの盗聴猫計画"
            ],
            .german: [
                "Tanzwut 1518", "Großer Emu-Krieg 1932", "Aufblasbare Geisterarmee", "1816: Jahr ohne Sommer",
                "Voynich-Manuskript", "Byzantinisches Griechisches Feuer", "Petrow-Fehlalarm 1983", "Tulpenmanie 1637",
                "Operation Mincemeat", "Olympia-Marathon 1904", "Selbstheilender Römerbeton", "Bostoner Melasseflut 1919",
                "Inka-Knotenschrift Quipu", "CIA-Spionagekatze"
            ],
            .french: [
                "Épidémie dansante de 1518", "Guerre des émeus 1932", "Armée fantôme gonflable", "1816, l'année sans été",
                "Manuscrit de Voynich", "Feu grégeois byzantin", "Décision Petrov de 1983", "Crise des tulipes 1637",
                "Opération Mincemeat", "Marathon chaotique 1904", "Béton romain autoréparant", "Déluge de mélasse 1919",
                "Quipus noués des Incas", "Chat espion de la CIA"
            ],
            .spanish: [
                "Peste del baile 1518", "Guerra del Emú 1932", "Ejército fantasma inflable", "1816: año sin verano",
                "Manuscrito Voynich", "Fuego griego bizantino", "Alerta nuclear Petrov 1983", "Crisis de tulipanes 1637",
                "Operación Mincemeat", "Maratón caótico de 1904", "Hormigón romano autorreparable", "Inundación de melaza 1919",
                "Quipus anudados incas", "Gato espía de la CIA"
            ],
            .korean: [
                "1518년 스트라스부르 춤 전염병", "1932년 호주 에뮤 전쟁", "연합군 풍선 유령 부대", "1816년 여름이 없던 해",
                "미해독 보이니치 필사본", "비잔틴 그리스의 불", "1983년 페트로프 핵 경보 판단", "1637년 튤립 선물 폭락",
                "민스미트 기만 작전", "1904년 올림픽 마라톤 대혼란", "자가 치유 로마 콘크리트", "1919년 보스턴 당밀 홍수",
                "잉카 매듭 문자 키푸", "CIA 도청 고양이 작전"
            ]
        ],
        "sports": [
            .japanese: [
                "フォスベリー背面跳び", "ブラバムBT46Bファンカー", "フィレンツェ古式フットボール", "ナックルボールのマグヌス効果",
                "バークレー・マラソン本破り", "2008年高速水着禁止", "149対0の抗議オウンゴール", "パネンカPKの心理学",
                "ブラウンGP二重ディフューザー", "6輪F1タイレルP34", "大相撲・土俵の塩清め", "カーリングのペブル氷",
                "1992年デンマークの奇跡", "マン島TT公道200マイル"
            ],
            .german: [
                "Fosbury-Flop-Hochsprung", "Brabham BT46B Fan Car", "Calcio Storico in Florenz", "Knuckleball-Physik",
                "Barkley-Buchseiten-Lauf", "Verbot der 2008er Schwimmanzüge", "149:0-Eigentor-Protest", "Panenka-Elfmeter-Psychologie",
                "Brawn-GP-Doppeldiffusor", "Sechsrädriger Tyrrell P34", "Sumo-Salzritual auf Dohyo", "Curling-Pebble-Eisphysik",
                "Dänemarks EM-Wunder 1992", "Isle of Man TT Straßenrennen"
            ],
            .french: [
                "Saut en Fosbury-flop", "Brabham BT46B à ventilateur", "Calcio Storico florentin", "Physique de la balle flottante",
                "Marathon Barkley à pages", "Combinaisons interdites 2008", "Protestation 149–0 contre soi", "Psychologie de la Panenka",
                "Double diffuseur Brawn GP", "Tyrrell P34 à six roues", "Rituel du sel au sumo", "Glace à picots du curling",
                "Miracle danois de 1992", "Tourist Trophy île de Man"
            ],
            .spanish: [
                "Salto estilo Fosbury", "Brabham BT46B ventilador", "Calcio Storico florentino", "Física del knuckleball",
                "Maratón Barkley con páginas", "Trajes prohibidos de 2008", "Protesta 149–0 en propia puerta", "Psicología del penalti Panenka",
                "Doble difusor Brawn GP", "Tyrrell P34 de seis ruedas", "Ritual de la sal en sumo", "Física del hielo en curling",
                "Milagro danés de 1992", "TT Isla de Man a 320 km/h"
            ],
            .korean: [
                "포스베리 배면뛰기 혁명", "브라밤 BT46B 팬 F1카", "피렌체 칼초 스토리코", "너클볼 마그누스 물리학",
                "바클리 마라톤 책 찢기", "2008년 폴리우레탄 수영복 금지", "149대 0 자책골 항의 경기", "파넨카 킥의 심리전",
                "브라운 GP 더블 디퓨저", "6바퀴 F1 타이렐 P34", "스모 도효 소금 정화 의식", "컬링 페블 얼음 물리학",
                "1992년 덴마크 유로 기적", "맨섬 TT 공도 320km 레이스"
            ]
        ],
        "tech": [
            .japanese: [
                "アポロ11号の手編みROM", "Cloudflare溶岩ランプ暗号", "1947年ハーバードの蛾バグ", "ASML錫液滴EUVレーザー",
                "海底ケーブルを噛むサメ", "2038年32ビット時刻問題", "宇宙線による選挙ビット反転", "Quake III謎の平方根定数",
                "囲碁盤から生まれたQRコード", "2600Hz笛と電話ハック", "マーズ探査機の単位ミス", "UTF-8ダイナーのナプキン設計",
                "GPSの相対論的時刻ズレ", "パリ気送管郵便網"
            ],
            .german: [
                "Apollo-11-Seilspeicher", "Cloudflare-Lavalampen-Entropie", "Harvard-Motte-Bug 1947", "ASML-Zinntropfen-EUV",
                "Haibisse in Seekabeln", "Jahr-2038-Überlauf", "Kosmischer Bitflip bei Wahl", "Quake-III-Code 0x5f3759df",
                "QR-Code vom Go-Brett", "2600-Hz-Pfeife Phone Phreaking", "Mars-Orbiter Einheiten-Bug", "UTF-8 auf Diner-Serviette",
                "GPS-Relativitäts-Drift", "Pariser Rohrpostnetz"
            ],
            .french: [
                "Mémoire tissée d'Apollo 11", "Entropie lampes à lave Cloudflare", "Le vrai bug mite de 1947", "Plasma étain EUV d'ASML",
                "Requins et câbles sous-marins", "Bug de l'an 2038", "Bit cosmique d'une élection", "Magie Quake III 0x5f3759df",
                "QR Code né du jeu de Go", "Sifflet 2600 Hz Cap'n Crunch", "Erreur métrique sur Mars", "UTF-8 sur une serviette",
                "Dérive relativiste du GPS", "Poste pneumatique de Paris"
            ],
            .spanish: [
                "Memoria tejida del Apolo 11", "Lámparas de lava Cloudflare", "La polilla real del bug 1947", "Láser EUV de gotas ASML",
                "Tiburones en cables submarinos", "Desbordamiento del año 2038", "Rayo cósmico en elecciones", "Constante Quake III 0x5f3759df",
                "Código QR del tablero de Go", "Silbato 2600 Hz de telefonía", "Error métrico rumbo a Marte", "UTF-8 en servilleta de café",
                "Deriva relativista del GPS", "Correo neumático de París"
            ],
            .korean: [
                "아폴로 11호 수직 밧줄 메모리", "클라우드플레어 라바 램프 암호", "1947년 진짜 나방 버그", "ASML 주석 방울 EUV 레이저",
                "해저 케이블 무는 상어", "2038년 유닉스 시간 오버플로", "우주선이 뒤집은 선거 비트", "퀘이크 III 역제곱근 상수",
                "바둑판에서 탄생한 QR 코드", "2600Hz 시리얼 호루라기 해킹", "화성 탐사선 단위계 실수", "냅킨 위에서 설계된 UTF-8",
                "GPS 상대성이론 시간 보정", "파리 기송관 우편 시스템"
            ]
        ],
        "nature": [
            .japanese: [
                "樹木のクラウン・シャイネス", "アリを操る冬虫夏草", "マラカイボ湖の絶えぬ稲妻", "デスバレーの動く石",
                "菌根菌の森のインターネット", "テッポウエビの4700℃衝撃波", "人間と口笛で協働する鳥", "海底の氷の死の指ブライニクル",
                "モノマネ上手なコトドリ", "120年周期の竹の一斉開花", "隔絶されたモヴィレ硫黄洞窟", "アマゾンを養うサハラ砂塵",
                "垂直に眠るマッコウクジラ", "15種に擬態するタコ"
            ],
            .german: [
                "Kronenscheu der Bäume", "Cordyceps-Zombie-Ameisen", "Ewige Blitze von Maracaibo", "Wandernde Steine im Death Valley",
                "Wood Wide Web der Pilze", "Knallkrebs 4.700°C-Schlag", "Honiganzeiger-Vogelpakt", "Brinicle: Eis-Todesfinger",
                "Leierschwanz-Kettensäge", "120-Jahre-Bambusblüte", "Abgeschottete Movile-Höhle", "Sahara-Staub düngt Amazonas",
                "Senkrecht schlafende Wale", "15-Arten-Mimikry-Oktopus"
            ],
            .french: [
                "Timidité des cimes", "Champignon zombie Cordyceps", "Foudre éternelle de Maracaibo", "Pierres mouvantes Death Valley",
                "Internet souterrain des forêts", "Crevette pistolet à 4 700 °C", "Pacte sifflé avec l'indicateur", "Doigt de glace sous-marin",
                "Oiseau-lyre imitateur", "Floraison du bambou 120 ans", "Grotte sulfurée de Movile", "Sable du Sahara en Amazonie",
                "Baleines dormant à la verticale", "Poulpe mime de 15 espèces"
            ],
            .spanish: [
                "Timidez de la copa arbórea", "Hongo zombi Cordyceps", "Relámpago eterno Maracaibo", "Piedras viajeras Death Valley",
                "Red subterránea micorrícica", "Camarón pistola a 4.700 °C", "Pacto con ave indicadora", "Dedo helado submarino",
                "Ave lira imitadora", "Floración bambú cada 120 años", "Cueva sellada de Movile", "Polvo del Sahara en Amazonas",
                "Ballenas durmiendo verticales", "Pulpo mimo de 15 especies"
            ],
            .korean: [
                "나무들의 수관 기피 현상", "개미를 조종하는 동충하초", "마라카이보 호수의 영원한 번개", "데스밸리의 움직이는 바위",
                "숲속 균근 곰팡이 인터넷", "딱총새우의 4,700도 충격파", "사람과 휘파람 소통하는 새", "바닷속 죽음의 얼음 손가락",
                "전기톱 소리 흉내 금조", "120년 주기로 피는 대나무", "밀봉된 모빌레 유황 동굴", "아마존을 먹여 살리는 사하라 먼지",
                "수직으로 잠자는 향유고래", "15종으로 변신하는 흉내문어"
            ]
        ],
        "art": [
            .japanese: [
                "エジプトのミイラ茶色顔料", "ホルバインの歪像頭蓋骨", "特許色イヴ・クライン・ブルー", "1911年モナリザ盗難事件",
                "フェルメールのカメラ・オブスクラ", "金継ぎの黄金修復美学", "ヒ素入りのシェーレグリーン", "バンクシーの額縁シュレッダー",
                "北斎のベロ藍革命", "鉄筋なしパンテオンの穹窿", "風で歩くストランドビースト", "システィーナの隠された脳",
                "マルセル・デュシャンの泉", "1万2千個の巻貝から取る紫"
            ],
            .german: [
                "Mumienbraun-Pigment", "Holbeins anamorpher Schädel", "Patentiertes Yves-Klein-Blau", "Mona-Lisa-Raub 1911",
                "Vermeers Camera Obscura", "Kintsugi-Goldreparatur", "Arsenhaltiges Scheeles Grün", "Banksys Schredder-Rahmen",
                "Hokusais Preußischblau", "Unbewehrte Pantheon-Kuppel", "Jansens Wind-Strandbeests", "Michelangelos verstecktes Gehirn",
                "Duchamps Urinal 1917", "Purpur aus 12.000 Schnecken"
            ],
            .french: [
                "Brun de momie égyptienne", "Crâne anamorphique d'Holbein", "Bleu Yves Klein breveté", "Vol de la Joconde en 1911",
                "Chambre noire de Vermeer", "Réparation dorée Kintsugi", "Vert de Scheele à l'arsenic", "Cadre broyeur de Banksy",
                "Bleu de Prusse d'Hokusai", "Dôme sans acier du Panthéon", "Créatures à vent de Jansen", "Cerveau caché de Michel-Ange",
                "Urinoir de Duchamp 1917", "Pourpre de 12 000 escargots"
            ],
            .spanish: [
                "Pigmento marrón de momia", "Cráneo anamórfico de Holbein", "Azul Yves Klein patentado", "Robo de la Mona Lisa 1911",
                "Cámara oscura de Vermeer", "Reparación dorada Kintsugi", "Verde de Scheele con arsénico", "Marco triturador de Banksy",
                "Azul de Prusia en Hokusai", "Cúpula sin acero del Panteón", "Bestias de viento de Jansen", "Cerebro oculto de Miguel Ángel",
                "Urinario de Duchamp 1917", "Púrpura de 12.000 caracoles"
            ],
            .korean: [
                "이집트 미라로 만든 갈색 물감", "홀바인의 왜상 해골 착시", "특허 받은 이브 클랭 블루", "1911년 모나리자 도난 사건",
                "베르메르의 카메라 옵스쿠라", "킨츠기 황금 틈새 수리", "비소 독극물 셸레 그린", "뱅크시의 파쇄기 액자",
                "호쿠사이와 프러시안 블루", "철근 없는 판테온 돔", "바람으로 걷는 해변 괴물", "시스티나 성당 숨겨진 뇌",
                "뒤샹의 1917년 샘 변기", "달팽이 1만2천 마리 티리안 퍼플"
            ]
        ],
        "philosophy": [
            .japanese: [
                "テセウスの船のパラドックス", "白黒の部屋のマリー", "サールの中国語の部屋", "ニューカムの予測者の箱",
                "ディオゲネスの毛をむしった鶏", "ノージックの経験機械", "ボルツマン脳の確率揺らぎ", "ヴィトゲンシュタイン箱のカブトムシ",
                "パーフィットの火星テレポート", "ラッセルの宇宙ティーポット", "フーコーのパノプティコン", "荘子の胡蝶の夢",
                "水槽の中の脳の懐疑", "チェスタートンの柵の教え"
            ],
            .german: [
                "Schiff des Theseus", "Mary im Schwarz-Weiß-Zimmer", "Searles Chinesisches Zimmer", "Newcombs Vorhersage-Box",
                "Diogenes' gerupftes Huhn", "Nozicks Erlebnismaschine", "Boltzmann-Gehirn-Fluktuation", "Wittgensteins Käfer-Schachtel",
                "Parfits Mars-Teleporter", "Russells Teekanne im Orbit", "Foucaults Panopticon", "Zhuangzis Schmetterlingstraum",
                "Gehirn im Tank", "Chestertons Zaun-Regel"
            ],
            .french: [
                "Paradoxe du bateau de Thésée", "Chambre noire et blanche de Mary", "Chambre chinoise de Searle", "Boîte de Newcomb",
                "Poulet plumé de Diogène", "Machine à expérience de Nozick", "Cerveau de Boltzmann", "Scarabée de Wittgenstein",
                "Téléporteur martien de Parfit", "Théière orbitale de Russell", "Panoptique de Foucault", "Rêve du papillon de Zhuangzi",
                "Cerveau dans une cuve", "Règle de la clôture Chesterton"
            ],
            .spanish: [
                "Paradoja del barco de Teseo", "El cuarto blanco y negro de Mary", "Habitación china de Searle", "Caja de Newcomb",
                "Pollo desplumado de Diógenes", "Máquina de experiencias Nozick", "Cerebro de Boltzmann", "Escarabajo de Wittgenstein",
                "Teletransportador de Parfit", "Tetera orbital de Russell", "Panóptico de Foucault", "Sueño mariposa de Zhuangzi",
                "Cerebro en una cubeta", "Valla de Chesterton"
            ],
            .korean: [
                "테세우스의 배 역설", "흑백 방에 갇힌 메리", "설의 중국어 방 논증", "뉴컴의 예언자 상자",
                "디오게네스의 털 뽑힌 닭", "노직의 경험 기계", "볼츠만 뇌 요동 가설", "비트겐슈타인 상자 속 딱정벌레",
                "파핏의 화성 순간이동 복제", "러셀의 우주 찻주전자", "푸코의 파놉티콘 감시탑", "장자의 호접몽",
                "통 속의 뇌 회의론", "체스터턴의 울타리 원칙"
            ]
        ],
        "travel": [
            .japanese: [
                "バールレの店内国境線", "ダイオミード21時間時差歩行", "スヴァールバル死去禁止法", "宇宙機の墓場ポイントネモ",
                "九龍城砦の立体迷宮", "クーバーペディ地下住宅街", "永遠に燃えるダルヴァザ地獄の門", "軍艦島こと端島の廃墟",
                "半年ごとに国が変わる島", "マンションを貫通する重慶鉄道", "道路のない運河の村ヒートホールン", "日照鏡で照らすリューカン村",
                "生きた木の根の橋メーガーラヤ", "ヴッパータール懸垂式モノレール"
            ],
            .german: [
                "Baarle: Grenze im Café", "Diomedes 21-Stunden-Marsch", "Svalbard: Verbot zu sterben", "Point Nemo Raumschiff-Friedhof",
                "Labyrinth der Kowloon-Stadt", "Coober Pedy Untergrundstadt", "Brennender Krater Darvaza", "Geisterinsel Hashima",
                "Fasaneninsel mit Länderwechsel", "Zug durch Wohnhaus Chongqing", "Grachtendorf ohne Straßen", "Sonnenspiegel von Rjukan",
                "Lebende Wurzelbrücken", "Wuppertaler Schwebebahn"
            ],
            .french: [
                "Baarle : frontière en café", "Îles Diomède à 21 h d'écart", "Interdiction de mourir au Svalbard", "Point Némo cimetière spatial",
                "Labyrinthe de Kowloon", "Maisons troglodytes Coober Pedy", "Cratère en feu de Darvaza", "Île fantôme d'Hashima",
                "Île des Faisans binationale", "Train traversant un immeuble", "Giethoorn sans routes", "Miroirs solaires de Rjukan",
                "Ponts vivants de racines", "Monorail suspendu de Wuppertal"
            ],
            .spanish: [
                "Baarle: frontera en cafés", "Islas Diómedes: 21 h de salto", "Prohibido morir en Svalbard", "Punto Nemo cementerio espacial",
                "Laberinto amurallado Kowloon", "Ciudad subterránea Coober Pedy", "Cráter ardiente de Darvaza", "Isla fantasma Hashima",
                "Isla de los Faisanes", "Tren que cruza un edificio", "Giethoorn sin carreteras", "Espejos solares de Rjukan",
                "Puentes vivos de raíces", "Monorraíl colgante Wuppertal"
            ],
            .korean: [
                "바를레 카페 안 국경선", "디오메데스 21시간 도보 시차", "스발바르 사망 금지법", "포인트 니모 우주선 무덤",
                "구룡성채 수직 미로 도시", "쿠버 페디 지하 동굴 마을", "꺼지지 않는 다르바자 지옥문", "폐허가 된 군함도 하시마",
                "6개월마다 국적 바뀌는 섬", "아파트를 뚫고 지나가는 충칭 열차", "도로 없는 운하 마을 히트호른", "태양 거울 마을 리우칸",
                "살아있는 나무뿌리 다리", "부퍼탈 공중 모노레일"
            ]
        ],
        "gaming": [
            .japanese: [
                "WoW堕落した血のパンデミック", "マリオ64の半Aボタン理論", "シヴィライゼーション核ガンジー", "サイレントヒルPS1の霧トリック",
                "インベーダー処理落ち加速", "ポケモンけつばんバグ", "1981年ポリビウス都市伝説", "パックマン256面キル画面",
                "DOOMの386 BSP木計算", "ストIIバグ由来コンボ", "アセンブリ記述の遊園地", "マザー2海賊版ボス消去罠",
                "サイコ・マンティスのメモリ読取", "コヨーテタイムの判定猶予"
            ],
            .german: [
                "WoW-Seuche Corrupted Blood", "Mario 64: Halber A-Knopf", "Civilization: Nuklear-Gandhi", "Silent Hill Nebeltrick PS1",
                "Space-Invaders-Lag-Tempo", "Pokémon MissingNo.-Bug", "1981 Polybius Arcade-Mythos", "Pac-Man Level-256-Absturz",
                "Doom 386er BSP-Baum-Mathe", "Street Fighter II Bug-Combos", "Assembly-RollerCoaster Tycoon", "EarthBound Kopierschutz-Falle",
                "Psycho Mantis Speicher-Trick", "Coyote-Time Sprung-Frames"
            ],
            .french: [
                "Peste du sang corrompu WoW", "Mario 64 : demi-pression A", "Gandhi nucléaire Civilization", "Brouillard PS1 de Silent Hill",
                "Accélération de Space Invaders", "Bug MissingNo. de Pokémon", "Mythe arcade Polybius 1981", "Écran fatal Pac-Man 256",
                "Arbres BSP de Doom sur 386", "Combos issus de bugs SF2", "RollerCoaster codé en assembleur", "Piège antipiratage EarthBound",
                "Psycho Mantis lit votre carte", "Marges de saut Coyote Time"
            ],
            .spanish: [
                "Plaga de sangre en WoW", "Mario 64: medio botón A", "Gandhi nuclear Civilization", "Truco niebla PS1 Silent Hill",
                "Aceleración Space Invaders", "Bug MissingNo. en Pokémon", "Mito arcade Polybius 1981", "Pantalla mortal Pac-Man 256",
                "Árboles BSP de Doom 386", "Combos por bug Street Fighter II", "RollerCoaster en ensamblador", "Trampa antipiratería EarthBound",
                "Psycho Mantis lee tu memoria", "Margen de salto Coyote Time"
            ],
            .korean: [
                "와우 오염된 피 전염병 사건", "마리오 64 반 박자 A버튼 수학", "문명 시리즈 핵간디 밈", "사일런트 힐 PS1 안개 트릭",
                "스페이스 인베이더 렉 가속", "포켓몬 미싱노 오버플로", "1981년 폴리비우스 오락실 괴담", "팩맨 256레벨 킬 스크린",
                "둠 386 BSP 트리 수학", "스파2 버그에서 탄생한 콤보", "어셈블리어로 짠 롤러코스터", "어스바운드 복제 방지 폭파",
                "사이코 맨티스 메모리카드 읽기", "점프 판정 유예 코요테 타임"
            ]
        ]
    ]
}
