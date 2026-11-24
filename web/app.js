/**
 * OMAKASE — OFFICIAL WEB APPLICATION LOGIC
 * Features:
 * - Dark/Light Mode Sync (Paper & OLED Black)
 * - Dual Language (TR / EN)
 * - Interactive iPhone 4-Screen Showcase (Feed, 2x6 Bento, Community, Profile) + 3-Tab Native Bar
 * - 12-Category Bento Simulator with Subtopic Pills, Letterboxd Diary Mode, SSE Typewriter & Top 3px Cooldown Bar
 * - Deep Dive Sheet Reader, #F5F0E8 Paper ShareCardView Modal, FAQ Accordion, and Waitlist Feedback
 */

document.addEventListener('DOMContentLoaded', () => {
  // ==========================================================================
  // 1. LOCALIZATION DICTIONARY (TR & EN)
  // ==========================================================================
  const translations = {
    tr: {
      "nav.screenshots": "Ekran Görüntüleri",
      "shots.tag": "Uygulamadan Kareler",
      "shots.title": "Tek dokunuşta fun-fact. Postu AI anlık üretir.",
      "shots.desc": "Kaynağını da verir. Kategorini aç, ilgini çeken alt konuya dokun, derine in.",
      "shots.l1": "Algoritmayı değil, zihnini besle",
      "shots.l2": "Fun-fact + kaynak",
      "shots.l3": "Alt konular",
      "shots.l4": "Derin İnceleme",
      "shots.l5": "Okuma molası",
      "shots.l6": "Topluluk",
      "device.feedSource": "Kaynak: Elisabeth Svärdström, Fornvännen — İsveç Eski Eserler Dergisi",
      "device.tag1": "Tarih",
      "device.tag2": "Vikingler",
      "device.tag3": "İstanbul",
      "device.segDiscover": "Keşfet",
      "device.segFollowing": "Takip Edilenler",
      "device.followBtn": "+ Takip et",
      "device.langVal": "7 Dil",
      "demo.sourcePrefix": "Kaynak:",
      "nav.demo": "Canlı Tadım",
      "nav.features": "Özellikler",
      "nav.philosophy": "Felsefe",
      "nav.faq": "SSS",
      "nav.getApp": "İndir",
      "nav.getAppFull": "Uygulamayı İndir",

      "hero.badge": "iOS 17+ • 7 Dil • Kişisel Kültür Akışı",
      "hero.title": "Algoritmayı değil, zihnini besle.",
      "hero.subtitle": "Tek dokunuşta fun-fact. Postu AI anlık üretir, kaynağını da verir. 12 kültür disiplini, okuma süresi molası ve Letterboxd günlüğün — günde 3 ücretsiz lokmayla başla.",
      "hero.appStoreLabel": "App Store",
      "hero.downloadCta": "iOS için İndir",
      "hero.tryDemo": "Canlı Tadımı Dene ↓",
      "hero.meta1": "Tek Dokunuşta Fun-Fact & Kaynak",
      "hero.meta2": "15–25 sn Okuma Molası",
      "hero.meta3": "7 Dil • Letterboxd & Topluluk",

      "device.tabFeed": "Akışım",
      "device.tabBento": "Bento Keşif",
      "device.tabCommunity": "Topluluk",
      "device.tabProfile": "Profil",
      "device.quotaPill": "••• Kalan: 3/3",
      "device.actDive": "İncele",
      "device.feedDate": "Bugün • 09:41",
      "device.feedTitle": "Ayasofya'nın Mermerindeki 1100 Yıllık Viking İmzası",
      "device.feedBody": "İstanbul'da Ayasofya'nın üst mermer galerisine çıkıp korkuluğa yakından baktığınızda, 6. yüzyıl taşının üzerine kazınmış İskandinav rünleri görürsünüz. 1964'te çözülen yazıt tek bir cümle söylüyor: \"Halfdan buradaydı.\" Halfdan, Bizans İmparatoru'nun seçkin Vareg Muhafızları arasında görev yapan bir Viking askeriydi.",
      "device.swipeForBento": "Yeni post için aşağı kaydır",
      "device.backToPost": "Son gönderiye dönmek için dokun",
      "device.bentoHeading": "Kategoriler",
      "device.bentoSub": "Bir kategori seç ve alt konuya dokunarak yeni post üret",
      "device.subFilm": "Kubrick f/0.7 · Kuleşov",
      "device.subMusic": "Röntgen Plak · Köln Piyano",
      "device.subSci": "Oklo Reaktörü · Tardigrad",
      "device.subFood": "Garum · 1814 Bira Tufanı",
      "device.subHist": "1518 Dans Vebası · Voynich",
      "device.subTech": "Apollo İp RAM · Lav Lambası",
      "device.inputPlaceholder": "Kendi konunu yaz veya ilgi ekle…",
      "device.communitySearch": "Kişi (@kullanıcı) veya gönderi ara…",
      "device.shared1Title": "Miles Davis ve Kind of Blue'nun Modal Sessizliği",
      "device.shared1Body": "1959 ilkbaharında Miles Davis, stüdyoya giren Bill Evans ve John Coltrane'e geleneksel akor şemaları yerine sadece birkaç mod notasından ibaret kağıtlar verdi…",
      "device.shared2Title": "Oklo: 2 Milyar Yıllık Doğal Nükleer Reaktör",
      "device.followers": "Takipçi",
      "device.following": "Takip",
      "device.savedPosts": "Kaydedilmiş Gönderiler",
      "device.langRow": "Dil",
      "device.themeRow": "Görünüm",
      "device.themeVal": "Mürekkep & Kağıt",

      "demo.tag": "İnteraktif Deneyim",
      "demo.title": "Canlı Şef Tadımı",
      "demo.desc": "12 kültür disiplininden birini seçin, ezber bozan alt konulara dokunun ve şefin sizin için gerçek zamanlı mikro-hikaye hazırlamasını deneyimleyin.",
      "demo.bentoTitle": "2×6 Bento Keşif Matrisi",
      "demo.bentoSub": "12 ana kültür disiplininden birine dokunun:",
      "demo.subtopicsLabel": "Alt Konular (Tavşan Delikleri)",
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
      "action.export": "Dışa Aktar",
      "action.save": "Kaydet",
      "action.deepdive": "Derin İncele",

      "shareModal.heading": "Paylaşım Kartı Önizlemesi (1080 × 1350)",

      "features.tag": "Sistem Mimarisi",
      "features.title": "Tek Dokunuş, Altı Güzel Detay",
      "features.desc": "Algoritmayı değil, zihnini besleyen; sonsuz akış ve boş sohbet kutusu arasında kalmayan okuma deneyimi.",
      "features.f1Title": "Kategorini aç, alt konuya dokun",
      "features.f1Desc": "12 disiplin; her birinde yenilenebilen ilgi çekici alt konular. Kategorini aç, seni heyecanlandıran konuya dokun.",
      "features.f2Title": "Okuma süresi kadar beklenir",
      "features.f2Desc": "Post'u okurken üstteki ince çubuk kayar; 15–25 sn'lik mola okuyup sindirmen içindir.",
      "features.f3Title": "Fun-fact, kaynak ve Derin İnceleme",
      "features.f3Desc": "Postu AI anlık üretir ve birincil kaynağını (Kaynak:) verir. İlgini çektiyse tek dokunuşla derine inebilirsin.",
      "features.f4Title": "Kültürel lokmaları paylaş",
      "features.f4Desc": "Tattığın kültürel lokmayı arkadaşlarınla paylaş. Başkalarının denk geldiği lokmaları da tat: Keşfet, takip et, beğen, yorumla.",
      "features.f5Title": "Letterboxd Günlüğü Bağlantısı",
      "features.f5Desc": "Şifre vermeden kullanıcı adını yaz, son 50 filmin bağlansın. İzlediğin filmlerin kamera arkası yapım hikayelerini oku.",
      "features.f6Title": "Kağıt Paylaşım Kartı & Arşiv",
      "features.f6Desc": "Beğendiğin yazıları 1080×1350 kağıt kart olarak dışa aktar veya 12 kategorilik çevrimdışı arşivine kaydet.",

      "phil.tag": "Felsefemiz",
      "phil.title": "Şefe Güvenmek",
      "phil.desc": "Japon mutfağında 'Omakase', seçimi şefe bırakmak demektir. Biz de sonu gelmeyen akışı değil, az ve öz tadımlık kültürü benimsedik.",
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
      "faq.a1": "Omakase, 12 ana kültür kategorisinden seçtiğiniz hiper-spesifik alt konuları, kendi yazdığınız özel başlıkları veya Letterboxd günlüğünüzü Google Cloud Run ve Gemini 3.5 Flash modelleriyle gerçek zamanlı olarak doğrulanmış, derinlikli mikro-hikayelere dönüştüren yerel bir iOS uygulamasıdır.",
      "faq.q2": "Okuma süresi sayacı (Reading Cooldown) neden var?",
      "faq.a2": "Sosyal medya akışları metinleri okumadan saniyede bir kaydırma alışkanlığı yaratır. Omakase, metin uzunluğuna göre 15–25 saniye sindirme süresi uygulayarak içeriği gerçekten okuyup hazmetmenizi sağlar.",
      "faq.q3": "İçeriklerin doğruluğu nasıl korunuyor?",
      "faq.a3": "Arka uç mimarimiz, katı doğruluk kuralları ve çok katmanlı moderasyon filtreleriyle kurgusal uydurmaları engeller; yüzeysel özetler yerine belgelenmiş tarihsel kayıtlara, bilimsel çalışmalara ve birincil kaynaklara odaklanır.",
      "faq.q4": "Letterboxd entegrasyonu nasıl çalışır?",
      "faq.a4": "Film kategorisindeki Letterboxd kartına veya Profil sekmesine sadece kullanıcı adınızı girmeniz yeterlidir; şifreniz asla istenmez. Uygulama herkese açık RSS günlüğünüzden son 50 filminizi okur ve her dokunuşta izlediğiniz bir filmin belgelenmiş kamera arkası prodüksiyon hikayesini üretir.",
      "faq.q5": "Topluluk ve koleksiyon özelliklerinde neler var?",
      "faq.a5": "Beğendiğiniz bir şef yazısını @kullanıcı_adı profilinizle topluluk akışında paylaşabilir, #F5F0E8 kağıt tasarımlı görsel kart olarak dışa aktarabilir veya 12 kategoriye göre otomatik düzenlenen çevrimdışı koleksiyonlarınıza kaydedebilirsiniz.",
      "faq.q6": "Veri gizliliği ve hesap güvenliği nasıl sağlanıyor?",
      "faq.a6": "Omakase reklam göstermez, uygulamalar arası takip (IDFA) yapmaz ve verilerinizi üçüncü taraflara satmaz. Sign in with Apple desteği sunar ve dilediğiniz an Profil sekmesinden hesabınızı ve tüm verilerinizi tek dokunuşla kalıcı olarak silmenize olanak tanır.",

      "cta.title": "Günün Menüsü Hazır",
      "cta.desc": "iOS 17+ için ücretsiz indir. Günde 3 ücretsiz post + 1 Derin İnceleme; dilediğinde Pro ile sınırları kaldır.",
      "cta.joinBtn": "TestFlight'a Katıl",

      "footer.privacy": "Gizlilik Politikası",
      "footer.terms": "Kullanım Koşulları",
      "footer.contact": "İletişim",
      "footer.copy": "© 2026 Omakase. Mürekkep ve kağıt sadeliğiyle iOS için tasarlandı."
    },

    en: {
      "nav.screenshots": "Screenshots",
      "shots.tag": "From the App",
      "shots.title": "Fun-facts in one tap. AI crafts each post live.",
      "shots.desc": "Always with its source. Open any discipline, tap the subtopic that sparks you, dive deeper.",
      "shots.l1": "Feed your mind, not the algorithm",
      "shots.l2": "Fun-fact + source",
      "shots.l3": "Subtopics",
      "shots.l4": "Deep Dive",
      "shots.l5": "Reading pause",
      "shots.l6": "Community",
      "device.feedSource": "Source: L. W. B. Brockliss, The University of Oxford: A History",
      "device.tag1": "History",
      "device.tag2": "Timelines",
      "device.tag3": "Culture",
      "device.segDiscover": "Discover",
      "device.segFollowing": "Following",
      "device.followBtn": "+ Follow",
      "device.langVal": "7 Languages",
      "demo.sourcePrefix": "Source:",
      "nav.demo": "Live Tasting",
      "nav.features": "Features",
      "nav.philosophy": "Philosophy",
      "nav.faq": "FAQ",
      "nav.getApp": "Get App",
      "nav.getAppFull": "Download the App",

      "hero.badge": "iOS 17+ • 7 Languages • Personal Culture Feed",
      "hero.title": "Feed your mind, not the algorithm.",
      "hero.subtitle": "Fun-facts in one tap. AI crafts each post live, always with its source. 12 disciplines, a reading pause and your Letterboxd diary — start with 3 free bites a day.",
      "hero.appStoreLabel": "App Store",
      "hero.downloadCta": "Download for iOS",
      "hero.tryDemo": "Try Live Tasting ↓",
      "hero.meta1": "One-Tap Fun-Facts & Sources",
      "hero.meta2": "15–25s Reading Pause",
      "hero.meta3": "7 Languages • Letterboxd & Community",

      "device.tabFeed": "My Feed",
      "device.tabBento": "Bento Box",
      "device.tabCommunity": "Community",
      "device.tabProfile": "Profile",
      "device.quotaPill": "••• 3/3 Left",
      "device.actDive": "Dive",
      "device.feedDate": "Today • 09:41",
      "device.feedTitle": "Oxford University Is Older Than the Aztec Empire",
      "device.feedBody": "Lectures were already echoing through Oxford by 1096, and the university had formal colleges by 1249—more than two centuries before the Aztecs founded Tenochtitlan in 1325. History's timelines overlap in ways school textbooks rarely make feel real.",
      "device.swipeForBento": "Scroll down for a new post",
      "device.backToPost": "Tap to return to last post",
      "device.bentoHeading": "Categories",
      "device.bentoSub": "Select a category and tap a subtopic to craft a new post",
      "device.subFilm": "Kubrick f/0.7 · Kuleshov",
      "device.subMusic": "X-Ray Records · Köln Piano",
      "device.subSci": "Oklo Reactor · Tardigrades",
      "device.subFood": "Garum · 1814 Beer Flood",
      "device.subHist": "1518 Dancing Plague · Voynich",
      "device.subTech": "Apollo Rope RAM · Lava Lamps",
      "device.inputPlaceholder": "Type a custom topic or add taste…",
      "device.communitySearch": "Search people (@username) or posts…",
      "device.shared1Title": "Miles Davis and the Modal Silence of Kind of Blue",
      "device.shared1Body": "In the spring of 1959, Miles Davis handed Bill Evans and John Coltrane scraps of paper containing modal scales rather than traditional chord changes…",
      "device.shared2Title": "Oklo: The 2-Billion-Year-Old Natural Nuclear Reactor",
      "device.followers": "Followers",
      "device.following": "Following",
      "device.savedPosts": "Saved Posts",
      "device.langRow": "Language",
      "device.themeRow": "Appearance",
      "device.themeVal": "Ink & Paper",

      "demo.tag": "Interactive Experience",
      "demo.title": "Live Chef Tasting",
      "demo.desc": "Pick one of the 12 cultural disciplines, tap a rabbit-hole subtopic, and watch the chef craft an instant micro-story in your browser.",
      "demo.bentoTitle": "2×6 Bento Discovery Matrix",
      "demo.bentoSub": "Tap one of the 12 core disciplines:",
      "demo.subtopicsLabel": "Subtopics (Rabbit Holes)",
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
      "action.export": "Export",
      "action.save": "Save",
      "action.deepdive": "Deep Dive",

      "shareModal.heading": "Share Card Preview (1080 × 1350)",

      "features.tag": "System Architecture",
      "features.title": "One Tap, Six Lovely Details",
      "features.desc": "Feed your mind, not the algorithm — a reading rhythm without endless feeds or blank chatbot prompts.",
      "features.f1Title": "Open a discipline, tap a subtopic",
      "features.f1Desc": "12 disciplines, each with refreshable subtopics. Open any one and tap what sparks you.",
      "features.f2Title": "A brief pause to read",
      "features.f2Desc": "A thin bar slides across the top while you read the current post. A 15–25s pause so every bite sinks in.",
      "features.f3Title": "Fun-facts, sources & Deep Dive",
      "features.f3Desc": "AI crafts each post live and always cites its primary source. Caught your interest? Dive deeper in one tap.",
      "features.f4Title": "Share the cultural bites",
      "features.f4Desc": "Share the cultural bites you loved with friends. Taste what others discovered too: Discover, follow, like, comment.",
      "features.f5Title": "Letterboxd Diary Synthesis",
      "features.f5Desc": "Enter your handle with zero passwords to pull your last 50 watched films and read verified behind-the-scenes stories.",
      "features.f6Title": "Paper Share Card & Offline Archive",
      "features.f6Desc": "Export stories as crisp 1080×1350 paper cards or save them into 12 offline category collections.",

      "phil.tag": "Our Philosophy",
      "phil.title": "Trust the Chef",
      "phil.desc": "In Japanese dining, 'Omakase' means leaving the menu to the chef. We replaced the endless scroll with focused, thoughtful daily posts.",
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
      "faq.a1": "Omakase is a native iOS app that transforms your chosen hyper-specific subtopics across 12 cultural disciplines, custom topics, or your Letterboxd diary into verified, real-time micro-stories powered by Google Cloud Run and Gemini 3.5 Flash.",
      "faq.q2": "Why is there a reading cooldown timer?",
      "faq.a2": "Conventional social feeds condition users to swipe in fractions of a second without absorbing anything. Omakase enforces a 15–25 second digestion window so every story is genuinely read.",
      "faq.q3": "How is factual accuracy maintained?",
      "faq.a3": "Our backend uses strict factual grounding rules and a multi-layer moderation pipeline to prevent fabrication, prioritizing documented historical records, peer-reviewed research, and primary sources.",
      "faq.q4": "How does the Letterboxd integration work?",
      "faq.a4": "Simply enter your Letterboxd handle in the Film Bento card or Profile tab—no password required. Omakase reads your public RSS diary of 50 recent films and generates verified behind-the-scenes production trivia from a randomly locked film.",
      "faq.q5": "What can I do with Community & Collections?",
      "faq.a5": "Share favorite stories to the Community timeline under your @username handle, export 1080×1350 #F5F0E8 paper cards, or bookmark posts into 12 automatically categorized offline collections.",
      "faq.q6": "How are privacy and account security handled?",
      "faq.a6": "Omakase displays zero ads, performs zero cross-app tracking (IDFA), and never sells your data. It supports Sign in with Apple and includes one-tap permanent Account Deletion directly in the Profile tab.",

      "cta.title": "Today's Menu Is Ready",
      "cta.desc": "Download free for iOS 17+. 3 free posts + 1 Deep Dive a day; go Pro anytime to remove the limits.",
      "cta.joinBtn": "Join TestFlight",

      "footer.privacy": "Privacy Policy",
      "footer.terms": "Terms of Use",
      "footer.contact": "Contact",
      "footer.copy": "© 2026 Omakase. Crafted for iOS with ink-and-paper simplicity."
    }
  };

  // ==========================================================================
  // 2. 12-CATEGORY SIMULATOR DATABASE (Match InterestCategory.swift Rabbit Holes)
  // ==========================================================================
  const stories = {
    film: {
      tr: {
        subtopics: ["70mm IMAX Şerit Fiziği", "Kubrick'in NASA f/0.7 Lensi", "Kuleşov Etkisi Deneyi", "🎬 Letterboxd Günlüğü"],
        title: "Oppenheimer ve IMAX 70mm'nin Görsel Ağırlığı",
        date: "Bugün • 20:17",
        body: "Christopher Nolan, Oppenheimer'ı çekerken 65mm IMAX siyah-beyaz filmi dünyada ilk kez Kodak'a özel olarak ürettirdi. Standart IMAX projektörleri bu 18 kilometrelik, 272 kiloluk devasa makarayı çevirirken platoda duyulan mekanik ses, sahnenin kendisinden bile daha hipnotize ediciydi. Nolan'a göre bu bir nostalji değil; izleyicinin göz bebeklerine kadar uzanan somut bir gerçeklik arayışıydı.",
        tags: ["Film", "ChristopherNolan", "Imax70Mm"],
        deepDiveTitle: "Derin İnceleme: Kodak 65mm Siyah-Beyaz Emülsiyonu",
        deepDiveBody: "IMAX formatında daha önce hiç 65mm siyah-beyaz film şeridi üretilmemişti. Kodak mühendisleri Nolan ve görüntü yönetmeni Hoyte van Hoytema'nın talebiyle fotokimyasal gren yapısını sıfırdan tasarladı. Film şeridinin kalınlığı standart filmlere göre daha farklıydı; kameraların vakumlu mekanizmaları bu şeridi taşırken yeniden kalibre edildi. Ortaya çıkan görüntü, dijital sensörlerin ulaşamayacağı organik bir ışık derinliği sundu.",
        variants: {
          1: {
            title: "Stanley Kubrick ve NASA'nın Mum Işığı Lensi (f/0.7)",
            body: "Stanley Kubrick, 1975 yapımı Barry Lyndon'da 18. yüzyıl saraylarını yapay set ışıkları olmadan, yalnızca gerçek balmumu mumlarıyla çekmek istedi. Bunun için NASA'nın Apollo görevlerinde Ay'ın karanlık yüzünü fotoğraflamak için Carl Zeiss'a ürettirdiği 50mm f/0.7 lensleri satın aldı. Alan derinliği o kadar inceydi ki oyuncular birkaç santim kıpırdasa netlik kayboluyordu.",
            tags: ["Film", "StanleyKubrick", "CarlZeiss"],
            deepDiveTitle: "Derin İnceleme: Zeiss Planar 50mm f/0.7 Modifikasyonu",
            deepDiveBody: "Dünyada yalnızca 10 adet üretilen Zeiss 50mm f/0.7 lensleri aslında fotoğraf kameraları içindi. Kubrick, mühendis Ed DiGiulio ile çalışarak Mitchell BNC sinema kamerasının gövdesini freze makinesiyle oyup lensin arka elemanını film şeridine sadece 4 milimetre kalacak şekilde yerleştirdi."
          },
          3: {
            title: "Letterboxd Sentezi: Chungking Express (1994) ve Gerilla Kamerası",
            body: "Wong Kar-wai, Ashes of Time'ın kurgu stresinden kaçmak için Hong Kong sokaklarında senaryosuz ve ruhsatsız bir ara proje olarak Chungking Express'i sadece 23 günde çekti. Görüntü yönetmeni Christopher Doyle, kalabalık Chungking Mansions koridorlarında saniyede 8 kare (step-printing) tekniği kullanarak aşıkların yalnızlığını bulanık bir zaman akışının ortasında dondurdu.",
            tags: ["Film", "Letterboxd", "WongKarWai"],
            deepDiveTitle: "Derin İnceleme: Step-Printing ve 10.000 Kutu Ananas",
            deepDiveBody: "Filmde deklanşör hızı düşürülüp kareler optik yazıcıda çoğaltılarak (step-printing) arka plandaki Hong Kong kalabalığı soyut bir boya darbesine dönüştürüldü. Bu teknik, karakterlerin içsel hızıyla şehrin mekanik hızı arasındaki kopukluğu sinema tarihinin en ikonik görsel imzalarından biri haline getirdi."
          }
        }
      },
      en: {
        subtopics: ["70mm IMAX Film Grain", "Kubrick's NASA f/0.7 Lenses", "Kuleshov Effect Mechanics", "🎬 Letterboxd Diary"],
        title: "Oppenheimer and the Physical Gravity of IMAX 70mm",
        date: "Today • 8:17 PM",
        body: "Christopher Nolan commissioned Kodak to engineer 65mm IMAX black-and-white film for the very first time in cinema history. As the projector spooled the 11-mile, 600-pound platter, the mechanical whirr on set was as hypnotic as the imagery. For Nolan, this was not mere nostalgia; it was an uncompromising quest for tangible optical presence.",
        tags: ["Film", "ChristopherNolan", "Imax70Mm"],
        deepDiveTitle: "Deep Dive: Kodak's 65mm Monochrome Chemistry",
        deepDiveBody: "Before Oppenheimer, 65mm black-and-white film emulsion simply did not exist for IMAX cameras. Kodak photo-chemists formulated a high-contrast silver halide grain capable of withstanding the vacuum-pressure feed of IMAX transport mechanisms, rendering micro-expressions with an analog density unattainable by digital sensors.",
        variants: {
          1: {
            title: "Stanley Kubrick and NASA's f/0.7 Candlelight Lenses",
            body: "To shoot 1975's Barry Lyndon entirely by authentic beeswax candlelight, Stanley Kubrick acquired three Carl Zeiss 50mm f/0.7 lenses originally commissioned by NASA to photograph the far side of the Moon. The depth of field was razor-thin—actors had to stay within millimeters of their marks or dissolve into blur.",
            tags: ["Film", "StanleyKubrick", "CarlZeiss"],
            deepDiveTitle: "Deep Dive: Milling the Mitchell BNC Camera Mount",
            deepDiveBody: "Only ten Zeiss 50mm f/0.7 lenses were ever manufactured. Engineer Ed DiGiulio physically milled out the metal mount of Kubrick's Mitchell BNC cinema camera so the rear lens element sat just four millimeters from the spinning film plane."
          },
          3: {
            title: "Letterboxd Diary: Chungking Express (1994) Step-Printing",
            body: "During a two-month editing break on Ashes of Time, Wong Kar-wai shot Chungking Express guerrilla-style in 23 days without permits. Cinematographer Christopher Doyle dropped the shutter speed to 8 frames per second and duplicated frames in post, turning the neon rush of Hong Kong into painterly streaks around solitary lovers.",
            tags: ["Film", "Letterboxd", "WongKarWai"],
            deepDiveTitle: "Deep Dive: Step-Printing and Urban Solitude",
            deepDiveBody: "By shooting at slow frame rates and step-printing every frame back to 24fps, Doyle and Wong separated the emotional tempo of their protagonists from the frantic mechanical velocity of 1994 Kowloon."
          }
        }
      }
    },

    science: {
      tr: {
        subtopics: ["Oklo Doğal Nükleer Reaktörü", "Tardigrad Camsı Kriptobiyozu", "97 Yıllık Zift Damlası", "Kuşlarda Kuantum Pusulası"],
        title: "Oklo: İki Milyar Yıl Önce Çalışan Doğal Nükleer Reaktör",
        date: "Bugün • 14:32",
        body: "1972'de Fransız fizikçi Francis Perrin, Gabon'daki Oklo madeninden gelen uranyum cevherinde doğada her yerde sabit olan U-235 oranının beklenenden düşük olduğunu fark etti. İncelemeler şaşırtıcı bir gerçeği ortaya çıkardı: 2 milyar yıl önce yeraltı sularının nötron yavaşlatıcı görevi görmesiyle Oklo'da kendi kendine başlayan doğal bir nükleer fisyon reaktörü yüz binlerce yıl boyunca çalışmıştı.",
        tags: ["Bilim", "NükleerFizik", "Jeoloji"],
        deepDiveTitle: "Derin İnceleme: Yeraltı Suyu Geri Besleme Döngüsü",
        deepDiveBody: "Oklo'daki doğal reaktörün patlamadan yüz binlerce yıl düzenli çalışabilmesinin sırrı, yeraltı suyunun doğal bir termostat gibi davranmasıydı. Fisyon hızlandığında su kaynayıp buharlaşıyor, nötronları yavaşlatacak su kalmayınca reaksiyon kendiliğinden duruyordu. Kayaçlar soğuyup su tekrar dolduğunda reaktör yeniden devreye giriyordu."
      },
      en: {
        subtopics: ["Oklo Natural Nuclear Reactor", "Tardigrade Glass Vitrification", "97-Year Pitch Drop Funnel", "Avian Quantum Compass"],
        title: "Oklo: The 2-Billion-Year-Old Natural Nuclear Reactor",
        date: "Today • 2:32 PM",
        body: "In 1972, French physicists analyzing uranium ore from Oklo, Gabon noticed a missing fraction of fissile U-235—a ratio that should be uniform across the solar system. The explanation stunned nuclear science: two billion years ago, groundwater infiltrated rich uranium veins, acting as a neutron moderator and sustaining a natural nuclear fission reactor for hundreds of thousands of years.",
        tags: ["Science", "NuclearPhysics", "Oklo"],
        deepDiveTitle: "Deep Dive: Hydrothermal Self-Regulating Geysers",
        deepDiveBody: "Oklo never suffered a runaway meltdown because groundwater acted as a negative feedback thermostat. Every three hours, fission heat boiled away the water, halting neutron moderation until the rock cooled and fresh water seeped back in."
      }
    },

    philosophy: {
      tr: {
        subtopics: ["Theseus'un Gemisi Paradoksu", "Mary'nin Siyah-Beyaz Odası", "Searle'ün Çince Odası", "Seneca ve Zaman Muhasebesi"],
        title: "Seneca'nın Zaman Muhasebesi ve Hayatın Kısalığı",
        date: "Bugün • 09:15",
        body: "Roma'nın en etkili düşünürlerinden Seneca, mülkünü birine kaptıranların çıkardığı yaygarayla günlerini başkalarına dağıtanların kayıtsızlığını kıyaslar. Hayat kısa değildir; biz onu fazlasıyla savurganca harcarız. Sahte meşguliyetler, insanın kendi zihniyle baş başa kalma korkusunun en zarif maskesidir.",
        tags: ["Felsefe", "Stoacılık", "Seneca"],
        deepDiveTitle: "Derin İnceleme: De Brevitate Vitae ve Otium Kavramı",
        deepDiveBody: "Seneca 'De Brevitate Vitae' (Hayatın Kısalığı Üzerine) risalesinde zamanı geri kazanılamaz tek varlık olarak tanımlar. Antik Roma'da 'otium' (bilinçli dinginlik), tembellik değil; geçmişin bilgeleriyle okuma ve tefekkür yoluyla kurulan zamansız dostluktur."
      },
      en: {
        subtopics: ["Ship of Theseus Paradox", "Mary's Black-and-White Room", "Searle's Chinese Room", "Seneca's Audit of Hours"],
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
        subtopics: ["Sovyet Röntgen Plakları", "Bozuk Köln Konser Piyanosu", "Stradivarius Buzul Çağı Ağacı", "Amen Break: 6 Saniyelik Loop"],
        title: "Sovyet Röntgen Plakları: Kemikler Üzerindeki Caz",
        date: "Bugün • 23:40",
        body: "1950'lerde Sovyetler Birliği'nde Batı cazı ve rock'n'roll plakları yasaklanınca, Leningradlı yeraltı ses mühendisleri hastanelerin çöpe attığı kullanılmış röntgen filmlerini topladı. Kırık kemik ve kafatası görüntülerinin üzerine el yapımı torna makineleriyle Ella Fitzgerald ve Miles Davis kayıtları kazındı; 'Roentgenizdat' adı verilen bu plaklar müzik tarihinin en sıra dışı direniş nesnesi oldu.",
        tags: ["Müzik", "Roentgenizdat", "CazTarihi"],
        deepDiveTitle: "Derin İnceleme: Kemiklerdeki Müzik (Music on Ribs)",
        deepDiveBody: "Hastaneler yangın tehlikesi nedeniyle röntgen filmlerini yılda bir kez imha etmek zorundaydı. Genç mühendisler bu filmleri makasla daire şeklinde kesip ortasını sigara ateşiyle delerek 78 devirli tek yüzlü plaklara dönüştürdü. Ses kalitesi cızırtılıydı ve sadece 5–10 dinlemeye dayanıyordu ama yasaklı melodileri elden ele dolaştırmaya yetti."
      },
      en: {
        subtopics: ["Soviet Bone X-Ray Records", "Jarrett's Broken Köln Piano", "Stradivarius Ice-Age Wood", "Amen Break 6-Second Loop"],
        title: "Roentgenizdat: Bootleg Jazz Cut into Hospital X-Rays",
        date: "Today • 11:40 PM",
        body: "When Western jazz was banned in the 1950s Soviet Union, underground Leningrad audio bootleggers raided hospital dumpsters for discarded medical X-ray plates. Using homemade lathes, they etched grooves of Miles Davis and Ella Fitzgerald directly across images of fractured ribs and skulls—creating 'Music on Bones.'",
        tags: ["Music", "Roentgenizdat", "JazzHistory"],
        deepDiveTitle: "Deep Dive: Cigarette Center-Holes and 78 RPM Lathes",
        deepDiveBody: "Cut into circles with manicure scissors and punctured in the center with a glowing cigarette tip, these 78 RPM X-ray discs could only survive ten plays before the radiograph emulsion wore thin—yet they carried forbidden rhythms across the Iron Curtain."
      }
    },

    art: {
      tr: {
        subtopics: ["Tadao Ando Işık Tapınağı", "Kintsugi Altın Kırık Onarımı", "Süleymaniye İs Odası Akustiği", "Patentli Yves Klein Mavisi"],
        title: "Tadao Ando ve Işığın Betondaki Tapınağı",
        date: "Bugün • 11:05",
        body: "Osaka'daki Işık Kilisesi'nde Tadao Ando, haçı altın ya da mermerle değil; çıplak beton duvara açtığı dikey ve yatay yarıklardan içeri sızan gün ışığıyla inşa etti. Güneş hareket ettikçe kilisenin içindeki ışık kesişimi yer değiştirir. Ando için mimarlık bir form değil, doğanın mekana bıraktığı gölgedir.",
        tags: ["Sanat", "TadaoAndo", "Mimari"],
        deepDiveTitle: "Derin İnceleme: Japon 'Ma' (Boşluk) Estetiği",
        deepDiveBody: "Ando'nun pürüzsüz ipek betonu, ahşap kalıpların özenle verniklenmesiyle elde edilir. Betonun soğuk endüstriyel dokusu, yarıktan sızan ışığın sıcaklığıyla dengelenir. Bu yaklaşım, Japon estetiğindeki 'Ma' (anlamlı boşluk) kavramının modern mimarideki en saf karşılığıdır."
      },
      en: {
        subtopics: ["Tadao Ando's Concrete Light", "Kintsugi Gold-Seam Repair", "Pantheon Unreinforced Dome", "Patented Yves Klein Blue"],
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
        subtopics: ["Antikythera Dişli Bilgisayarı", "1518 Strazburg Dans Vebası", "Kendini Onaran Roma Betonu", "Çözülemeyen Voynich Yazması"],
        title: "Antikythera Düzeneği: İki Bin Yıllık Analog Bilgisayar",
        date: "Bugün • 16:40",
        body: "1901'de Ege Denizi'ndeki bir Roma batığından çıkarılan paslı bronz kütle, X-ışını tomografisiyle incelendiğinde içinden 30'dan fazla hassas dişli çark çıktı. MÖ 2. yüzyılda yapılan Antikythera düzeneği, güneş ve ay tutulmalarını on yıllar öncesinden hesaplayabilen avuç içi boyutunda bir astronomik bilgisayardı.",
        tags: ["Tarih", "AntikYunan", "Arkeoloji"],
        deepDiveTitle: "Derin İnceleme: Kayıp Helenistik Mühendislik",
        deepDiveBody: "Düzeneğin en çarpıcı parçası, Ay'ın eliptik yörüngesindeki hız değişimini simüle eden 'pim ve yuvalı' epikiklik dişli sistemidir. Bu seviyedeki diferansiyel dişli teknolojisi, Antikythera'dan sonra ancak 14. yüzyıl Avrupa mekanik saatlerinde yeniden ortaya çıkabilmiştir."
      },
      en: {
        subtopics: ["Antikythera Gear Calculus", "1518 Dancing Plague", "Self-Healing Roman Concrete", "Uncracked Voynich Script"],
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
        subtopics: ["Apollo 11 Dokuma İp Belleği", "Cloudflare Lav Lambası Şifresi", "Peçetede Yazılan UTF-8", "ASML Kalay Damlası Lazeri"],
        title: "Apollo 11'i Ay'a İndiren Elle Dokunmuş İp Bellek (LOL Memory)",
        date: "Bugün • 17:10",
        body: "1969'da Apollo 11 Ay yüzeyine inerken rehber bilgisayarın (AGC) yazılımı silikon çiplerde değil, tekstil işçisi kadınların iğnelerle ferit halkaların içinden geçirdiği bakır tellerde saklanıyordu. Tel halkanın içinden geçerse '1', etrafından dolanırsa '0' oluyordu. Kozmik radyasyondan etkilenmeyen bu fiziksel dokuma, insanlığı Ay'a hatasız indirdi.",
        tags: ["Teknoloji", "Apollo11", "BilgisayarTarihi"],
        deepDiveTitle: "Derin İnceleme: Margaret Hamilton ve Core Rope Mimarisi",
        deepDiveBody: "MIT mühendisleri bu belleğe sevgiyle 'LOL (Little Old Lady) Memory' adını vermişti. Fabrika dokumacıları tarafından tek tek elle işlenen 72 kilobyte'lık bu salt okunur bellek, iniş anında radar aşırı yüklenmesine rağmen Margaret Hamilton'ın öncelik tabanlı görev zamanlayıcısı sayesinde çökmeden çalışmaya devam etti."
      },
      en: {
        subtopics: ["Apollo 11 Woven Rope Memory", "Cloudflare Lava Lamp Entropy", "UTF-8 Diner Napkin Design", "ASML Tin-Droplet EUV Plasma"],
        title: "Apollo 11's Hand-Woven Core Rope Memory",
        date: "Today • 5:10 PM",
        body: "When Apollo 11 descended onto the lunar surface in 1969, its guidance software was not stored on silicon chips, but physically woven by textile workers threading copper wires through magnetic ferrite rings. Passing through a ring encoded a '1'; bypassing it encoded a '0'—creating radiation-proof code sewn by hand.",
        tags: ["Tech", "Apollo11", "ComputingHistory"],
        deepDiveTitle: "Deep Dive: Margaret Hamilton and Fault-Tolerant Scheduling",
        deepDiveBody: "Holding just 72 kilobytes of read-only memory, the Apollo Guidance Computer survived a critical radar overload seconds before touchdown because Margaret Hamilton's asynchronous executive shed low-priority tasks and kept thruster calculations alive."
      }
    },

    food: {
      tr: {
        subtopics: ["Edomae Sushi & Kızıl Sirke", "1814 Londra Bira Tufanı", "Garum: Antik Balık Sosu", "1976 Paris Şarap Şoku"],
        title: "Edomae Sushi ve Kusursuz Pirincin (Shari) Dengesi",
        date: "Bugün • 19:05",
        body: "Tokyo'nun geleneksel omakase tezgahlarında bir şefin ustalığı balığın nadirliğiyle değil, 'shari' adı verilen sirkeli pirincin sıcaklığı ve dokusuyla ölçülür. Balık dilimi (neta) ile vücut sıcaklığındaki pirinç ağızda buluştuğunda, tanelerin arasında kalan mikroskobik hava boşlukları lezzetin dağılma hızını belirler.",
        tags: ["Yemek", "JaponMutfağı", "Gastronomi"],
        deepDiveTitle: "Derin İnceleme: Kızıl Sirke (Akazu) ve Edomae Geleneği",
        deepDiveBody: "19. yüzyıl Edo (Tokyo) döneminde buzdolabı yokken şefler, yıllandırılmış sake tortusundan üretilen kızıl sirkeyi (akazu) pirince katarak hem koruyuculuk hem de derin bir umami dengesi elde ettiler. Çırakların balığa dokunmadan önce yıllarca sadece pirinç yıkaması bu yüzdendir."
      },
      en: {
        subtopics: ["Edomae Sushi & Red Vinegar", "1814 London Beer Flood", "Garum Roman Fish Sauce", "1976 Paris Blind Wine Shock"],
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
        subtopics: ["Ormanların Mantar İnterneti", "Ağaçlarda Taç Utangaçlığı", "4700 Derece Karides Yumruğu", "120 Yılda Açan Bambular"],
        title: "Ormanın Yeraltı Ağı: Mikorizal İletişim",
        date: "Bugün • 13:20",
        body: "Bir ormanda yürürken gördüğünüz ağaçlar birbirinden bağımsız sütunlar değildir; toprak altında kilometrelerce uzanan mikorizal mantar iplikçikleriyle (hif) birbirine bağlıdır. Yaşlı 'anne ağaçlar', gölgede kalan genç fidelerin köklerine bu yeraltı ağından karbon, azot ve savunma sinyalleri gönderir.",
        tags: ["Doğa", "Ekoloji", "Mikoriza"],
        deepDiveTitle: "Derin İnceleme: Suzanne Simard ve Karbon Paylaşımı",
        deepDiveBody: "Orman ekologu Suzanne Simard, radyoaktif karbon izotopları kullanarak köknar ve huş ağaçlarının mevsimlere göre birbirine besin aktardığını kanıtladı. Yazın yapraklı huş ağacı gölgedeki köknara karbon gönderirken, kışın yaprak dökmeyen köknar borcunu geri öder."
      },
      en: {
        subtopics: ["Mycorrhizal Wood Wide Web", "Crown Shyness Canopy Gaps", "Pistol Shrimp 4,700°C Snap", "120-Year Bamboo Flowering"],
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
        subtopics: ["Kyoto 120 Yosun Tapınağı", "Derinkuyu 18 Katlı Yeraltı", "Svalbard Tohum Kemeri", "Kowloon Duvarlı Şehri"],
        title: "Kyoto'da Saiho-ji: 120 Yosun Türünün Sessizliği",
        date: "Bugün • 10:15",
        body: "Kyoto'nun batısındaki Saiho-ji (Yosun Tapınağı) bahçesine girmeden önce ziyaretçiler sessizce fırça kaligrafisiyle sutralar kopyalar. Dışarı adım attığınızda sizi çiçekler değil, zemini zümrüt bir halı gibi kaplayan 120 farklı yosun türü karşılar. Yağmur sonrası yosunların emdiği ses, bahçeyi mutlak bir akustik sığınağa dönüştürür.",
        tags: ["Seyahat", "Kyoto", "JaponBahçesi"],
        deepDiveTitle: "Derin İnceleme: Muso Soseki ve Wabi-Sabi Peyzajı",
        deepDiveBody: "1339'da Zen ustası Muso Soseki tarafından yeniden düzenlenen bahçe, başlangıçta beyaz kumlarla kaplıydı. Yüzyıllar içinde Kyoto'nun nemli iklimi ve seller bahçeyi yosunlarla örttü; Japon estetiği bu doğa müdahalesini temizlemek yerine 'wabi-sabi' (zamanın bıraktığı kusurlu güzellik) olarak kutsadı."
      },
      en: {
        subtopics: ["Kyoto's 120-Moss Sanctuary", "Derinkuyu 18-Level Subterranean", "Svalbard Seed Vault", "Kowloon Walled City Density"],
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
        subtopics: ["Johan Cruyff Mekan Geometrisi", "Brabham Fanlı F1 Aracı", "Fosbury Sırtüstü Atlama", "Barkley Kitap Sayfası Maratonu"],
        title: "Johan Cruyff ve Futbolda 'Mekan' Kavramının İcadı",
        date: "Bugün • 21:00",
        body: "Johan Cruyff için futbol topla oynanan fiziksel bir koşu yarışı değil, zamana ve mekana hükmetme geometrisiydi. 'Top sende değilken ne yaptığın, sahanın büyüklüğünü belirler' derdi. Hücum ederken sahayı olabildiğince genişletmek, top kaybedildiğinde ise saniyeler içinde daraltmak modern futbolun temel aksiyomu oldu.",
        tags: ["Spor", "FutbolTaktikleri", "JohanCruyff"],
        deepDiveTitle: "Derin İnceleme: Total Futbol ve Pozisyonel Oyun",
        deepDiveBody: "Rinus Michels ve Cruyff'un Ajax ile geliştirdiği Total Futbol, sabit mevki kavramını yıktı. Bir bek ileri çıktığında bir orta saha oyuncusu onun bıraktığı boşluğu dolduruyor; böylece takım şeklini kaybetmeden saha üzerindeki üçgenleri sürekli yeniden kuruyordu."
      },
      en: {
        subtopics: ["Johan Cruyff Pitch Geometry", "Brabham BT46B Fan Car", "Fosbury Flop High-Jump", "Barkley Book-Page Checkpoints"],
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
        subtopics: ["Shadow of the Colossus Eksiltme", "Quake 0x5f3759df Karekök Kodu", "Outer Wilds 22 Dakika Döngüsü", "Silent Hill Sis Hilesi"],
        title: "Shadow of the Colossus ve Eksiltmeyle Kurulan Dünya",
        date: "Bugün • 22:15",
        body: "Fumito Ueda, Shadow of the Colossus'u tasarlarken 'eksiltme yoluyla tasarım' (design by subtraction) adını verdiği bir yöntem uyguladı. Geleneksel oyunlardaki zindanları, küçük düşmanları ve kalabalık kasabaları tamamen sildi. Geriye sadece rüzgarlı uçsuz bucaksız bir yasak toprak, atınız ve 16 devasa varlıkla yüzleşmenin melankolisi kaldı.",
        tags: ["Oyun", "OyunTasarımı", "FumitoUeda"],
        deepDiveTitle: "Derin İnceleme: Eksiltme Yoluyla Tasarım (Design by Subtraction)",
        deepDiveBody: "Ueda'ya göre bir oyunun duygusal ağırlığı ekrana eklenen sistemlerle değil, ana temayla ilgisi olmayan her şeyin çıkarılmasıyla artar. Boş arazide dakikalarca sadece rüzgar ve nal sesi dinleyerek yolculuk etmek, karşılaşma anının dramatik etkisini katbekat büyütür."
      },
      en: {
        subtopics: ["Shadow of the Colossus Subtraction", "Quake III 0x5f3759df Math", "Outer Wilds 22-Minute Loop", "Silent Hill Distance Fog"],
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
  const sunIcon = themeToggleBtn ? themeToggleBtn.querySelector('.sun-icon') : null;
  const moonIcon = themeToggleBtn ? themeToggleBtn.querySelector('.moon-icon') : null;
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
  const btnExportCard = document.getElementById('btn-export-card');
  const btnBookmarkDemo = document.getElementById('btn-bookmark-demo');
  const btnOpenDeepDive = document.getElementById('btn-open-deep-dive');

  // Hero device interactive buttons
  const heroBtnDive = document.getElementById('hero-btn-dive');
  const heroBtnExport = document.getElementById('hero-btn-export');

  // Deep Dive Modal elements
  const deepDiveModal = document.getElementById('deep-dive-modal');
  const modalTitle = document.getElementById('modal-title');
  const modalBody = document.getElementById('modal-body');
  const btnCloseModal = document.getElementById('btn-close-modal');

  // Share Card Modal elements (#F5F0E8 Paper Card)
  const shareCardModal = document.getElementById('share-card-modal');
  const btnCloseShareModal = document.getElementById('btn-close-share-modal');
  const paperCardTitle = document.getElementById('paper-card-title');
  const paperCardText = document.getElementById('paper-card-text');
  const paperCardTags = document.getElementById('paper-card-tags');
  const paperCardDate = document.getElementById('paper-card-date');

  // ==========================================================================
  // 4. THEME CONTROLLER
  // ==========================================================================
  function applyTheme(theme) {
    currentTheme = theme;
    htmlEl.setAttribute('data-theme', theme);
    localStorage.setItem('omakase_theme', theme);

    if (sunIcon && moonIcon) {
      if (theme === 'dark') {
        sunIcon.style.display = 'block';
        moonIcon.style.display = 'none';
      } else {
        sunIcon.style.display = 'none';
        moonIcon.style.display = 'block';
      }
    }
    if (themeMeta) {
      themeMeta.setAttribute('content', theme === 'dark' ? '#000000' : '#FAFAFA');
    }
  }

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', () => {
      const nextTheme = currentTheme === 'dark' ? 'light' : 'dark';
      applyTheme(nextTheme);
    });
  }

  // ==========================================================================
  // 5. HERO IPHONE SCREEN SWITCHER (FEED / BENTO / COMMUNITY / PROFILE)
  // ==========================================================================
  function switchHeroDeviceScreen(screenKey) {
    document.querySelectorAll('.device-tab-pill').forEach(pill => {
      const active = pill.getAttribute('data-screen') === screenKey;
      pill.classList.toggle('active', active);
      pill.setAttribute('aria-selected', active ? 'true' : 'false');
    });

    // In the real iOS app (MainTabView.swift), Bento is hosted inside "My Feed" (tab 1)
    document.querySelectorAll('.ios-tab-item').forEach(tab => {
      const tabGroup = tab.getAttribute('data-tab-group');
      const isFeedOrBento = (screenKey === 'feed' || screenKey === 'bento') && tabGroup === 'feed-bento';
      const isDirectMatch = tab.getAttribute('data-switch-screen') === screenKey && tabGroup !== 'feed-bento';
      tab.classList.toggle('active', isFeedOrBento || isDirectMatch);
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

  // Hero device "Dive" button opens Deep Dive for Tadao Ando
  if (heroBtnDive) {
    heroBtnDive.addEventListener('click', () => {
      const artStory = stories.art[currentLang] || stories.art.tr;
      modalTitle.textContent = artStory.deepDiveTitle;
      modalBody.textContent = artStory.deepDiveBody;
      deepDiveModal.classList.add('open');
      document.body.style.overflow = 'hidden';
    });
  }

  // Hero device "Export" button opens Share Card for Tadao Ando
  if (heroBtnExport) {
    heroBtnExport.addEventListener('click', () => {
      const artStory = stories.art[currentLang] || stories.art.tr;
      openShareCardModalWithData(artStory);
    });
  }

  // ==========================================================================
  // 6. LANGUAGE CONTROLLER
  // ==========================================================================
  function applyLanguage(lang) {
    currentLang = lang;
    htmlEl.setAttribute('lang', lang);
    localStorage.setItem('omakase_lang', lang);
    if (currentLangText) {
      currentLangText.textContent = lang.toUpperCase();
    }

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
    renderScreenshots();
  }

  if (langToggleBtn) {
    langToggleBtn.addEventListener('click', () => {
      const nextLang = currentLang === 'tr' ? 'en' : 'tr';
      applyLanguage(nextLang);
    });
  }

  // ==========================================================================
  // 7. SIMULATOR LOGIC & TYPEWRITER SSE STREAM
  // ==========================================================================
  function getActiveStoryData() {
    const story = stories[currentTopic] || stories.film;
    const base = story[currentLang] || story.tr;
    if (base.variants && base.variants[activeSubtopicIndex]) {
      const v = base.variants[activeSubtopicIndex];
      return {
        ...base,
        title: v.title || base.title,
        body: v.body || base.body,
        tags: v.tags || base.tags,
        deepDiveTitle: v.deepDiveTitle || base.deepDiveTitle,
        deepDiveBody: v.deepDiveBody || base.deepDiveBody
      };
    }
    if (activeSubtopicIndex > 0 && base.subtopics && base.subtopics[activeSubtopicIndex]) {
      const chosenSub = base.subtopics[activeSubtopicIndex];
      const cleanTag = chosenSub.replace(/[^a-zA-Z0-9ğüşöçıİĞÜŞÖÇ]/g, '');
      const updatedTags = [base.tags[0], cleanTag || base.tags[1], base.tags[2]].filter(Boolean);
      return {
        ...base,
        tags: updatedTags
      };
    }
    return base;
  }

  function renderSubtopicsPills() {
    if (!subtopicsList) return;
    const story = stories[currentTopic] || stories.film;
    const base = story[currentLang] || story.tr;
    subtopicsList.innerHTML = '';

    (base.subtopics || []).forEach((sub, idx) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      const isLetterboxd = sub.toLowerCase().includes('letterboxd');
      btn.className = 'subtopic-pill'
        + (idx === activeSubtopicIndex ? ' active' : '')
        + (isLetterboxd ? ' letterboxd-pill' : '');
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
    if (!simPostTitle || !simPostBody) return;
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
    updateSource(topicKey);

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
    }, 20);
  }

  function startReadingCooldown(seconds) {
    let remaining = seconds;
    cooldownBar.style.transition = 'none';
    cooldownBar.style.width = '100%';
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

  if (tastesGrid) {
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
  }

  if (btnSpin) {
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
  }

  if (btnStreamStart) {
    btnStreamStart.addEventListener('click', () => {
      if (isStreaming) return;
      const story = stories[currentTopic] || stories.film;
      const base = story[currentLang] || story.tr;
      if (base.subtopics && base.subtopics.length > 1) {
        activeSubtopicIndex = (activeSubtopicIndex + 1) % base.subtopics.length;
        renderSubtopicsPills();
      }
      renderSimulatorPost(currentTopic, true);
    });
  }

  if (btnReread) {
    btnReread.addEventListener('click', () => {
      if (isStreaming) return;
      renderSimulatorPost(currentTopic, true);
    });
  }

  // Bookmark Button Simulation
  let isBookmarked = false;
  if (btnBookmarkDemo) {
    btnBookmarkDemo.addEventListener('click', () => {
      isBookmarked = !isBookmarked;
      const svg = btnBookmarkDemo.querySelector('svg');
      const span = btnBookmarkDemo.querySelector('span');
      if (isBookmarked) {
        svg.setAttribute('fill', 'currentColor');
        btnBookmarkDemo.style.color = 'var(--ink-primary)';
        if (span) span.textContent = currentLang === 'tr' ? 'Kaydedildi' : 'Saved';
      } else {
        svg.setAttribute('fill', 'none');
        btnBookmarkDemo.style.color = 'var(--ink-secondary)';
        if (span) span.textContent = translations[currentLang]['action.save'];
      }
    });
  }

  // Share Button Simulation
  if (btnShareDemo) {
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
  }

  // ==========================================================================
  // 8. DEEP DIVE MODAL & SHARE CARD (#F5F0E8) MODAL
  // ==========================================================================
  function openDeepDiveModal() {
    const data = getActiveStoryData();
    modalTitle.textContent = data.deepDiveTitle;
    modalBody.textContent = data.deepDiveBody;
    deepDiveModal.classList.add('open');
    document.body.style.overflow = 'hidden';
  }

  function closeDeepDiveModal() {
    if (!deepDiveModal) return;
    deepDiveModal.classList.remove('open');
    document.body.style.overflow = '';
  }

  function openShareCardModalWithData(data) {
    if (!shareCardModal) return;
    paperCardTitle.textContent = data.title;
    paperCardText.textContent = data.body;
    paperCardTags.innerHTML = '';
    (data.tags || []).forEach(tag => {
      const pill = document.createElement('span');
      pill.className = 'paper-tag-pill';
      pill.textContent = tag.replace(/^#/, '');
      paperCardTags.appendChild(pill);
    });
    paperCardDate.textContent = currentLang === 'tr' ? '15 Kas 2026' : 'Nov 15, 2026';
    shareCardModal.classList.add('open');
    document.body.style.overflow = 'hidden';
  }

  function closeShareCardModal() {
    if (!shareCardModal) return;
    shareCardModal.classList.remove('open');
    document.body.style.overflow = '';
  }

  if (btnOpenDeepDive) btnOpenDeepDive.addEventListener('click', openDeepDiveModal);
  if (btnCloseModal) btnCloseModal.addEventListener('click', closeDeepDiveModal);
  if (btnExportCard) {
    btnExportCard.addEventListener('click', () => {
      openShareCardModalWithData(getActiveStoryData());
    });
  }
  if (btnCloseShareModal) btnCloseShareModal.addEventListener('click', closeShareCardModal);

  if (deepDiveModal) {
    deepDiveModal.addEventListener('click', (e) => {
      if (e.target === deepDiveModal) closeDeepDiveModal();
    });
  }

  if (shareCardModal) {
    shareCardModal.addEventListener('click', (e) => {
      if (e.target === shareCardModal) closeShareCardModal();
    });
  }

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (deepDiveModal && deepDiveModal.classList.contains('open')) closeDeepDiveModal();
      if (shareCardModal && shareCardModal.classList.contains('open')) closeShareCardModal();
      if (mobileDrawer && mobileDrawer.classList.contains('open')) {
        mobileDrawer.classList.remove('open');
        if (mobileToggleBtn) mobileToggleBtn.setAttribute('aria-expanded', 'false');
      }
    }
  });

  // ==========================================================================
  // 8b. SOURCES + APP STORE SCREENSHOTS GALLERY + LIGHTBOX
  // ==========================================================================
  const topicSources = {
    film: "Kodak Motion Picture Film Archives; Hoyte van Hoytema interviews",
    science: "Physical Review; Francis Perrin, CEA Oklo report (1972)",
    philosophy: "Seneca, De Brevitate Vitae (Loeb Classical Library)",
    music: "Alexei Yurchak; Stephen Coates, Bone Music archive",
    art: "Tadao Ando, Light & Concrete; Church of the Light monograph",
    history: "Tony Freeth et al., Nature (2006); Antikythera Research Project",
    tech: "MIT Instrumentation Lab; NASA AGC Documentation",
    food: "Harold McGee, On Food and Cooking; Edo-period culinary records",
    nature: "Suzanne Simard, Nature (1997)",
    travel: "Saiho-ji Temple Records; Kyoto Prefecture Heritage Office",
    sports: "Rinus Michels, Teambuilding; Ajax Archives",
    gaming: "Fumito Ueda interviews, Edge Magazine; GDC Archives"
  };

  function updateSource(topicKey) {
    const el = document.getElementById('sim-post-source');
    if (!el) return;
    const prefix = translations[currentLang]['demo.sourcePrefix'] || 'Source:';
    el.textContent = `${prefix} ${topicSources[topicKey] || topicSources.film}`;
  }

  let lightboxIndex = 0;
  const shotLabels = ['shots.l1','shots.l2','shots.l3','shots.l4','shots.l5','shots.l6'];
  const shotsGrid = document.getElementById('screenshots-grid');
  const lightbox = document.getElementById('lightbox');
  const lightboxImg = document.getElementById('lightbox-img');

  function shotPath(i) {
    const lang = currentLang === 'en' ? 'en' : 'tr';
    return `assets/screenshots/${lang}/0${i + 1}.png`;
  }

  function renderScreenshots() {
    if (!shotsGrid) return;
    shotsGrid.innerHTML = '';
    shotLabels.forEach((key, i) => {
      const card = document.createElement('button');
      card.type = 'button';
      card.className = 'screenshot-card';
      const label = translations[currentLang][key];
      card.innerHTML = `<div class="screenshot-img-wrap"><img class="screenshot-img" loading="lazy" src="${shotPath(i)}" alt="${label}"></div>` +
        `<div class="screenshot-caption"><span class="screenshot-step">0${i + 1}</span><span class="screenshot-label">${label}</span></div>`;
      card.addEventListener('click', () => openLightbox(i));
      shotsGrid.appendChild(card);
    });
    if (lightbox && lightbox.classList.contains('open')) lightboxImg.src = shotPath(lightboxIndex);
  }

  function openLightbox(i) {
    lightboxIndex = (i + 6) % 6;
    lightboxImg.src = shotPath(lightboxIndex);
    lightboxImg.alt = translations[currentLang][shotLabels[lightboxIndex]];
    lightbox.classList.add('open');
    document.body.style.overflow = 'hidden';
  }
  function closeLightbox() {
    lightbox.classList.remove('open');
    document.body.style.overflow = '';
  }
  if (lightbox) {
    document.getElementById('lightbox-close').addEventListener('click', closeLightbox);
    document.getElementById('lightbox-prev').addEventListener('click', () => openLightbox(lightboxIndex - 1));
    document.getElementById('lightbox-next').addEventListener('click', () => openLightbox(lightboxIndex + 1));
    lightbox.addEventListener('click', (e) => { if (e.target === lightbox) closeLightbox(); });
    document.addEventListener('keydown', (e) => {
      if (!lightbox.classList.contains('open')) return;
      if (e.key === 'Escape') closeLightbox();
      if (e.key === 'ArrowLeft') openLightbox(lightboxIndex - 1);
      if (e.key === 'ArrowRight') openLightbox(lightboxIndex + 1);
    });
  }

  // ==========================================================================
  // 9. FAQ ACCORDION
  // ==========================================================================
  const faqItems = document.querySelectorAll('.faq-item');
  faqItems.forEach(item => {
    const questionBtn = item.querySelector('.faq-question');
    if (!questionBtn) return;
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

  if (waitlistForm) {
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
  }

  // ==========================================================================
  // 11. MOBILE DRAWER NAVIGATION
  // ==========================================================================
  if (mobileToggleBtn && mobileDrawer) {
    mobileToggleBtn.addEventListener('click', () => {
      const isOpen = mobileDrawer.classList.toggle('open');
      mobileToggleBtn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    });

    document.querySelectorAll('.mobile-link').forEach(link => {
      link.addEventListener('click', () => {
        mobileDrawer.classList.remove('open');
        mobileToggleBtn.setAttribute('aria-expanded', 'false');
      });
    });

    window.addEventListener('resize', () => {
      if (window.innerWidth > 768 && mobileDrawer.classList.contains('open')) {
        mobileDrawer.classList.remove('open');
        mobileToggleBtn.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // ==========================================================================
  // 12. INITIALIZATION
  // ==========================================================================
  applyTheme(currentTheme);
  applyLanguage(currentLang);
});
