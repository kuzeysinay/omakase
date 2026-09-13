/**
 * OMAKASE — OFFICIAL WEB APPLICATION LOGIC
 * Features: Dark/Light Mode Sync, Dual Language (TR/EN), 
 * Interactive Bento Simulator with SSE-style Typewriter & 18s Cooldown,
 * Deep Dive Sheet Reader, FAQ Accordion, and Mobile Navigation.
 */

document.addEventListener('DOMContentLoaded', () => {
  // ==========================================================================
  // 1. DATA & LOCALIZATION DICTIONARY
  // ==========================================================================
  const translations = {
    tr: {
      "nav.features": "Özellikler",
      "nav.demo": "Canlı Deneyim",
      "nav.philosophy": "Felsefe",
      "nav.gallery": "Arayüz",
      "nav.faq": "SSS",
      "nav.getApp": "İndir",

      "hero.badge": "iOS 17+ • Kişisel Kültür & Bilgi Şefi",
      "hero.title": "Algoritmaların gürültüsünden uzak, zihinsel damak tadınıza özel kültür akışı.",
      "hero.subtitle": "Letterboxd günlüğünüzü, ilgi alanlarınızı ve zamansız merakınızı gerçek zamanlı, doğrulanmış mikro-hikayelere dönüştüren kişisel bilgi şefiniz.",
      "hero.downloadCta": "Hemen İndir",
      "hero.tryDemo": "Canlı Tadımı Dene ↓",
      "hero.meta1": "Hidden Folks Monokrom Palet",
      "hero.meta2": "Gemini 3.5 Flash Canlı Akış",
      "hero.meta3": "18s Okuma Süresi Koruması",
      "hero.pill1Title": "Letterboxd Entegre",
      "hero.pill1Sub": "Son 50 filminden özel trivia",
      "hero.pill2Title": "Doyum Koruması",
      "hero.pill2Sub": "18s akıllı okuma süresi",

      "demo.tag": "İnteraktif Simülatör",
      "demo.title": "Canlı Şef Tadımı",
      "demo.desc": "Uygulamayı indirmeden önce doğrudan tarayıcınızda deneyimleyin. İlgi alanınızı seçin, şefin sizin için anlık mikro-hikaye hazırlamasını izleyin.",
      "demo.bentoTitle": "Bento Keşif Izgarası",
      "demo.bentoSub": "O an ne tüketmek istediğinizi seçin:",
      "demo.lbSub": "İzleme günlüğünden rastgele film",
      "demo.spin": "Rastgele Çevir (Roll)",
      "demo.startStream": "Şeften Tadım İste",
      "demo.cooldownReady": "Okuma sindirme koruması hazır",

      "taste.cinema": "Sinema",
      "taste.science": "Bilim",
      "taste.philosophy": "Felsefe",
      "taste.music": "Müzik",
      "taste.literature": "Edebiyat",
      "taste.architecture": "Mimarlık",

      "action.reread": "Yeniden Oku",
      "action.share": "Paylaş",
      "action.save": "Kaydet",
      "action.deepdive": "Derinlemesine İncele",

      "features.tag": "Temel Yetenekler",
      "features.title": "Düşünceyi Besleyen Bir Deneyim",
      "features.desc": "Sosyal medyanın dikkati parçalayan algoritmalarına karşı, zihinsel dinginliği ve hakiki öğrenmeyi önceleyen sistem mimarisi.",
      "features.f1Title": "BentoTasteBox (2048 Tarzı Dokunsal Keşif)",
      "features.f1Desc": "Altı ana kategori (Sinema, Bilim, Felsefe, Müzik vb.), dokunsal 3D kart çevirme ve her kategoriye dokunduğunuzda Google Gemini ile anında türetilen 10 dinamik alt konu karosu. Algoritmaların tahminine mahkum olmadan, kendi iradenizle keşfedin.",
      "features.f2Title": "Letterboxd Entegrasyonu",
      "features.f2Desc": "Letterboxd günlüğünüzdeki son 50 filmi tek tıkla analiz eder. Rastgele kilitlerle her açılışta izlediğiniz bir filme dair doğrulanmış kamera arkası trivia'sı ve yönetmen sırları üretir.",
      "features.f3Title": "Doyum & Doomscrolling Koruması",
      "features.f3Desc": "Metin uzunluğuna göre 15 - 25 saniye akıllı sindirme süresi (reading cooldown) uygular. Hızlı kaydırma yerine metni gerçekten okutup sindirten benzersiz bir tüketim psikolojisi sunar.",
      "features.f4Title": "Reels Tarzı Dikey Tam Ekran Akış",
      "features.f4Desc": "Instagram Reels formatında pürüzsüz sayfalama (.viewAligned). Server-Sent Events (SSE) üzerinden gelen kelimeler daktilo efektiyle anlık olarak ekrana canlı akar.",
      "features.f5Title": "Tavşan Deliği (Deep Dive)",
      "features.f5Desc": "Bir konuyu daha derin öğrenmek istediğinizde tek tıkla o konuya özel kapsamlı şef follow-up analizini anında üretir ve sayfa düzeninizi bozmadan alt sheet okuyucuda açar.",

      "phil.tag": "Felsefemiz",
      "phil.title": "Şefe Güvenin Felsefesi",
      "phil.desc": "Japon mutfak kültüründe 'Omakase', seçimi şefe bırakmak ve onun ustalığına güvenmek anlamına gelir. Biz bu kavramı bilgi tüketimine taşıdık.",
      "phil.badTitle": "Algoritmik Sonsuz Akış",
      "phil.bad1": "Sonsuz ve doyumsuz kaydırma (doomscrolling)",
      "phil.bad2": "Öfke ve etkileşim odaklı kışkırtıcı başlıklar",
      "phil.bad3": "Reklamlar, sponsorlu gönderiler ve dikkat hırsızlığı",
      "phil.bad4": "Kullanım sonrası tükenmişlik ve zaman kaybı hissi",
      "phil.goodTitle": "Omakase Kişisel Bilgi Şefi",
      "phil.good1": "Metni sindirten akıllı okuma süresi ve doyum psikolojisi",
      "phil.good2": "Zamansız kültür, derinlikli sinema, felsefe ve bilim",
      "phil.good3": "Sıfır reklam, sıfır gürültü, saf mürekkep & kağıt estetiği",
      "phil.good4": "Kullanım sonrası zihinsel berraklık ve beslenmişlik hissi",

      "gallery.tag": "Arayüz Vitrini",
      "gallery.title": "Mürekkep ve Kağıt Sadeliği",
      "gallery.desc": "Hidden Folks sanat tarzından ilham alan siyah-beyaz monokrom arayüz, gözlerinizi yormaz ve sadece içeriğe odaklanmanızı sağlar.",
      "gallery.item1Title": "Açık Mod Akış",
      "gallery.item1Sub": "Doğal kağıt beyazlığı",
      "gallery.item2Title": "Koyu Mod Akış",
      "gallery.item2Sub": "Derin OLED siyahı",
      "gallery.item3Title": "İlgi Alanı Seçimi",
      "gallery.item3Sub": "Zevklerinize göre kalibrasyon",
      "gallery.item4Title": "Giriş & Profil",
      "gallery.item4Sub": "Google ile tek dokunuş",

      "faq.tag": "Merak Edilenler",
      "faq.title": "Sıkça Sorulan Sorular",
      "faq.desc": "Omakase hakkında aklınıza takılabilecek teknik, felsefi ve kullanım detayları.",
      "faq.q1": "Omakase nedir ve nasıl çalışır?",
      "faq.a1": "Omakase, kullanıcının ilgi alanlarını ve Letterboxd izleme günlüğünü Google Cloud Run ve Gemini 3.5 Flash yapay zeka modelleriyle anlık olarak doğrulanmış, derinlikli mikro-hikayelere dönüştüren yerel bir iOS uygulamasıdır.",
      "faq.q2": "Letterboxd hesabımı bağlamak zorunda mıyım?",
      "faq.a2": "Hayır! Letterboxd entegrasyonu tamamen opsiyoneldir. Sadece genel ilgi alanlarınızı (Bilim, Felsefe, Mimarlık vb.) seçerek de Omakase'nin zengin akışını eksiksiz kullanabilirsiniz. Letterboxd bağlarsanız son izlediğiniz filmlerle ilgili özel trivia'lar akışınıza eklenir.",
      "faq.q3": "Okuma süresi sayacı (Reading Cooldown) neden var?",
      "faq.a3": "Geleneksel sosyal medya kullanıcıları metinleri okumadan saniyede bir kaydırarak tüketim yorgunluğuna (doomscrolling) kapılır. Omakase, metin uzunluğuna göre 15-25 saniye akıllı sindirme süresi uygulayarak metni gerçekten okuyup hazmetmenizi sağlar.",
      "faq.q4": "Bilgilerin doğruluğu nasıl garanti ediliyor?",
      "faq.a4": "Arka uç sistemimiz, Gemini 3.5 Flash'a verilen özel prompt mimarisi ve çift katmanlı moderasyon filtreleriyle halüsinasyonları engeller; genel geçer özetler yerine doğrulanmış set arkası röportajlarına, bilimsel makalelere ve tarihsel belgelere dayanır.",
      "faq.q5": "Omakase ücretsiz mi?",
      "faq.a5": "Omakase ücretsiz olarak indirilebilir ve temel günlük şef kotasıyla keşif yapılabilir. Sınırsız derinlemesine inceleme ve özel koleksiyonlar için opsiyonel bir Omakase Plus üyeliği sunulmaktadır.",

      "cta.title": "Zihinsel Damak Tadınızı Beslemeye Hazır mısınız?",
      "cta.desc": "Omakase şu anda iOS için aktif yayındadır. Hemen katılın, Letterboxd günlüğünüzü derinlikli hikayelere dönüştürün.",
      "cta.joinBtn": "TestFlight / Katıl",

      "footer.contact": "İletişim",
      "footer.copy": "© 2026 Omakase. Tüm hakları saklıdır. Hidden Folks monokrom estetiği ve Japon mutfak sadeliğiyle inşa edildi."
    },

    en: {
      "nav.features": "Features",
      "nav.demo": "Live Tasting",
      "nav.philosophy": "Philosophy",
      "nav.gallery": "Interface",
      "nav.faq": "FAQ",
      "nav.getApp": "Get App",

      "hero.badge": "iOS 17+ • Personal Culture & Knowledge Chef",
      "hero.title": "Beyond the algorithmic noise. A feed tuned to your personal palate.",
      "hero.subtitle": "Your personal knowledge chef transforming your Letterboxd diary, curated tastes, and timeless curiosities into verified, real-time micro-stories.",
      "hero.downloadCta": "Download on iOS",
      "hero.tryDemo": "Try Live Tasting ↓",
      "hero.meta1": "Hidden Folks Monochrome Palette",
      "hero.meta2": "Gemini 3.5 Flash Live Stream",
      "hero.meta3": "18s Reading Cooldown Protection",
      "hero.pill1Title": "Letterboxd Integrated",
      "hero.pill1Sub": "Exclusive trivia from your last 50 films",
      "hero.pill2Title": "Satiation Defense",
      "hero.pill2Sub": "18s smart reading cooldown",

      "demo.tag": "Interactive Simulator",
      "demo.title": "Live Chef Tasting",
      "demo.desc": "Experience the app directly in your browser. Select an interest and watch the chef craft an instant micro-story just for you.",
      "demo.bentoTitle": "Bento Taste Box",
      "demo.bentoSub": "Select what your mind craves right now:",
      "demo.lbSub": "Random pick from your film diary",
      "demo.spin": "Roll Tastes (Spin)",
      "demo.startStream": "Request Chef Tasting",
      "demo.cooldownReady": "Reading cooldown protection ready",

      "taste.cinema": "Cinema",
      "taste.science": "Science",
      "taste.philosophy": "Philosophy",
      "taste.music": "Music",
      "taste.literature": "Literature",
      "taste.architecture": "Architecture",

      "action.reread": "Re-read",
      "action.share": "Share",
      "action.save": "Save",
      "action.deepdive": "Deep Dive",

      "features.tag": "Core Capabilities",
      "features.title": "An Architecture Built for Thought",
      "features.desc": "Designed to counter the attention-shredding mechanics of social media, prioritizing mental stillness and authentic retention.",
      "features.f1Title": "BentoTasteBox (2048-Style Tactile Discovery)",
      "features.f1Desc": "Six core categories with tactile 3D flipping cards, instantly generating 10 dynamic subtopic tiles powered by Google Gemini. Explore by your own intent, not an algorithmic prediction.",
      "features.f2Title": "Letterboxd Integration",
      "features.f2Desc": "Seamlessly pulls your last 50 films. With randomized locks, each launch delivers verified behind-the-scenes production anecdotes and director insights from a movie you actually watched.",
      "features.f3Title": "Satiation & Anti-Doomscrolling Defense",
      "features.f3Desc": "Enforces a 15 to 25 second intelligent reading cooldown based on text length. Normal scrolling pauses, giving your brain the essential space to digest and reflect.",
      "features.f4Title": "Reels-Style Fullscreen Vertical Stream",
      "features.f4Desc": "Instagram Reels format with silky smooth paging (.viewAligned). Server-Sent Events (SSE) stream words onto the screen with a typewriter cadence.",
      "features.f5Title": "Rabbit Hole (Deep Dive)",
      "features.f5Desc": "Want to unpack an anecdote? One tap generates an in-depth follow-up report from the chef, opening smoothly in an iOS reader sheet.",

      "phil.tag": "Our Philosophy",
      "phil.title": "Trust the Chef",
      "phil.desc": "In Japanese culinary tradition, 'Omakase' means entrusting yourself to the chef's craft. We applied this noble idea to the consumption of knowledge.",
      "phil.badTitle": "Algorithmic Endless Stream",
      "phil.bad1": "Addictive, insatiable scrolling (doomscrolling)",
      "phil.bad2": "Rage-baiting, engagement-seeking headlines",
      "phil.bad3": "Ads, sponsored interruptions, and attention theft",
      "phil.bad4": "Depletion and post-session emptiness",
      "phil.goodTitle": "Omakase Personal Knowledge Chef",
      "phil.good1": "Mindful reading cooldown and genuine satiation",
      "phil.good2": "Timeless culture, cinema lore, science and philosophy",
      "phil.good3": "Zero ads, zero clutter, pure ink and paper harmony",
      "phil.good4": "Mental clarity and a sense of true nourishment",

      "gallery.tag": "Interface Gallery",
      "gallery.title": "The Elegance of Ink & Paper",
      "gallery.desc": "Inspired by Hidden Folks art direction, our monochrome palette relieves eye strain and lets the prose breathe.",
      "gallery.item1Title": "Light Feed",
      "gallery.item1Sub": "Warm natural paper tint",
      "gallery.item2Title": "Dark Feed",
      "gallery.item2Sub": "Deep OLED pure black",
      "gallery.item3Title": "Taste Selection",
      "gallery.item3Sub": "Tailored to your palate",
      "gallery.item4Title": "Auth & Profile",
      "gallery.item4Sub": "One-tap Google sign in",

      "faq.tag": "Curiosities",
      "faq.title": "Frequently Asked Questions",
      "faq.desc": "Everything you need to know about the philosophy, technology, and usage of Omakase.",
      "faq.q1": "What is Omakase and how does it work?",
      "faq.a1": "Omakase is a native iOS application that synthesizes your chosen interests and Letterboxd diary into verified, thoughtful micro-stories via Google Cloud Run and Gemini 3.5 Flash.",
      "faq.q2": "Do I have to connect a Letterboxd account?",
      "faq.a2": "Not at all! Letterboxd is entirely optional. You can enjoy Omakase solely by selecting general cultural tastes like Science, Philosophy, Architecture, or Jazz.",
      "faq.q3": "Why is there a reading cooldown timer?",
      "faq.a3": "Traditional feeds train users to swipe in fractions of a second, causing consumption fatigue. Omakase locks the feed for 15-25 seconds so you actually read and absorb the insight.",
      "faq.q4": "How do you ensure historical and factual accuracy?",
      "faq.a4": "Our backend uses strict system prompts and a dual moderation pipeline on Gemini 3.5 Flash, prioritizing verified archival interviews, production notes, and peer-reviewed journals over generic summaries.",
      "faq.q5": "Is Omakase free to use?",
      "faq.a5": "Omakase is free to download with a generous daily chef tasting quota. An optional Omakase Plus membership is available for unlimited deep-dive explorations and offline bookmarking.",

      "cta.title": "Ready to Nourish Your Mental Palate?",
      "cta.desc": "Omakase is available now on iOS. Join today and turn your curiosity into a tranquil daily ritual.",
      "cta.joinBtn": "Join TestFlight",

      "footer.contact": "Contact",
      "footer.copy": "© 2026 Omakase. All rights reserved. Built with Hidden Folks ink aesthetics and Japanese culinary minimalism."
    }
  };

  // ==========================================================================
  // 2. SIMULATOR POST CONTENT DATABASE (TR & EN)
  // ==========================================================================
  const stories = {
    cinema: {
      tr: {
        title: "Oppenheimer ve IMAX 70mm'nin Görsel Ağırlığı",
        date: "11 Eyl 2026 • 20:17",
        body: "Christopher Nolan, Oppenheimer'ı çekerken 65mm IMAX siyah-beyaz filmi dünyada ilk kez Kodak'a özel olarak ürettirdi. Standart IMAX projektörleri bu 18 kilometrelik, 272 kiloluk devasa makarayı çevirirken platoda duyulan mekanik ses, sahnenin kendisinden bile daha hipnotize ediciydi. Nolan'a göre bu bir nostalji değil; izleyicinin göz bebeklerine kadar uzanan somut bir gerçeklik arayışıydı.",
        tags: ["Sinema", "ChristopherNolan", "Imax70Mm"],
        deepDiveTitle: "Derinlemesine İnceleme: Kodak 65mm B&W Üretimi",
        deepDiveBody: "IMAX formatında daha önce hiç 65mm siyah-beyaz film emülsiyonu üretilmemişti. Kodak mühendisleri Nolan ve görüntü yönetmeni Hoyte van Hoytema'nın talebiyle laboratuvara girerek fotokimyasal gren yapısını sıfırdan tasarladı. Film şeridinin kalınlığı normal renkli filmlere göre %14 daha fazlaydı; bu durum kameraların motorlarının platoda aşırı ısınmasına yol açtı. Ancak ortaya çıkan sonuç, insan yüzündeki en ufak bir gözenekten nükleer patlama anındaki ışıma partiküllerine kadar dijital sensörlerin asla yakalayamayacağı bir organik derinlik sağladı."
      },
      en: {
        title: "Oppenheimer and the Physical Gravity of IMAX 70mm",
        date: "Sep 11, 2026 • 8:17 PM",
        body: "Christopher Nolan commissioned Kodak to engineer 65mm IMAX black-and-white film for the very first time in cinema history. As the projector spooled the 11-mile, 600-pound platter, the mechanical whirr on set was as hypnotic as the imagery. For Nolan, this was not mere nostalgia; it was an uncompromising quest for tangible optical presence.",
        tags: ["Cinema", "ChristopherNolan", "Imax70Mm"],
        deepDiveTitle: "Deep Dive: Kodak's 65mm Monochrome Chemistry",
        deepDiveBody: "Before Oppenheimer, 65mm black-and-white film emulsion simply did not exist for IMAX cameras. Kodak photo-chemists formulated a high-contrast emulsion capable of withstanding the immense vacuum-pressure feed of IMAX transport mechanisms. The resulting analog density rendered micro-expressions on Cillian Murphy's skin with an astonishing fidelity unattainable by digital sensors."
      }
    },

    science: {
      tr: {
        title: "Kuantum Eşevresizliği: Kedinin Gerçekten Yaşadığı An",
        date: "12 Eyl 2026 • 14:32",
        body: "Schrödinger'in kedisi paradoksunda asıl sır kutuyu açan insanda değil; kutunun içine sızan tek bir fotondadır. Kuantum eşevresizliği (decoherence), süperpozisyon durumunun çevreyle en ufak termodinamik temasta mikrosaniyeler içinde klasik gerçekliğe 'çöküşünü' açıklar. Yani evren, biz bakmasak dahi kendi kendini sürekli izlemektedir.",
        tags: ["Kuantum", "Fizik", "Schrodinger"],
        deepDiveTitle: "Derinlemesine İnceleme: Çevre Kaynaklı Dalga Çökmesi",
        deepDiveBody: "Wojciech Zurek'in 'kuantum darwinizmi' kuramına göre, bir kuantum sisteminin çevresindeki fotonlar ve hava molekülleri sistemin kopyalarını oluşturur. Yalnızca çevreye en dayanıklı klasik durumlar (örneğin 'kedi canlı' veya 'kedi ölü') hayatta kalır. Süperpozisyon mistik bir bilinçle değil, termodinamik bilgi yayılımıyla son bulur."
      },
      en: {
        title: "Quantum Decoherence: When the Cat Actually Decides",
        date: "Sep 12, 2026 • 2:32 PM",
        body: "In Schrödinger's paradox, the secret lies not in human consciousness opening the box, but in a stray environmental photon. Quantum decoherence explains how superpositions leak phase information into surrounding particles within femtoseconds, collapsing fuzzy probabilities into crisp classical facts.",
        tags: ["Quantum", "Physics", "Decoherence"],
        deepDiveTitle: "Deep Dive: Quantum Darwinism and Pointer States",
        deepDiveBody: "Pioneered by Wojciech Zurek, Quantum Darwinism suggests that the environment acts as a communication channel. Only the hardiest states—those resilient against ambient bombardment—reproduce their signatures across the universe, effectively creating objective reality without observer mysticism."
      }
    },

    philosophy: {
      tr: {
        title: "Seneca'nın Zaman Muhasebesi ve Hayatın Kısalığı",
        date: "10 Eyl 2026 • 09:15",
        body: "Roma'nın en zengin adamlarından Seneca, mülkünü birine kaptıranların çıkardığı yaygarayla günlerini başkalarına dağıtanların kayıtsızlığını kıyaslar. Hayat kısa değildir; biz onu fazlasıyla harcarız. Bir saatin tik takları zamanın geçişini değil, geri gelmeyecek olan parçamızın ölümünü haber verir.",
        tags: ["Felsefe", "Stoacılık", "Seneca"],
        deepDiveTitle: "Derinlemesine İnceleme: De Brevitate Vitae'nin Gizli Matematiği",
        deepDiveBody: "Seneca 'De Brevitate Vitae' (Hayatın Kısalığı Üzerine) risalesinde zamanı bir sermaye gibi yönetmeyi önerir. Paulinus'a yazdığı mektupta kamu görevlerinin sahte meşguliyetlerini eleştirir: 'İnsanların çoğu tam da yaşamaya başlamaları gerektiği yaşta ölüp giderler.' Çözüm, geçmişin bilgeleriyle dostluk kurarak zamansızlaşmaktır."
      },
      en: {
        title: "Seneca's Audit of Lost Hours",
        date: "Sep 10, 2026 • 9:15 AM",
        body: "Seneca observed that while men guard their physical estates with fierce litigiousness, they distribute their hours with profligate nonchalance. Life is not short; we merely squander it on trivial obligations, mistaking perpetual busyness for purposeful existence.",
        tags: ["Philosophy", "Stoicism", "Seneca"],
        deepDiveTitle: "Deep Dive: The Temporal Economics of De Brevitate Vitae",
        deepDiveBody: "In his treatise to Paulinus, Seneca argues that authentic leisure (otium) is not idle stagnation, but study alongside timeless thinkers. By engaging with Socrates or Epicurus, one annexes centuries of ancestral wisdom into a single mortal lifespan, triumphing over temporal fragility."
      }
    },

    music: {
      tr: {
        title: "Miles Davis ve Kind of Blue'nun Modal Sessizliği",
        date: "09 Eyl 2026 • 23:40",
        body: "1959 ilkbaharında Miles Davis, stüdyoya giren Bill Evans ve John Coltrane'in eline geleneksel akor şemaları yerine sadece birkaç mod notasından ibaret buruşuk kağıtlar verdi. Müzisyenler ne çalacaklarını provada öğrendiler. O albümü ölümsüz kılan şey, çalınan notalardan çok aralarda nefes alan bilinçli sessizliklerdi.",
        tags: ["Caz", "MilesDavis", "KindOfBlue"],
        deepDiveTitle: "Derinlemesine İnceleme: George Russell'ın Lydian Kromatik Konsepti",
        deepDiveBody: "Kind of Blue, geleneksel bebop'ın hızlı akor geçişlerinden (chord changes) bir kaçıştı. Miles, George Russell'ın teorisinden ilham alarak müzisyeni akor kalıplarından kurtardı ve tek bir gam üzerinde melodik şiir yazmaya davet etti. 'So What' parçasındaki kontrbas riff'i bu özgürlüğün en saf manifestosudur."
      },
      en: {
        title: "Miles Davis and the Radical Silence of Kind of Blue",
        date: "Sep 9, 2026 • 11:40 PM",
        body: "In the spring of 1959, Miles Davis handed Bill Evans and John Coltrane cryptic scraps of paper containing modal scales rather than chords. There were no rehearsals. What cemented Kind of Blue into legend was not the sheer virtuosity of notes played, but the deliberate chasms of air between them.",
        tags: ["Jazz", "MilesDavis", "ModalHarmony"],
        deepDiveTitle: "Deep Dive: Escape from the Tyranny of Bebop Changes",
        deepDiveBody: "Influenced by George Russell's Lydian Chromatic Concept, Davis broke free from the relentless chord changes of bebop. By lingering on a single Dorian mode for sixteen bars in 'So What', he demanded that soloists invent melodic poetry rather than mathematical gymnastics."
      }
    },

    literature: {
      tr: {
        title: "Borges'in Babil Kütüphanesi ve Sonsuz İhtimaller",
        date: "08 Eyl 2026 • 18:20",
        body: "Jorge Luis Borges'in tasavvur ettiği kütüphanede 25 sembolün tüm permütasyonlarıyla yazılmış sonsuz sayıda kitap vardır. İçinde sizin tam biyografiniz de mevcuttur, o biyografinin tek harfi yanlış olan versiyonu da. Borges'e göre her şeyin yazılı olduğu bir evrende en büyük lanet, hakikatin anlamsızlık okyanusunda kaybolmasıdır.",
        tags: ["Edebiyat", "Borges", "Kombinatorik"],
        deepDiveTitle: "Derinlemesine İnceleme: 25 Sembolün Kozmolojik Ağırlığı",
        deepDiveBody: "Borges'in 1941 tarihli öyküsü modern bilgi teorisinin (Shannon enformasyonu) edebi bir önsezisidir. Kütüphanedeki kitap sayısı 25 üzeri 1.312.000 gibi akıl almaz bir sayıdır. Kütüphaneciler gerçeği ararken delirme noktasına gelir; çünkü mutlak bilgiyle saf gürültü arasındaki sınır matematiksel olarak belirsizleşmiştir."
      },
      en: {
        title: "Borges' Library of Babel: The Tragedy of Infinite Signal",
        date: "Sep 8, 2026 • 6:20 PM",
        body: "In Jorge Luis Borges' hexagonal cosmos, every book containing all permutations of 25 orthographic symbols already exists. Your true biography sits on a shelf—along with billions of editions containing a single falsehood. When everything is written, meaning dissolves into statistical noise.",
        tags: ["Literature", "Borges", "Combinatorics"],
        deepDiveTitle: "Deep Dive: Shannon Entropy in Argentine Metaphysics",
        deepDiveBody: "Written in 1941, Borges anticipated modern information theory. The total number of volumes (~25^1,312,000) exceeds all subatomic particles in the observable universe. The librarians' despair echoes modern web overload: pure noise perfectly masquerading as omniscient scripture."
      }
    },

    architecture: {
      tr: {
        title: "Tadao Ando ve Işığın Betondaki Tapınağı",
        date: "07 Eyl 2026 • 11:05",
        body: "Osaka'daki Işık Kilisesi'nde Tadao Ando, haçı altın ya da mermerle değil; çıplak beton duvara açtığı dikey ve yatay yarıklardan içeri sızan gün ışığıyla inşa etti. Güneş hareket ettikçe kilisenin içindeki haç yer değiştirir. Ando için mimarlık bir form değil, doğanın mekana bıraktığı gölgedir.",
        tags: ["Mimarlık", "TadaoAndo", "Minimalizm"],
        deepDiveTitle: "Derinlemesine İnceleme: Japon 'Ma' (Boşluk) Felsefesi",
        deepDiveBody: "Ando'nun pürüzsüz ipek betonu (Pritzker ödüllü teknik) ahşap kalıpların verniklenmesiyle elde edilir. Betonun soğuk endüstriyel hissi, sızan ışığın sıcaklığıyla kasten çatıştırılır. Bu, Japon estetiğindeki 'Ma' (mekansal ve zamansal negatif boşluk) ilkesinin çağdaş betonarme tercümesidir."
      },
      en: {
        title: "Tadao Ando and the Slits of Living Sunlight",
        date: "Sep 7, 2026 • 11:05 AM",
        body: "At the Church of the Light in Ibaraki, Tadao Ando constructed the central crucifix not from gilded timber, but from cruciform slits cut into raw concrete. As the sun traverses the Japanese sky, the light cross glides across the floor. For Ando, architecture is merely the canvas that makes invisible light tangible.",
        tags: ["Architecture", "TadaoAndo", "ConcreteLight"],
        deepDiveTitle: "Deep Dive: The Spatial Geometry of Japanese 'Ma'",
        deepDiveBody: "Ando's mirror-smooth exposed concrete relies on lacquered formwork polished to a silk sheen. By stripping away ornamentation, the sanctuary honors 'Ma'—the pregnant Japanese concept of negative interval—forcing the worshipper to contemplate void rather than matter."
      }
    },

    letterboxd: {
      tr: {
        title: "Wong Kar-wai'nin Bitmeyen Mantı Sahnesi İşkencesi",
        date: "Bugün • 19:42",
        body: "Letterboxd günlüğünüzdeki 'In the Mood for Love' kaydından türetildi: Wong Kar-wai, Tony Leung ve Maggie Cheung'un dar merdivenlerde mantı sefertaslarıyla karşılaştığı sahneyi tam 43 kez yeniden çekti. Yönetmen oyunculara replik vermemişti; istediği tek şey, daracık koridorda iki ceketin birbirine değmeden hemen önceki o elektrikli gerilimiydi.",
        tags: ["Letterboxd", "WongKarWai", "InTheMoodForLove"],
        deepDiveTitle: "Derinlemesine İnceleme: Christopher Doyle'un Step-Printing Tekniği",
        deepDiveBody: "Filmin o rüya benzeri yavaş akışı, görüntü yönetmeni Christopher Doyle'un 'step-printing' tekniğiyle sağlandı. Saniyede 8 veya 12 kare çekilen film, kurguda kareler kopyalanarak 24 kareye tamamlandı. Böylece karakterler ağır çekimde süzülürken fondaki duman ve yağmur gerçek zamanlı akarak unutulmaz bir melankoli yarattı."
      },
      en: {
        title: "Wong Kar-wai and the 43 Takes of Noodle-Bar Torment",
        date: "Today • 7:42 PM",
        body: "Derived from your Letterboxd log of 'In the Mood for Love': Director Wong Kar-wai filmed Tony Leung and Maggie Cheung passing each other on the narrow staircase 43 consecutive times without scripted dialogue. He sought only the electric, unspoken tension in the fraction of an inch separating their coat fabrics.",
        tags: ["Letterboxd", "WongKarWai", "InTheMoodForLove"],
        deepDiveTitle: "Deep Dive: Christopher Doyle's Step-Printing Magic",
        deepDiveBody: "The film's intoxicating waltz was achieved via cinematographer Christopher Doyle's under-cranked step-printing. Filming at 8 to 12 frames per second and duplicating frames in optical printing created motion trails that turned humid 1960s Hong Kong alleyways into a lingering, memory-haunted dreamscape."
      }
    }
  };

  // ==========================================================================
  // 3. STATE MANAGEMENT
  // ==========================================================================
  let currentLang = localStorage.getItem('omakase_lang') || 'tr';
  let currentTheme = localStorage.getItem('omakase_theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  let currentTopic = 'cinema';
  let isLetterboxdMode = false;
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
  const heroScreenImg = document.getElementById('hero-screen-img');

  // Mobile drawer
  const mobileToggleBtn = document.getElementById('mobile-toggle-btn');
  const mobileDrawer = document.getElementById('mobile-drawer');

  // Simulator elements
  const tastesGrid = document.getElementById('tastes-grid');
  const letterboxdSwitch = document.getElementById('letterboxd-switch');
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
      heroScreenImg.src = 'assets/screen-feed-dark.png';
    } else {
      sunIcon.style.display = 'none';
      moonIcon.style.display = 'block';
      themeMeta.setAttribute('content', '#FAFAFA');
      heroScreenImg.src = 'assets/screen-feed.png';
    }
  }

  themeToggleBtn.addEventListener('click', () => {
    const nextTheme = currentTheme === 'dark' ? 'light' : 'dark';
    applyTheme(nextTheme);
  });

  // ==========================================================================
  // 5. LANGUAGE CONTROLLER
  // ==========================================================================
  function applyLanguage(lang) {
    currentLang = lang;
    htmlEl.setAttribute('lang', lang);
    localStorage.setItem('omakase_lang', lang);
    currentLangText.textContent = lang.toUpperCase();

    // Update all data-i18n elements
    const elements = document.querySelectorAll('[data-i18n]');
    elements.forEach(el => {
      const key = el.getAttribute('data-i18n');
      if (translations[lang] && translations[lang][key]) {
        el.textContent = translations[lang][key];
      }
    });

    // Refresh current simulator view with the new language
    renderSimulatorPost(currentTopic, false);
  }

  langToggleBtn.addEventListener('click', () => {
    const nextLang = currentLang === 'tr' ? 'en' : 'tr';
    applyLanguage(nextLang);
  });

  // ==========================================================================
  // 6. SIMULATOR LOGIC & TYPEWRITER SSE STREAM
  // ==========================================================================
  function getActiveStoryData() {
    const key = isLetterboxdMode ? 'letterboxd' : currentTopic;
    const story = stories[key] || stories.cinema;
    return story[currentLang] || story.tr;
  }

  function renderSimulatorPost(topicKey, animate = false) {
    const data = getActiveStoryData();

    simPostTitle.textContent = data.title;
    simPostDate.textContent = data.date;

    // Render Tags
    simPostTags.innerHTML = '';
    data.tags.forEach(tag => {
      const span = document.createElement('span');
      span.className = 'tag-badge';
      span.textContent = tag.startsWith('#') ? tag : `#${tag}`;
      simPostTags.appendChild(span);
    });

    // Update modal content
    modalTitle.textContent = data.deepDiveTitle;
    modalBody.textContent = data.deepDiveBody;

    if (!animate) {
      simPostBody.textContent = data.body;
      simCursor.style.display = 'none';
      simLiveBadge.style.display = 'inline-flex';
      simLiveText.textContent = currentLang === 'tr' ? 'TAMAMLANDI' : 'COMPLETE';
      simLiveBadge.style.color = 'var(--ink-secondary)';
      btnStreamStart.disabled = false;
      return;
    }

    // Streaming Typewriter Animation
    if (isStreaming) {
      clearInterval(streamInterval);
    }

    isStreaming = true;
    btnStreamStart.disabled = true;
    simPostBody.textContent = '';
    simCursor.style.display = 'inline-block';
    simLiveBadge.style.display = 'inline-flex';
    simLiveText.textContent = currentLang === 'tr' ? 'CANLI AKIŞ (SSE)' : 'STREAMING (SSE)';
    simLiveBadge.style.color = 'var(--accent-live)';

    // Reset cooldown bar
    clearInterval(cooldownTimer);
    cooldownBar.style.transition = 'none';
    cooldownBar.style.width = '0%';
    cooldownText.textContent = currentLang === 'tr' ? 'Metin daktilo ediliyor…' : 'Typing micro-story…';

    const fullText = data.body;
    let charIndex = 0;

    streamInterval = setInterval(() => {
      if (charIndex < fullText.length) {
        // Append 2-3 characters at a time for natural SSE pacing
        const chunk = fullText.slice(charIndex, charIndex + 2);
        simPostBody.textContent += chunk;
        charIndex += 2;
      } else {
        clearInterval(streamInterval);
        isStreaming = false;
        simCursor.style.display = 'none';
        simLiveText.textContent = currentLang === 'tr' ? 'TAMAMLANDI' : 'COMPLETE';
        simLiveBadge.style.color = 'var(--ink-secondary)';
        btnStreamStart.disabled = false;

        // Start 18s Reading Cooldown Countdown!
        startReadingCooldown(18);
      }
    }, 28);
  }

  function startReadingCooldown(seconds) {
    let remaining = seconds;
    cooldownBar.style.transition = `width ${seconds}s linear`;
    cooldownBar.style.width = '100%';

    function updateText() {
      if (currentLang === 'tr') {
        cooldownText.textContent = `Okuma Süresi Koruması: ${remaining}s (Kilitli)`;
      } else {
        cooldownText.textContent = `Reading Cooldown: ${remaining}s (Paging Locked)`;
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
          ? '✓ Sindirme tamamlandı • Kaydırmaya hazır' 
          : '✓ Satiated • Next post unlocked';
        cooldownBar.style.transition = 'none';
        cooldownBar.style.width = '0%';
      }
    }, 1000);
  }

  // Bento Topic Chips Click Handling
  tastesGrid.addEventListener('click', (e) => {
    const btn = e.target.closest('.taste-chip-btn');
    if (!btn || isStreaming) return;

    // Uncheck letterboxd if topic chosen
    if (isLetterboxdMode) {
      isLetterboxdMode = false;
      letterboxdSwitch.checked = false;
    }

    document.querySelectorAll('.taste-chip-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');

    currentTopic = btn.getAttribute('data-topic');
    renderSimulatorPost(currentTopic, true);
  });

  // Letterboxd Mode Switch
  letterboxdSwitch.addEventListener('change', () => {
    isLetterboxdMode = letterboxdSwitch.checked;
    if (isLetterboxdMode) {
      document.querySelectorAll('.taste-chip-btn').forEach(b => b.classList.remove('active'));
    } else {
      const activeBtn = document.querySelector(`.taste-chip-btn[data-topic="${currentTopic}"]`);
      if (activeBtn) activeBtn.classList.add('active');
    }
    renderSimulatorPost(currentTopic, true);
  });

  // Spin (Random Roll) Button
  btnSpin.addEventListener('click', () => {
    if (isStreaming) return;
    const topics = ['cinema', 'science', 'philosophy', 'music', 'literature', 'architecture'];
    const otherTopics = topics.filter(t => t !== currentTopic);
    const randomTopic = otherTopics[Math.floor(Math.random() * otherTopics.length)];

    currentTopic = randomTopic;
    isLetterboxdMode = false;
    letterboxdSwitch.checked = false;

    document.querySelectorAll('.taste-chip-btn').forEach(b => {
      b.classList.toggle('active', b.getAttribute('data-topic') === randomTopic);
    });

    renderSimulatorPost(currentTopic, true);
  });

  // Start Stream Button
  btnStreamStart.addEventListener('click', () => {
    if (isStreaming) return;
    renderSimulatorPost(currentTopic, true);
  });

  // Re-read Button
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
    const text = `"${title}" — Omakase ile keşfedildi.`;
    if (navigator.share) {
      try {
        await navigator.share({ title: 'Omakase', text: text, url: window.location.href });
      } catch (err) {
        // User cancelled or not supported
      }
    } else {
      navigator.clipboard.writeText(`${text} ${window.location.href}`);
      const prevText = btnShareDemo.querySelector('span').textContent;
      btnShareDemo.querySelector('span').textContent = currentLang === 'tr' ? 'Kopyalandı!' : 'Copied!';
      setTimeout(() => {
        btnShareDemo.querySelector('span').textContent = prevText;
      }, 1500);
    }
  });

  // ==========================================================================
  // 7. DEEP DIVE MODAL SHEET
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
  // 8. FAQ ACCORDION
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
  // 9. WAITLIST FORM SUBMISSION
  // ==========================================================================
  const waitlistForm = document.getElementById('waitlist-form');
  const waitlistEmail = document.getElementById('waitlist-email');
  const waitlistSubmitBtn = document.getElementById('waitlist-submit-btn');

  waitlistForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const email = waitlistEmail.value.trim();
    if (!email || !email.includes('@')) return;

    waitlistSubmitBtn.disabled = true;
    waitlistSubmitBtn.textContent = currentLang === 'tr' ? 'Alındı! 🍣' : 'Joined! 🍣';

    // Store in localStorage
    try {
      const list = JSON.parse(localStorage.getItem('omakase_waitlist') || '[]');
      list.push({ email, date: new Date().toISOString() });
      localStorage.setItem('omakase_waitlist', JSON.stringify(list));
    } catch (err) {}

    setTimeout(() => {
      waitlistEmail.value = '';
      waitlistSubmitBtn.disabled = false;
      waitlistSubmitBtn.textContent = translations[currentLang]['cta.joinBtn'];
      alert(currentLang === 'tr' 
        ? `Teşekkürler! (${email}) TestFlight beta davet listenize eklendi.` 
        : `Thank you! (${email}) has been added to our TestFlight invitation queue.`);
    }, 600);
  });

  // ==========================================================================
  // 10. MOBILE DRAWER NAVIGATION
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
  // 11. INITIALIZATION
  // ==========================================================================
  applyTheme(currentTheme);
  applyLanguage(currentLang);
  renderSimulatorPost(currentTopic, false);
});
