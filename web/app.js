/**
 * OMAKASE — OFFICIAL WEB APPLICATION LOGIC
 * Features:
 * - Dark/Light Mode Sync (Paper & OLED Black)
 * - Dual Language (TR / EN)
 * - Interactive iPhone 16 Pro 3-Screen Showcase (Feed, 12-Category Bento, Community)
 * - 12-Category Bento Simulator with Subtopic Pills, SSE Typewriter & Top 3px Cooldown Bar
 * - Deep Dive Sheet Reader, FAQ Accordion, and Inline Waitlist Feedback
 */

document.addEventListener('DOMContentLoaded', () => {
  // ==========================================================================
  // 1. LOCALIZATION DICTIONARY (TR & EN)
  // ==========================================================================
  const translations = {
    tr: {
      "nav.demo": "Canlı Tadım",
      "nav.features": "Mimari",
      "nav.philosophy": "Felsefe",
      "nav.faq": "SSS",
      "nav.getApp": "İndir",

      "hero.badge": "iOS 17+ • Kişisel Kültür & Bilgi Akışı",
      "hero.title": "Algoritmaların gürültüsünden uzak, zihinsel damak tadınıza özel akış.",
      "hero.subtitle": "12 kültür kategorisini, dinamik alt konuları ve kendi merakınızı gerçek zamanlı, doğrulanmış mikro-hikayelere dönüştüren kişisel bilgi şefiniz.",
      "hero.appStoreLabel": "App Store",
      "hero.downloadCta": "iOS için İndir",
      "hero.tryDemo": "Canlı Tadımı Dene ↓",
      "hero.meta1": "12 Kültür Kategorisi",
      "hero.meta2": "18 sn Sindirme Koruması",
      "hero.meta3": "Seçkin Topluluk Akışı",

      "device.tabFeed": "Akış",
      "device.tabBento": "Kategoriler",
      "device.tabCommunity": "Topluluk",
      "device.feedDate": "Bugün • 09:41",
      "device.feedTitle": "Tadao Ando ve Işığın Betondaki Tapınağı",
      "device.feedBody": "Osaka'daki Işık Kilisesi'nde Tadao Ando, haçı altın ya da mermerle değil; çıplak beton duvara açtığı yarıklardan içeri sızan gün ışığıyla inşa etti. Güneş hareket ettikçe kilisenin içindeki ışık kesişimi yer değiştirir. Ando için mimarlık bir form değil, doğanın mekana bıraktığı gölgedir.",
      "device.swipeForBento": "Yeni konu seçmek için kaydır",
      "device.catCount": "Kategori",
      "device.bentoHeading": "Kategoriler",
      "device.bentoSub": "Bir kategori seç ve alt konuya dokunarak yeni post üret",
      "device.inputPlaceholder": "Kendi konunu yaz veya ilgi ekle…",
      "device.communitySearch": "Kişi (@kullanıcı) veya gönderi ara…",
      "device.shared1Title": "Miles Davis ve Kind of Blue'nun Modal Sessizliği",
      "device.shared1Body": "1959 ilkbaharında Miles Davis, stüdyoya giren Bill Evans ve John Coltrane'e geleneksel akor şemaları yerine sadece birkaç mod notasından ibaret kağıtlar verdi…",
      "device.shared2Title": "Kuantum Eşevresizliği ve Gözlemci",

      "demo.tag": "İnteraktif Deneyim",
      "demo.title": "Canlı Şef Tadımı",
      "demo.desc": "12 kültür kategorisinden birini seçin, alt konulara göz atın ve şefin sizin için anlık mikro-hikaye hazırlamasını deneyimleyin.",
      "demo.bentoTitle": "Bento Keşif Izgarası",
      "demo.bentoSub": "12 ana kategoriden birine dokunun:",
      "demo.subtopicsLabel": "Alt Konular",
      "demo.spin": "Rastgele",
      "demo.startStream": "Şeften Yeni Tadım İste",
      "demo.cooldownReady": "Sindirme koruması hazır",

      "cat.film": "Film",
      "cat.science": "Bilim",
      "cat.philosophy": "Felsefe",
      "cat.music": "Müzik",
      "cat.art": "Sanat",
      "cat.history": "Tarih",
      "cat.tech": "Teknoloji",
      "cat.food": "Yemek",
      "cat.nature": "Doğa",
      "cat.travel": "Seyahat",
      "cat.sports": "Spor",
      "cat.gaming": "Oyun",

      "action.reread": "Yeniden",
      "action.share": "Paylaş",
      "action.save": "Kaydet",
      "action.deepdive": "Derinlemesine İncele",

      "features.tag": "Sistem Mimarisi",
      "features.title": "Düşünceyi Besleyen Sade Bir Deneyim",
      "features.desc": "Dikkati parçalayan sonsuz kaydırma döngülerine karşı, bilinçli keşfi ve zihinsel dinginliği önceleyen dört temel yapı taşı.",
      "features.f1Title": "Tam Ekran Bento Keşif Izgarası",
      "features.f1Desc": "Film, Bilim, Felsefe, Sanat, Tarih ve Teknoloji dahil 12 ana kültür kategorisi. Bir kategoriye dokunduğunuzda dinamik alt konular açılır; dilerseniz kendi merak ettiğiniz özel bir başlığı yazıp anında şef yazısı üretebilirsiniz.",
      "features.f2Title": "Okuma Süresi & Doyum Koruması",
      "features.f2Desc": "Metin uzunluğuna göre 15 ile 25 saniye arasında akıllı sindirme süresi uygular. Üst bar boyunca ilerleyen ince sayaç tamamlanana kadar yeni üretime ara verilir; refleksif kaydırma yerine gerçek okuma teşvik edilir.",
      "features.f3Title": "Canlı Akış & Derinlemesine İnceleme",
      "features.f3Desc": "Tam ekran dikey sayfalama yapısında kelimeler gerçek zamanlı olarak ekrana akar. İlginizi çeken bir anekdotun perde arkasını merak ettiğinizde tek dokunuşla kapsamlı inceleme katmanını açabilirsiniz.",
      "features.f4Title": "Seçkin Topluluk & Ortak Hafıza",
      "features.f4Desc": "Kendinize özel @kullanıcı_adı kimliğinizle sizi etkileyen hikayeleri topluluk akışında paylaşın. Kişi ve gönderi aramasıyla zevklerinize yakın okurları takip edin, tepkiler ve yorumlarla sohbete katılın.",

      "phil.tag": "Felsefemiz",
      "phil.title": "Şefe Güvenmek",
      "phil.desc": "Japon mutfak kültüründe 'Omakase', seçimi şefe bırakmak ve onun ustalığına güvenmek demektir. Bu yaklaşımı dijital bilgi tüketimine taşıdık.",
      "phil.badTitle": "Algoritmik Sonsuz Akış",
      "phil.bad1": "Sonsuz ve doyumsuz kaydırma döngüsü (doomscrolling)",
      "phil.bad2": "Öfke ve anlık tıklama odaklı yüzeysel başlıklar",
      "phil.bad3": "Reklamlar, sponsorlu gürültü ve görsel karmaşa",
      "phil.bad4": "Uygulamadan çıkınca hissedilen zihinsel yorgunluk",
      "phil.goodTitle": "Omakase Yaklaşımı",
      "phil.good1": "Metni sindirten 15–25 saniyelik akıllı okuma temposu",
      "phil.good2": "12 kültür alanında doğrulanmış, zamansız mikro-hikayeler",
      "phil.good3": "Sıfır reklam, mürekkep ve kağıt sadeliğinde monokrom arayüz",
      "phil.good4": "Okuma sonrası kalıcı merak ve zihinsel berraklık",

      "faq.tag": "Merak Edilenler",
      "faq.title": "Sıkça Sorulan Sorular",
      "faq.q1": "Omakase nasıl çalışır?",
      "faq.a1": "Omakase, 12 ana kültür kategorisinden seçtiğiniz alt konuları veya kendi yazdığınız özel başlıkları Google Cloud Run ve Gemini 3.5 Flash modelleriyle gerçek zamanlı olarak doğrulanmış, derinlikli mikro-hikayelere dönüştüren yerel bir iOS uygulamasıdır.",
      "faq.q2": "Okuma süresi sayacı (Reading Cooldown) neden var?",
      "faq.a2": "Sosyal medya akışları metinleri okumadan saniyede bir kaydırma alışkanlığı yaratır. Omakase, metin uzunluğuna göre 15–25 saniye sindirme süresi uygulayarak içeriği gerçekten okuyup hazmetmenizi sağlar.",
      "faq.q3": "İçeriklerin doğruluğu nasıl korunuyor?",
      "faq.a3": "Arka uç mimarimiz, katı doğruluk kuralları ve çift katmanlı moderasyon filtreleriyle kurgusal uydurmaları engeller; yüzeysel özetler yerine belgelenmiş tarihsel kayıtlara, bilimsel çalışmalara ve birincil kaynaklara odaklanır.",
      "faq.q4": "Topluluk sekmesinde neler yapabilirim?",
      "faq.a4": "Kişisel akışınızda beğendiğiniz bir şef yazısını tek dokunuşla kendi @kullanıcı_adı profiliniz üzerinden toplulukla paylaşabilir, diğer okurları arayıp takip edebilir, gönderilere ifade bırakabilir ve yorumlarda tartışabilirsiniz.",

      "cta.title": "Zihinsel Damak Tadınızı Besleyin",
      "cta.desc": "Omakase iOS için yayında. Günlük merak ritüelinize başlamak için hemen indirin veya TestFlight erken erişim listesine katılın.",
      "cta.joinBtn": "TestFlight'a Katıl",

      "footer.contact": "İletişim",
      "footer.copy": "© 2026 Omakase. Mürekkep ve kağıt sadeliğiyle iOS için tasarlandı."
    },

    en: {
      "nav.demo": "Live Tasting",
      "nav.features": "Architecture",
      "nav.philosophy": "Philosophy",
      "nav.faq": "FAQ",
      "nav.getApp": "Get App",

      "hero.badge": "iOS 17+ • Personal Culture & Knowledge Feed",
      "hero.title": "Beyond algorithmic noise. A feed tuned to your mental palate.",
      "hero.subtitle": "Your personal knowledge chef transforming 12 cultural categories, dynamic subtopics, and your own curiosities into verified, real-time micro-stories.",
      "hero.appStoreLabel": "App Store",
      "hero.downloadCta": "Download for iOS",
      "hero.tryDemo": "Try Live Tasting ↓",
      "hero.meta1": "12 Cultural Categories",
      "hero.meta2": "18s Satiation Cooldown",
      "hero.meta3": "Curated Community Feed",

      "device.tabFeed": "Feed",
      "device.tabBento": "Categories",
      "device.tabCommunity": "Community",
      "device.feedDate": "Today • 09:41",
      "device.feedTitle": "Tadao Ando and the Sanctuary of Concrete Light",
      "device.feedBody": "At the Church of the Light in Osaka, Tadao Ando constructed the central cross not from gilded marble, but from cruciform slits cut into raw concrete. As the sun moves across the sky, the intersection of light glides across the dark interior. For Ando, architecture is the canvas that makes light tangible.",
      "device.swipeForBento": "Swipe down to pick a new topic",
      "device.catCount": "Categories",
      "device.bentoHeading": "Categories",
      "device.bentoSub": "Select a category and tap a subtopic to craft a new post",
      "device.inputPlaceholder": "Type a custom topic or add taste…",
      "device.communitySearch": "Search people (@username) or posts…",
      "device.shared1Title": "Miles Davis and the Modal Silence of Kind of Blue",
      "device.shared1Body": "In the spring of 1959, Miles Davis handed Bill Evans and John Coltrane scraps of paper containing modal scales rather than traditional chord changes…",
      "device.shared2Title": "Quantum Decoherence and the Observer",

      "demo.tag": "Interactive Experience",
      "demo.title": "Live Chef Tasting",
      "demo.desc": "Pick one of the 12 cultural categories, explore subtopics, and watch the chef craft an instant micro-story in your browser.",
      "demo.bentoTitle": "Bento Taste Box",
      "demo.bentoSub": "Tap one of the 12 core categories:",
      "demo.subtopicsLabel": "Subtopics",
      "demo.spin": "Randomize",
      "demo.startStream": "Request New Tasting",
      "demo.cooldownReady": "Reading cooldown ready",

      "cat.film": "Film",
      "cat.science": "Science",
      "cat.philosophy": "Philosophy",
      "cat.music": "Music",
      "cat.art": "Art",
      "cat.history": "History",
      "cat.tech": "Tech",
      "cat.food": "Food",
      "cat.nature": "Nature",
      "cat.travel": "Travel",
      "cat.sports": "Sports",
      "cat.gaming": "Gaming",

      "action.reread": "Re-read",
      "action.share": "Share",
      "action.save": "Save",
      "action.deepdive": "Deep Dive",

      "features.tag": "System Architecture",
      "features.title": "A Calm Experience Built for Thought",
      "features.desc": "Four foundational pillars designed to counter attention-fragmenting feeds with deliberate discovery and mental stillness.",
      "features.f1Title": "Full-Screen Bento Discovery Grid",
      "features.f1Desc": "Explore 12 core categories across Film, Science, Philosophy, Art, History, and Technology. Tap any category to reveal dynamic subtopics, or type your own custom prompt to craft a dedicated story.",
      "features.f2Title": "Reading Cooldown & Satiation Defense",
      "features.f2Desc": "Applies a 15 to 25 second smart digestion window scaled to text length. A subtle top progress bar pauses new generation until finished—rewarding comprehension over reflexive swiping.",
      "features.f3Title": "Live Stream & Deep Dive Reader",
      "features.f3Desc": "Words stream onto a distraction-free vertical canvas in real time. Whenever an anecdote sparks deeper curiosity, one tap opens a comprehensive follow-up exploration sheet.",
      "features.f4Title": "Curated Community & Shared Memory",
      "features.f4Desc": "Share standout insights to the community feed with your unique @username handle. Search for like-minded readers and posts, leave quick reactions, and join thoughtful discussions.",

      "phil.tag": "Our Philosophy",
      "phil.title": "Trust the Chef",
      "phil.desc": "In Japanese culinary tradition, 'Omakase' means entrusting the selection to the chef's craft. We brought this principle to digital knowledge.",
      "phil.badTitle": "Algorithmic Endless Stream",
      "phil.bad1": "Addictive, insatiable scrolling loops (doomscrolling)",
      "phil.bad2": "Outrage-driven, engagement-baiting headlines",
      "phil.bad3": "Ads, sponsored clutter, and visual noise",
      "phil.bad4": "Mental fatigue and emptiness after closing the app",
      "phil.goodTitle": "The Omakase Approach",
      "phil.good1": "Mindful 15–25s reading cadence that respects comprehension",
      "phil.good2": "Verified, timeless micro-stories across 12 cultural domains",
      "phil.good3": "Zero ads, pure monochrome ink-on-paper serenity",
      "phil.good4": "Lasting curiosity and mental clarity after every session",

      "faq.tag": "Curiosities",
      "faq.title": "Frequently Asked Questions",
      "faq.q1": "How does Omakase work?",
      "faq.a1": "Omakase is a native iOS app that transforms your chosen subtopics across 12 cultural categories—or any custom topic you type—into verified, real-time micro-stories powered by Google Cloud Run and Gemini 3.5 Flash.",
      "faq.q2": "Why is there a reading cooldown timer?",
      "faq.a2": "Conventional social feeds condition users to swipe in fractions of a second without absorbing anything. Omakase enforces a 15–25 second digestion window so every story is genuinely read.",
      "faq.q3": "How is factual accuracy maintained?",
      "faq.a3": "Our backend uses strict factual grounding rules and a dual-layer moderation pipeline to prevent fabrication, prioritizing documented historical records, peer-reviewed research, and primary sources.",
      "faq.q4": "What can I do in the Community tab?",
      "faq.a4": "You can share favorite stories from your personal feed under your @username profile, search for people and posts, react with quick emojis, and discuss insights in the comments.",

      "cta.title": "Nourish Your Mental Palate",
      "cta.desc": "Omakase is live on iOS. Download now or join the TestFlight early access list to begin your daily ritual of curiosity.",
      "cta.joinBtn": "Join TestFlight",

      "footer.contact": "Contact",
      "footer.copy": "© 2026 Omakase. Crafted for iOS with ink-and-paper simplicity."
    }
  };

  // ==========================================================================
  // 2. 12-CATEGORY SIMULATOR DATABASE (TR & EN)
  // ==========================================================================
  const stories = {
    film: {
      tr: {
        subtopics: ["Christopher Nolan", "Yeni Dalga Sineması", "A24", "Stanley Kubrick"],
        title: "Oppenheimer ve IMAX 70mm'nin Görsel Ağırlığı",
        date: "Bugün • 20:17",
        body: "Christopher Nolan, Oppenheimer'ı çekerken 65mm IMAX siyah-beyaz filmi dünyada ilk kez Kodak'a özel olarak ürettirdi. Standart IMAX projektörleri bu 18 kilometrelik, 272 kiloluk devasa makarayı çevirirken platoda duyulan mekanik ses, sahnenin kendisinden bile daha hipnotize ediciydi. Nolan'a göre bu bir nostalji değil; izleyicinin göz bebeklerine kadar uzanan somut bir gerçeklik arayışıydı.",
        tags: ["Film", "ChristopherNolan", "Imax70Mm"],
        deepDiveTitle: "Derinlemesine İnceleme: Kodak 65mm Siyah-Beyaz Emülsiyonu",
        deepDiveBody: "IMAX formatında daha önce hiç 65mm siyah-beyaz film şeridi üretilmemişti. Kodak mühendisleri Nolan ve görüntü yönetmeni Hoyte van Hoytema'nın talebiyle fotokimyasal gren yapısını sıfırdan tasarladı. Film şeridinin kalınlığı standart filmlere göre daha farklıydı; kameraların vakumlu mekanizmaları bu şeridi taşırken yeniden kalibre edildi. Ortaya çıkan görüntü, dijital sensörlerin ulaşamayacağı organik bir ışık derinliği sundu."
      },
      en: {
        subtopics: ["Christopher Nolan", "French New Wave", "A24", "Stanley Kubrick"],
        title: "Oppenheimer and the Physical Gravity of IMAX 70mm",
        date: "Today • 8:17 PM",
        body: "Christopher Nolan commissioned Kodak to engineer 65mm IMAX black-and-white film for the very first time in cinema history. As the projector spooled the 11-mile, 600-pound platter, the mechanical whirr on set was as hypnotic as the imagery. For Nolan, this was not mere nostalgia; it was an uncompromising quest for tangible optical presence.",
        tags: ["Film", "ChristopherNolan", "Imax70Mm"],
        deepDiveTitle: "Deep Dive: Kodak's 65mm Monochrome Chemistry",
        deepDiveBody: "Before Oppenheimer, 65mm black-and-white film emulsion simply did not exist for IMAX cameras. Kodak photo-chemists formulated a high-contrast silver halide grain capable of withstanding the vacuum-pressure feed of IMAX transport mechanisms, rendering micro-expressions with an analog density unattainable by digital sensors."
      }
    },

    science: {
      tr: {
        subtopics: ["Kuantum Fiziği", "Nörobilim", "James Webb Teleskobu", "CRISPR"],
        title: "Kuantum Eşevresizliği: Kedinin Gerçekten Yaşadığı An",
        date: "Bugün • 14:32",
        body: "Schrödinger'in kedisi paradoksunda asıl sır kutuyu açan insanda değil; kutunun içine sızan tek bir fotondadır. Kuantum eşevresizliği (decoherence), süperpozisyon durumunun çevreyle en ufak termodinamik temasta mikrosaniyeler içinde klasik gerçekliğe 'çöküşünü' açıklar. Yani evren, biz bakmasak dahi kendi kendini sürekli izlemektedir.",
        tags: ["Bilim", "KuantumFiziği", "Termodinamik"],
        deepDiveTitle: "Derinlemesine İnceleme: Çevre Kaynaklı Dalga Çökmesi",
        deepDiveBody: "Wojciech Zurek'in 'kuantum darwinizmi' kuramına göre, bir kuantum sisteminin çevresindeki fotonlar ve hava molekülleri sistemin bilgisini kopyalar. Yalnızca çevreye en dayanıklı klasik durumlar hayatta kalır; böylece süperpozisyon mistik bir gözlemciye ihtiyaç duymadan termodinamik bilgi yayılımıyla çözülür."
      },
      en: {
        subtopics: ["Quantum Physics", "Neuroscience", "James Webb Telescope", "CRISPR"],
        title: "Quantum Decoherence: When the Cat Actually Decides",
        date: "Today • 2:32 PM",
        body: "In Schrödinger's paradox, the secret lies not in human consciousness opening the box, but in a stray environmental photon. Quantum decoherence explains how superpositions leak phase information into surrounding particles within femtoseconds, collapsing fuzzy probabilities into crisp classical facts.",
        tags: ["Science", "QuantumPhysics", "Decoherence"],
        deepDiveTitle: "Deep Dive: Quantum Darwinism and Pointer States",
        deepDiveBody: "Pioneered by Wojciech Zurek, Quantum Darwinism suggests that the environment acts as a broadcast channel. Only the hardiest states resilient against ambient bombardment reproduce their signatures across the universe, creating objective reality without observer mysticism."
      }
    },

    philosophy: {
      tr: {
        subtopics: ["Stoacılık", "Varoluşçuluk", "Zihin Felsefesi", "Zen Budizmi"],
        title: "Seneca'nın Zaman Muhasebesi ve Hayatın Kısalığı",
        date: "Bugün • 09:15",
        body: "Roma'nın en etkili düşünürlerinden Seneca, mülkünü birine kaptıranların çıkardığı yaygarayla günlerini başkalarına dağıtanların kayıtsızlığını kıyaslar. Hayat kısa değildir; biz onu fazlasıyla savurganca harcarız. Sahte meşguliyetler, insanın kendi zihniyle baş başa kalma korkusunun en zarif maskesidir.",
        tags: ["Felsefe", "Stoacılık", "Seneca"],
        deepDiveTitle: "Derinlemesine İnceleme: De Brevitate Vitae ve Otium Kavramı",
        deepDiveBody: "Seneca 'De Brevitate Vitae' (Hayatın Kısalığı Üzerine) risalesinde zamanı geri kazanılamaz tek varlık olarak tanımlar. Antik Roma'da 'otium' (bilinçli dinginlik), tembellik değil; geçmişin bilgeleriyle okuma ve tefekkür yoluyla kurulan zamansız dostluktur."
      },
      en: {
        subtopics: ["Stoicism", "Existentialism", "Philosophy of Mind", "Zen Buddhism"],
        title: "Seneca's Audit of Lost Hours",
        date: "Today • 9:15 AM",
        body: "Seneca observed that while people guard their physical estates with fierce vigilance, they distribute their hours with effortless nonchalance. Life is not short; we merely squander it on performative obligations, mistaking perpetual busyness for purposeful existence.",
        tags: ["Philosophy", "Stoicism", "Seneca"],
        deepDiveTitle: "Deep Dive: The Temporal Economics of De Brevitate Vitae",
        deepDiveBody: "In his treatise to Paulinus, Seneca argues that authentic leisure (otium) is not idle stagnation, but contemplative study alongside timeless thinkers—annexing centuries of wisdom into a single mortal lifespan."
      }
    },

    music: {
      tr: {
        subtopics: ["Caz", "Film Müzikleri", "Ambient", "Modüler Sentezleyiciler"],
        title: "Miles Davis ve Kind of Blue'nun Modal Sessizliği",
        date: "Bugün • 23:40",
        body: "1959 ilkbaharında Miles Davis, stüdyoya giren Bill Evans ve John Coltrane'in eline geleneksel akor şemaları yerine sadece birkaç mod notasından ibaret kağıtlar verdi. Müzisyenler parçaları ilk kez kayıt anında çaldılar. Albümü ölümsüz kılan şey, çalınan notalardan çok aralarda nefes alan bilinçli sessizliklerdi.",
        tags: ["Müzik", "MilesDavis", "KindOfBlue"],
        deepDiveTitle: "Derinlemesine İnceleme: George Russell ve Modal Caz Devrimi",
        deepDiveBody: "Kind of Blue, bebop akımının yoğun akor geçişlerinden radikal bir kopuştu. Miles, George Russell'ın Lydian Kromatik Konsepti'nden ilham alarak solistleri akor kafeslerinden kurtardı ve tek bir gam üzerinde melodik boşluklar bırakmaya davet etti."
      },
      en: {
        subtopics: ["Jazz", "Film Scores", "Ambient", "Modular Synthesizers"],
        title: "Miles Davis and the Radical Silence of Kind of Blue",
        date: "Today • 11:40 PM",
        body: "In the spring of 1959, Miles Davis handed Bill Evans and John Coltrane scraps of paper containing modal scales rather than chord progressions. There were no rehearsals. What cemented Kind of Blue into legend was not the density of notes played, but the deliberate chasms of air between them.",
        tags: ["Music", "MilesDavis", "ModalJazz"],
        deepDiveTitle: "Deep Dive: Escape from the Tyranny of Bebop Changes",
        deepDiveBody: "Influenced by George Russell's Lydian Chromatic Concept, Davis broke free from relentless chord changes. By lingering on a single Dorian mode for sixteen bars in 'So What', he invited soloists to craft spacious melodic poetry."
      }
    },

    art: {
      tr: {
        subtopics: ["Mimari", "Bauhaus", "Japon Ahşap Baskı", "Minimalizm"],
        title: "Tadao Ando ve Işığın Betondaki Tapınağı",
        date: "Bugün • 11:05",
        body: "Osaka'daki Işık Kilisesi'nde Tadao Ando, haçı altın ya da mermerle değil; çıplak beton duvara açtığı dikey ve yatay yarıklardan içeri sızan gün ışığıyla inşa etti. Güneş hareket ettikçe kilisenin içindeki ışık kesişimi yer değiştirir. Ando için mimarlık bir form değil, doğanın mekana bıraktığı gölgedir.",
        tags: ["Sanat", "TadaoAndo", "Mimari"],
        deepDiveTitle: "Derinlemesine İnceleme: Japon 'Ma' (Boşluk) Estetiği",
        deepDiveBody: "Ando'nun pürüzsüz ipek betonu, ahşap kalıpların özenle verniklenmesiyle elde edilir. Betonun soğuk endüstriyel dokusu, yarıktan sızan ışığın sıcaklığıyla dengelenir. Bu yaklaşım, Japon estetiğindeki 'Ma' (anlamlı boşluk) kavramının modern mimarideki en saf karşılığıdır."
      },
      en: {
        subtopics: ["Architecture", "Bauhaus", "Japanese Woodblock", "Minimalism"],
        title: "Tadao Ando and the Slits of Living Sunlight",
        date: "Today • 11:05 AM",
        body: "At the Church of the Light in Osaka, Tadao Ando constructed the central cross not from gilded timber, but from cruciform slits cut into raw concrete. As the sun traverses the sky, the light glides across the dark floor. For Ando, architecture is merely the vessel that makes light tangible.",
        tags: ["Art", "TadaoAndo", "Architecture"],
        deepDiveTitle: "Deep Dive: The Spatial Geometry of Japanese 'Ma'",
        deepDiveBody: "Ando's silk-smooth exposed concrete relies on lacquered timber formwork. By stripping away ornament, the sanctuary honors 'Ma'—the Japanese concept of negative interval—inviting quiet contemplation."
      }
    },

    history: {
      tr: {
        subtopics: ["Antik Roma", "İpek Yolu", "Rönesans", "Bilim Tarihi"],
        title: "Antikythera Düzeneği: İki Bin Yıllık Analog Bilgisayar",
        date: "Bugün • 16:40",
        body: "1901'de Ege Denizi'ndeki bir Roma batığından çıkarılan paslı bronz kütle, X-ışını tomografisiyle incelendiğinde içinden 30'dan fazla hassas dişli çark çıktı. MÖ 2. yüzyılda yapılan Antikythera düzeneği, güneş ve ay tutulmalarını on yıllar öncesinden hesaplayabilen avuç içi boyutunda bir astronomik bilgisayardı.",
        tags: ["Tarih", "AntikYunan", "Arkeoloji"],
        deepDiveTitle: "Derinlemesine İnceleme: Kayıp Helenistik Mühendislik",
        deepDiveBody: "Düzeneğin en çarpıcı parçası, Ay'ın eliptik yörüngesindeki hız değişimini simüle eden 'pim ve yuvalı' epikiklik dişli sistemidir. Bu seviyedeki diferansiyel dişli teknolojisi, Antikythera'dan sonra ancak 14. yüzyıl Avrupa mekanik saatlerinde yeniden ortaya çıkabilmiştir."
      },
      en: {
        subtopics: ["Ancient Rome", "Silk Road", "Renaissance", "History of Science"],
        title: "The Antikythera Mechanism: A Two-Millennia-Old Analog Computer",
        date: "Today • 4:40 PM",
        body: "Recovered from a Roman shipwreck in 1901, a corroded bronze lump revealed over 30 precision gearwheels under X-ray tomography. Built in the 2nd century BCE, the Antikythera mechanism was a shoebox-sized astronomical calculator capable of predicting eclipses decades in advance.",
        tags: ["History", "Hellenistic", "Archaeology"],
        deepDiveTitle: "Deep Dive: Pin-and-Slot Epicyclic Gearing",
        deepDiveBody: "Its most astonishing feature is a pin-and-slot gear train that models the Moon's variable orbital velocity (Kepler's second law approximation). Comparable mechanical complexity did not reappear in human history until 14th-century European astronomical clocks."
      }
    },

    tech: {
      tr: {
        subtopics: ["Yapay Zekâ", "Çip Mimarisi", "Tasarım Sistemleri", "Açık Kaynak"],
        title: "UNIX Felsefesi ve Tek Bir İşi Kusursuz Yapmak",
        date: "Bugün • 17:10",
        body: "1970'lerde Bell Laboratuvarları'nda Ken Thompson ve Dennis Ritchie, devasa ve karmaşık yazılımlar yerine birbirine borularla (pipe) bağlanabilen küçük, keskin araçlar tasarladı. Doug McIlroy'un özetlediği UNIX ilkesi bugün hâlâ modern yazılım mimarisinin kutup yıldızıdır: 'Her programı tek bir işi çok iyi yapacak şekilde yazın.'",
        tags: ["Teknoloji", "Unix", "YazılımMimarisi"],
        deepDiveTitle: "Derinlemesine İnceleme: Bell Labs ve Boru Hattı (Pipeline) Devrimi",
        deepDiveBody: "1973'te sisteme eklenen '|' (pipe) operatörü, bir programın metin çıktısını diğerinin girdisine dönüştürerek modülerliğin önünü açtı. Karmaşık problemler monolitik kod bloklarıyla değil, sade metin akışlarıyla konuşan bağımsız araçların birleşimiyle çözüldü."
      },
      en: {
        subtopics: ["AI & ML", "Chip Architecture", "Design Systems", "Open Source"],
        title: "The UNIX Philosophy and Doing One Thing Well",
        date: "Today • 5:10 PM",
        body: "At Bell Labs in the 1970s, Ken Thompson and Dennis Ritchie rejected monolithic complexity in favor of small, sharp tools connected by text streams. Summarized by Doug McIlroy, the UNIX maxim remains the north star of software craft: 'Write programs that do one thing and do it well.'",
        tags: ["Tech", "Unix", "SystemsDesign"],
        deepDiveTitle: "Deep Dive: Doug McIlroy and the Birth of Composable Pipes",
        deepDiveBody: "Introduced in 1973, the '|' pipe operator allowed the output of one small utility to become the input of another. This composability proved that simplicity at the interface layer unlocks exponential power across the system."
      }
    },

    food: {
      tr: {
        subtopics: ["Japon Mutfağı", "Fermentasyon", "Kahve Demleme", "Ekşi Maya"],
        title: "Edomae Sushi ve Kusursuz Pirincin (Shari) Dengesi",
        date: "Bugün • 19:05",
        body: "Tokyo'nun geleneksel omakase tezgahlarında bir şefin ustalığı balığın nadirliğiyle değil, 'shari' adı verilen sirkeli pirincin sıcaklığı ve dokusuyla ölçülür. Balık dilimi (neta) ile vücut sıcaklığındaki pirinç ağızda buluştuğunda, tanelerin arasında kalan mikroskobik hava boşlukları lezzetin dağılma hızını belirler.",
        tags: ["Yemek", "JaponMutfağı", "Gastronomi"],
        deepDiveTitle: "Derinlemesine İnceleme: Kızıl Sirke (Akazu) ve Edomae Geleneği",
        deepDiveBody: "19. yüzyıl Edo (Tokyo) döneminde buzdolabı yokken şefler, yıllandırılmış sake tortusundan üretilen kızıl sirkeyi (akazu) pirince katarak hem koruyuculuk hem de derin bir umami dengesi elde ettiler. Çırakların balığa dokunmadan önce yıllarca sadece pirinç yıkaması bu yüzdendir."
      },
      en: {
        subtopics: ["Japanese Cuisine", "Fermentation", "Coffee Brewing", "Sourdough"],
        title: "Edomae Sushi and the Quiet Mastery of Shari",
        date: "Today • 7:05 PM",
        body: "At traditional Tokyo omakase counters, a master is judged not by the rarity of the fish, but by the temperature and aeration of 'shari'—the seasoned rice. Pressed with just enough tension to hold pockets of air, body-temperature rice dissolves the moment it meets the palate.",
        tags: ["Food", "JapaneseCuisine", "CulinaryCraft"],
        deepDiveTitle: "Deep Dive: Aged Red Vinegar (Akazu) and Edo Preservation",
        deepDiveBody: "In 19th-century Edo, before refrigeration, chefs seasoned rice with akazu—red vinegar brewed from aged sake lees—imparting a warm amber hue and complex umami depth that balanced rich coastal fish."
      }
    },

    nature: {
      tr: {
        subtopics: ["Derin Okyanus", "Mantar Bilimi", "Biyolüminesans", "Orman Ekolojisi"],
        title: "Ormanın Yeraltı Ağı: Mikorizal İletişim",
        date: "Bugün • 13:20",
        body: "Bir ormanda yürürken gördüğünüz ağaçlar birbirinden bağımsız sütunlar değildir; toprak altında kilometrelerce uzanan mikorizal mantar iplikçikleriyle (hif) birbirine bağlıdır. Yaşlı 'anne ağaçlar', gölgede kalan genç fidelerin köklerine bu yeraltı ağından karbon, azot ve savunma sinyalleri gönderir.",
        tags: ["Doğa", "Ekoloji", "Mikoriza"],
        deepDiveTitle: "Derinlemesine İnceleme: Suzanne Simard ve Karbon Paylaşımı",
        deepDiveBody: "Orman ekologu Suzanne Simard, radyoaktif karbon izotopları kullanarak köknar ve huş ağaçlarının mevsimlere göre birbirine besin aktardığını kanıtladı. Yazın yapraklı huş ağacı gölgedeki köknara karbon gönderirken, kışın yaprak dökmeyen köknar borcunu geri öder."
      },
      en: {
        subtopics: ["Deep Ocean", "Mycology", "Bioluminescence", "Forest Ecology"],
        title: "The Subterranean Pulse: Mycorrhizal Forest Networks",
        date: "Today • 1:20 PM",
        body: "Trees in an old-growth forest are not solitary columns; beneath the soil, microscopic fungal threads weave roots into a vast cooperative lattice. Through this mycorrhizal network, towering mother trees shuttle carbon, nitrogen, and chemical warning signals to shaded seedlings.",
        tags: ["Nature", "Mycology", "ForestEcology"],
        deepDiveTitle: "Deep Dive: Suzanne Simard's Isotope Tracing Experiments",
        deepDiveBody: "Using carbon-14 isotopes, ecologist Suzanne Simard demonstrated reciprocal nutrient exchange between Douglas fir and paper birch trees—revealing that forests behave as self-regulating, interdependent superorganisms."
      }
    },

    travel: {
      tr: {
        subtopics: ["Kyoto Tapınakları", "Tren Yolculukları", "İskandinav Fiyortları", "Patagonya"],
        title: "Kyoto'da Saiho-ji: 120 Yosun Türünün Sessizliği",
        date: "Bugün • 10:15",
        body: "Kyoto'nun batısındaki Saiho-ji (Yosun Tapınağı) bahçesine girmeden önce ziyaretçiler sessizce fırça kaligrafisiyle sutralar kopyalar. Dışarı adım attığınızda sizi çiçekler değil, zemini zümrüt bir halı gibi kaplayan 120 farklı yosun türü karşılar. Yağmur sonrası yosunların emdiği ses, bahçeyi mutlak bir akustik sığınağa dönüştürür.",
        tags: ["Seyahat", "Kyoto", "JaponBahçesi"],
        deepDiveTitle: "Derinlemesine İnceleme: Muso Soseki ve Wabi-Sabi Peyzajı",
        deepDiveBody: "1339'da Zen ustası Muso Soseki tarafından yeniden düzenlenen bahçe, başlangıçta beyaz kumlarla kaplıydı. Yüzyıllar içinde Kyoto'nun nemli iklimi ve seller bahçeyi yosunlarla örttü; Japon estetiği bu doğa müdahalesini temizlemek yerine 'wabi-sabi' (zamanın bıraktığı kusurlu güzellik) olarak kutsadı."
      },
      en: {
        subtopics: ["Kyoto Temples", "Train Journeys", "Nordic Fjords", "Patagonia"],
        title: "Saiho-ji in Kyoto: The Acoustic Sanctuary of 120 Mosses",
        date: "Today • 10:15 AM",
        body: "Before stepping into the garden of Saiho-ji in western Kyoto, visitors sit in silence to trace calligraphy sutras by brush. Outside awaits not a floral display, but a velvet carpet of 120 distinct moss species that absorbs ambient sound into a hushed emerald stillness.",
        tags: ["Travel", "Kyoto", "ZenGarden"],
        deepDiveTitle: "Deep Dive: Muso Soseki and Unintended Wabi-Sabi",
        deepDiveBody: "Designed by Zen master Muso Soseki in 1339, the lower garden was originally raked white sand. Over centuries of flooding and humidity, wild moss overtook the grounds—an unplanned reclamation embraced as the pinnacle of wabi-sabi."
      }
    },

    sports: {
      tr: {
        subtopics: ["Futbol Taktikleri", "Formula 1", "Satranç", "Basketbol Analizi"],
        title: "Johan Cruyff ve Futbolda 'Mekan' Kavramının İcadı",
        date: "Bugün • 21:00",
        body: "Johan Cruyff için futbol topla oynanan fiziksel bir koşu yarışı değil, zamana ve mekana hükmetme geometrisiydi. 'Top sende değilken ne yaptığın, sahanın büyüklüğünü belirler' derdi. Hücum ederken sahayı olabildiğince genişletmek, top kaybedildiğinde ise saniyeler içinde daraltmak modern futbolun temel aksiyomu oldu.",
        tags: ["Spor", "FutbolTaktikleri", "JohanCruyff"],
        deepDiveTitle: "Derinlemesine İnceleme: Total Futbol ve Pozisyonel Oyun",
        deepDiveBody: "Rinus Michels ve Cruyff'un Ajax ile geliştirdiği Total Futbol, sabit mevki kavramını yıktı. Bir bek ileri çıktığında bir orta saha oyuncusu onun bıraktığı boşluğu dolduruyor; böylece takım şeklini kaybetmeden saha üzerindeki üçgenleri sürekli yeniden kuruyordu."
      },
      en: {
        subtopics: ["Football Tactics", "Formula 1", "Chess", "Basketball Analytics"],
        title: "Johan Cruyff and the Geometry of Pitch Space",
        date: "Today • 9:00 PM",
        body: "For Johan Cruyff, football was not a test of athletic sprinting, but a spatial puzzle of time and angles. 'When you have the ball, make the pitch as large as possible; when you lose it, make it as small as possible.' That single axiom reshaped modern tactical thought.",
        tags: ["Sports", "FootballTactics", "JohanCruyff"],
        deepDiveTitle: "Deep Dive: Total Football and Positional Play (Juego de Posición)",
        deepDiveBody: "Pioneered with Rinus Michels at Ajax, Total Football dissolved rigid player roles. Whenever a defender stepped into midfield, a teammate rotated seamlessly into the vacated zone, preserving passing triangles across every phase."
      }
    },

    gaming: {
      tr: {
        subtopics: ["Oyun Tasarımı", "Indie Oyunlar", "Hidetaka Miyazaki", "Bölüm Tasarımı"],
        title: "Shadow of the Colossus ve Eksiltmeyle Kurulan Dünya",
        date: "Bugün • 22:15",
        body: "Fumito Ueda, Shadow of the Colossus'u tasarlarken 'eksiltme yoluyla tasarım' (design by subtraction) adını verdiği bir yöntem uyguladı. Geleneksel oyunlardaki zindanları, küçük düşmanları ve kalabalık kasabaları tamamen sildi. Geriye sadece rüzgarlı uçsuz bucaksız bir yasak toprak, atınız ve 16 devasa varlıkla yüzleşmenin melankolisi kaldı.",
        tags: ["Oyun", "OyunTasarımı", "FumitoUeda"],
        deepDiveTitle: "Derinlemesine İnceleme: Eksiltme Yoluyla Tasarım (Design by Subtraction)",
        deepDiveBody: "Ueda'ya göre bir oyunun duygusal ağırlığı ekrana eklenen sistemlerle değil, ana temayla ilgisi olmayan her şeyin çıkarılmasıyla artar. Boş arazide dakikalarca sadece rüzgar ve nal sesi dinleyerek yolculuk etmek, karşılaşma anının dramatik etkisini katbekat büyütür."
      },
      en: {
        subtopics: ["Game Design", "Indie Games", "Hidetaka Miyazaki", "Level Design"],
        title: "Shadow of the Colossus and Design by Subtraction",
        date: "Today • 10:15 PM",
        body: "Director Fumito Ueda built Shadow of the Colossus around a discipline he called 'design by subtraction.' He stripped away dungeons, minor enemies, and towns—leaving only wind-swept forbidden plains, your horse, and the solemn weight of sixteen towering encounters.",
        tags: ["Gaming", "GameDesign", "FumitoUeda"],
        deepDiveTitle: "Deep Dive: Emotional Resonance Through Negative Space",
        deepDiveBody: "By removing conventional video game filler, the long silent rides across empty canyons become part of the narrative rhythm—making the scale and moral ambiguity of each colossus unforgettable."
      }
    }
  };

  // ==========================================================================
  // 3. STATE MANAGEMENT
  // ==========================================================================
  let currentLang = localStorage.getItem('omakase_lang') || 'tr';
  let currentTheme = localStorage.getItem('omakase_theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  let currentTopic = 'film';
  let activeSubtopicIndex = 0;
  let isStreaming = false;
  let streamInterval = null;
  let cooldownTimer = null;

  // DOM Elements
  const htmlEl = document.documentElement;
  const langToggleBtn = document.getElementById('lang-toggle-btn');
  const currentLangText = document.getElementById('current-lang-text');
  const themeToggleBtn = document.getElementById('theme-toggle-btn');
  const sunIcon = themeToggleBtn.querySelector('.sun-icon');
  const moonIcon = themeToggleBtn.querySelector('.moon-icon');
  const themeMeta = document.getElementById('theme-color-meta');

  // Mobile drawer
  const mobileToggleBtn = document.getElementById('mobile-toggle-btn');
  const mobileDrawer = document.getElementById('mobile-drawer');

  // Simulator elements
  const tastesGrid = document.getElementById('tastes-grid');
  const subtopicsList = document.getElementById('sim-subtopics-list');
  const btnSpin = document.getElementById('btn-spin-tastes');
  const btnStreamStart = document.getElementById('btn-stream-start');
  const simPostTitle = document.getElementById('sim-post-title');
  const simPostDate = document.getElementById('sim-post-date');
  const simPostBody = document.getElementById('sim-post-body');
  const simCursor = document.getElementById('sim-cursor');
  const simLiveBadge = document.getElementById('sim-live-badge');
  const simLiveText = document.getElementById('sim-live-text');
  const simPostTags = document.getElementById('sim-post-tags');
  const cooldownText = document.getElementById('cooldown-text');
  const cooldownBar = document.getElementById('cooldown-bar');
  const btnReread = document.getElementById('btn-reread');
  const btnShareDemo = document.getElementById('btn-share-demo');
  const btnBookmarkDemo = document.getElementById('btn-bookmark-demo');
  const btnOpenDeepDive = document.getElementById('btn-open-deep-dive');

  // Modal elements
  const deepDiveModal = document.getElementById('deep-dive-modal');
  const modalTitle = document.getElementById('modal-title');
  const modalBody = document.getElementById('modal-body');
  const btnCloseModal = document.getElementById('btn-close-modal');

  // ==========================================================================
  // 4. THEME CONTROLLER
  // ==========================================================================
  function applyTheme(theme) {
    currentTheme = theme;
    htmlEl.setAttribute('data-theme', theme);
    localStorage.setItem('omakase_theme', theme);

    if (theme === 'dark') {
      sunIcon.style.display = 'block';
      moonIcon.style.display = 'none';
      themeMeta.setAttribute('content', '#000000');
    } else {
      sunIcon.style.display = 'none';
      moonIcon.style.display = 'block';
      themeMeta.setAttribute('content', '#FAFAFA');
    }
  }

  themeToggleBtn.addEventListener('click', () => {
    const nextTheme = currentTheme === 'dark' ? 'light' : 'dark';
    applyTheme(nextTheme);
  });

  // ==========================================================================
  // 5. HERO IPHONE SCREEN SWITCHER (FEED / BENTO / COMMUNITY)
  // ==========================================================================
  function switchHeroDeviceScreen(screenKey) {
    document.querySelectorAll('.device-tab-pill').forEach(pill => {
      const active = pill.getAttribute('data-screen') === screenKey;
      pill.classList.toggle('active', active);
      pill.setAttribute('aria-selected', active ? 'true' : 'false');
    });

    document.querySelectorAll('.ios-tab-item').forEach(tab => {
      tab.classList.toggle('active', tab.getAttribute('data-switch-screen') === screenKey);
    });

    document.querySelectorAll('.ios-view').forEach(view => {
      view.classList.toggle('active', view.id === `ios-view-${screenKey}`);
    });
  }

  document.querySelectorAll('[data-screen]').forEach(btn => {
    btn.addEventListener('click', () => {
      switchHeroDeviceScreen(btn.getAttribute('data-screen'));
    });
  });

  document.querySelectorAll('[data-switch-screen]').forEach(btn => {
    btn.addEventListener('click', () => {
      switchHeroDeviceScreen(btn.getAttribute('data-switch-screen'));
    });
  });

  // ==========================================================================
  // 6. LANGUAGE CONTROLLER
  // ==========================================================================
  function applyLanguage(lang) {
    currentLang = lang;
    htmlEl.setAttribute('lang', lang);
    localStorage.setItem('omakase_lang', lang);
    currentLangText.textContent = lang.toUpperCase();

    const elements = document.querySelectorAll('[data-i18n]');
    elements.forEach(el => {
      const key = el.getAttribute('data-i18n');
      if (translations[lang] && translations[lang][key]) {
        el.textContent = translations[lang][key];
      }
    });

    const emailInput = document.getElementById('waitlist-email');
    if (emailInput) {
      emailInput.placeholder = lang === 'tr' ? 'E-posta adresiniz...' : 'Your email address...';
    }

    renderSubtopicsPills();
    renderSimulatorPost(currentTopic, false);
  }

  langToggleBtn.addEventListener('click', () => {
    const nextLang = currentLang === 'tr' ? 'en' : 'tr';
    applyLanguage(nextLang);
  });

  // ==========================================================================
  // 7. SIMULATOR LOGIC & TYPEWRITER SSE STREAM
  // ==========================================================================
  function getActiveStoryData() {
    const story = stories[currentTopic] || stories.film;
    return story[currentLang] || story.tr;
  }

  function renderSubtopicsPills() {
    if (!subtopicsList) return;
    const data = getActiveStoryData();
    subtopicsList.innerHTML = '';

    (data.subtopics || []).forEach((sub, idx) => {
      const btn = document.createElement('button');
      btn.className = 'subtopic-pill' + (idx === activeSubtopicIndex ? ' active' : '');
      btn.textContent = sub;
      btn.addEventListener('click', () => {
        if (isStreaming) return;
        activeSubtopicIndex = idx;
        renderSubtopicsPills();
        renderSimulatorPost(currentTopic, true);
      });
      subtopicsList.appendChild(btn);
    });
  }

  function renderSimulatorPost(topicKey, animate = false) {
    const data = getActiveStoryData();

    simPostTitle.textContent = data.title;
    simPostDate.textContent = data.date;

    simPostTags.innerHTML = '';
    data.tags.forEach(tag => {
      const span = document.createElement('span');
      span.className = 'tag-badge';
      span.textContent = tag.startsWith('#') ? tag : `#${tag}`;
      simPostTags.appendChild(span);
    });

    modalTitle.textContent = data.deepDiveTitle;
    modalBody.textContent = data.deepDiveBody;

    if (!animate) {
      simPostBody.textContent = data.body;
      simCursor.style.display = 'none';
      simLiveBadge.style.display = 'inline-flex';
      simLiveText.textContent = currentLang === 'tr' ? 'HAZIR' : 'READY';
      btnStreamStart.disabled = false;
      return;
    }

    if (isStreaming) {
      clearInterval(streamInterval);
    }

    isStreaming = true;
    btnStreamStart.disabled = true;
    simPostBody.textContent = '';
    simCursor.style.display = 'inline-block';
    simLiveBadge.style.display = 'inline-flex';
    simLiveText.textContent = currentLang === 'tr' ? 'CANLI AKIŞ' : 'STREAMING';

    clearInterval(cooldownTimer);
    cooldownBar.style.transition = 'none';
    cooldownBar.style.width = '0%';
    cooldownText.textContent = currentLang === 'tr' ? 'Şef yazıyor…' : 'Chef is writing…';

    const fullText = data.body;
    let charIndex = 0;

    streamInterval = setInterval(() => {
      if (charIndex < fullText.length) {
        const chunk = fullText.slice(charIndex, charIndex + 3);
        simPostBody.textContent += chunk;
        charIndex += 3;
      } else {
        clearInterval(streamInterval);
        isStreaming = false;
        simCursor.style.display = 'none';
        simLiveText.textContent = currentLang === 'tr' ? 'TAMAMLANDI' : 'COMPLETE';
        btnStreamStart.disabled = false;

        startReadingCooldown(18);
      }
    }, 22);
  }

  function startReadingCooldown(seconds) {
    let remaining = seconds;
    cooldownBar.style.transition = 'none';
    cooldownBar.style.width = '100%';
    // Force reflow so smooth countdown animation runs from 100% to 0%
    void cooldownBar.offsetWidth;
    cooldownBar.style.transition = `width ${seconds}s linear`;
    cooldownBar.style.width = '0%';

    function updateText() {
      if (currentLang === 'tr') {
        cooldownText.textContent = `⏳ Okuma süresi: ${remaining} sn`;
      } else {
        cooldownText.textContent = `⏳ Reading cooldown: ${remaining}s`;
      }
    }

    updateText();
    clearInterval(cooldownTimer);

    cooldownTimer = setInterval(() => {
      remaining--;
      if (remaining > 0) {
        updateText();
      } else {
        clearInterval(cooldownTimer);
        cooldownText.textContent = currentLang === 'tr'
          ? '✓ Sindirildi • Yeni konuya hazır'
          : '✓ Digested • Ready for next post';
      }
    }, 1000);
  }

  // Bento Topic Chips Click Handling
  tastesGrid.addEventListener('click', (e) => {
    const btn = e.target.closest('.taste-chip-btn');
    if (!btn || isStreaming) return;

    document.querySelectorAll('.taste-chip-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');

    currentTopic = btn.getAttribute('data-topic');
    activeSubtopicIndex = 0;
    renderSubtopicsPills();
    renderSimulatorPost(currentTopic, true);
  });

  // Spin (Random Category) Button
  btnSpin.addEventListener('click', () => {
    if (isStreaming) return;
    const topics = Object.keys(stories);
    const otherTopics = topics.filter(t => t !== currentTopic);
    const randomTopic = otherTopics[Math.floor(Math.random() * otherTopics.length)];

    currentTopic = randomTopic;
    activeSubtopicIndex = 0;

    document.querySelectorAll('.taste-chip-btn').forEach(b => {
      b.classList.toggle('active', b.getAttribute('data-topic') === randomTopic);
    });

    renderSubtopicsPills();
    renderSimulatorPost(currentTopic, true);
  });

  btnStreamStart.addEventListener('click', () => {
    if (isStreaming) return;
    renderSimulatorPost(currentTopic, true);
  });

  btnReread.addEventListener('click', () => {
    if (isStreaming) return;
    renderSimulatorPost(currentTopic, true);
  });

  // Bookmark Button Simulation
  let isBookmarked = false;
  btnBookmarkDemo.addEventListener('click', () => {
    isBookmarked = !isBookmarked;
    const svg = btnBookmarkDemo.querySelector('svg');
    if (isBookmarked) {
      svg.setAttribute('fill', 'currentColor');
      btnBookmarkDemo.style.color = 'var(--ink-primary)';
    } else {
      svg.setAttribute('fill', 'none');
      btnBookmarkDemo.style.color = 'var(--ink-secondary)';
    }
  });

  // Share Button Simulation
  btnShareDemo.addEventListener('click', async () => {
    const title = simPostTitle.textContent;
    const text = `"${title}" — Omakase`;
    if (navigator.share) {
      try {
        await navigator.share({ title: 'Omakase', text: text, url: window.location.href });
      } catch (err) {}
    } else {
      navigator.clipboard.writeText(`${text} ${window.location.href}`);
      const span = btnShareDemo.querySelector('span');
      const prevText = span.textContent;
      span.textContent = currentLang === 'tr' ? 'Kopyalandı' : 'Copied';
      setTimeout(() => {
        span.textContent = prevText;
      }, 1400);
    }
  });

  // ==========================================================================
  // 8. DEEP DIVE MODAL SHEET
  // ==========================================================================
  function openDeepDiveModal() {
    const data = getActiveStoryData();
    modalTitle.textContent = data.deepDiveTitle;
    modalBody.textContent = data.deepDiveBody;
    deepDiveModal.classList.add('open');
    document.body.style.overflow = 'hidden';
  }

  function closeDeepDiveModal() {
    deepDiveModal.classList.remove('open');
    document.body.style.overflow = '';
  }

  btnOpenDeepDive.addEventListener('click', openDeepDiveModal);
  btnCloseModal.addEventListener('click', closeDeepDiveModal);

  deepDiveModal.addEventListener('click', (e) => {
    if (e.target === deepDiveModal) {
      closeDeepDiveModal();
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && deepDiveModal.classList.contains('open')) {
      closeDeepDiveModal();
    }
  });

  // ==========================================================================
  // 9. FAQ ACCORDION
  // ==========================================================================
  const faqItems = document.querySelectorAll('.faq-item');
  faqItems.forEach(item => {
    const questionBtn = item.querySelector('.faq-question');
    questionBtn.addEventListener('click', () => {
      const isOpen = item.classList.contains('active');
      faqItems.forEach(other => other.classList.remove('active'));
      if (!isOpen) {
        item.classList.add('active');
      }
    });
  });

  // ==========================================================================
  // 10. WAITLIST FORM SUBMISSION (CLEAN INLINE FEEDBACK)
  // ==========================================================================
  const waitlistForm = document.getElementById('waitlist-form');
  const waitlistEmail = document.getElementById('waitlist-email');
  const waitlistSubmitBtn = document.getElementById('waitlist-submit-btn');
  const waitlistFeedback = document.getElementById('waitlist-feedback');

  waitlistForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const email = waitlistEmail.value.trim();
    if (!email || !email.includes('@')) return;

    waitlistSubmitBtn.disabled = true;
    waitlistSubmitBtn.textContent = currentLang === 'tr' ? 'Kaydedildi ✓' : 'Joined ✓';

    try {
      const list = JSON.parse(localStorage.getItem('omakase_waitlist') || '[]');
      list.push({ email, date: new Date().toISOString() });
      localStorage.setItem('omakase_waitlist', JSON.stringify(list));
    } catch (err) {}

    if (waitlistFeedback) {
      waitlistFeedback.textContent = currentLang === 'tr'
        ? `${email} TestFlight davet listesine eklendi.`
        : `${email} has been added to the TestFlight invite list.`;
    }

    setTimeout(() => {
      waitlistEmail.value = '';
      waitlistSubmitBtn.disabled = false;
      waitlistSubmitBtn.textContent = translations[currentLang]['cta.joinBtn'];
    }, 1800);
  });

  // ==========================================================================
  // 11. MOBILE DRAWER NAVIGATION
  // ==========================================================================
  mobileToggleBtn.addEventListener('click', () => {
    mobileDrawer.classList.toggle('open');
  });

  document.querySelectorAll('.mobile-link').forEach(link => {
    link.addEventListener('click', () => {
      mobileDrawer.classList.remove('open');
    });
  });

  // ==========================================================================
  // 12. INITIALIZATION
  // ==========================================================================
  applyTheme(currentTheme);
  applyLanguage(currentLang);
});
