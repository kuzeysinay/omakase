//
//  InterestCategory.swift
//  omakase
//
//  Static data model for preset interest categories used in the
//  tap-first discovery grid (onboarding + feed explorer).
//

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
}

// MARK: - Preset Categories

extension InterestCategory {

    static let presets: [InterestCategory] = [
        InterestCategory(
            id: "film",
            iconName: "film",
            emoji: "🎬",
            nameEN: "Film",
            nameTR: "Film",
            hue: 0.0,
            fallbackInterestsEN: ["Christopher Nolan", "A24", "Studio Ghibli", "Wong Kar-wai", "Tarantino", "French New Wave", "Sci-Fi Cinema", "David Fincher", "Denis Villeneuve", "Stanley Kubrick", "Neo-Noir", "Martin Scorsese", "Hayao Miyazaki"],
            fallbackInterestsTR: ["Christopher Nolan", "A24", "Studio Ghibli", "Wong Kar-wai", "Tarantino", "Yeni Dalga Sineması", "Bilim Kurgu Filmleri", "David Fincher", "Denis Villeneuve", "Stanley Kubrick", "Neo-Noir", "Martin Scorsese", "Hayao Miyazaki"]
        ),
        InterestCategory(
            id: "music",
            iconName: "music.note",
            emoji: "🎵",
            nameEN: "Music",
            nameTR: "Müzik",
            hue: 0.08,
            fallbackInterestsEN: ["Jazz", "Radiohead", "Classical Piano", "Indie Rock", "Electronic Music", "K-Pop", "Blues", "Film Scores", "Ambient", "Shoegaze", "Hip Hop Production", "Miles Davis", "Post-Rock"],
            fallbackInterestsTR: ["Caz", "Radiohead", "Klasik Piyano", "Indie Rock", "Elektronik Müzik", "K-Pop", "Blues", "Film Müzikleri", "Ambient", "Shoegaze", "Hip Hop Prodüksiyonu", "Miles Davis", "Post-Rock"]
        ),
        InterestCategory(
            id: "science",
            iconName: "atom",
            emoji: "🔬",
            nameEN: "Science",
            nameTR: "Bilim",
            hue: 0.55,
            fallbackInterestsEN: ["Quantum Physics", "CRISPR", "Astronomy", "Neuroscience", "Climate Science", "Marine Biology", "AI Research", "Space Exploration", "Astrophysics", "Evolutionary Biology", "Dark Matter", "James Webb Telescope"],
            fallbackInterestsTR: ["Kuantum Fiziği", "CRISPR", "Astronomi", "Nörobilim", "İklim Bilimi", "Deniz Biyolojisi", "Yapay Zekâ", "Uzay Keşfi", "Astrofizik", "Evrimsel Biyoloji", "Karanlık Madde", "James Webb Teleskobu"]
        ),
        InterestCategory(
            id: "food",
            iconName: "fork.knife",
            emoji: "🍳",
            nameEN: "Food",
            nameTR: "Yemek",
            hue: 0.1,
            fallbackInterestsEN: ["Sourdough Bread", "Japanese Cuisine", "Fermentation", "Street Food", "Wine Pairing", "Coffee Brewing", "Italian Cooking", "Spice Science", "Pastry Arts", "Artisan Cheese", "Ramen Culture", "Michelin Guide"],
            fallbackInterestsTR: ["Ekşi Maya Ekmek", "Japon Mutfağı", "Fermentasyon", "Sokak Lezzetleri", "Şarap Eşleştirme", "Kahve Demleme", "İtalyan Mutfağı", "Baharat Bilimi", "Pastacılık", "Gurme Peynirler", "Ramen Kültürü", "Michelin Rehberi"]
        ),
        InterestCategory(
            id: "history",
            iconName: "clock.arrow.circlepath",
            emoji: "📜",
            nameEN: "History",
            nameTR: "Tarih",
            hue: 0.12,
            fallbackInterestsEN: ["Ancient Rome", "Ottoman Empire", "World War II", "Medieval Europe", "Ancient Egypt", "Cold War", "Silk Road", "Viking Age", "Byzantine Empire", "Renaissance", "Industrial Revolution", "Samurai History"],
            fallbackInterestsTR: ["Antik Roma", "Osmanlı İmparatorluğu", "İkinci Dünya Savaşı", "Ortaçağ Avrupası", "Antik Mısır", "Soğuk Savaş", "İpek Yolu", "Viking Çağı", "Bizans İmparatorluğu", "Rönesans", "Sanayi Devrimi", "Samuray Tarihi"]
        ),
        InterestCategory(
            id: "sports",
            iconName: "figure.run",
            emoji: "⚽",
            nameEN: "Sports",
            nameTR: "Spor",
            hue: 0.33,
            fallbackInterestsEN: ["Football Tactics", "F1 Racing", "Basketball Analytics", "Tennis", "MMA", "Cycling", "Olympic History", "Chess", "Marathon Training", "Premier League", "NBA History", "Scuba Diving"],
            fallbackInterestsTR: ["Futbol Taktikleri", "Formula 1", "Basketbol Analizi", "Tenis", "MMA", "Bisiklet", "Olimpiyat Tarihi", "Satranç", "Maraton Koşusu", "Premier Lig", "NBA Tarihi", "Tüplü Dalış"]
        ),
        InterestCategory(
            id: "tech",
            iconName: "cpu",
            emoji: "💻",
            nameEN: "Technology",
            nameTR: "Teknoloji",
            hue: 0.6,
            fallbackInterestsEN: ["AI & Machine Learning", "Cybersecurity", "Startups", "Blockchain", "UX Design", "Robotics", "Apple", "Open Source", "LLMs & Prompting", "Chip Architecture", "Web3", "Cloud Computing"],
            fallbackInterestsTR: ["Yapay Zekâ", "Siber Güvenlik", "Girişimcilik", "Blockchain", "UX Tasarım", "Robotik", "Apple", "Açık Kaynak", "Büyük Dil Modelleri", "Çip Mimarisi", "Web3", "Bulut Bilişim"]
        ),
        InterestCategory(
            id: "nature",
            iconName: "leaf",
            emoji: "🌿",
            nameEN: "Nature",
            nameTR: "Doğa",
            hue: 0.38,
            fallbackInterestsEN: ["Deep Ocean", "Birdwatching", "Volcanoes", "Forests", "Animal Behavior", "Geology", "Weather Patterns", "National Parks", "Mycology", "Coral Reefs", "Arctic Wildlife", "Botany"],
            fallbackInterestsTR: ["Derin Okyanus", "Kuş Gözlemi", "Yanardağlar", "Ormanlar", "Hayvan Davranışı", "Jeoloji", "Hava Olayları", "Milli Parklar", "Mantar Bilimi", "Mercan Resifleri", "Kutup Doğası", "Botanik"]
        ),
        InterestCategory(
            id: "art",
            iconName: "paintpalette",
            emoji: "🎨",
            nameEN: "Art",
            nameTR: "Sanat",
            hue: 0.75,
            fallbackInterestsEN: ["Renaissance Art", "Street Art", "Photography", "Architecture", "Sculpture", "Digital Art", "Art Deco", "Impressionism", "Bauhaus", "Minimalism", "Graphic Design", "Typography"],
            fallbackInterestsTR: ["Rönesans Sanatı", "Sokak Sanatı", "Fotoğrafçılık", "Mimari", "Heykel", "Dijital Sanat", "Art Deco", "Empresyonizm", "Bauhaus", "Minimalizm", "Grafik Tasarım", "Tipografi"]
        ),
        InterestCategory(
            id: "philosophy",
            iconName: "brain.head.profile",
            emoji: "🧠",
            nameEN: "Philosophy",
            nameTR: "Felsefe",
            hue: 0.82,
            fallbackInterestsEN: ["Stoicism", "Existentialism", "Ethics", "Eastern Philosophy", "Logic", "Philosophy of Mind", "Nietzsche", "Political Philosophy", "Epistemology", "Absurdism", "Marcus Aurelius", "Kantian Ethics"],
            fallbackInterestsTR: ["Stoacılık", "Varoluşçuluk", "Etik", "Doğu Felsefesi", "Mantık", "Zihin Felsefesi", "Nietzsche", "Siyaset Felsefesi", "Epistemoloji", "Absürdizm", "Marcus Aurelius", "Kant Etiği"]
        ),
        InterestCategory(
            id: "travel",
            iconName: "globe.americas",
            emoji: "✈️",
            nameEN: "Travel",
            nameTR: "Seyahat",
            hue: 0.48,
            fallbackInterestsEN: ["Japan Travel", "Hidden European Gems", "Solo Backpacking", "Cultural Festivals", "Island Hopping", "Road Trips", "Arctic Adventures", "Southeast Asia", "Nordic Fjords", "Train Journeys", "Eco-Tourism", "Patagonia"],
            fallbackInterestsTR: ["Japonya Seyahati", "Avrupa'nın Gizli Köşeleri", "Solo Sırt Çantası", "Kültürel Festivaller", "Ada Turu", "Karayolu Gezileri", "Arktik Macera", "Güneydoğu Asya", "İskandinav Fiyortları", "Tren Yolculukları", "Eko-Turizm", "Patagonya"]
        ),
        InterestCategory(
            id: "gaming",
            iconName: "gamecontroller",
            emoji: "🎮",
            nameEN: "Gaming",
            nameTR: "Oyun",
            hue: 0.7,
            fallbackInterestsEN: ["Indie Games", "Game Design", "Retro Gaming", "RPGs", "Esports", "Nintendo", "Game Lore", "Board Games", "Zelda Series", "Speedrunning", "Dark Souls", "Pixel Art Games"],
            fallbackInterestsTR: ["Indie Oyunlar", "Oyun Tasarımı", "Retro Oyunlar", "RPG'ler", "E-Spor", "Nintendo", "Oyun Hikayeleri", "Masa Oyunları", "Zelda Serisi", "Speedrunning", "Dark Souls", "Piksel Sanatı Oyunlar"]
        ),
    ]
}
