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
        lang == .turkish ? nameTR : nameEN
    }

    func fallbackInterests(for lang: AppLanguage) -> [String] {
        lang == .turkish ? fallbackInterestsTR : fallbackInterestsEN
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
        let candidateTokens = ([legacyCollectionName].compactMap { $0 } + tags)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.caseInsensitiveCompare("All") != .orderedSame && $0.caseInsensitiveCompare("Tümü") != .orderedSame }

        for token in candidateTokens {
            if let match = presets.first(where: {
                $0.id.caseInsensitiveCompare(token) == .orderedSame ||
                $0.nameEN.caseInsensitiveCompare(token) == .orderedSame ||
                $0.nameTR.caseInsensitiveCompare(token) == .orderedSame
            }) {
                return match
            }
        }

        // 3. Match against curated sub-topics in each preset
        for token in candidateTokens {
            let lowerToken = token.lowercased()
            if let match = presets.first(where: { cat in
                cat.fallbackInterestsEN.contains(where: { $0.lowercased() == lowerToken }) ||
                cat.fallbackInterestsTR.contains(where: { $0.lowercased() == lowerToken })
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
                "a24", "giallo", "belgesel", "animasyon", "ghibli", "kurgu", "kadraj", "imax", "technicolor"
            ],
            "music": [
                "müzik", "music", "şarkı", "piyano", "gitar", "davul", "akort", "senfoni", "orkestra",
                "caz", "jazz", "rock", "plak", "albüm", "frekans", "beste", "enstrüman", "nota", "koro",
                "melodi", "sentezleyici", "synth", "theremin", "reverb", "vokal", "tını", "konser", "radiohead"
            ],
            "science": [
                "bilim", "science", "fizik", "kimya", "biyoloji", "atom", "molekül", "gen", "dna", "hücre",
                "deney", "kuantum", "quantum", "crispr", "uzay", "gezegen", "yıldız", "nötron", "nötrino",
                "radyasyon", "reaktör", "evrim", "nöron", "nörobilim", "izotop", "bakteri", "enzim",
                "teleskop", "termodinamik", "foton", "plazma", "helyum", "tardigrad", "astronomi", "astrofizik"
            ],
            "food": [
                "yemek", "food", "mutfak", "cuisine", "ekmek", "bread", "sourdough", "ekşi maya", "peynir",
                "cheese", "şarap", "wine", "kahve", "coffee", "bira", "beer", "sos", "sauce", "garum",
                "pişirme", "restoran", "aşçı", "lezzet", "baharat", "çikolata", "balık", "gastronomi",
                "fermentasyon", "fermentation", "maya", "tuz", "şeker", "çay", "ramen", "kimçi", "trüf",
                "safran", "viski", "şampanya", "fugu", "cheesecake", "ortolan", "zeytinyağı", "makarna"
            ],
            "history": [
                "tarih", "history", "imparatorluk", "empire", "savaş", "war", "antik", "ancient", "ortaçağ",
                "medieval", "kral", "padişah", "osmanlı", "ottoman", "roma", "roman", "bizans", "byzantine",
                "mısır", "egypt", "devrim", "antlaşma", "kuşatma", "arkeoloji", "uygarlık", "hanedan",
                "viking", "samuray", "mezopotamya", "inquisition", "veba", "plague", "mÖ", "milattan"
            ],
            "sports": [
                "spor", "sport", "futbol", "football", "soccer", "basketbol", "formula 1", "f1", "olimpiyat",
                "olympic", "maraton", "koşu", "tenis", "maç", "şampiyon", "rekor", "atlet", "yüzme",
                "boks", "satranç", "chess", "bisiklet", "stadyum", "penaltı", "gol", "nba", "premier lig",
                "sumo", "curling", "kriket", "tırmanış"
            ],
            "tech": [
                "teknoloji", "technology", "tech", "bilgisayar", "computer", "yazılım", "software", "algoritma",
                "kod", "internet", "işlemci", "çip", "siber", "şifreleme", "robot", "yapay zeka", "yapay zekâ",
                "ai", "veri", "bellek", "uydu", "lazer", "donanım", "sunucu", "unix", "linux", "transistör",
                "kablo", "derleyici", "rust", "apple", "kuantum bilişim", "blockchain"
            ],
            "nature": [
                "doğa", "nature", "hayvan", "bitki", "ağaç", "orman", "okyanus", "deniz", "göl", "çöl",
                "yanardağ", "kuş", "balina", "karınca", "mantar", "ekosistem", "buzul", "mercan",
                "kelebek", "ahtapot", "köpekbalığı", "fosil", "jeoloji", "biyolüminesans", "ekoloji", "kutup"
            ],
            "art": [
                "sanat", "art", "tablo", "painting", "resim", "heykel", "sculpture", "mimari", "architecture",
                "müze", "boya", "pigment", "fresk", "seramik", "tasarım", "kubbe", "galeri", "ressam",
                "tuval", "vitray", "baskı", "rönesans", "bauhaus", "brütalizm", "kaligrafi", "tipografi",
                "mona lisa", "michelangelo", "vermeer", "banksy", "kintsugi"
            ],
            "philosophy": [
                "felsefe", "philosophy", "paradoks", "paradox", "etik", "ethics", "ahlak", "bilinç",
                "consciousness", "zihin", "mantık", "düşünce deneyi", "varoluş", "özgür irade", "sokrates",
                "platon", "kant", "nietzsche", "diyojen", "stoacılık", "stoicism", "epistemoloji", "qualıa",
                "qualia", "determinizm", "theseus", "schopenhauer", "foucault", "wittgenstein"
            ],
            "travel": [
                "seyahat", "travel", "ada", "island", "kasaba", "şehir", "köy", "ülke", "sınır", "coğrafya",
                "rota", "kanyon", "nehir", "tapınak", "manastır", "yeraltı şehri", "svalbard", "patagonya",
                "izlanda", "kyoto", "derinkuyu", "kapadokya", "fiyort", "krater"
            ],
            "gaming": [
                "oyun", "game", "gaming", "oyuncu", "konsol", "atari", "playstation", "ps1", "ps2",
                "nintendo", "arcade", "speedrun", "boss", "piksel", "fps", "rpg", "minecraft", "mario",
                "zelda", "tetris", "doom", "quake", "pac-man", "street fighter", "warcraft", "pokemon", "pokémon"
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
}
