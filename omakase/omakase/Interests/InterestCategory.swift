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
            emoji: "🎬",
            nameEN: "Film",
            nameTR: "Film",
            hue: 0.0,
            fallbackInterestsEN: ["Christopher Nolan", "A24", "Studio Ghibli", "Wong Kar-wai", "Tarantino", "French New Wave", "Sci-Fi Cinema", "David Fincher"],
            fallbackInterestsTR: ["Christopher Nolan", "A24", "Studio Ghibli", "Wong Kar-wai", "Tarantino", "Yeni Dalga Sineması", "Bilim Kurgu Filmleri", "David Fincher"]
        ),
        InterestCategory(
            id: "music",
            emoji: "🎵",
            nameEN: "Music",
            nameTR: "Müzik",
            hue: 0.08,
            fallbackInterestsEN: ["Jazz", "Radiohead", "Classical Piano", "Indie Rock", "Electronic Music", "K-Pop", "Blues", "Film Scores"],
            fallbackInterestsTR: ["Caz", "Radiohead", "Klasik Piyano", "Indie Rock", "Elektronik Müzik", "K-Pop", "Blues", "Film Müzikleri"]
        ),
        InterestCategory(
            id: "science",
            emoji: "🔬",
            nameEN: "Science",
            nameTR: "Bilim",
            hue: 0.55,
            fallbackInterestsEN: ["Quantum Physics", "CRISPR", "Astronomy", "Neuroscience", "Climate Science", "Marine Biology", "AI Research", "Space Exploration"],
            fallbackInterestsTR: ["Kuantum Fiziği", "CRISPR", "Astronomi", "Nörobilim", "İklim Bilimi", "Deniz Biyolojisi", "Yapay Zekâ", "Uzay Keşfi"]
        ),
        InterestCategory(
            id: "food",
            emoji: "🍳",
            nameEN: "Food",
            nameTR: "Yemek",
            hue: 0.1,
            fallbackInterestsEN: ["Sourdough Bread", "Japanese Cuisine", "Fermentation", "Street Food", "Wine Pairing", "Coffee Brewing", "Italian Cooking", "Spice Science"],
            fallbackInterestsTR: ["Ekşi Maya Ekmek", "Japon Mutfağı", "Fermentasyon", "Sokak Lezzetleri", "Şarap Eşleştirme", "Kahve Demleme", "İtalyan Mutfağı", "Baharat Bilimi"]
        ),
        InterestCategory(
            id: "history",
            emoji: "📜",
            nameEN: "History",
            nameTR: "Tarih",
            hue: 0.12,
            fallbackInterestsEN: ["Ancient Rome", "Ottoman Empire", "World War II", "Medieval Europe", "Ancient Egypt", "Cold War", "Silk Road", "Viking Age"],
            fallbackInterestsTR: ["Antik Roma", "Osmanlı İmparatorluğu", "İkinci Dünya Savaşı", "Ortaçağ Avrupası", "Antik Mısır", "Soğuk Savaş", "İpek Yolu", "Viking Çağı"]
        ),
        InterestCategory(
            id: "sports",
            emoji: "⚽",
            nameEN: "Sports",
            nameTR: "Spor",
            hue: 0.33,
            fallbackInterestsEN: ["Football Tactics", "F1 Racing", "Basketball Analytics", "Tennis", "MMA", "Cycling", "Olympic History", "Chess"],
            fallbackInterestsTR: ["Futbol Taktikleri", "Formula 1", "Basketbol Analizi", "Tenis", "MMA", "Bisiklet", "Olimpiyat Tarihi", "Satranç"]
        ),
        InterestCategory(
            id: "tech",
            emoji: "💻",
            nameEN: "Technology",
            nameTR: "Teknoloji",
            hue: 0.6,
            fallbackInterestsEN: ["AI & Machine Learning", "Cybersecurity", "Startups", "Blockchain", "UX Design", "Robotics", "Apple", "Open Source"],
            fallbackInterestsTR: ["Yapay Zekâ", "Siber Güvenlik", "Girişimcilik", "Blockchain", "UX Tasarım", "Robotik", "Apple", "Açık Kaynak"]
        ),
        InterestCategory(
            id: "nature",
            emoji: "🌿",
            nameEN: "Nature",
            nameTR: "Doğa",
            hue: 0.38,
            fallbackInterestsEN: ["Deep Ocean", "Birdwatching", "Volcanoes", "Forests", "Animal Behavior", "Geology", "Weather Patterns", "National Parks"],
            fallbackInterestsTR: ["Derin Okyanus", "Kuş Gözlemi", "Yanardağlar", "Ormanlar", "Hayvan Davranışı", "Jeoloji", "Hava Olayları", "Milli Parklar"]
        ),
        InterestCategory(
            id: "art",
            emoji: "🎨",
            nameEN: "Art",
            nameTR: "Sanat",
            hue: 0.75,
            fallbackInterestsEN: ["Renaissance Art", "Street Art", "Photography", "Architecture", "Sculpture", "Digital Art", "Art Deco", "Impressionism"],
            fallbackInterestsTR: ["Rönesans Sanatı", "Sokak Sanatı", "Fotoğrafçılık", "Mimari", "Heykel", "Dijital Sanat", "Art Deco", "Empresyonizm"]
        ),
        InterestCategory(
            id: "philosophy",
            emoji: "🧠",
            nameEN: "Philosophy",
            nameTR: "Felsefe",
            hue: 0.82,
            fallbackInterestsEN: ["Stoicism", "Existentialism", "Ethics", "Eastern Philosophy", "Logic", "Philosophy of Mind", "Nietzsche", "Political Philosophy"],
            fallbackInterestsTR: ["Stoacılık", "Varoluşçuluk", "Etik", "Doğu Felsefesi", "Mantık", "Zihin Felsefesi", "Nietzsche", "Siyaset Felsefesi"]
        ),
        InterestCategory(
            id: "travel",
            emoji: "✈️",
            nameEN: "Travel",
            nameTR: "Seyahat",
            hue: 0.48,
            fallbackInterestsEN: ["Japan Travel", "Hidden European Gems", "Solo Backpacking", "Cultural Festivals", "Island Hopping", "Road Trips", "Arctic Adventures", "Southeast Asia"],
            fallbackInterestsTR: ["Japonya Seyahati", "Avrupa'nın Gizli Köşeleri", "Solo Sırt Çantası", "Kültürel Festivaller", "Ada Turu", "Karayolu Gezileri", "Arktik Macera", "Güneydoğu Asya"]
        ),
        InterestCategory(
            id: "gaming",
            emoji: "🎮",
            nameEN: "Gaming",
            nameTR: "Oyun",
            hue: 0.7,
            fallbackInterestsEN: ["Indie Games", "Game Design", "Retro Gaming", "RPGs", "Esports", "Nintendo", "Game Lore", "Board Games"],
            fallbackInterestsTR: ["Indie Oyunlar", "Oyun Tasarımı", "Retro Oyunlar", "RPG'ler", "E-Spor", "Nintendo", "Oyun Hikayeleri", "Masa Oyunları"]
        ),
    ]
}
