# 🍣 Omakase

> **Kişisel Yapay Zeka Kültür & Bilgi Akışı**  
> Kaydırmayı bırak, günde 3 ücretsiz tabak gerçek kültürle başla. Kullanıcının 12 kültür kategorisindeki tercihlerini, özel konu başlıklarını ve Letterboxd izleme günlüğünü 7 dilde (`en, tr, ja, de, fr, es, ko`) gerçek zamanlı, birincil kaynakçalı mikro-hikayelere dönüştüren iOS, Cloud Run ve Web platformu.

---

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Omakase Ekosistemi                              │
├───────────────────────────────────┬─────────────────────────────────────┤
│        SwiftUI iOS Client         │       Web Landing & Demo (web/)     │
│  - iOS 17+ • Reels Dikey Akış     │  - getomakase.app (Firebase/CF)     │
│  - 7 Dil (.lproj & L10n)          │  - Canlı Tadım (Interactive Demo)   │
│  - Üst Bar Stres Sayacı (3/gün)   │  - Derin İnceleme Önizleme          │
│  - PostSourceView Birincil Kaynak │  - TR/EN Çoklu Dil & Koyu/Açık Tema │
│  - Keşfet/Takip Topluluk & Pro UI │  - TestFlight & Yasal Sayfalar      │
└─────────────────┬─────────────────┴──────────────────┬──────────────────┘
                  │                                    │
                  │ HTTPS SSE + REST                   │ Firebase SDK
                  │ /feed/*, /billing/*, /notifications/*  (Auth + Firestore)
                  ▼                                    ▼
┌───────────────────────────────────┐        ┌────────────────────────────┐
│     Google Cloud Run (Canlı)      │        │      Google Firebase       │
│  FastAPI Backend                  │        │  - Apple/Google/Email Auth │
│  - Firebase JWT & Rate Limiting   │        │  - Cloud Firestore & Rules │
│  - RevenueCat Sync & Webhook      │        │  - Crashlytics (Non-Fatal) │
│  - APNs/FCM Bildirim Kuyruğu      │        │  - FCM Push & Hosting      │
│  - Letterboxd 50 Film RSS         │        └────────────────────────────┘
└─────────────────┬─────────────────┘
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

* **🍱 BentoTasteBox (12 Kategori & 2×6 Alt Konu Izgarası):**
  12 ana kültür kategorisi (*Film, Müzik, Bilim, Yemek, Tarih, Spor, Teknoloji, Doğa, Sanat, Felsefe, Seyahat, Oyun*), kategori değişiminde korunan alt konu karosu, isteğe bağlı **Gemini 3.1 Flash-Lite** yenilemesi ve özel konu girişi.
* **📚 Tıklanabilir Birincil Kaynakça (`PostSourceView`):**
  Her şef tabağı ve **Derin İnceleme** (`Deep Dive`) çıktısı gerçek bir birincil kaynak (*kitap, akademik makale, arşiv veya röportaj*) içerir ("Wikipedia" yasaktır). Gönderi altındaki kaynak kapsülüne dokunarak tam kaynak adını görebilir ve varsayılan tarayıcıda tek dokunuşla arayabilirsiniz.
* **🌍 7 Dil Desteği (`en`, `tr`, `ja`, `de`, `fr`, `es`, `ko`):**
  Hem iOS arayüzü (`.lproj` + `AppLanguage` + `L10n.swift`) hem de Cloud Run içerik üretimi ve sosyal push bildirimleri İngilizce, Türkçe, Japonca, Almanca, Fransızca, İspanyolca ve Korece dillerinde tam yerel çalışır.
* **🍱 "Günün Menüsü" Freemium & RevenueCat Pro Altyapısı:**
  Ücretsiz planda günde **3 şef tabağı** (ana akış üst çubuğunda canlı `Kalan: X/3` stres sayacıyla) ve **1 Derin İnceleme** (paylaşımla günde `+1` bonus); **Omakase Pro** (\$29.99/yıl · 7 gün ücretsiz deneme veya \$3.99/ay) ile sınırsız okuma ve Derin İnceleme.
* **✨ Sürtünmesiz 3 Adımlı Kayıt & `@username` Kimliği:**
  Sign in with Apple (SHA-256 Nonce + Keychain), Google Sign-In ve gerçek zamanlı Firestore müsaitlik kontrolüne sahip benzersiz `@kullanıcı_adı` kayıt akışı.
* **🎬 Letterboxd Entegrasyonu:**
  Kullanıcının Letterboxd günlüğünden son 50 filmi şifresiz çeker. Python seviyesinde rastgele hedef film kilidiyle (`random.choice`) çeşitliliği garanti eder ve doğrulanmış kamera arkası prodüksiyon anekdotlarına öncelik verir.
* **⏳ Okuma Süresi & Doomscrolling Koruması (Reading Cooldown):**
  Metin uzunluğuna göre 15–25 saniye akıllı sindirme süresi uygular. Üstteki ince sayaç tamamlanana kadar yeni post üretimi kilitlenir.
* **📱 Reels Tarzı Dikey Akış & Derin İnceleme Modalı:**
  `.viewAligned` tam ekran dikey sayfalama, SSE üzerinden daktilo efektiyle akan metinler ve tek dokunuşla açılan **Derin İnceleme** (`DeepDiveSheetView`).
* **👥 Keşfet (`Discover`) & Takip Topluluğu, Bildirimler & Çevrimdışı Arşiv:**
  Yazar bazlı round-robin karıştırma ile rastgele farklı okurları öne çıkaran **Keşfet / Takip Edilenler** akışı, kart başlığından tek dokunuşla `+ Takip et`, yorum/tepki/engelleme/şikayet, bağlam içi yerel ve APNs/FCM bildirimleri, `#F5F0E8` paylaşım kartı ve SwiftData önbelleği.
* **🌐 İnteraktif Web Deneyimi (`web/`):**
  Tarayıcı üzerinde çalışan Canlı Tadım simülatörü, Derin İnceleme önizlemesi, TR/EN dil geçişi, abonelik/gizlilik yasal sayfaları ve TestFlight bekleme listesi.

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
│   │   ├── config.py        # Ortam değişkenleri, 7 dil desteği, kota/bildirim sabitleri, CORS
│   │   ├── errors.py        # Kanonik hata kodları ve Gemini/HTTP hata eşleme
│   │   ├── security.py      # Firebase JWT doğrulama, rate limiter ve girdi filtreleri
│   │   ├── schemas.py       # Pydantic istek/yanıt modelleri ve alan doğrulayıcıları
│   │   ├── prompts.py       # Küratör sistem talimatları, 14 format ve birincil kaynakça kuralı
│   │   ├── routers/         # APIRouter uç noktaları (feed, interests, letterboxd, billing, notifications)
│   │   └── services/        # gemini_service, letterboxd_service, access_service, billing_service, notification_service, firestore_admin
│   ├── tests/               # Birim testleri (19/19: hata sözleşmesi, kota/billing, bildirim, çoklu dil)
│   ├── main.py              # FastAPI uygulama giriş noktası (uvicorn main:app)
│   ├── Dockerfile           # Cloud Run deployment konteyneri (non-root appuser)
│   └── requirements.txt
├── docs/                    # Güncel mimari, PMF, pazarlama, App Store, güvenlik ve müşteri doğrulama raporları
│   ├── master_rapor.md               # Tüm raporları tek dokümanda birleştiren yönetici özeti
│   ├── proje_durum_ve_mimari_raporu.md # Güncel iOS/Cloud Run/Firestore mimarisi ve Faz 1–4 durumu
│   ├── founder_100_musteri_raporu.md # founder-skill 100 müşteri simülasyonu (1. Tur %1 → 2. Tur %72)
│   ├── appstore_raporu.md            # Apple Agent Kit tabanlı App Store gönderim ve uyumluluk denetimi
│   ├── pazarlama_ve_dagitim_stratejisi.md # Küresel dağıtım (US/UK), TikTok otomasyonu ve Paid UA stratejisi
│   ├── urun_analizi_ve_pazarlama.md  # Product-Market Fit (PMF), ICP, birim ekonomisi ve ASO/GTM raporu
│   └── siber_guvenlik_raporu.md      # API anahtarları, Cloud Run, Firestore (5/5), iOS ve Web güvenlik denetimi
├── omakase/                 # SwiftUI iOS projesi (iOS 17.0+)
│   ├── omakase.xcodeproj    # Xcode proje paketi & paylaşımlı şema (xcshareddata)
│   └── omakase/             # Swift kaynak kodları ve uygulama kaynakları
│       ├── App/             # omakaseApp, ContentView, MainTabView
│       ├── Auth/            # AuthView (3 adımlı kayıt, Apple & Google), AuthService
│       ├── Onboarding/      # OnboardingView, InterestsEditorForm
│       ├── Feed/            # FeedView, FeedViewModel, InlineTasteBar, AdjustTastesSheet, BookmarkStore, BookmarksSheet, ShareCardView
│       ├── Interests/       # BentoTasteBox, CategoryGridView, InterestCategory
│       ├── Monetization/    # OmakasePaywallView, DailyLimitCardView
│       ├── Social/          # TimelineView (Keşfet/Takip), TimelineViewModel, TimelinePostCard, CommentsView, UserProfileSheet, UserSearchView
│       ├── Profile/         # ProfileTabView
│       ├── Models/          # Post, CachedPost, SharedPost, Comment, Reaction, UserProfile (@username)
│       ├── Networking/      # SSEClient (APITokenProvider), CategoryExpansionService, InterestSuggestor, LetterboxdService
│       ├── Services/        # AccessManager, NotificationManager, OmakaseError, FirestoreService, ContentModerationService, PostCacheService, ShareService
│       ├── Localization/    # AppLanguage (7 dil), L10n, LanguagePicker & en/tr/ja/de/fr/es/ko.lproj
│       ├── Theme/           # OmakaseTheme, AppAppearance, PostSourceView (tıklanabilir kaynakça)
│       ├── Assets.xcassets/ # Uygulama ikonu, logo ve renk varlıkları
│       ├── Info.plist       # Uygulama izin ve yapılandırma tanımları
│       ├── omakase.entitlements # Sign in with Apple & APNs (aps-environment)
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
| [📊 Proje Durum & Teknik Mimari Raporu](docs/proje_durum_ve_mimari_raporu.md) | Faz 1–4 durumu, RevenueCat monetizasyon, APNs/FCM bildirimleri, Crashlytics, 7 dil ve birincil kaynakça mimarisi. |
| [🧪 100 Müşteri Simülasyon Raporu](docs/founder_100_musteri_raporu.md) | `founder-skill` 100 müşteri simülasyonu (1. Tur `%1` → 2. Tur `%72`) ve Van Westendorp fiyatlandırma analizi. |
| [📄 App Store Raporu](docs/appstore_raporu.md) | Apple Agent Kit tabanlı App Review, `PrivacyInfo.xcprivacy`, Xcode yapılandırma ve Archive/Validate denetimi. |
| [🎯 **ASO & Web SEO / GEO Raporu**](docs/aso_ve_seo_raporu.md) | 9 yerel ayar App Store Connect kopyala-yapıştır metadata paketi, kategori/anahtar kelime analizi ve `getomakase.app` SEO/GEO optimizasyonu. |
| [🛡️ Siber Güvenlik Raporu](docs/siber_guvenlik_raporu.md) | API anahtarları, Cloud Run backend, Firestore kuralları (`5/5`), iOS istemci ve Web siber güvenlik analizi (`S-01`–`S-12`). |
| [🚀 Küresel Pazarlama & Dağıtım Stratejisi](docs/pazarlama_ve_dagitim_stratejisi.md) | Tier-1 küresel açılım (US/UK), otomatize TikTok Photo Mode büyüme motoru, Paid UA matematiği ve sıfır bütçeli dağıtım kanalları. |
| [📈 Ürün Analizi & PMF Raporu](docs/urun_analizi_ve_pazarlama.md) | Product-Market Fit hipotezi, hedef personalar (ICP), AARRR hunisi, birim ekonomisi ve App Store (ASO) vitrin stratejisi. |
