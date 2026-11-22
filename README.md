# 🍣 Omakase

> **Kişisel Yapay Zeka Kültür & Bilgi Akışı**  
> Algoritmaların gürültüsünden uzak; kullanıcının 12 kültür kategorisindeki tercihlerini, özel konu başlıklarını ve Letterboxd izleme günlüğünü gerçek zamanlı olarak doğrulanmış, derinlikli mikro-hikayelere dönüştüren yerel iOS, Cloud Run ve Web platformu.

---

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Omakase Ekosistemi                              │
├───────────────────────────────────┬─────────────────────────────────────┤
│        SwiftUI iOS Client         │       Web Landing & Demo (web/)     │
│  - iOS 17+ • Reels Dikey Akış     │  - getomakase (Cloudflare/Firebase) │
│  - 3 Adımlı Kayıt (@username)     │  - Canlı Tadım (Interactive Demo)   │
│  - 12 Kategori & 6'lı Alt Konu    │  - Deep Dive Modal Önizleme         │
│  - Deep Dive Bottom Sheet Modal   │  - TR/EN Çoklu Dil & Koyu/Açık Tema │
│  - Topluluk Akışı & Arama Barı    │  - TestFlight Bekleme Listesi       │
└─────────────────┬─────────────────┴──────────────────┬──────────────────┘
                  │                                    │
                  │ HTTPS Server-Sent Events           │ Firebase SDK
                  │ POST /feed/stream                  │ (Auth + Cloud Firestore)
                  ▼                                    ▼
┌───────────────────────────────────┐        ┌────────────────────────────┐
│     Google Cloud Run (Canlı)      │        │      Google Firebase       │
│  FastAPI Backend                  │        │  - Email & Google Auth     │
│  - Çift Katmanlı Moderasyon       │        │  - Cloud Firestore         │
│  - Server-Sent Events (SSE)       │        │  - firestore.rules         │
│  - Letterboxd 50 Film RSS         │        │  - Firebase Hosting        │
└─────────────────┬─────────────────┘        └────────────────────────────┘
                  │
                  │ google-genai SDK
                  ▼
┌───────────────────────────────────┐
│        Google Gemini API          │
│  - gemini-3.5-flash (Feed/Dive)   │
│  - gemini-3.1-flash-lite (Topics) │
└───────────────────────────────────┘
```

---

## 🚀 Öne Çıkan Özellikler

* **🍱 BentoTasteBox (12 Kategori & 6'lı Alt Konu Izgarası):**
  12 ana kültür kategorisi (*Sinema, Bilim, Felsefe, Sanat, Teknoloji, Tarih, Müzik, Edebiyat, Psikoloji, Mimari, Gastronomi, Uzay*), kategori değişiminde korunan 6'lı kompakt alt konu karosu, isteğe bağlı **Gemini 3.1 Flash-Lite** yenilemesi ve özel konu girişi.
* **✨ Sürtünmesiz 3 Adımlı Kayıt & `@username` Kimliği:**
  Twitter/X tarzı çok adımlı kayıt akışı (Görünür İsim, gerçek zamanlı Firestore müsaitlik kontrolüne sahip benzersiz `@kullanıcı_adı`, canlı profil önizleme kartı) ve Google Sign-In desteği.
* **🎬 Letterboxd Entegrasyonu:**
  Kullanıcının Letterboxd günlüğünden son 50 filmi tek seferde çeker. Python seviyesinde rastgele hedef film kilidiyle (`random.choice`) çeşitliliği garanti eder ve doğrulanmış kamera arkası prodüksiyon anekdotlarına öncelik verir.
* **⏳ Okuma Süresi & Doomscrolling Koruması (Reading Cooldown):**
  Metin uzunluğuna göre 15–25 saniye akıllı sindirme süresi uygular. Bu sürede yeni post üretimi ve kategori seçimleri kilitlenir; animasyonlu bir kum saati canlı geri sayım yapar.
* **📱 Reels Tarzı Dikey Akış & Deep Dive Modal:**
  `.viewAligned` tam ekran dikey sayfalama, SSE üzerinden daktilo efektiyle akan metinler ve tek dokunuşla açılan **Deep Dive Bottom Sheet Modal** (`DeepDiveSheetView`).
* **👥 Topluluk (`Community`), Arama & Yer İmleri:**
  Beğenilen şef yazılarını `@username` profili üzerinden toplulukla paylaşma, gönderi/kişi arama barı, 5'li ifade sistemi (`🔥, 🧠, ❤️, 👏, 🤯`), yorumlar ve çevrimdışı yer imleri (`BookmarkStore`).
* **🌐 İnteraktif Web Deneyimi (`web/`):**
  Tarayıcı üzerinde çalışan Canlı Tadım simülatörü, Deep Dive önizlemesi, TR/EN dil geçişi ve TestFlight bekleme listesi.

---

## 📂 Proje Dizin Yapısı

```
omakase/
├── .agents/                 # Apple Agent Kit (v2.5.1) yönlendirme, yetenek ve bilgi sözleşmeleri
│   ├── AGENTS.md            # Ajan başlangıç prosedürü ve katman kuralları
│   ├── knowledge/           # HIG, SwiftUI, Xcode, Privacy ve App Review sözleşmeleri
│   ├── references/          # Resmi Apple dokümantasyon referansları
│   ├── skills/              # Yönlendirme indeksleri (skills/index.md) ve yetenekler
│   └── workflows/           # Çoklu yetenek iş akışları (app-store-submission, authentication vb.)
├── .vscode/                 # IDE ayarları ve derleme görevleri (Cmd+Shift+B)
│   └── tasks.json
├── backend/                 # FastAPI & Google GenAI mikroservisi
│   ├── app/                 # Modüler backend mimarisi
│   │   ├── config.py        # Ortam değişkenleri, CORS ve Gemini güvenlik ayarları
│   │   ├── security.py      # Firebase JWT doğrulama, rate limiter ve girdi filtreleri
│   │   ├── schemas.py       # Pydantic istek/yanıt modelleri ve alan doğrulayıcıları
│   │   ├── prompts.py       # Küratör sistem talimatları ve 12 dönüşümlü post formatı
│   │   ├── routers/         # APIRouter uç noktaları (feed.py, interests.py, letterboxd.py)
│   │   └── services/        # İş mantığı katmanı (gemini_service.py, letterboxd_service.py)
│   ├── main.py              # FastAPI uygulama giriş noktası (uvicorn main:app)
│   ├── Dockerfile           # Cloud Run deployment konteyneri (non-root appuser)
│   └── requirements.txt
├── docs/                    # Detaylı mimari, strateji, PMF/pazarlama, App Store ve güvenlik raporları
│   ├── master_rapor.md      # Tüm raporları tek dokümanda birleştiren yönetici özeti (Master Rapor)
│   ├── appstore_raporu.md   # Apple Agent Kit tabanlı App Store gönderim ve uyumluluk denetimi
│   ├── gelecek_stratejisi.md# Moat analizi, doyum psikolojisi ve kültürel entegrasyon vizyonu
│   ├── ozellik_fikirleri.md # Tamamlanan 8 temel sistem ve v1/v2/v3 özellik yol haritası
│   ├── pazarlama_ve_dagitim_stratejisi.md # Küresel dağıtım (US/UK), TikTok otomasyonu ve Paid UA stratejisi
│   ├── urun_analizi_ve_pazarlama.md # Product-Market Fit (PMF), ICP, birim ekonomisi ve ASO/GTM raporu
│   └── siber_guvenlik_raporu.md # API anahtarları, Cloud Run, Firestore, iOS ve Web güvenlik denetimi
├── omakase/                 # SwiftUI iOS projesi (iOS 17.0+)
│   ├── omakase.xcodeproj    # Xcode proje paketi & paylaşımlı şema (xcshareddata)
│   └── omakase/             # Swift kaynak kodları ve uygulama kaynakları
│       ├── App/             # omakaseApp, ContentView, MainTabView
│       ├── Auth/            # AuthView (3 adımlı kayıt), AuthService
│       ├── Onboarding/      # OnboardingView, InterestsEditorForm
│       ├── Feed/            # FeedView, FeedViewModel, InlineTasteBar, AdjustTastesSheet, BookmarkStore, BookmarksSheet, ShareCardView
│       ├── Interests/       # BentoTasteBox, CategoryGridView, InterestCategory
│       ├── Social/          # TimelineView, TimelineViewModel, TimelinePostCard, CommentsView, UserProfileSheet, UserSearchView
│       ├── Profile/         # ProfileTabView
│       ├── Models/          # Post, CachedPost, SharedPost, Comment, Reaction, UserProfile (@username)
│       ├── Networking/      # SSEClient (APITokenProvider), CategoryExpansionService, InterestSuggestor, LetterboxdService
│       ├── Services/        # FirestoreService, ContentModerationService, PostCacheService, ShareService
│       ├── Localization/    # AppLanguage, L10n, LanguagePicker
│       ├── Theme/           # OmakaseTheme, AppAppearance
│       ├── Assets.xcassets/ # Uygulama ikonu, logo ve renk varlıkları
│       ├── Info.plist       # Uygulama izin ve yapılandırma tanımları
│       └── PrivacyInfo.xcprivacy # Apple App Privacy Manifest (Required Reason API & veri beyanı)
├── scripts/
│   ├── launch-ios.sh        # Fiziksel iPhone'a otomatik derleme & başlatma betiği
│   └── launch-simulator.sh  # iOS Simulator'da otomatik derleme & başlatma betiği
├── web/                     # İnteraktif tanıtım web sitesi (getomakase.app)
│   ├── index.html           # Canlı Tadım simülatörü, özellikler, felsefe ve SSS
│   ├── style.css            # Monokrom açık/koyu tema stilleri
│   ├── app.js               # İnteraktif demo motoru ve TR/EN çeviri katmanı
│   └── assets/              # İkonlar ve ekran görselleri
├── firebase.json            # Firestore kuralları ve Firebase Hosting yapılandırması
├── firestore.rules          # Cloud Firestore güvenlik kuralları
├── wrangler.json            # Cloudflare statik varlık dağıtım yapılandırması (getomakase)
├── GEMINI.md                # Çalışma alanı geliştirici kuralları
└── README.md
```

---

## 🛠️ Hızlı Başlangıç

### 1. iOS Uygulamasını Çalıştırma (Fiziksel Cihaz veya Simulator)

```bash
# Bağlı fiziksel iPhone üzerinde derleyip başlatmak için (veya Cmd + Shift + B):
./scripts/launch-ios.sh

# iOS Simulator (iPhone 17) üzerinde derleyip başlatmak için:
./scripts/launch-simulator.sh
```

### 2. Canlı Backend Bilgisi

Backend Google Cloud Run üzerinde canlı yayındadır:
* **Canlı URL:** `https://omakase-backend-20235796246.us-central1.run.app`
* **Sağlık Kontrolü:** `curl https://omakase-backend-20235796246.us-central1.run.app/health`

Lokal olarak çalıştırmak için:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

## 📚 Kapsamlı Dokümantasyon Dizini

Detaylı rapor ve analizler için `docs/` klasörünü inceleyebilirsiniz:

| Doküman | Açıklama |
|---------|----------|
| [👑 **Master Rapor (Yönetici Özeti)**](docs/master_rapor.md) | **Tüm raporların (Mimari, PMF, Küresel Pazarlama, App Store, Siber Güvenlik ve Yol Haritası) tek belgede birleştirilmiş özeti.** |
| [📄 App Store Raporu](docs/appstore_raporu.md) | Apple Agent Kit tabanlı App Review, `PrivacyInfo.xcprivacy`, Xcode yapılandırma ve Archive/Validate denetimi. |
| [🛡️ Siber Güvenlik Raporu](docs/siber_guvenlik_raporu.md) | API anahtarları, Cloud Run backend, Firestore kuralları, iOS istemci ve Web siber güvenlik analizi. |
| [🚀 Küresel Pazarlama & Dağıtım Stratejisi](docs/pazarlama_ve_dagitim_stratejisi.md) | Tier-1 küresel açılım (US/UK), otomatize TikTok Photo Mode büyüme motoru, Paid UA matematiği ve sıfır bütçeli dağıtım kanalları. |
| [📈 Ürün Analizi & PMF Raporu](docs/urun_analizi_ve_pazarlama.md) | Product-Market Fit hipotezi, hedef personalar (ICP), AARRR hunisi, birim ekonomisi ve App Store (ASO) vitrin stratejisi. |
| [🔮 Gelecek Stratejisi](docs/gelecek_stratejisi.md) | 5 katmanlı Moat analizi, doyum psikolojisi, web edinim hunisi ve kültürel entegrasyon vizyonu. |
| [💡 Özellik Haritası](docs/ozellik_fikirleri.md) | Tamamlanan 8 temel sistem (3 adımlı `@username` kaydı, 12 kategori, Topluluk, Web) ve v2/v3 yol haritası. |
