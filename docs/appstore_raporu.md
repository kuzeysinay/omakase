# 🍣 Omakase — App Store Gönderim Denetimi & Prodüksiyon Raporu

> **Son Güncelleme:** 26 Kasım 2026 (7 Veri Tipli `PrivacyInfo`, AI Gönderi Raporlama, Mission Control Moderasyon, Export Studio, 12 XCUITest & 8×7 Ekran Görüntüsü Tamamlandı)  
> **Denetim Metodolojisi:** Apple Agent Kit — `workflow.app-store-submission` (`skill.app-store-review-guidelines.submission` → `skill.privacy.foundations` → `skill.xcode.foundations`) & `workflow.authentication` (`skill.authenticationservices.foundations` → `skill.security.foundations` → `skill.style-guide.writing` → `skill.accessibility.foundations`)  
> **Amaç:** Uygulamanın ve web/admin altyapısının (`omakase/`, `backend/`, `web/`, `admin-web/`, `firestore.rules`, `app-store-screenshots/`) App Store Connect gönderimi öncesinde tespit edilen tüm kritik red sebeplerinin giderilmesi ve güncel prodüksiyon uyumunun belgelenmesi.

---

## İçindekiler

1. [Yönetici Özeti: Tespit Edilen Kırmızı Bayraklar ve Çözüm Durumu](#1-yönetici-özeti-tespit-edilen-kırmızı-bayraklar-ve-çözüm-durumu)
2. [Kapı 1: App Review Kılavuzu Uyumluluk Denetimi (`skill.app-store-review-guidelines.submission`)](#2-kapı-1-app-review-kılavuzu-uyumluluk-denetimi)
3. [Kapı 2: Gizlilik Manifestosu ve Veri Beyanı Denetimi (`skill.privacy.foundations`)](#3-kapı-2-gizlilik-manifestosu-ve-veri-beyanı-denetimi)
4. [Kapı 3: Xcode, İmzalama, Güvenlik ve Arşiv Denetimi (`skill.xcode.foundations`)](#4-kapı-3-xcode-imzalama-güvenlik-ve-arşiv-denetimi)
5. [Güncel Sistem Mimarisi ve Bileşen Durumu](#5-güncel-sistem-mimarisi-ve-bileşen-durumu)
6. [Adım Adım Yayına Hazırlık Eylem Planı (Checklist)](#6-adım-adım-yayına-hazırlık-eylem-planı-checklist)
7. [Apple Agent Kit İzlenebilirlik Özeti (Workflow, Skill ve Knowledge Contracts)](#7-apple-agent-kit-izlenebilirlik-özeti)

---

## 1. Yönetici Özeti: Tespit Edilen Kırmızı Bayraklar ve Çözüm Durumu

İlk denetimde tespit edilen **7 kritik bulgunun tamamı** kod tabanında, güvenlik kurallarında ve web/admin altyapısında çözülmüştür:

| # | Durum | Kategori / Kural | Yapılan Düzeltme & Uygulama Özeti | İlgili Dosya |
|---|-------|------------------|-----------------------------------|--------------|
| **1** | ✅ **ÇÖZÜLDÜ** | **Kural 5.1.2** — `PrivacyInfo.xcprivacy` | `PrivacyInfo.xcprivacy` güncellendi: `NSPrivacyAccessedAPICategoryUserDefaults` (`CA92.1`), `NSPrivacyTracking: false` ve **7 toplanan veri tipi** (`Name`, `EmailAddress`, `UserID`, `PurchaseHistory`, `CrashData`, `OtherUserContent`, `ProductInteraction`). | [`omakase/omakase/PrivacyInfo.xcprivacy`](file:///Users/kuzey/projects/omakase/omakase/omakase/PrivacyInfo.xcprivacy) |
| **2** | ✅ **ÇÖZÜLDÜ** | **Kural 4.8** — Sign in with Apple | `AuthenticationServices` + `CryptoKit` (SHA256 Nonce) + Keychain (`appleIDUser`) + `getCredentialState` + `credentialRevokedNotification` + kayıt sonrası `ProfileSetupView` ve atomik `usernames/{handle}` rezervasyonu. | [`Auth/AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift), [`Auth/AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift), [`Onboarding/OnboardingView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Onboarding/OnboardingView.swift) |
| **3** | ✅ **ÇÖZÜLDÜ** | **Kural 5.1.1(v)** — Hesap Silme | `AuthService.deleteAccount(l10n:)` ve `FirestoreService.deleteAllUserData(uid:)` Apple token iptali, Firestore temizliği, SwiftData önbellek (`PostCacheService`) ve `BookmarkStore` temizliği yapar. | [`Auth/AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift), [`Services/FirestoreService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift) |
| **4** | ✅ **ÇÖZÜLDÜ** | **Kural 1.2** — UGC & AI İçerik Moderasyonu | 1) `ContentModerationService.isAppropriate` ön filtresi (yorum, `displayName`, `@username`).<br>2) Gönderi (`reportPost`), Yorum (`reportComment`), Profil (`reportUser`) ve **AI Üretimi Post (`reportAIPost`)** şikayetleri `moderation_reports` koleksiyonuna yazılır.<br>3) `blockUser` anında akışı gizler; **Mission Control (`admin-web/`)** 24 saatlik inceleme triyajı sunar. | [`Services/ContentModerationService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/ContentModerationService.swift), [`Feed/FeedView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/FeedView.swift), [`admin-web/admin.html`](file:///Users/kuzey/projects/omakase/admin-web/admin.html) |
| **5** | ✅ **ÇÖZÜLDÜ** | **Kural 1.2, 1.5 & 5.1.1(i)** — İletişim, Geri Bildirim & Yasal Sayfalar | `MyProfileSheet` / Ayarlar ve `AuthView` içinde **Destek (`mailto:destek@getomakase.app`)**, **Uygulama İçi Geri Bildirim (`FeedbackSheetView`)**, **Gizlilik Politikası (`privacy.html`)** ve **Kullanım Koşulları (`terms.html`)** bağlıdır. *(Not: `privacy.html` / `terms.html` son telemetri ve cihaz kota maddeleri için güncellenmelidir.)* | [`Profile/FeedbackSheetView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Profile/FeedbackSheetView.swift), [`web/privacy.html`](file:///Users/kuzey/projects/omakase/web/privacy.html), [`web/terms.html`](file:///Users/kuzey/projects/omakase/web/terms.html) |
| **6** | ✅ **ÇÖZÜLDÜ** | **Kural 1.6** — Veri Güvenliği (`firestore.rules`) | `users`, `usernames`, `following`, `followers`, `blocked_users`, `shared_posts`, `reactions`, `comments` ve `moderation_reports` için `hasOnly` + sahip/şema doğrulamalı kurallar; sunucu koleksiyonları (`entitlements`, `usage`, `device_usage`, `metrics_daily`, `user_feedback`) korumalı. | [`firestore.rules`](file:///Users/kuzey/projects/omakase/firestore.rules) |
| **7** | ✅ **ÇÖZÜLDÜ** | **Kural 1.6 & 2.1(a)** — `Info.plist`, ATS & Telemetri Temizliği | Yerel HTTP istisnaları ve `Release` `NSLocalNetworkUsageDescription` kaldırıldı; `ExportPostSheet` için `LSApplicationQueriesSchemes` (`instagram-stories`, `instagram`, `whatsapp`, `twitter`) ve `NSPhotoLibraryAddUsageDescription` eklendi. | [`omakase/omakase/Info.plist`](file:///Users/kuzey/projects/omakase/omakase/omakase/Info.plist), [`Networking/SSEClient.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift) |

---

## 2. Kapı 1: App Review Kılavuzu Uyumluluk Denetimi (`skill.app-store-review-guidelines.submission`)

### 2.1. Giriş Servisleri ve Eşdeğer Seçenek Zorunluluğu — Kural 4.8 (✅ Tamamlandı)
* **Dayanak:** `knowledge.app-store-review-guidelines.login-services-equivalent-option`, `workflow.authentication`
* **Yapılan Uygulama:**
  - [`AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift) içinde `AuthenticationServices` ve `CryptoKit` kullanılarak `signInWithApple()` metodu, kriptografik nonce + SHA256 özeti, yalnızca ilk girişte dönen `fullName` yakalama, Keychain (`appleIDUser`) saklama, `getCredentialState` ve `credentialRevokedNotification` dinleyicisi uygulanmıştır.
  - Apple, Google veya eksik profilli kullanıcılar giriş sonrası `ProfileSetupView` ([`Onboarding/OnboardingView.swift#L350`](file:///Users/kuzey/projects/omakase/omakase/omakase/Onboarding/OnboardingView.swift#L350)) üzerinden görünür ad + atomik benzersiz `@username` (`usernames/{handle}`) belirler; `@username` değişimi 14 günlük bekleme süresiyle sınırlandırılmıştır.
  - [`AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift) ekranında **"Apple ile devam et" / "Continue with Apple"** butonu Google Sign-In butonunun üstünde, eşit boyut ve görsel ağırlıkta yer alır.

### 2.2. Kullanıcı Tarafından Oluşturulan İçerik (UGC) & AI İçerik Moderasyonu — Kural 1.2 (✅ Tamamlandı)
* **Dayanak:** `knowledge.app-store-review-guidelines.user-generated-content-moderation`
* **Yapılan Uygulama (4 Zorunlu Mekanizma + AI Raporlama & Admin Triyajı):**
  1. **Yayın Öncesi Sakıncalı İçerik Filtresi:** [`ContentModerationService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/ContentModerationService.swift) yorumlarda (`CommentsView.sendComment()`), `displayName` ve `@username` adımlarında zorunludur; backend tarafında da `_BLOCKLIST_RE` ve Gemini `BLOCK_MEDIUM_AND_ABOVE` güvenlik filtreleri çalışır.
  2. **Şikayet Mekanizması (UGC + AI Post):**
     - Topluluk gönderileri (`reportPost`), yorumlar (`reportComment`) ve profiller (`reportUser`) yanında **ana akıştaki AI üretimi gönderiler** de üç nokta (`ellipsis`) menüsü üzerinden (`FirestoreService.reportAIPost` → `moderation_reports`) bildirilebilir ([`FeedView.swift#L1012-L1360`](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/FeedView.swift#L1012-L1360)).
     - Gelen şikayetler **Mission Control (`admin-web/`) Moderasyon sekmesi** ve `PATCH /admin/reports/{report_id}` üzerinden 24 saat içinde incelenip çözülebilir veya ilgili gönderi silinebilir.
  3. **Kötü Niyetli Kullanıcıları Engelleme:** `blockUser(targetUid:currentUid:)` karşı kayıtları ve karşılıklı takibi temizler, `.omakaseDidUpdateBlockedUsers` ile tüm akıştan, yorumlardan ve aramadan anında gizler.
  4. **Yayınlanmış İletişim Bilgisi:** `mailto:destek@getomakase.app` Ayarlar ve `AuthView` içinde erişilebilirdir.

### 2.3. Geliştirici İletişim Bilgileri, Geri Bildirim & Yasal Web Sayfaları — Kural 1.5 & 5.1.1(i) (✅ Kod Hazır · ⏳ Yasal Metin Güncellemesi)
* Ayarlar (ayrı ekran — [`UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift)) ve `AuthView` içinde **Destek (`mailto:destek@getomakase.app`)**, **Geri Bildirim Gönder ([`FeedbackSheetView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Profile/FeedbackSheetView.swift))**, **Gizlilik Politikası (`https://getomakase.app/privacy.html`)** ve **Kullanım Koşulları (`https://getomakase.app/terms.html`)** yer alır.
* *Not:* [`web/privacy.html`](file:///Users/kuzey/projects/omakase/web/privacy.html) ve [`web/terms.html`](file:///Users/kuzey/projects/omakase/web/terms.html) şu an `22 Kasım 2026` tarihlidir; gönderim öncesi `ProductInteraction` analitiği, uygulama içi geri bildirim, günlük 1 Letterboxd ücretsiz kotası ve anonim Keychain cihaz kota özeti maddelerini yansıtacak şekilde güncellenip Cloudflare'e dağıtılmalıdır.

### 2.4. Veri Toplama, Saklama ve Hesap Silme — Kural 5.1.1(v) (✅ Tamamlandı)
* [`FirestoreService.swift#L709`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift#L709) içindeki `deleteAllUserData(uid:)` kullanıcının `shared_posts`, takip/takipçi bağlantıları, `blocked_users` ve `users/{uid}` belgesini siler.
* [`AuthService.swift#L446-L483`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift#L446-L483) içindeki `deleteAccount(l10n:)` Apple yetkilendirme kodunu iptal eder (`revokeToken`), Firestore verilerini ve Firebase Auth hesabını siler; ardından Keychain Apple kimliğini, `PostCacheService` SwiftData önbelleğini, `BookmarkStore` yer imlerini ve `UserDefaults` tercihlerini temizler.
* *Not (Kural 5.1.1 & Kota Suistimali):* [`SSEClient.swift#L42-L72`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L42-L72) içindeki `quotaDeviceID`, kullanıcıyı kimliklendirmeyen ve iCloud'a senkronlanmayan bir anonim Keychain UUID'si olarak yalnızca sunucuda SHA-256 hash'iyle (`device_usage`) ücretsiz günlük kota suistimalini önlemek için korunur; reklam veya takip amaçlı kullanılmaz.

---

## 3. Kapı 2: Gizlilik Manifestosu ve Veri Beyanı Denetimi (`skill.privacy.foundations`)

* **Dayanak:** `manifest-file-structure-and-scope`, `required-reason-api-declarations`, `collected-data-types-declaration`, `tracking-domains-and-third-party-sdk-signatures`

### 3.1. `PrivacyInfo.xcprivacy` Dosyası (✅ Tamamlandı — 7 Veri Tipi)
[`omakase/omakase/PrivacyInfo.xcprivacy`](file:///Users/kuzey/projects/omakase/omakase/omakase/PrivacyInfo.xcprivacy) dosyası `PBXFileSystemSynchronizedRootGroup` üzerinden uygulama paketinin köküne (`omakase.app/PrivacyInfo.xcprivacy`) dahil edilmektedir:
- `NSPrivacyTracking`: `false`
- `NSPrivacyTrackingDomains`: `[]`
- `NSPrivacyAccessedAPITypes`: `NSPrivacyAccessedAPICategoryUserDefaults` (`CA92.1`)
- `NSPrivacyCollectedDataTypes` (**7 veri tipi**):
  1. `NSPrivacyCollectedDataTypeName` (`Linked: true`, `Tracking: false`, Purpose: `AppFunctionality`)
  2. `NSPrivacyCollectedDataTypeEmailAddress` (`Linked: true`, `Tracking: false`, Purpose: `AppFunctionality`)
  3. `NSPrivacyCollectedDataTypeUserID` (`Linked: true`, `Tracking: false`, Purpose: `AppFunctionality`)
  4. `NSPrivacyCollectedDataTypePurchaseHistory` (`Linked: true`, `Tracking: false`, Purpose: `AppFunctionality`)
  5. `NSPrivacyCollectedDataTypeCrashData` (`Linked: false`, `Tracking: false`, Purpose: `AppFunctionality`)
  6. `NSPrivacyCollectedDataTypeOtherUserContent` (`Linked: true`, `Tracking: false`, Purpose: `AppFunctionality`)
  7. `NSPrivacyCollectedDataTypeProductInteraction` (`Linked: true`, `Tracking: false`, Purpose: `Analytics` — [`TelemetryService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/TelemetryService.swift) izinli ürün etkileşimleri)

> [!IMPORTANT]
> App Store Connect → **App Privacy** anketi doldurulurken `Product Interaction` (`Analytics`, Linked to User, Not Used for Tracking) dahil yukarıdaki **7 veri tipinin tamamı** birebir eşleştirilmelidir.

---

## 4. Kapı 3: Xcode, İmzalama, Güvenlik ve Arşiv Denetimi (`skill.xcode.foundations`)

### 4.1. Veri Güvenliği ve `firestore.rules` Sıkılaştırması (✅ Tamamlandı)
* [`firestore.rules`](file:///Users/kuzey/projects/omakase/firestore.rules): Tüm kullanıcı yazılabilir belgelerde `hasOnly`, tip/uzunluk kilidi, `usernames/{handle}` atomikliği, 14 günlük `@username` değişim beklemesi ve sunucu koleksiyonları (`entitlements`, `usage`, `device_usage`, `metrics_daily`, `daily_active`, `user_feedback`, `notification_queue`, `notification_cooldowns`) için istemci yazım yasağı uygulanmıştır. *(Not: `devices` ve `notification_prefs` `language` doğrulaması deploy öncesi `en/tr`'den 7 dile genişletilecektir.)*

### 4.2. `Info.plist`, Entitlements ve Görsel Varlıklar (✅ Tamamlandı)
* [`omakase/omakase/Info.plist`](file:///Users/kuzey/projects/omakase/omakase/omakase/Info.plist) içinde yerel HTTP istisnaları ve Release `NSLocalNetworkUsageDescription` temizlenmiştir. Export Studio için yalnızca gereken `NSPhotoLibraryAddUsageDescription` (yalnızca ekleme izni) ve `LSApplicationQueriesSchemes` (`instagram-stories`, `instagram`, `whatsapp`, `twitter`) tanımlıdır.
* [`omakase/omakase/omakase.entitlements`](file:///Users/kuzey/projects/omakase/omakase/omakase/omakase.entitlements) üzerinde `com.apple.developer.applesignin` (`Default`) ve `aps-environment` (`development`) yetkileri mevcuttur.
* `AppIcon.appiconset/omakase.png`: `1024×1024`, `RGB`, `hasAlpha: no`, `sRGB`.

### 4.3. Derleme Yapılandırmaları, Otomatik Testler & Arşiv Prosedürü
* **Otomatik Doğrulama:** Backend tarafında **32/32** birim testi (`backend/tests/`), iOS tarafında ise `omakaseUITests/` altında **12 XCUITest** (Auth, 3 slayt Onboarding, Bento & Letterboxd, Feed/Kaynakça/Deep Dive, Export Studio, Topluluk & Günlük Limit/Paywall) hazırlanmıştır.
* **Arşiv & Dağıtım (`archive-process` & `export-options`):**
  1. Hedef olarak **"Any iOS Device (arm64)"** seçin; Scheme → Archive yapılandırmasının **Release** olduğunu doğrulayın.
  2. **Product → Archive** sonrası Organizer'da **Generate Privacy Report** çalıştırarak Firebase, GoogleSignIn ve RevenueCat manifestolarının uygulama `PrivacyInfo.xcprivacy` ile birleştiğini teyit edin.
  3. **Validate App** → **Distribute App → App Store Connect** (Automatic Signing) adımlarını izleyin ve `.xcarchive` içindeki `dSYMs` sembollerini Crashlytics için saklayın.

---

## 5. Güncel Sistem Mimarisi ve Bileşen Durumu

| Bileşen | Durum | App Store Hazırlık Notu |
|---------|-------|-------------------------|
| **Kayıt, Profil Kurulumu & Ayarlar** | ✅ Hazır | Sign in with Apple (Kural 4.8), Google Sign-In, E-posta (8 krk parola), `ProfileSetupView`, atomik `@username` + 14 gün bekleme, Hesap Silme (Kural 5.1.1v) ve ayrı Ayarlar + Geri Bildirim ekranı. |
| **3 Slaytlı Onboarding & Bento Akış** | ✅ Hazır | ASCII suşi 3 slaytlı `OnboardingView` (varsayılan ilgi alanı dayatmaz), 12 kategori + 24 merak merceği + Şefin Seçimi, `PostSourceView` birincil kaynakça, `DeepDiveSheetView`, 15–25 sn Cooldown ve `reportAIPost`. |
| **Export Studio (`ExportPostSheet`)** | ✅ Hazır | 3D önizleme, 3 oran (`1080×1920`, `1080×1350`, `1080×1080`), 4 tema, Instagram Stories / WhatsApp / X / Fotoğraflar / Kopyala / Paylaş. |
| **Topluluk & Mission Control (`admin-web/`)** | ✅ Hazır | Keşfet/Takip akışı, `contentModerationService`, gönderi/yorum/profil/AI şikayet (`moderation_reports`), `blockUser` ve Firebase Hosting üzerinde 24 saatlik moderasyon triyaj paneli. |
| **Monetizasyon, Cihaz Kotası & 7 Dil** | ✅ Hazır | `RevenueCat` `5.103.2` (StoreKit 2), 3 post/gün (1 Letterboxd/gün) + 1 Deep Dive (`+1` paylaşım ödülü), Keychain `device_usage` koruması, bağlam içi bildirim ve **7 dil** (`en, tr, ja, de, fr, es, ko`). |
| **Web Tanıtım & Yasal Sayfalar (`web/`)** | ⚠️ Metin Güncellemesi | Yenilenen `index.html` (8 slayt & 4 ekran maket) Cloudflare'e hazır; `privacy.html` / `terms.html` son telemetri, geri bildirim ve Letterboxd/cihaz kotası detaylarıyla güncellenmeli. |
| **App Store Ekran Görüntüleri** | ✅ Hazır | `app-store-screenshots/exports/ios/iphone/` altında **8 slayt × 7 dil** (`1125×2436`, `1206×2622`, `1284×2778`, `1320×2868`). |

---

## 6. Adım Adım Yayına Hazırlık Eylem Planı (Checklist)

### Tamamlanan Kod, Test ve Varlık Maddeleri
- [x] **1. `PrivacyInfo.xcprivacy` (7 Veri Tipi):** `CA92.1` + `Name`, `EmailAddress`, `UserID`, `PurchaseHistory`, `CrashData`, `OtherUserContent`, `ProductInteraction`.
- [x] **2. Sign in with Apple & `ProfileSetupView` (Kural 4.8):** SHA256 nonce, Keychain `appleIDUser`, `getCredentialState` ve atomik `@username` rezervasyonu.
- [x] **3. Tam Hesap Silme (Kural 5.1.1v):** Auth + Firestore + Apple token iptali + `PostCacheService` + `BookmarkStore` temizliği.
- [x] **4. UGC & AI Moderasyon (Kural 1.2):** Ön filtre, gönderi/yorum/profil/AI post raporlama, `blockUser` ve Mission Control Moderasyon sekmesi.
- [x] **5. Uygulama İçi İletişim, Geri Bildirim & Yasal Bağlantılar (Kural 1.2 & 1.5):** `mailto:destek@getomakase.app`, `FeedbackSheetView`, `privacy.html`, `terms.html`.
- [x] **6. `Info.plist`, `omakase.entitlements` & Otomatik Testler:** ATS/debug log temizliği, Export Studio izinleri, **32/32** backend testi ve **12** XCUITest.
- [x] **7. App Store Ekran Görüntüleri:** **8 slayt × 7 dil** 4 iPhone boyutunda üretildi.

### Gönderim Öncesi Kalan Güncelleme, Dağıtım & Konsol Adımları
- [ ] **A. Son Küçük Güncellemeler ve Dağıtımlar:**
  1. `firestore.rules` içinde `devices` / `notification_prefs` `language` kısıtını 7 dile genişletin; `web/privacy.html` & `web/terms.html` sayfalarını güncelleyin.
  2. Güncel backend'i Cloud Run'a, `firestore:rules` ve `admin-web/` Hosting'i Firebase'e, `web/` tanıtım sitesini Cloudflare'e (`wrangler`) dağıtın:
     ```bash
     cd backend && gcloud run deploy omakase-backend --source . --region us-central1 --project gen-lang-client-0120875563
     firebase deploy --only firestore:rules,hosting --project gen-lang-client-0120875563
     ```
- [ ] **B. Xcode, Firebase & RevenueCat Konsolu:**
  1. Xcode'da **Signing & Capabilities** altında `Sign in with Apple` ve `Push Notifications` profil doğrulamasını kontrol edin (`Release` aps-environment otomatik imzalanacaktır).
  2. Firebase Console → **Authentication → Apple** sağlayıcısını açın, **APNs `.p8`** anahtarını yükleyin ve `S-03` iOS `API_KEY` kısıtlamasını GCP Console'dan uygulayın.
  3. App Store Connect **Paid Apps Agreement (`Active`)**, `omakase.pro.monthly` / `omakase.pro.yearly` incelemesi ve RevenueCat Webhook Sandbox testini tamamlayın.
- [ ] **C. App Store Connect Gönderimi:**
  1. **App Privacy** anketini 7 veri tipi (`ProductInteraction` dahil) ile eşleştirin; **App Review Information** içine Demo Hesap girin; 8 slayt × 7 dil ekran görüntülerini yükleyin.
  2. Xcode'da **Any iOS Device (arm64)** seçip **Product → Archive → Generate Privacy Report → Validate App → Distribute App** adımlarını tamamlayın.

---

## 7. Apple Agent Kit İzlenebilirlik Özeti

`.agents/AGENTS.md` kuralları gereğince bu denetim ve uygulama sürecinde kullanılan yönlendirme zinciri:

1. **Seçilen Workflow'lar:** [`workflow.app-store-submission`](file:///Users/kuzey/projects/omakase/.agents/workflows/app-store-submission/WORKFLOW.md), [`workflow.authentication`](file:///Users/kuzey/projects/omakase/.agents/workflows/authentication/WORKFLOW.md)
2. **Sırasıyla Çalıştırılan Skill'ler:** [`skill.app-store-review-guidelines.submission`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-review-guidelines/SKILL.md), [`skill.privacy.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/privacy/SKILL.md), [`skill.xcode.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/xcode/SKILL.md), [`skill.authenticationservices.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/authenticationservices/SKILL.md), [`skill.security.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/security/SKILL.md), [`skill.style-guide.writing`](file:///Users/kuzey/projects/omakase/.agents/skills/style-guide/SKILL.md), [`skill.accessibility.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/accessibility/SKILL.md)
3. **Yüklenen Knowledge Contracts:** [`app-completeness.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/app-completeness.md), [`demo-account.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/demo-account.md), [`login-services-equivalent-option.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/login-services-equivalent-option.md), [`user-generated-content-moderation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/user-generated-content-moderation.md), [`developer-contact-information.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/developer-contact-information.md), [`data-security.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/data-security.md), [`privacy-manifest.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/privacy-manifest.md), [`privacy-nutrition-label.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/privacy-nutrition-label.md), [`manifest-file-structure-and-scope.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/manifest-file-structure-and-scope.md), [`required-reason-api-declarations.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/required-reason-api-declarations.md), [`collected-data-types-declaration.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/collected-data-types-declaration.md), [`tracking-domains-and-third-party-sdk-signatures.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/tracking-domains-and-third-party-sdk-signatures.md), [`sign-in-with-apple-request-and-credential.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/sign-in-with-apple-request-and-credential.md), [`nonce-and-identity-token-verification.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/nonce-and-identity-token-verification.md), [`credential-state-and-revocation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/credential-state-and-revocation.md), [`session-persistence-and-sign-out.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/session-persistence-and-sign-out.md), [`keychain-item-crud.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/security/keychain-item-crud.md), [`keychain-accessibility-levels.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/security/keychain-accessibility-levels.md), [`sign-in-and-authentication-terminology.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/style-guide/sign-in-and-authentication-terminology.md), [`accessibility-labels.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/accessibility/accessibility-labels.md), [`build-configurations.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/build-configurations.md), [`entitlements-capabilities.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/entitlements-capabilities.md), [`archive-process.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/archive-process.md), [`export-options.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/export-options.md).
