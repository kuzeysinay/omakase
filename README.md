# 🍣 Omakase

> **Kişisel Yapay Zeka Kültür & Bilgi Akışı (`v1.0` — Apple App Review `Waiting for Review` · `APP_ID: 6838044134`)**  
> Kaydırmayı bırak, günde 3 ücretsiz post gerçek kültürle başla. Kullanıcının 12 kültür kategorisini, 24 merak merceğiyle üretilen alt konuları ve Letterboxd izleme günlüğünü **7 dilde** (`en, tr, ja, de, fr, es, ko` · **528 yerelleştirme anahtarı/dil**) gerçek zamanlı, birincil kaynakçalı mikro-hikayelere dönüştüren iOS, WidgetKit, Cloud Run ve Web platformu.

---

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Omakase Ekosistemi                              │
├───────────────────────────────────┬─────────────────────────────────────┤
│   SwiftUI iOS + WidgetKit Client  │    Web (web/) & Admin (admin-web/)  │
│  - iOS 17+ • Reels Dikey Akış     │  - getomakase.app (CF, SEO/GEO)     │
│  - omakaseWidget (Ana/Kilit Ekran)│  - Canlı Tadım & 8 Slaytlı Vitrin   │
│  - 7 Dil (.lproj · 528 anahtar)   │  - Mission Control (Firebase Auth)  │
│  - GuestTasteView (Kayıtsız Tadım)│  - RevenueCat v2 & Moderasyon Panel │
│  - PostSourceView & Export Studio │  - App Review: Waiting for Review   │
└─────────────────┬─────────────────┴──────────────────┬──────────────────┘
                  │                                    │
                  │ HTTPS SSE + REST                   │ Firebase SDK
                  │ /feed/*, /billing/*, /telemetry/*    (Auth + Firestore)
                  ▼                                    ▼
┌───────────────────────────────────┐        ┌────────────────────────────┐
│     Google Cloud Run (Canlı)      │        │      Google Firebase       │
│  FastAPI Backend (7 Router)       │        │  - Apple/Google/Email Auth │
│  - Firebase JWT (`check_revoked`) │        │  - Cloud Firestore & Rules │
│  - Cihaz Kotası (`device_usage`)  │        │  - Crashlytics (Non-Fatal) │
│  - RevenueCat Sync & v2 + Webhook │        │  - FCM Push & Hosting      │
│  - APNs/FCM + Letterboxd 50 RSS   │        └────────────────────────────┘
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

* **🍱 BentoTasteBox (12 Kategori, 24 Merak Merceği & Şefin Seçimi):**
  12 ana kültür kategorisi (*Film, Müzik, Bilim, Yemek, Tarih, Spor, Teknoloji, Doğa, Sanat, Felsefe, Seyahat, Oyun*), kategori değişiminde korunan alt konu karosu, `gemini-3.1-flash-lite` yenilemesi ve başparmak bölgesinde **Şefin Seçimi (Chef's Pick)**.
* **📚 Tıklanabilir Birincil Kaynakça (`PostSourceView`):**
  Her post ve **Derin İnceleme** (`Deep Dive`) çıktısı gerçek bir birincil kaynak (*kitap, akademik makale, arşiv veya röportaj*) içerir ("Wikipedia" yasaktır). Gönderi altındaki kaynak kapsülüne dokunarak tam kaynak adını görebilir ve varsayılan tarayıcıda tek dokunuşla arayabilirsiniz.
* **🧩 Ana Ekran & Kilit Ekranı WidgetKit (`omakaseWidget/`):**
  Paylaşımlı App Group (`group.kuzeysinay.omakase`) ve `WidgetDataBridge` üzerinden beslenen küçük, orta ve kilit ekranı widget'ları ile günün kültürel kıvılcımlarını doğrudan ana ekrana taşır.
* **🎨 İnteraktif Export Studio (`ExportPostSheet` & `ShareCardView`):**
  3D sürükleme eğimli kart önizlemesi, **3 oran** (`1080×1920`, `1080×1350`, `1080×1080`), **4 monokrom tema** (`Paper`, `Ink`, `Editorial`, `Midnight`) ve Instagram Stories / WhatsApp / X / Fotoğraflar'a doğrudan aktarım.
* **🌍 7 Dil Desteği (`en`, `tr`, `ja`, `de`, `fr`, `es`, `ko`):**
  Hem iOS arayüzü (`.lproj` başına **528 anahtar** + `AppLanguage` + `L10n.swift`) hem de Cloud Run içerik üretimi ve sosyal push bildirimleri 7 dilde tam yerel çalışır.
* **🍱 "Günün Menüsü" Freemium, Cihaz Kotası & RevenueCat Pro:**
  Ücretsiz planda günde **3 post** (**1 Letterboxd/gün** dahil, üst çubukta `Kalan: X/3` stres sayacıyla) ve **1 Derin İnceleme** (paylaşımla günde `+1` bonus) ile Keychain + SHA-256 `device_usage` anti-abuse koruması; **Omakase Pro** (`omakase.pro.yearly` \$29.99/yıl · 7 gün ücretsiz deneme veya `omakase.pro.monthly` \$3.99/ay) + `ProWelcomeView`.
* **✨ Misafir Tadımı (`GuestTasteView`), `ProfileSetupView` & `@username` Kimliği:**
  Kayıt olmadan önce statik katalogdan deneyim sunan Misafir Tadımı, ardından Sign in with Apple (SHA-256 Nonce + Keychain), Google Sign-In veya E-posta sonrası atomik `usernames/{handle}` (**14 gün değişim beklemesi**) ve 3 slaytlı ASCII suşi onboarding.
* **🎬 Letterboxd Entegrasyonu:**
  Kullanıcının Letterboxd günlüğünden son 50 filmi şifresiz çeker; Python seviyesinde rastgele hedef film kilidiyle (`random.choice`) çeşitliliği garanti eder ve doğrulanmış kamera arkası prodüksiyon anekdotlarına öncelik verir.
* **⏳ Okuma Süresi (`Reading Cooldown`), Reels Akışı & Değerlendirme:**
  Metin uzunluğuna göre 15–25 saniye okuma molası, `.viewAligned` tam ekran SSE daktilo akışı, tek dokunuşla **Derin İnceleme**, `HapticManager` dokunsal geri bildirimi ve 3 tamamlanmış okuma sonrasında Kural 5.6.1/5.6.3 uyumlu `RatingPromptManager`.
* **👥 Keşfet / Takip Topluluğu, Moderasyon & Mission Control:**
  Yazar bazlı round-robin **Keşfet / Takip** akışı, `FollowListSheet`, yorum/tepki/engelleme, AI post şikayeti (`reportAIPost`), uygulama içi geri bildirim (`FeedbackSheetView`), bağlam içi APNs/FCM bildirimleri, SwiftData çevrimdışı arşivi ve Firebase Hosting üzerinde 5 sekmeli **Mission Control (`admin-web/`)**.
* **🌐 Tanıtım & SEO/GEO Web Deneyimi (`web/`):**
  Canlı Tadım simülatörü, 8 slaytlı vitrin, 4 ekranlı canlı iPhone maketi, statik `web/en/index.html`, Schema.org JSON-LD, `llms.txt`, `sitemap.xml`, `_headers` ve güncel `privacy.html` / `terms.html`.

---

## 📂 Proje Dizin Yapısı

```
omakase/
├── .agents/                    # Apple Agent Kit yönlendirme, yetenek ve bilgi sözleşmeleri
│   ├── AGENTS.md               # Ajan başlangıç prosedürü ve katman kuralları
│   ├── knowledge/              # HIG, SwiftUI, Xcode, Privacy ve App Review sözleşmeleri
│   ├── references/             # Resmi Apple dokümantasyon referansları
│   ├── skills/                 # Yönlendirme indeksleri (skills/index.md) ve yetenekler
│   └── workflows/              # Çoklu yetenek iş akışları (app-store-submission, authentication vb.)
├── admin-web/                  # Mission Control admin paneli (Firebase Hosting — noindex, CSP)
│   ├── admin.html
│   ├── admin.css
│   └── admin.js                # Genel Bakış, Gelir & AI, Geri Bildirim, Moderasyon, Kullanıcılar
├── app-store-screenshots/      # Next.js App Store ekran görüntüsü stüdyosu & exports/ios/ (224 PNG)
├── backend/                    # FastAPI & Google GenAI mikroservisi (Cloud Run)
│   ├── app/
│   │   ├── config.py           # Ortam değişkenleri, 7 dil desteği, kota/bildirim sabitleri, CORS
│   │   ├── errors.py           # Kanonik hata kodları ve Gemini/HTTP hata eşleme
│   │   ├── security.py         # Firebase JWT (check_revoked=True), TTL rate limiter ve filtreler
│   │   ├── schemas.py          # Pydantic istek/yanıt modelleri ve alan doğrulayıcıları
│   │   ├── prompts.py          # Küratör sistem talimatları, 14 format, 24 merak merceği ve kaynakça
│   │   ├── routers/            # 7 router: feed, interests, letterboxd, billing, notifications, telemetry, admin
│   │   └── services/           # gemini, letterboxd, access, billing, notification, admin, metrics, firestore_admin
│   ├── tests/                  # Birim testleri (38/38 PASS: hata, kota/billing, bildirim, parser, admin/telemetri)
│   ├── main.py                 # FastAPI uygulama giriş noktası
│   ├── Dockerfile              # Cloud Run konteyneri (non-root appuser)
│   └── requirements.txt
├── docs/                       # Güncel mimari, PMF, ASO/SEO, pazarlama, App Store ve güvenlik raporları
│   ├── master_rapor.md                  # Tüm raporları tek dokümanda birleştiren yönetici özeti
│   ├── proje_durum_ve_mimari_raporu.md  # Güncel iOS/Widget/Cloud Run/Firestore mimarisi ve Faz 1–4 durumu
│   ├── founder_100_musteri_raporu.md    # founder-skill 100 müşteri simülasyonu (1. Tur %1 → 2. Tur %72)
│   ├── appstore_raporu.md               # Apple Agent Kit App Store gönderimi (`Waiting for Review`, 8 veri tipi)
│   ├── aso_ve_seo_raporu.md             # 9 yerel ayar ASO metadata paketi ve getomakase.app SEO/GEO raporu
│   ├── siber_guvenlik_raporu.md         # API anahtarları, Cloud Run, Firestore ve iOS/Web güvenlik denetimi (28/28)
│   ├── pazarlama_ve_dagitim_stratejisi.md # Tier-1 küresel açılım, TikTok otomasyonu ve Paid UA stratejisi
│   └── urun_analizi_ve_pazarlama.md     # Product-Market Fit (PMF), ICP, birim ekonomisi ve GTM raporu
├── omakase/                    # SwiftUI iOS projesi (iOS 17.0+, TARGETED_DEVICE_FAMILY = 1)
│   ├── omakase.xcodeproj       # Xcode proje paketi & paylaşımlı şema (xcshareddata)
│   ├── omakase/                # Ana uygulama kaynak kodları
│   │   ├── App/                # omakaseApp, ContentView, MainTabView, UITestHarness, ScreenshotPreviewHarness
│   │   ├── Auth/               # AuthView, AuthService
│   │   ├── Onboarding/         # OnboardingView, GuestTasteView, GuestStaticCatalog*, InterestsEditorForm
│   │   ├── Feed/               # FeedView, FeedViewModel, ExportPostSheet, ShareCardView, InlineTasteBar, Bookmark*
│   │   ├── Interests/          # BentoTasteBox, CategoryGridView, InterestCategory
│   │   ├── Monetization/       # OmakasePaywallView, ProWelcomeView, DailyLimitCardView
│   │   ├── Social/             # TimelineView, TimelineViewModel, TimelinePostCard, CommentsView, UserProfileSheet, FollowListSheet, UserSearchView
│   │   ├── Profile/            # ProfileTabView, FeedbackSheetView
│   │   ├── Models/             # Post, CachedPost, SharedPost, Comment, Reaction, UserProfile
│   │   ├── Networking/         # SSEClient, CategoryExpansionService, InterestSuggestor, LetterboxdService
│   │   ├── Services/           # AccessManager, TelemetryService, RatingPromptManager, HapticManager, WidgetDataBridge, NotificationManager, OmakaseError, FirestoreService, PostCacheService, ContentModerationService, ShareService
│   │   ├── Localization/       # AppLanguage (7 dil), L10n, LanguagePicker & en/tr/ja/de/fr/es/ko.lproj (528 anahtar)
│   │   ├── Theme/              # OmakaseTheme, AppAppearance, PostSourceView
│   │   ├── Info.plist          # İzinler, LSApplicationQueriesSchemes & ITSAppUsesNonExemptEncryption=false
│   │   ├── omakase.entitlements # Apple Sign-In, APNs & group.kuzeysinay.omakase App Group
│   │   └── PrivacyInfo.xcprivacy # Apple Privacy Manifest (CA92.1 + 1C8F.1 + 8 veri tipi)
│   ├── omakaseWidget/          # WidgetKit uzantısı (OmakaseWidget, WidgetTopicCatalog, PrivacyInfo.xcprivacy)
│   └── omakaseUITests/         # 12 otomatik XCUITest
├── scripts/
│   ├── launch-ios.sh           # Fiziksel iPhone'a otomatik derleme & başlatma betiği
│   └── launch-simulator.sh     # iOS Simulator'da otomatik derleme & başlatma betiği
├── web/                        # Tanıtım web sitesi & yasal sayfalar (getomakase.app — Cloudflare)
│   ├── index.html & en/index.html # Çift dilli Canlı Tadım, 8 slayt vitrin, Schema.org JSON-LD
│   ├── privacy.html & terms.html  # 26 Kasım 2026 güncel Gizlilik ve Kullanım Koşulları
│   ├── llms.txt, robots.txt, sitemap.xml, _headers
│   ├── style.css & app.js
│   └── assets/
├── firebase.json               # Firestore kuralları ve Mission Control Firebase Hosting yapılandırması
├── firestore.rules             # Cloud Firestore güvenlik kuralları (7 dil + S-18/S-19/S-23 canlıda)
├── wrangler.json               # Cloudflare statik varlık dağıtım yapılandırması (getomakase)
├── GEMINI.md                   # Çalışma alanı geliştirici kuralları
└── README.md
```

---

## 🛠️ Hızlı Başlangıç

### 1. iOS Uygulamasını Çalıştırma (Fiziksel Cihaz veya Simulator)

```bash
# Bağlı fiziksel iPhone üzerinde derleyip başlatmak için (veya Cmd + Shift + B):
./scripts/launch-ios.sh

# iOS Simulator üzerinde derleyip başlatmak için:
./scripts/launch-simulator.sh
```

### 2. Canlı Backend Bilgisi

Backend Google Cloud Run üzerinde canlı yayındadır (`omakase-backend-00023-68f`):
* **Canlı URL:** `https://omakase-backend-20235796246.us-central1.run.app`
* **Sağlık Kontrolü:** `curl https://omakase-backend-20235796246.us-central1.run.app/health`

Lokal olarak çalıştırmak ve backend birim testlerini (`38/38`) koşmak için:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
pytest tests/ -q
```

---

## 📚 Kapsamlı Dokümantasyon Dizini

Detaylı rapor ve analizler için `docs/` klasörünü inceleyebilirsiniz:

| Doküman | Açıklama |
|---------|----------|
| [👑 **Master Rapor (Yönetici Özeti)**](docs/master_rapor.md) | **Tüm raporların (Mimari, PMF, Küresel Pazarlama, App Store, ASO ve Siber Güvenlik) tek belgede birleştirilmiş özeti.** |
| [📊 Proje Durum & Teknik Mimari Raporu](docs/proje_durum_ve_mimari_raporu.md) | Faz 1–4, WidgetKit, Misafir Tadımı, RevenueCat monetizasyon, APNs/FCM bildirimleri, Crashlytics ve 7 dil mimarisi. |
| [🧪 100 Müşteri Simülasyon Raporu](docs/founder_100_musteri_raporu.md) | `founder-skill` 100 müşteri simülasyonu (1. Tur `%1` → 2. Tur `%72`) ve Van Westendorp fiyatlandırma analizi. |
| [📄 App Store Raporu](docs/appstore_raporu.md) | Apple Agent Kit tabanlı App Review gönderimi (`Waiting for Review`, `APP_ID: 6838044134`), `PrivacyInfo.xcprivacy` (8 veri tipi) ve Xcode denetimi. |
| [🎯 **ASO & Web SEO / GEO Raporu**](docs/aso_ve_seo_raporu.md) | 9 yerel ayar App Store Connect metadata paketi, kategori/anahtar kelime analizi, `RatingPromptManager` ve `getomakase.app` SEO/GEO optimizasyonu. |
| [🛡️ Siber Güvenlik Raporu](docs/siber_guvenlik_raporu.md) | API anahtarları, Cloud Run backend, Firestore kuralları, iOS/WidgetKit ve Web siber güvenlik denetimi (`S-01`–`S-28`, 28/28 çözüldü). |
| [🚀 Küresel Pazarlama & Dağıtım Stratejisi](docs/pazarlama_ve_dagitim_stratejisi.md) | Tier-1 küresel açılım (US/UK), otomatize TikTok Photo Mode büyüme motoru, Paid UA matematiği ve sıfır bütçeli dağıtım kanalları. |
| [📈 Ürün Analizi & PMF Raporu](docs/urun_analizi_ve_pazarlama.md) | Product-Market Fit hipotezi, hedef personalar (ICP), AARRR hunisi, birim ekonomisi ve App Store (ASO) vitrin stratejisi. |