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
            fallbackInterestsEN: ["Christopher Nolan", "French New Wave", "A24", "Quentin Tarantino", "David Fincher", "Denis Villeneuve", "Stanley Kubrick", "Neo-Noir", "Martin Scorsese", "Wes Anderson", "Silent Cinema", "Italian Neorealism", "Stop-Motion", "Akira Kurosawa", "Soviet Sci-Fi", "Korean Cinema", "Giallo Films", "Documentary Filmmaking", "Studio Ghibli", "Wong Kar-wai", "German Expressionism", "Cinematography", "Cult Classics", "Camera Techniques", "Animation History"],
            fallbackInterestsTR: ["Christopher Nolan", "Yeni Dalga Sineması", "A24", "Quentin Tarantino", "David Fincher", "Denis Villeneuve", "Stanley Kubrick", "Neo-Noir", "Martin Scorsese", "Wes Anderson", "Sessiz Sinema", "İtalyan Yeni Gerçekçilik", "Stop-Motion", "Akira Kurosawa", "Sovyet Bilim Kurgu", "Kore Sineması", "Giallo Filmleri", "Belgesel Sinemacılığı", "Studio Ghibli", "Wong Kar-wai", "Alman Dışavurumculuğu", "Sinematografi", "Kült Klasikler", "Görüntü Yönetimi", "Animasyon Tarihi"]
        ),
        InterestCategory(
            id: "music",
            iconName: "music.note",
            emoji: "🎵",
            nameEN: "Music",
            nameTR: "Müzik",
            hue: 0.08,
            fallbackInterestsEN: ["Jazz", "Radiohead", "Classical Piano", "Indie Rock", "Electronic Music", "K-Pop", "Blues", "Film Scores", "Ambient", "Shoegaze", "Hip Hop Production", "Miles Davis", "Post-Rock", "Modular Synthesizers", "Bossa Nova", "City Pop", "Psychedelic Rock", "Folk Music", "Lo-Fi Beats", "Chamber Pop", "Drum & Bass", "Math Rock", "Jazz Fusion", "Afrobeats", "Synthwave"],
            fallbackInterestsTR: ["Caz", "Radiohead", "Klasik Piyano", "Indie Rock", "Elektronik Müzik", "K-Pop", "Blues", "Film Müzikleri", "Ambient", "Shoegaze", "Hip Hop Prodüksiyonu", "Miles Davis", "Post-Rock", "Modüler Sentezleyiciler", "Bossa Nova", "City Pop", "Psikedelik Rock", "Halk Müziği", "Lo-Fi Beats", "Oda Müziği", "Drum & Bass", "Math Rock", "Caz Füzyon", "Afrobeats", "Synthwave"]
        ),
        InterestCategory(
            id: "science",
            iconName: "atom",
            emoji: "🔬",
            nameEN: "Science",
            nameTR: "Bilim",
            hue: 0.55,
            fallbackInterestsEN: ["Quantum Physics", "CRISPR", "Astronomy", "Neuroscience", "Climate Science", "Marine Biology", "AI Research", "Space Exploration", "Astrophysics", "Evolutionary Biology", "Dark Matter", "James Webb Telescope", "Synthetic Biology", "Particle Physics", "Quantum Computing", "Ocean Trench Ecology", "Exoplanets", "Neuroplasticity", "Thermodynamics", "Paleontology", "String Theory", "Gene Therapy", "Nanotechnology", "Cognitive Science", "Astrobiology"],
            fallbackInterestsTR: ["Kuantum Fiziği", "CRISPR", "Astronomi", "Nörobilim", "İklim Bilimi", "Deniz Biyolojisi", "Yapay Zekâ", "Uzay Keşfi", "Astrofizik", "Evrimsel Biyoloji", "Karanlık Madde", "James Webb Teleskobu", "Sentetik Biyoloji", "Parçacık Fiziği", "Kuantum Hesaplama", "Derin Deniz Ekolojisi", "Ötegezegenler", "Nöroplastisite", "Termodinamik", "Paleontoloji", "Sicim Teorisi", "Gen Terapisi", "Nanoteknoloji", "Bilişsel Bilim", "Astrobiyoloji"]
        ),
        InterestCategory(
            id: "food",
            iconName: "fork.knife",
            emoji: "🍳",
            nameEN: "Food",
            nameTR: "Yemek",
            hue: 0.1,
            fallbackInterestsEN: ["Sourdough Bread", "Japanese Cuisine", "Fermentation", "Street Food", "Wine Pairing", "Coffee Brewing", "Italian Cooking", "Spice Science", "Pastry Arts", "Artisan Cheese", "Ramen Culture", "Michelin Guide", "Molecular Gastronomy", "Tea Ceremonies", "Charcuterie", "Kimchi Making", "Smoked Barbecue", "Handmade Pasta", "Craft Beer", "Wild Foraging", "Chocolate Making", "Olive Oil Tasting", "Cocktail Mixology", "Dim Sum", "Boulangerie"],
            fallbackInterestsTR: ["Ekşi Maya Ekmek", "Japon Mutfağı", "Fermentasyon", "Sokak Lezzetleri", "Şarap Eşleştirme", "Kahve Demleme", "İtalyan Mutfağı", "Baharat Bilimi", "Pastacılık", "Gurme Peynirler", "Ramen Kültürü", "Michelin Rehberi", "Moleküler Gastronomi", "Çay Seremonisi", "Şarküteri", "Kimçi Yapımı", "Tütsülenmiş Barbekü", "El Yapımı Makarna", "Zanaat Birası", "Doğadan Mantar Toplama", "Çikolata Zanaatı", "Zeytinyağı Tadımı", "Kokteyl Miksolojisi", "Dim Sum", "Fransız Fırıncılığı"]
        ),
        InterestCategory(
            id: "history",
            iconName: "clock.arrow.circlepath",
            emoji: "📜",
            nameEN: "History",
            nameTR: "Tarih",
            hue: 0.12,
            fallbackInterestsEN: ["Ancient Rome", "Ottoman Empire", "World War II", "Medieval Europe", "Ancient Egypt", "Cold War", "Silk Road", "Viking Age", "Byzantine Empire", "Renaissance", "Industrial Revolution", "Samurai History", "Mesopotamia", "Age of Discovery", "French Revolution", "Ancient Greece", "Mongol Empire", "Maya Civilization", "Space Race", "WWI Aviation", "Balkan History", "Feudal Japan", "Enlightenment", "Inca Empire", "Maritime Trade"],
            fallbackInterestsTR: ["Antik Roma", "Osmanlı İmparatorluğu", "İkinci Dünya Savaşı", "Ortaçağ Avrupası", "Antik Mısır", "Soğuk Savaş", "İpek Yolu", "Viking Çağı", "Bizans İmparatorluğu", "Rönesans", "Sanayi Devrimi", "Samuray Tarihi", "Mezopotamya", "Coğrafi Keşifler", "Fransız İhtilali", "Antik Yunan", "Moğol İmparatorluğu", "Maya Uygarlığı", "Uzay Yarışı", "1. Dünya Savaşı Havacılığı", "Balkan Tarihi", "Feodal Japonya", "Aydınlanma Çağı", "İnka İmparatorluğu", "Deniz Ticareti Tarihi"]
        ),
        InterestCategory(
            id: "sports",
            iconName: "figure.run",
            emoji: "⚽",
            nameEN: "Sports",
            nameTR: "Spor",
            hue: 0.33,
            fallbackInterestsEN: ["Football Tactics", "F1 Racing", "Basketball Analytics", "Tennis", "MMA", "Cycling", "Olympic History", "Chess", "Marathon Training", "Premier League", "NBA History", "Scuba Diving", "Rock Climbing", "Motorsport Engineering", "Surfing Culture", "Gymnastics", "Track & Field", "Triathlon", "Table Tennis", "Rugby Tactics", "Skiing & Snowboarding", "Boxing Classics", "Sailing Regattas", "Highland Games", "Esports Tactics"],
            fallbackInterestsTR: ["Futbol Taktikleri", "Formula 1", "Basketbol Analizi", "Tenis", "MMA", "Bisiklet", "Olimpiyat Tarihi", "Satranç", "Maraton Koşusu", "Premier Lig", "NBA Tarihi", "Tüplü Dalış", "Kaya Tırmanışı", "Motor Sporları Mühendisliği", "Sörf Kültürü", "Jimnastik", "Atletizm", "Triatlon", "Masa Tenisi", "Ragbi Taktikleri", "Kayak ve Snowboard", "Boks Klasikleri", "Yelken Yarışları", "Dağcılık", "E-Spor Taktikleri"]
        ),
        InterestCategory(
            id: "tech",
            iconName: "cpu",
            emoji: "💻",
            nameEN: "Technology",
            nameTR: "Teknoloji",
            hue: 0.6,
            fallbackInterestsEN: ["AI & Machine Learning", "Cybersecurity", "Startups", "Blockchain", "UX Design", "Robotics", "Apple", "Open Source", "LLMs & Prompting", "Chip Architecture", "Web3", "Cloud Computing", "Spatial Computing", "Quantum Computing", "Compilers", "Rust Language", "Developer Tooling", "Autonomous Vehicles", "Computer Vision", "Distributed Systems", "Clean Code", "Linux Kernel", "Design Systems", "Edge AI", "Bioinformatics"],
            fallbackInterestsTR: ["Yapay Zekâ", "Siber Güvenlik", "Girişimcilik", "Blockchain", "UX Tasarım", "Robotik", "Apple", "Açık Kaynak", "Büyük Dil Modelleri", "Çip Mimarisi", "Web3", "Bulut Bilişim", "Uzamsal Hesaplama", "Kuantum Bilişim", "Derleyiciler", "Rust Dili", "Geliştirici Araçları", "Otonom Araçlar", "Bilgisayarlı Görü", "Dağıtık Sistemler", "Temiz Kod", "Linux Çekirdeği", "Tasarım Sistemleri", "Uç Cihaz Yapay Zekâsı", "Biyoinformatik"]
        ),
        InterestCategory(
            id: "nature",
            iconName: "leaf",
            emoji: "🌿",
            nameEN: "Nature",
            nameTR: "Doğa",
            hue: 0.38,
            fallbackInterestsEN: ["Deep Ocean", "Birdwatching", "Volcanoes", "Forests", "Animal Behavior", "Geology", "Weather Patterns", "National Parks", "Mycology", "Coral Reefs", "Arctic Wildlife", "Botany", "Bioluminescence", "Mountain Ecosystems", "Carnivorous Plants", "Whale Migration", "Desert Ecology", "Rainforest Canopies", "Insect Societies", "Glaciology", "Wetlands", "Nocturnal Animals", "Fossil Formations", "Mangrove Forests", "Symbiosis"],
            fallbackInterestsTR: ["Derin Okyanus", "Kuş Gözlemi", "Yanardağlar", "Ormanlar", "Hayvan Davranışı", "Jeoloji", "Hava Olayları", "Milli Parklar", "Mantar Bilimi", "Mercan Resifleri", "Kutup Doğası", "Botanik", "Biyolüminesans", "Dağ Ekosistemleri", "Etobur Bitkiler", "Balina Göçleri", "Çöl Ekolojisi", "Yağmur Ormanı Tepeleri", "Böcek Kolonileri", "Buzul Bilimi", "Sulak Alanlar", "Gece Hayvanları", "Fosil Oluşumları", "Mangrov Ormanları", "Simbiyoz"]
        ),
        InterestCategory(
            id: "art",
            iconName: "paintpalette",
            emoji: "🎨",
            nameEN: "Art",
            nameTR: "Sanat",
            hue: 0.75,
            fallbackInterestsEN: ["Renaissance Art", "Street Art", "Photography", "Architecture", "Sculpture", "Digital Art", "Art Deco", "Impressionism", "Bauhaus", "Minimalism", "Graphic Design", "Typography", "Japanese Woodblock", "Surrealism", "Contemporary Ceramics", "Calligraphy", "Brutalism", "Oil Painting", "Stained Glass", "Kinetic Sculpture", "Conceptual Art", "Abstract Expressionism", "Curatorship", "Textile Arts", "Color Theory"],
            fallbackInterestsTR: ["Rönesans Sanatı", "Sokak Sanatı", "Fotoğrafçılık", "Mimari", "Heykel", "Dijital Sanat", "Art Deco", "Empresyonizm", "Bauhaus", "Minimalizm", "Grafik Tasarım", "Tipografi", "Japon Ahşap Baskı", "Sürrealizm", "Çağdaş Seramik", "Kaligrafi", "Brütalizm", "Yağlıboya Resim", "Vitray Sanatı", "Kinetik Heykel", "Kavramsal Sanat", "Soyut Dışavurumculuk", "Küratörlük", "Tekstil Sanatları", "Renk Teorisi"]
        ),
        InterestCategory(
            id: "philosophy",
            iconName: "brain.head.profile",
            emoji: "🧠",
            nameEN: "Philosophy",
            nameTR: "Felsefe",
            hue: 0.82,
            fallbackInterestsEN: ["Stoicism", "Existentialism", "Ethics", "Eastern Philosophy", "Logic", "Philosophy of Mind", "Nietzsche", "Political Philosophy", "Epistemology", "Absurdism", "Marcus Aurelius", "Kantian Ethics", "Phenomenology", "Philosophy of Language", "Daoism", "Utilitarianism", "Socrates & Plato", "Schopenhauer", "Philosophy of Science", "Free Will", "Aesthetics", "Zen Buddhism", "Postmodernism", "Ancient Skepticism", "Virtue Ethics"],
            fallbackInterestsTR: ["Stoacılık", "Varoluşçuluk", "Etik", "Doğu Felsefesi", "Mantık", "Zihin Felsefesi", "Nietzsche", "Siyaset Felsefesi", "Epistemoloji", "Absürdizm", "Marcus Aurelius", "Kant Etiği", "Fenomenoloji", "Dil Felsefesi", "Taoizm", "Faydacılık", "Sokrates ve Platon", "Schopenhauer", "Bilim Felsefesi", "Özgür İrade", "Estetik", "Zen Budizmi", "Postmodernizm", "Antik Şüphecilik", "Erdem Etiği"]
        ),
        InterestCategory(
            id: "travel",
            iconName: "globe.americas",
            emoji: "✈️",
            nameEN: "Travel",
            nameTR: "Seyahat",
            hue: 0.48,
            fallbackInterestsEN: ["Japan Travel", "Hidden European Gems", "Solo Backpacking", "Cultural Festivals", "Island Hopping", "Road Trips", "Arctic Adventures", "Southeast Asia", "Nordic Fjords", "Train Journeys", "Eco-Tourism", "Patagonia", "Silk Road Cities", "Greek Islands", "Sahara Trekking", "Alpine Hiking", "Kyoto Temples", "New Zealand Trails", "Moroccan Medinas", "Scottish Highlands", "Balkan Road Trips", "Iceland Ring Road", "Trans-Siberian Railway", "Amazon River", "Peruvian Andes"],
            fallbackInterestsTR: ["Japonya Seyahati", "Avrupa'nın Gizli Köşeleri", "Solo Sırt Çantası", "Kültürel Festivaller", "Ada Turu", "Karayolu Gezileri", "Arktik Macera", "Güneydoğu Asya", "İskandinav Fiyortları", "Tren Yolculukları", "Eko-Turizm", "Patagonya", "İpek Yolu Şehirleri", "Yunan Adaları", "Sahra Yürüyüşü", "Alp Patikaları", "Kyoto Tapınakları", "Yeni Zelanda Rotaları", "Fas Medinaları", "İskoç Yaylaları", "Balkan Gezileri", "İzlanda Ring Yolu", "Trans-Sibirya Demiryolu", "Amazon Nehri", "Peru Andları"]
        ),
        InterestCategory(
            id: "gaming",
            iconName: "gamecontroller",
            emoji: "🎮",
            nameEN: "Gaming",
            nameTR: "Oyun",
            hue: 0.7,
            fallbackInterestsEN: ["Indie Games", "Game Design", "Retro Gaming", "RPGs", "Esports", "Nintendo", "Game Lore", "Board Games", "Zelda Series", "Speedrunning", "Dark Souls", "Pixel Art Games", "Roguelikes", "Metroidvanias", "Immersive Sims", "Game Audio Design", "Fighting Games", "Stealth Games", "Visual Novels", "Chrono Trigger", "Hidetaka Miyazaki", "Level Design", "Survival Horror", "Point-and-Click", "Deus Ex"],
            fallbackInterestsTR: ["Indie Oyunlar", "Oyun Tasarımı", "Retro Oyunlar", "RPG'ler", "E-Spor", "Nintendo", "Oyun Hikayeleri", "Masa Oyunları", "Zelda Serisi", "Speedrunning", "Dark Souls", "Piksel Sanatı Oyunlar", "Roguelike Oyunlar", "Metroidvania", "Immersive Sim", "Oyun Ses Tasarımı", "Dövüş Oyunları", "Gizlilik Oyunları", "Görsel Romanlar", "Chrono Trigger", "Hidetaka Miyazaki", "Bölüm Tasarımı", "Hayatta Kalma Korku", "Point-and-Click", "Deus Ex"]
        ),
    ]
}
