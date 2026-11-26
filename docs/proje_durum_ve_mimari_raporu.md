# 📊 Omakase — Proje Durum ve Teknik Mimari Raporu

> **Güncelleme Tarihi:** 26 Kasım 2026 · **Kapsam:** iOS İstemci ([omakase/](file:///Users/kuzey/projects/omakase/omakase)), UI Test Paketi ([omakaseUITests/](file:///Users/kuzey/projects/omakase/omakase/omakaseUITests)), Cloud Run Backend ([backend/](file:///Users/kuzey/projects/omakase/backend)), Mission Control Admin Paneli ([admin-web/](file:///Users/kuzey/projects/omakase/admin-web)), Tanıtım Web Sitesi ([web/](file:///Users/kuzey/projects/omakase/web)), Ekran Görüntüsü Stüdyosu ([app-store-screenshots/](file:///Users/kuzey/projects/omakase/app-store-screenshots)) ve Firestore Kuralları ([firestore.rules](file:///Users/kuzey/projects/omakase/firestore.rules))
> **Amaç:** Omakase v1.0 uygulamasının güncel mimarisini, tamamlanan geliştirme fazlarını (Faz 1–4 + 24–26 Kasım prodüksiyon genişletmeleri), cihaz-bazlı kota korumasını, Export Studio'yu, Mission Control admin/telemetri altyapısını, canlı envanteri ve App Store yayını öncesi kalan dış panel/dağıtım adımlarını tek dokümanda toplamak.

---

## 0. Yönetici Özeti (Proje Durum Panosu)

| Alan / Sistem | Durum | Özet & Kanıt |
|---|---|---|
| **Çekirdek AI Akış, Bento, 7 Dil & Kaynakça** | ✅ **Tamamlandı** | 12 disiplinli `BentoTasteBox` ([BentoTasteBox.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Interests/BentoTasteBox.swift)) + **24 dikey merak merceği** (`prompts.py` — 10.626 kombinasyon) + ön-ısıtmalı alt konular + başparmak bölgesi **Şefin Seçimi (Chef's Pick)** çekme/dokunma tetikleyicisi, **7 dil desteği** (`en, tr, ja, de, fr, es, ko`), zorunlu **birincil kaynakça** ([PostSourceView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Theme/PostSourceView.swift)), 15–25 sn okuma molası, Letterboxd RSS ve SwiftData çevrimdışı önbellek hidrasyonu. Manuel serbest konu girişi kaldırıldı. |
| **Kimlik Doğrulama, 3 Adımlı Giriş & Topluluk** | ✅ **Tamamlandı** | Sign in with Apple + Google Sign-In + E-posta ([AuthService.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift)), kayıt sonrası `ProfileSetupView` (adım 1.5), atomik `usernames/{handle}` rezervasyonu, **14 gün `@username` değiştirme beklemesi**, Hidden Folks tarzı `MonogramAvatarView`, 3 slaytlı ASCII suşi `OnboardingView`, Keşfet / Takip Edilenler segmentli topluluk, AI üretimi gönderi şikayet akışı (`reportAIPost`) ve hesap silmede tam yerel önbellek/yer imi temizliği. |
| **İnteraktif Dışa Aktarım Stüdyosu (Export Studio)** | ✅ **Tamamlandı** | [ExportPostSheet.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/ExportPostSheet.swift) ve [ShareCardView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/ShareCardView.swift): 3D sürükleme eğimli önizleme, **3 oran** (`Story` 1080×1920, `Post` 1080×1350, `Kare` 1080×1080), **4 monokrom tema** (`paper`, `ink`, `editorial`, `midnight`), kaynak/etiket/motif anahtarları, `getomakase.app` kopyala barı ve Instagram Stories / WhatsApp / X / Fotoğraflar'a Kaydet / Kopyala / Paylaş rıhtımı. |
| **Faz 1 — Hata Yönetimi, Telemetri & Geri Bildirim** | ✅ **Tamamlandı & Doğrulandı** | Canonical backend `code` + `Retry-After` ([errors.py](file:///Users/kuzey/projects/omakase/backend/app/errors.py)), iOS [OmakaseError.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/OmakaseError.swift) + Crashlytics non-fatal kaydı, izleme dışı etkileşim toplayıcısı ([TelemetryService.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/TelemetryService.swift)) ve Ayarlar içinden uygulama içi geri bildirim ekranı ([FeedbackSheetView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Profile/FeedbackSheetView.swift) → `POST /feedback`). |
| **Faz 2 — RevenueCat, 3 Post + 1 Letterboxd & Cihaz Kotası** | ✅ **Kod & Kurallar Tamamlandı** | `RevenueCat` SDK `5.103.2` (StoreKit 2), tek ekranlı ASCII suşi paywall ([OmakasePaywallView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Monetization/OmakasePaywallView.swift) — 5 tetikleyici kaynak), ücretsiz günde **3 post** (içinde **1 Letterboxd/gün** sınırı) + **1 Derin İnceleme** (`+1` paylaşım bonusu), Keychain `X-Omakase-Device-Id` + SHA-256 `device_usage` ile hesap değiştirme/silme suistimaline karşı cihaz bazlı kota kilidi, RevenueCat v2 metrik senkronu (`projfdc295f4`). |
| **Faz 3 — Bildirim Sistemi (Yerel + APNs/FCM)** | ✅ **Kod & Backend Tamamlandı** | `FirebaseMessaging` (`12.13.0`), [NotificationManager.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/NotificationManager.swift), bağlam içi izin (`[.alert, .sound]`, rozetsiz), `omakase.daily-menu` yerel hatırlatıcı, derin bağlantı ve 7 dilli push şablonları (`notification_service.py`). *Not:* `firestore.rules` içinde `devices` ve `notification_prefs` `language` kısıtının `en/tr`'den 7 dile genişletilmesi ve APNs `.p8` / Cloud Scheduler kurulumu bekleniyor. |
| **Faz 4 — Mission Control, Web, Gizlilik & Testler** | ✅ **Kod & Görseller Tamamlandı · ⏳ Panel/Deploy** | Firebase Hosting'e izole edilmiş **Mission Control** ([admin-web/](file:///Users/kuzey/projects/omakase/admin-web)), Cloudflare üzerinde yenilenmiş `getomakase.app` ([web/](file:///Users/kuzey/projects/omakase/web) — 8 slaytlı vitrin & 4 ekranlı canlı maket), **8 slayt × 7 dil** App Store ekran görüntüleri ([app-store-screenshots/](file:///Users/kuzey/projects/omakase/app-store-screenshots)), **7 veri tipli** [PrivacyInfo.xcprivacy](file:///Users/kuzey/projects/omakase/omakase/omakase/PrivacyInfo.xcprivacy), **32/32** backend testi ve **12** XCUITest ([omakaseUITests/](file:///Users/kuzey/projects/omakase/omakase/omakaseUITests)) hazır. |

---

## 1. Güncel Sistem Mimarisi ve Canlı Altyapı Envanteri

### 1.1. iOS Uygulaması ([omakase/](file:///Users/kuzey/projects/omakase/omakase))
- **Kimlik & Hedef:** Bundle ID `kuzeysinay.omakase` · Team ID `S88MSGP5UR` · SwiftUI + `@Observable` + SwiftData · `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` · **7 Dil** (`en, tr, ja, de, fr, es, ko` `.lproj` + `AppLanguage.systemDefault`).
- **Swift Package Bağımlılıkları ([Package.resolved](file:///Users/kuzey/projects/omakase/omakase/omakase.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved)):**
  - `firebase-ios-sdk` `12.13.0` (`FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`, `FirebaseCrashlytics`, `FirebaseMessaging`)
  - `GoogleSignIn-iOS` `10.0.0`
  - `purchases-ios-spm` (`RevenueCat`) `5.103.2`
- **Capabilities & `Info.plist` Yetkileri:**
  - [omakase.entitlements](file:///Users/kuzey/projects/omakase/omakase/omakase/omakase.entitlements): `com.apple.developer.applesignin` (`Default`) + `aps-environment` (`development`).
  - [Info.plist](file:///Users/kuzey/projects/omakase/omakase/omakase/Info.plist): `NSPhotoLibraryAddUsageDescription`, `LSApplicationQueriesSchemes` (`instagram-stories`, `instagram`, `whatsapp`, `twitter`), `OMAKASE_API_URL` ve `REVENUECAT_API_KEY`.
- **Ana Uygulama Katmanları:**
  - **Yaşam Döngüsü, Yönlendirme & Test Koşucuları:** [omakaseApp.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/App/omakaseApp.swift), [ContentView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/App/ContentView.swift) (`AuthView` → `ProfileSetupView` → `OnboardingView` → `MainTabView`), [MainTabView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/App/MainTabView.swift) (`Akışım` / `Topluluk` / `Profil`), `#if DEBUG` [UITestHarness.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/App/UITestHarness.swift) ve [ScreenshotPreviewHarness.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/App/ScreenshotPreviewHarness.swift).
  - **Kayıt, Onboarding & Profil:** [AuthView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift), [AuthService.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift), 3 slaytlı ASCII suşi [OnboardingView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Onboarding/OnboardingView.swift) (+ `ProfileSetupView`), [ProfileTabView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Profile/ProfileTabView.swift), [FeedbackSheetView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Profile/FeedbackSheetView.swift) ve ayrı Ayarlar ekranlı [UserProfileSheet.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift) (`MonogramAvatarView` + 14 gün `@username` düzenleme beklemesi).
  - **Akış, Bento & Dışa Aktarım:** [FeedView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/FeedView.swift), [FeedViewModel.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/FeedViewModel.swift), [BentoTasteBox.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Interests/BentoTasteBox.swift), [ExportPostSheet.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/ExportPostSheet.swift), [ShareCardView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/ShareCardView.swift) ve [PostSourceView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Theme/PostSourceView.swift).
  - **Servisler & Monetizasyon:** [AccessManager.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/AccessManager.swift), [TelemetryService.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/TelemetryService.swift), [NotificationManager.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/NotificationManager.swift), [OmakaseError.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/OmakaseError.swift), [FirestoreService.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift), [PostCacheService.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/PostCacheService.swift), [ContentModerationService.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/ContentModerationService.swift), [ShareService.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/ShareService.swift), [OmakasePaywallView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Monetization/OmakasePaywallView.swift), [DailyLimitCardView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Monetization/DailyLimitCardView.swift).
  - **Otomatik UI Test Paketi ([omakaseUITests/](file:///Users/kuzey/projects/omakase/omakase/omakaseUITests)):** 5 test dosyasında (`AppLaunchSmokeUITests`, `AuthFlowUITests`, `OnboardingUITests`, `FeedAndBentoUITests`, `CommunityAndMonetizationUITests`) toplam **12 XCUITest** çevrimdışı `UITestHarness` üzerinde koşar.

### 1.2. Cloud Run Backend ([backend/](file:///Users/kuzey/projects/omakase/backend))
- **Servis:** `omakase-backend` · Bölge `us-central1` · GCP/Firebase Proje `gen-lang-client-0120875563` · Canlı URL `https://omakase-backend-20235796246.us-central1.run.app` (24–26 Kasım'daki `/admin/*`, `/telemetry/*`, `/feedback`, Letterboxd 1/gün limiti ve cihaz-bazlı kota koruması için güncel deploy gerekir).
- **Bağımlılıklar ([requirements.txt](file:///Users/kuzey/projects/omakase/backend/requirements.txt)):** `fastapi==0.115.5`, `uvicorn[standard]==0.32.1`, `google-genai==1.47.0`, `pydantic==2.9.2`, `python-dotenv==1.0.1`, `firebase-admin==6.6.0`, `httpx==0.28.1`, `tzdata==2024.2`.
- **Aktif Uç Noktalar (7 Router — [main.py](file:///Users/kuzey/projects/omakase/backend/main.py)):**

| Yöntem & Yol | Router | Yetkilendirme / Koruma | Görev |
|---|---|---|---|
| `GET /health` | [main.py](file:///Users/kuzey/projects/omakase/backend/main.py) | Açık | Minimal canlılık kontrolü (`{"status":"ok"}`) |
| `POST /feed/stream` | [feed.py](file:///Users/kuzey/projects/omakase/backend/app/routers/feed.py) | Firebase ID Token + rate limit (`20/dk`) + `plate` & (`letterboxd`) kotası + `X-Omakase-Device-Id` | Tekil post SSE yayını; başarılı `done` çıktısında kota düşer |
| `POST /feed/deep-dive` | [feed.py](file:///Users/kuzey/projects/omakase/backend/app/routers/feed.py) | Firebase ID Token + rate limit (`20/dk`) + `deep_dive` kotası + `X-Omakase-Device-Id` | Derinlemesine inceleme SSE yayını |
| `POST /feed/reward-share` | [feed.py](file:///Users/kuzey/projects/omakase/backend/app/routers/feed.py) | Firebase ID Token + rate limit (`10/dk`) + Firestore transaction (`usage` + `device_usage`) | Günde 1 kez paylaşımla `+1` bonus Derin İnceleme açar |
| `POST /interests/suggest`, `/interests/expand-category` | [interests.py](file:///Users/kuzey/projects/omakase/backend/app/routers/interests.py) | Firebase ID Token + rate limit + günlük kota (`suggestion`) | İlgi alanı / 24 merak merceğiyle alt konu üretimi (7 dil) |
| `POST /letterboxd/films` | [letterboxd.py](file:///Users/kuzey/projects/omakase/backend/app/routers/letterboxd.py) | Firebase ID Token + rate limit (`10/dk`) | Letterboxd RSS okuma ve kanonik 404/403/502 eşlemesi |
| `GET /billing/status`, `POST /billing/sync` | [billing.py](file:///Users/kuzey/projects/omakase/backend/app/routers/billing.py) | Firebase ID Token + rate limit (`30/dk`, `10/dk`) + `X-Omakase-Device-Id` | Pro yetkisi + kullanıcı/cihaz birleşik günlük kota özeti ve RevenueCat REST v1 sync |
| `POST /billing/revenuecat-webhook` | [billing.py](file:///Users/kuzey/projects/omakase/backend/app/routers/billing.py) | `REVENUECAT_WEBHOOK_SECRET` (`hmac.compare_digest`) | RevenueCat abonelik olaylarını Firestore'a, `metrics_daily`'ye ve opsiyonel `ADMIN_ALERT_WEBHOOK_URL`'ye işler |
| `POST /notifications/events`, `/notifications/process-queue` | [notifications.py](file:///Users/kuzey/projects/omakase/backend/app/routers/notifications.py) | Firebase ID Token / `NOTIFICATION_CRON_SECRET` (`hmac.compare_digest`) | Yorum/takip/tepki olayları ve `notification_queue` teslimatı |
| `POST /telemetry/events`, `POST /feedback` | [telemetry.py](file:///Users/kuzey/projects/omakase/backend/app/routers/telemetry.py) | Firebase ID Token + rate limit (`60/dk`, `5/dk`) | Allowlist'li izleme dışı ürün telemetrisi (`metrics_daily`, `daily_active`) ve uygulama içi geri bildirim (`user_feedback` + admin webhook uyarısı) |
| `GET /admin/me`, `/overview`, `/feedback`, `/reports`, `/users`, `/export`, `PATCH /admin/feedback/{id}`, `/reports/{id}` | [admin.py](file:///Users/kuzey/projects/omakase/backend/app/routers/admin.py) | `verify_admin_user` (`ADMIN_UIDS` / doğrulanmış `ADMIN_EMAILS`) + rate limit (`20–60/dk`) | Mission Control KPI, RevenueCat v2 (`projfdc295f4`) + Gemini maliyet analizi, geri bildirim/moderasyon triyajı ve AI Agent export (`launch`, `conversion`, `triage`, `growth`) |

- **Otomatik Backend Testleri:** [test_error_contract.py](file:///Users/kuzey/projects/omakase/backend/tests/test_error_contract.py), [test_billing_and_quota.py](file:///Users/kuzey/projects/omakase/backend/tests/test_billing_and_quota.py), [test_notifications.py](file:///Users/kuzey/projects/omakase/backend/tests/test_notifications.py), [test_stream_parser.py](file:///Users/kuzey/projects/omakase/backend/tests/test_stream_parser.py) ve [test_admin_and_telemetry.py](file:///Users/kuzey/projects/omakase/backend/tests/test_admin_and_telemetry.py) toplam **32/32** birim testiyle doğrulandı (26 Kasım 2026 itibarıyla geçti).

### 1.3. Firestore Güvenlik Kuralları ([firestore.rules](file:///Users/kuzey/projects/omakase/firestore.rules))
Güncel erişim matrisi (`gen-lang-client-0120875563`):

| Koleksiyon / Alt Koleksiyon | Okuma | Yazma / Silme | Güvenlik Kısıtları |
|---|---|---|---|
| `users/{userId}` | Oturumlu kullanıcı | Yalnızca sahip (`isOwner`) | `hasOnly` şema beyaz listesi (`usernameUpdatedAt`, `profileSetupCompleted` dahil), `isPro`/`quota`/`usage` yazım yasağı ve `isValidUsernameUpdate()` ile **14 gün kullanıcı adı bekleme zorunluluğu** |
| `usernames/{handle}` | Oturumlu kullanıcı | `create`: `uid == auth.uid`; `update`: **kapalı**; `delete`: sahip | `^[a-z0-9_.]{3,20}$` regex + `!exists(...)` ile atomik benzersizlik rezervasyonu |
| `users/{userId}/following`, `followers`, `blocked_users` | Oturumlu (`blocked_users`: sahip) | Sahip / karşı taraf kurallı | Kendini takip etme yasağı, engelli kullanıcıların takip etmesini engelleyen çapraz `exists` kontrolü ve `hasOnly` |
| `users/{userId}/devices/{deviceId}`, `notification_prefs/{prefId}` | Sahip | Sahip | `platform == 'ios'`, `prefId == 'settings'`. *Küçük takip maddesi:* Kurallardaki `language in ['en', 'tr']` kontrolü yakında 7 dili (`en, tr, ja, de, fr, es, ko`) kapsayacak şekilde güncellenmelidir. |
| `shared_posts/{postId}`, `reactions`, `comments` | Oturumlu | Kurallı sahip / etkileşim | Değişmez `authorId`, `reportedBy` küçültme yasağı, `commentCount` ±1 ve alan bazlı diff doğrulaması |
| `moderation_reports/{reportId}` | Kapalı | Oturumlu (`create`) | `reporterUid == request.auth.uid` (kullanıcı, yorum ve AI gönderi raporları) |
| `entitlements/{userId}`, `usage/{docId}` | Sahip (`^{uid}_[0-9]{8}$`) | **Kapalı** (`false`) | Yalnızca Cloud Run Firebase Admin SDK yazar |
| `device_usage/{docId}`, `metrics_daily/{date}`, `daily_active/{docId}`, `user_feedback/{id}`, `notification_queue/{docId}`, `notification_cooldowns/{docId}` | **Kapalı** (`false`) | **Kapalı** (`false`) | Varsayılan red (default-deny) altında yalnızca Cloud Run Admin SDK erişir |

### 1.4. Mission Control (`admin-web/`), Tanıtım Sitesi (`web/`) & Ekran Görüntüsü Stüdyosu (`app-store-screenshots/`)
- **Mission Control ([admin-web/](file:///Users/kuzey/projects/omakase/admin-web)):** `web/`'den tamamen ayrılıp yalnızca **Firebase Hosting**'e (`firebase.json` → `"public": "admin-web"`, `/` → `/admin` 302 yönlendirmesi, `X-Robots-Tag: noindex, nofollow`, COOP, HSTS ve sıkı CSP) taşınmıştır. Google/E-posta Firebase Auth kapısı + Demo Modu, 5 sekme (`Genel Bakış`, `Gelir & AI`, `Geri Bildirim`, `Moderasyon`, `Kullanıcılar`), `7g`/`14g`/`30g` pencere seçimi, 60s canlı yenileme, Metrik Sözlüğü (`?`) ve **Agent'a Aktar** (`launch`, `conversion`, `triage`, `growth` Markdown/JSON brifingleri) içerir.
- **Tanıtım Sitesi ([web/](file:///Users/kuzey/projects/omakase/web) — `getomakase.app`):** [wrangler.json](file:///Users/kuzey/projects/omakase/wrangler.json) ile **Cloudflare** statik barındırma üzerinden sunulur. 25 Kasım'da ASCII suşi arka planı, **8 slaytlı App Store vitrini (`#screenshots`)**, **4 ekranlı canlı iPhone maketi** (`Akışım`, `Bento Keşif`, `Topluluk`, `Profil`), Canlı Tadım demosu ve güncellenmiş kopyalarla yenilenmiştir.
- **App Store Screenshot Studio ([app-store-screenshots/](file:///Users/kuzey/projects/omakase/app-store-screenshots)):** Next.js editörü (`app-store-screenshots.json`) ile **8 slayt × 7 dil** (`en, tr, ja, de, fr, es, ko`), **4 iPhone çözünürlüğünde** (`1125×2436`, `1206×2622`, `1284×2778`, `1320×2868`) dışa aktarılmıştır.

---

## 2. Monetizasyon, Paywall ve Cihaz-Bazlı Kota Koruması *(Faz 2 + 25 Kasım Güncellemesi)*

### 2.1. "Günün Menüsü" Freemium Modeli & Paylaşım Ödülü
Günlük sınırlar sunucu tarafında ([config.py](file:///Users/kuzey/projects/omakase/backend/app/config.py), [access_service.py](file:///Users/kuzey/projects/omakase/backend/app/services/access_service.py)) yönetilir:

| Özellik | Ücretsiz | Omakase Pro (Adil Kullanım Tavanı) |
|---|---|---|
| Günlük AI post (`feed` / Bento alt konu / Şefin Seçimi) | **Günde 3** (`Kalan: X/3` stres sayacı) | Sınırsız UI (sunucuda `100/gün`) |
| Letterboxd günlük post kotası | **Günde 1** (3 günlük post hakkının içinden sayılır) | Sınırsız UI (sunucuda `100/gün`) |
| Derin İnceleme (Deep Dive) | **Günde 1** (+ **günde 1 kez paylaşımda `+1` ödül**) | Sınırsız UI (sunucuda `40/gün`) |
| Alt konu önerisi (`suggest` / `expand-category`) | **Günde 10** | Sınırsız UI (sunucuda `100/gün`) |
| Topluluk (Keşfet/Takip), Export Studio & yer imleri | Tamamen ücretsiz | Tamamen ücretsiz + Profil/kartlarda `PRO` rozeti |
| Okuma bekleme süresi (cooldown ritüeli) | 15–25 sn | Aynı (marka değeri, ücretli kaldırılmaz) |

- **Doğru sayım & kopma koruması:** Kota yalnızca Gemini akışı başarıyla `event: done` verdiğinde düşülür (`on_complete`); hata, safety block veya istemci bağlantısının kesilmesi (`request.is_disconnected`) hak yemez.
- **Cihaz-Bazlı Anti-Abuse (`device_usage`):** [SSEClient.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift) içinde `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` ile Keychain'de saklanan anonim kurulum kimliği (`X-Omakase-Device-Id`, çıkışta veya hesap silmede sıfırlanmaz, iCloud'a senkronlanmaz) sunucuda SHA-256 ile özetlenerek `device_usage/{hash}_{yyyymmdd}` belgesinde tutulur ve ücretsiz katman için `max(user_usage, device_usage)` birleşimi uygulanır. Böylece Apple/Google/E-posta arasında hesap aç-sil/değiştir ile günlük 3 post sınırının aşılması engellenir.

### 2.2. Fiyat, Paketler ve 5 Paywall Temas Noktası
- Abonelik grubu: **Omakase Pro** — `omakase.pro.yearly` (**\$29.99/yıl**, `~$2.49/ay`, **7 gün ücretsiz deneme**) ve `omakase.pro.monthly` (**\$3.99/ay**).
- Tek ekranlı, iç kaydırmasız ASCII suşi arka planlı ve buzlu karşılaştırma kartlı [OmakasePaywallView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Monetization/OmakasePaywallView.swift) 5 bağlamsal `PaywallSource` üzerinden açılır: `firstPlateSoft` (ilk okuma sonrası tek sefer), `plateLimit` (3/3 dolunca veya üst bar sayacından), `deepDiveLimit` (2. Derin İnceleme denemesi), `letterboxdLimit` (günlük 1 Letterboxd sınırı dolunca) ve `profile` (Profildeki ink-on-paper Pro CTA).

### 2.3. RevenueCat v1/v2 & Sunucu Senkronizasyonu
- İstemci tarafında StoreKit 2 + `.with(entitlementVerificationMode: .informational)` ve `verification != .failed` kontrolü çalışır ([AccessManager.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/AccessManager.swift)).
- Backend tarafında `/billing/sync` (v1 REST) ve `/billing/revenuecat-webhook` `entitlements/{uid}` belgesini günceller; ayrıca [billing_service.py](file:///Users/kuzey/projects/omakase/backend/app/services/billing_service.py) içinde `fetch_revenuecat_overview_metrics` (`REVENUECAT_V2_SECRET_API_KEY`, proje `projfdc295f4`, 5 dk TTL önbellek + Firestore fallback) ile Mission Control'e canlı 28 günlük RevenueCat metrikleri aktarılır.

---

## 3. Bildirim Sistemi *(Faz 3 — Uygulandı)*

### 3.1. İzin Akışı ve Delegate Yaşam Döngüsü
- Açılışta veya 3 slaytlı onboarding sırasında izin istenmez; izin yalnızca limit kartındaki **Yarın Hatırlat**, Profil/Ayarlar → **Bildirimler** anahtarları veya ilk yorum sonrası **Bildirimleri Aç** çubuğuyla tetiklenir.
- [NotificationManager.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/NotificationManager.swift) `[.alert, .sound]` ister (rozet yok), `omakaseApp.swift` launch öncesi delegate ve 3 kategori kaydeder; `willPresent` sessizce `.omakaseDidReceiveForegroundNotification` yayınlar, `didReceive` tüm dallarda `completionHandler()` çağırarak `Akışım` veya `CommentsView(postId:)` derin bağlantısına yönlendirir.

### 3.2. Yerel Hatırlatıcı ve Sosyal Push Politikası
- **Yerel "Günün Menüsü" (`omakase.daily-menu`):** Varsayılan `09:00` saatinde planlanır; o günkü menü bittiyse sonraki güne ötelenir.
- **Sosyal Push Kuralları ([notification_service.py](file:///Users/kuzey/projects/omakase/backend/app/services/notification_service.py)):** İlk yorum anlık, 30 dk içindeki veya `22:00–08:00` sessiz saatlerdeki yorumlar gruplanır (`08:30` teslim); takipçi/tepkiler yalnızca `19:00` günlük özetinde birleşir; tüm metinler 7 dili destekler ve çift taraflı `blocked_users` kontrolünden geçer.

---

## 4. Hata Yönetimi, Telemetri ve Geri Bildirim *(Faz 1 + 25 Kasım Güncellemesi)*

1. **Kanonsal Hata Sözleşmesi:** Backend her hatada ([errors.py](file:///Users/kuzey/projects/omakase/backend/app/errors.py)) sabit `code` + opsiyonel `Retry-After` döner; iOS [OmakaseError.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/OmakaseError.swift) + 7 dilli [L10n.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Localization/L10n.swift) ile teknik metin göstermeden satır içi banner, toast veya alert sunar ve ham hataları **Firebase Crashlytics**'e non-fatal kaydeder.
2. **İzleme Dışı Ürün Telemetrisi ([TelemetryService.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/TelemetryService.swift)):** `app_open`, `onboarding_started`, `onboarding_skipped`, `cooldown_completed`, `paywall_viewed` (kaynak bazlı), `source_tapped` gibi allowlist'li olayları 8 olaylık veya 15 sn'lik partiler halinde `POST /telemetry/events` ucuna gönderir (`metrics_daily` + `daily_active`). Reklam amaçlı cross-app tracking (`NSPrivacyTracking: false`) yoktur.
3. **Uygulama İçi Geri Bildirim ([FeedbackSheetView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Profile/FeedbackSheetView.swift)):** 4 kategori (`bug`, `idea`, `content`, `other`), opsiyonel 1–5★ memnuniyet puanı ve 3–2000 karakter mesajı `POST /feedback` ucuna iletir; `user_feedback` koleksiyonuna kaydedilir ve `ADMIN_ALERT_WEBHOOK_URL` tanımlıysa anlık bildirim atar.

---

## 5. Faz İlerlemesi, Kalan İşler ve v1.0 Yayın Kontrol Listesi

```mermaid
flowchart LR
    F1["✅ Faz 1 — Hata, Crashlytics & Telemetri<br/>OmakaseError + Feedback + TelemetryService"] --> F2["✅ Faz 2 — RevenueCat, 3/1 Kota & Anti-Abuse<br/>Paywall + Letterboxd 1/gün + Device Hash"]
    F2 --> F3["✅ Faz 3 — Bildirim Sistemi<br/>Yerel + 7 Dilli FCM + Quiet Hours"]
    F3 --> F4["✅ Faz 4 (Kod/Web/Admin/Test)<br/>Mission Control + Export Studio + 8x7 Görseller + 32/12 Test → ⏳ Deploy/Panel → 🚀 v1.0"]
```

### 5.1. Son Tamamlananlar & Yayın Öncesi Kalan Teknik/Yasal Maddeler
- [x] **Gizlilik Manifesti (`PrivacyInfo.xcprivacy`):** `PurchaseHistory`, `CrashData`, `OtherUserContent` ve `ProductInteraction` (`Analytics`, Tracking `false`) dahil 7 veri tipi eklendi.
- [x] **Otomatik Doğrulama:** Backend **32/32** birim testi ve iOS **12** XCUITest (`omakaseUITests/`) tamamlandı.
- [ ] **Küçük Takip Düzeltmeleri (Kod/Web):**
  - `firestore.rules` (satır 330 & 368) içinde `devices` ve `notification_prefs` `language` doğrulamasının `['en', 'tr']` yerine 7 dili (`en, tr, ja, de, fr, es, ko`) kabul edecek şekilde genişletilmesi.
  - `web/privacy.html` ve `web/terms.html` sayfalarının (şu an `22 Kasım 2026` tarihli) `ProductInteraction` analitiği, uygulama içi geri bildirim (`user_feedback`), 1/gün Letterboxd kotası ve anonim cihaz kota özeti maddeleriyle güncellenmesi.
- [ ] **Canlı Dağıtımlar (CLI):**
  - Cloud Run güncel backend deploy'u (`cd backend && gcloud run deploy omakase-backend --source . --region us-central1 --project gen-lang-client-0120875563` — `REVENUECAT_V2_SECRET_API_KEY`, `ADMIN_UIDS`, opsiyonel `ADMIN_ALERT_WEBHOOK_URL` ortam değişkenleriyle).
  - Firebase Hosting (`admin-web/`) & `firestore:rules` deploy'u (`firebase deploy --only firestore:rules,hosting --project gen-lang-client-0120875563`).
  - Cloudflare Pages/Assets (`web/` — `getomakase.app`) deploy'u (`npx wrangler deploy` / Cloudflare dashboard).

### 5.2. Kalan Dış Panel Aksiyonları *(Apple / RevenueCat / Firebase / GCP)*
- [ ] **Apple Developer & App Store Connect:** Paid Apps Agreement (`Active`) onayı; `omakase.pro.monthly` & `omakase.pro.yearly` fiyat/localization/review screenshot kontrolü; App Store Gizlilik Etiketi (`ProductInteraction` dahil 7 tip); Demo Hesap bilgisi; 8 slayt × 7 dil ekran görüntüsü yüklemesi; Xcode Archive + `Generate Privacy Report` + `Validate App` + `Distribute App`.
- [ ] **RevenueCat:** Webhook (`https://omakase-backend-20235796246.us-central1.run.app/billing/revenuecat-webhook`) **Send Test Event** (`200 OK`), Sandbox satın alma/restore doğrulaması ve `REVENUECAT_V2_SECRET_API_KEY` kontrolü.
- [ ] **Firebase & GCP:** `S-03` iOS `API_KEY` (`kuzeysinay.omakase`) API kısıtlaması (`Generative Language API` hariç), **Apple** Sign-in sağlayıcısı aktivasyonu, **APNs `.p8`** yüklemesi ve Cloud Scheduler (`/notifications/process-queue` 15 dk cron).

---

## 6. Kullanılan Skill'ler ve Bilgi Sözleşmeleri (`AGENTS.md` gereği)

| Skill | Yüklenen Bilgi Sözleşmeleri (Knowledge Contracts) | Kullanım Amacı |
|---|---|---|
| `app-store-review-guidelines` | `digital-goods-iap`, `restore-purchases`, `user-generated-content-moderation` | Dijital Pro yetkilerinin IAP ile açılması, Geri Yükle butonu ve AI/UGC raporlama |
| `storekit` | `product-loading-and-purchase`, `transaction-verification-and-entitlements`, `transaction-updates-and-restoring-purchases` | Ürün yükleme, JWS doğrulama, `customerInfoStream` ve restore akışı |
| `usernotifications` | `authorization-request`, `local-notification-scheduling`, `remote-push-registration`, `notification-delegate-handling`, `notification-actions-and-categories`, `managing-pending-delivered-and-badge` | Ön ayar kontrolü, tek seferlik izin, sabit `omakase.daily-menu`, launch öncesi delegate ve rozet `0` temizliği |
| `human-interface-guidelines-patterns` | `notifications`, `feedback`, `onboarding` | Bildirim zamanlama, 3 katmanlı hata geri bildirimi ve sürtünmesiz 3 slaytlı başlangıç |
| `human-interface-guidelines` / `-components` | `privacy`, `alerts` | Bağlam içi izin ve uyarı sınırları |
| `style-guide` | `app-state-and-error-terminology` | Kullanıcı dostu, suçlamasız çok dilli hata ve boş durum metinleri |

> [!NOTE]
> **Kit dışı 3. parti entegrasyonlar:** RevenueCat `purchases-ios` SDK'sı (`5.103.2`), RevenueCat REST v1/v2 & Webhook senkronizasyonu, Firebase Crashlytics, `firebase-admin` Messaging, Cloudflare Wrangler statik barındırma ve Mission Control admin arayüzü Apple Agent Kit kapsamı dışındadır; kod incelemesi ve backend birim testleriyle (`32/32`) doğrulanmıştır.
