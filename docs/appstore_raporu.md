# 🍣 Omakase — App Store Gönderim Denetimi & Prodüksiyon Raporu

> **Son Güncelleme:** 26 Kasım 2026 (`v1.0 (1)` **Apple App Review'a Gönderildi — `Waiting for Review`** · `APP_ID: 6838044134`)  
> **Denetim Metodolojisi:** Apple Agent Kit — `workflow.app-store-submission` (`skill.app-store-review-guidelines.submission` → `skill.privacy.foundations` → `skill.xcode.foundations`) & `workflow.authentication` (`skill.authenticationservices.foundations` → `skill.security.foundations` → `skill.style-guide.writing` → `skill.accessibility.foundations`)  
> **Amaç:** Uygulamanın ve web/admin altyapısının (`omakase/`, `omakaseWidget/`, `backend/`, `web/`, `admin-web/`, `firestore.rules`, `app-store-screenshots/`) App Store Connect gönderiminde tespit edilen tüm kritik red sebeplerinin giderilmesi ve canlı inceleme (`Submission ID: 243fa22d-ed73-4dc8-a8e8-ad362f0dc071`) durumunun belgelenmesi.

---

## İçindekiler

1. [Yönetici Özeti: Tespit Edilen Kırmızı Bayraklar ve Çözüm Durumu](#1-yönetici-özeti-tespit-edilen-kırmızı-bayraklar-ve-çözüm-durumu)
2. [Kapı 1: App Review Kılavuzu Uyumluluk Denetimi (`skill.app-store-review-guidelines.submission`)](#2-kapı-1-app-review-kılavuzu-uyumluluk-denetimi)
3. [Kapı 2: Gizlilik Manifestosu ve Veri Beyanı Denetimi (`skill.privacy.foundations`)](#3-kapı-2-gizlilik-manifestosu-ve-veri-beyanı-denetimi)
4. [Kapı 3: Xcode, İmzalama, Güvenlik ve Arşiv Denetimi (`skill.xcode.foundations`)](#4-kapı-3-xcode-imzalama-güvenlik-ve-arşiv-denetimi)
5. [Güncel Sistem Mimarisi ve Bileşen Durumu](#5-güncel-sistem-mimarisi-ve-bileşen-durumu)
6. [App Store Connect Gönderim Özeti & Kontrol Listesi (Checklist)](#6-app-store-connect-gönderim-özeti--kontrol-listesi-checklist)
7. [Apple Agent Kit İzlenebilirlik Özeti (Workflow, Skill ve Knowledge Contracts)](#7-apple-agent-kit-izlenebilirlik-özeti)

---

## 1. Yönetici Özeti: Tespit Edilen Kırmızı Bayraklar ve Çözüm Durumu

İlk denetimde tespit edilen **7 kritik bulgunun tamamı** kod tabanında, güvenlik kurallarında, App Store Connect ayarlarında ve web/admin altyapısında çözülmüştür:

| # | Durum | Kategori / Kural | Yapılan Düzeltme & Uygulama Özeti | İlgili Dosya |
|---|-------|------------------|-----------------------------------|--------------|
| **1** | ✅ **ÇÖZÜLDÜ & YAYINDA** | **Kural 5.1.2** — `PrivacyInfo.xcprivacy` | Ana uygulama manifesti `NSPrivacyAccessedAPICategoryUserDefaults` (`CA92.1` + App Group için `1C8F.1`), `NSPrivacyTracking: false` ve **8 toplanan veri tipi** (`Name`, `EmailAddress`, `UserID`, `PurchaseHistory`, `CrashData`, `OtherUserContent`, `ProductInteraction`, `DeviceID`) ile güncellendi; `omakaseWidget` manifesti (`1C8F.1`, `[]`) eklendi ve App Store Connect **App Privacy** anketi yayınlandı. | [`omakase/omakase/PrivacyInfo.xcprivacy`](file:///Users/kuzey/projects/omakase/omakase/omakase/PrivacyInfo.xcprivacy), [`omakaseWidget/PrivacyInfo.xcprivacy`](file:///Users/kuzey/projects/omakase/omakase/omakaseWidget/PrivacyInfo.xcprivacy) |
| **2** | ✅ **ÇÖZÜLDÜ** | **Kural 4.8** — Sign in with Apple | `AuthenticationServices` + `CryptoKit` (SHA256 Nonce) + Keychain (`appleIDUser`) + `getCredentialState` + `credentialRevokedNotification` + kayıt sonrası `ProfileSetupView` ve atomik `usernames/{handle}` rezervasyonu. Misafir tadım (`GuestTasteView`) ile kayıt öncesi deneyim de eklendi. | [`Auth/AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift), [`Auth/AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift), [`Onboarding/GuestTasteView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Onboarding/GuestTasteView.swift) |
| **3** | ✅ **ÇÖZÜLDÜ** | **Kural 5.1.1(v)** — Hesap Silme | `AuthService.deleteAccount(l10n:)` ve `FirestoreService.deleteAllUserData(uid:)` Apple token iptali, Firestore temizliği, SwiftData önbellek (`PostCacheService`) ve `BookmarkStore` temizliği yapar. | [`Auth/AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift), [`Services/FirestoreService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift) |
| **4** | ✅ **ÇÖZÜLDÜ** | **Kural 1.2** — UGC & AI İçerik Moderasyonu | 1) `ContentModerationService.isAppropriate` ön filtresi (yorum, `displayName`, `@username`).<br>2) Gönderi (`reportPost`), Yorum (`reportComment`), Profil (`reportUser`) ve **AI Üretimi Post (`reportAIPost`)** şikayetleri `moderation_reports` koleksiyonuna yazılır.<br>3) `blockUser` anında akışı gizler; **Mission Control (`admin-web/`)** 24 saatlik inceleme triyajı sunar. | [`Services/ContentModerationService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/ContentModerationService.swift), [`Feed/FeedView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/FeedView.swift), [`admin-web/admin.html`](file:///Users/kuzey/projects/omakase/admin-web/admin.html) |
| **5** | ✅ **ÇÖZÜLDÜ** | **Kural 1.2, 1.5 & 5.1.1(i)** — İletişim, Geri Bildirim & Yasal Sayfalar | `UserProfileSheet` / Ayarlar ve `AuthView` içinde **Destek (`mailto:support@getomakase.app`)**, **Uygulama İçi Geri Bildirim (`FeedbackSheetView`)**, **Gizlilik Politikası (`privacy.html`)** ve **Kullanım Koşulları (`terms.html`)** bağlıdır; yasal sayfalar 26 Kasım 2026 itibarıyla güncellenmiştir. | [`Profile/FeedbackSheetView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Profile/FeedbackSheetView.swift), [`web/privacy.html`](file:///Users/kuzey/projects/omakase/web/privacy.html), [`web/terms.html`](file:///Users/kuzey/projects/omakase/web/terms.html) |
| **6** | ✅ **ÇÖZÜLDÜ & CANLIDA** | **Kural 1.6** — Veri Güvenliği (`firestore.rules`) | `users`, `usernames`, `following`, `followers`, `blocked_users`, `shared_posts`, `reactions`, `comments` ve `moderation_reports` için `hasOnly` + sahip/şema doğrulamalı kurallar (7 dil dahil); sunucu koleksiyonları (`entitlements`, `usage`, `device_usage`, `metrics_daily`, `user_feedback`) korumalı ve canlıda. | [`firestore.rules`](file:///Users/kuzey/projects/omakase/firestore.rules) |
| **7** | ✅ **ÇÖZÜLDÜ** | **Kural 1.6 & 2.1(a)** — `Info.plist`, ATS & İhracat Beyanı | Yerel HTTP istisnaları ve `Release` `NSLocalNetworkUsageDescription` temizlendi; `ITSAppUsesNonExemptEncryption = false` eklendi; `ExportPostSheet` için `LSApplicationQueriesSchemes` (`instagram-stories`, `instagram`, `whatsapp`, `twitter`) ve `NSPhotoLibraryAddUsageDescription` tanımlı. | [`omakase/omakase/Info.plist`](file:///Users/kuzey/projects/omakase/omakase/omakase/Info.plist), [`Networking/SSEClient.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift) |

---

## 2. Kapı 1: App Review Kılavuzu Uyumluluk Denetimi (`skill.app-store-review-guidelines.submission`)

### 2.1. Giriş Servisleri ve Eşdeğer Seçenek Zorunluluğu — Kural 4.8 (✅ Tamamlandı)
* **Dayanak:** `knowledge.app-store-review-guidelines.login-services-equivalent-option`, `workflow.authentication`
* **Yapılan Uygulama:**
  - [`AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift) içinde `AuthenticationServices` ve `CryptoKit` kullanılarak `signInWithApple()` metodu, kriptografik nonce + SHA256 özeti, yalnızca ilk girişte dönen `fullName` yakalama, Keychain (`appleIDUser`) saklama, `getCredentialState` ve `credentialRevokedNotification` dinleyicisi uygulanmıştır.
  - Apple, Google veya eksik profilli kullanıcılar giriş sonrası `ProfileSetupView` ([`Onboarding/OnboardingView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Onboarding/OnboardingView.swift)) üzerinden görünür ad + atomik benzersiz `@username` (`usernames/{handle}`) belirler; `@username` değişimi 14 günlük bekleme süresiyle sınırlandırılmıştır.
  - [`AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift) ekranında **"Apple ile devam et" / "Continue with Apple"** butonu Google Sign-In butonunun üstünde, eşit boyut ve görsel ağırlıkta yer alır. Ek olarak kayıt zorunluluğu olmadan önizleme sağlayan [`GuestTasteView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Onboarding/GuestTasteView.swift) sunulur ve App Review doğrulaması için Firebase Email/Password sağlayıcısı açılıp canlı demo hesap (`reviewer@getomakase.app` / `@appreview`) doğrulandı.

### 2.2. Kullanıcı Tarafından Oluşturulan İçerik (UGC) & AI İçerik Moderasyonu — Kural 1.2 (✅ Tamamlandı)
* **Dayanak:** `knowledge.app-store-review-guidelines.user-generated-content-moderation`
* **Yapılan Uygulama (4 Zorunlu Mekanizma + AI Raporlama & Admin Triyajı):**
  1. **Yayın Öncesi Sakıncalı İçerik Filtresi:** [`ContentModerationService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/ContentModerationService.swift) yorumlarda (`CommentsView.sendComment()`), `displayName` ve `@username` adımlarında zorunludur; backend tarafında da `_BLOCKLIST_RE` ve Gemini `BLOCK_MEDIUM_AND_ABOVE` güvenlik filtreleri çalışır.
  2. **Şikayet Mekanizması (UGC + AI Post):**
     - Topluluk gönderileri (`reportPost`), yorumlar (`reportComment`), profiller (`reportUser`) ve **ana akıştaki AI üretimi gönderiler** de üç nokta (`ellipsis`) menüsü üzerinden (`FirestoreService.reportAIPost` → `moderation_reports`) bildirilebilir ([`FeedView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/FeedView.swift)).
     - Gelen şikayetler **Mission Control (`admin-web/`) Moderasyon sekmesi** ve `PATCH /admin/reports/{report_id}` üzerinden 24 saat içinde incelenip çözülebilir veya ilgili gönderi silinebilir.
  3. **Kötü Niyetli Kullanıcıları Engelleme:** `blockUser(targetUid:currentUid:)` karşı kayıtları ve karşılıklı takibi temizler, `.omakaseDidUpdateBlockedUsers` ile tüm akıştan, yorumlardan ve aramadan anında gizler.
  4. **Yayınlanmış İletişim Bilgisi:** `mailto:support@getomakase.app` Ayarlar ve `AuthView` içinde erişilebilirdir.

### 2.3. Geliştirici İletişim Bilgileri, Geri Bildirim & Yasal Web Sayfaları — Kural 1.5 & 5.1.1(i) (✅ Tamamlandı)
* Ayarlar ([`UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift)) ve `AuthView` içinde **Destek (`mailto:support@getomakase.app`)**, **Geri Bildirim Gönder ([`FeedbackSheetView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Profile/FeedbackSheetView.swift))**, **Gizlilik Politikası (`https://getomakase.app/privacy.html`)** ve **Kullanım Koşulları (`https://getomakase.app/terms.html`)** yer alır.
* [`web/privacy.html`](file:///Users/kuzey/projects/omakase/web/privacy.html) ve [`web/terms.html`](file:///Users/kuzey/projects/omakase/web/terms.html) dosyaları `26 Kasım 2026` tarihinde `support@getomakase.app` adresi, `ProductInteraction` analitiği, uygulama içi geri bildirim, günlük 1 Letterboxd ücretsiz kotası ve anonim Keychain cihaz kota özeti maddeleriyle güncellenmiştir. Ayrıca 9 App Store Connect açıklamasına Standart Apple EULA + Gizlilik Politikası bağlantıları eklendi.

### 2.4. Veri Toplama, Saklama ve Hesap Silme — Kural 5.1.1(v) (✅ Tamamlandı)
* [`FirestoreService.swift#L709`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift#L709) içindeki `deleteAllUserData(uid:)` kullanıcının `shared_posts`, takip/takipçi bağlantıları, `blocked_users` ve `users/{uid}` belgesini siler.
* [`AuthService.swift#L446-L483`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift#L446-L483) içindeki `deleteAccount(l10n:)` Apple yetkilendirme kodunu iptal eder (`revokeToken`), Firestore verilerini ve Firebase Auth hesabını siler; ardından Keychain Apple kimliğini, `PostCacheService` SwiftData önbelleğini, `BookmarkStore` yer imlerini ve `UserDefaults` tercihlerini temizler.
* *Not (Kural 5.1.1 & Kota Suistimali):* [`SSEClient.swift#L42-L72`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L42-L72) içindeki `quotaDeviceID`, kullanıcıyı kimliklendirmeyen ve iCloud'a senkronlanmayan bir anonim Keychain UUID'si olarak yalnızca sunucuda SHA-256 hash'iyle (`device_usage`) ücretsiz günlük kota suistimalini önlemek için korunur; reklam veya takip amaçlı kullanılmaz (`DeviceID`, `Linked: false`, `Tracking: false`).

---

## 3. Kapı 2: Gizlilik Manifestosu ve Veri Beyanı Denetimi (`skill.privacy.foundations`)

* **Dayanak:** `manifest-file-structure-and-scope`, `required-reason-api-declarations`, `collected-data-types-declaration`, `tracking-domains-and-third-party-sdk-signatures`

### 3.1. `PrivacyInfo.xcprivacy` Dosyaları (✅ Tamamlandı & Yayınlandı — 8 Veri Tipi + Widget)
[`omakase/omakase/PrivacyInfo.xcprivacy`](file:///Users/kuzey/projects/omakase/omakase/omakase/PrivacyInfo.xcprivacy) dosyası `PBXFileSystemSynchronizedRootGroup` üzerinden uygulama paketinin köküne (`omakase.app/PrivacyInfo.xcprivacy`) dahil edilmektedir:
- `NSPrivacyTracking`: `false`
- `NSPrivacyTrackingDomains`: `[]`
- `NSPrivacyAccessedAPITypes`: `NSPrivacyAccessedAPICategoryUserDefaults` — **`CA92.1`** (uygulama içi tercihler) ve **`1C8F.1`** (App Group `group.kuzeysinay.omakase` ile Widget veri paylaşımı)
- `NSPrivacyCollectedDataTypes` (**8 veri tipi**):
  1. `NSPrivacyCollectedDataTypeName` (`Linked: true`, `Tracking: false`, Purpose: `AppFunctionality`)
  2. `NSPrivacyCollectedDataTypeEmailAddress` (`Linked: true`, `Tracking: false`, Purpose: `AppFunctionality`)
  3. `NSPrivacyCollectedDataTypeUserID` (`Linked: true`, `Tracking: false`, Purpose: `AppFunctionality`)
  4. `NSPrivacyCollectedDataTypePurchaseHistory` (`Linked: true`, `Tracking: false`, Purpose: `AppFunctionality`)
  5. `NSPrivacyCollectedDataTypeCrashData` (`Linked: false`, `Tracking: false`, Purpose: `AppFunctionality`)
  6. `NSPrivacyCollectedDataTypeOtherUserContent` (`Linked: true`, `Tracking: false`, Purpose: `AppFunctionality`)
  7. `NSPrivacyCollectedDataTypeProductInteraction` (`Linked: true`, `Tracking: false`, Purpose: `Analytics` — [`TelemetryService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/TelemetryService.swift) izinli ürün etkileşimleri)
  8. `NSPrivacyCollectedDataTypeDeviceID` (`Linked: false`, `Tracking: false`, Purpose: `AppFunctionality` — Keychain tabanlı anonim `quotaDeviceID`)

Ek olarak [`omakase/omakaseWidget/PrivacyInfo.xcprivacy`](file:///Users/kuzey/projects/omakase/omakase/omakaseWidget/PrivacyInfo.xcprivacy) WidgetKit uzantısı için `NSPrivacyTracking: false`, `NSPrivacyCollectedDataTypes: []` ve `NSPrivacyAccessedAPICategoryUserDefaults` (`1C8F.1`) beyan eder. App Store Connect → **App Privacy** anketi bu **8 veri tipiyle** birebir eşleştirilip **yayınlanmıştır**.

---

## 4. Kapı 3: Xcode, İmzalama, Güvenlik ve Arşiv Denetimi (`skill.xcode.foundations`)

### 4.1. Veri Güvenliği ve `firestore.rules` Sıkılaştırması (✅ Tamamlandı & Canlıda)
* [`firestore.rules`](file:///Users/kuzey/projects/omakase/firestore.rules): Tüm kullanıcı yazılabilir belgelerde `hasOnly`, tip/uzunluk kilidi, `usernames/{handle}` atomikliği, 14 günlük `@username` değişim beklemesi, `devices` / `notification_prefs` için **7 dil (`en, tr, ja, de, fr, es, ko`)** desteği ve sunucu koleksiyonları (`entitlements`, `usage`, `device_usage`, `metrics_daily`, `daily_active`, `user_feedback`, `notification_queue`, `notification_cooldowns`) için istemci yazım yasağı uygulanmış ve canlıya alınmıştır.

### 4.2. `Info.plist`, Entitlements, Hedef Cihaz & Görsel Varlıklar (✅ Tamamlandı)
* [`omakase/omakase/Info.plist`](file:///Users/kuzey/projects/omakase/omakase/omakase/Info.plist): Yerel HTTP istisnaları ve Release `NSLocalNetworkUsageDescription` temizlenmiş; `ITSAppUsesNonExemptEncryption = false` eklenmiştir. Export Studio için `NSPhotoLibraryAddUsageDescription` ve `LSApplicationQueriesSchemes` (`instagram-stories`, `instagram`, `whatsapp`, `twitter`) tanımlıdır.
* [`omakase/omakase/omakase.entitlements`](file:///Users/kuzey/projects/omakase/omakase/omakase/omakase.entitlements) & [`omakase/omakaseWidget/omakaseWidget.entitlements`](file:///Users/kuzey/projects/omakase/omakase/omakaseWidget/omakaseWidget.entitlements): Sign in with Apple (`Default`), `aps-environment` ve paylaşımlı App Group (`group.kuzeysinay.omakase`) yetkileri mevcuttur.
* **Xcode Hedef Ayarları:** `TARGETED_DEVICE_FAMILY = 1` (yalnızca iPhone), uygulama görünen adı küçük harf `omakase`, Bundle ID `kuzeysinay.omakase`, `manifest.json` (Xcode Cloud) tanımlı.
* `AppIcon.appiconset/omakase.png`: `1024×1024`, `RGB`, `hasAlpha: no`, `sRGB`.

### 4.3. Derleme Yapılandırmaları, Otomatik Testler & Arşiv Doğrulaması (✅ Tamamlandı)
* **Otomatik Doğrulama:** Backend tarafında **38/38** birim testi (`backend/tests/`), iOS tarafında ise `omakaseUITests/` altında **12 XCUITest** hazırlanmıştır.
* **Dinamik StoreKit Fiyatlandırması:** [`OmakasePaywallView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Monetization/OmakasePaywallView.swift) içindeki sabit para birimi/fiyat fallback metinleri kaldırılarak StoreKit 2 `displayPrice` / `ProgressView` / `"—"` akışına geçirildi (Kural 2.1 & yerelleştirme uyumu).
* **Arşiv & Doğrulama:** `1.0 (1)` derlemesi (Build ID `66226357-a818-4100-bc60-ac8cba4c597b`) App Store Connect'e yüklendi ve `asc validate` (0 engelleyici hata) sonrası incelemeye gönderildi.

---

## 5. Güncel Sistem Mimarisi ve Bileşen Durumu

| Bileşen | Durum | App Store Hazırlık Notu |
|---------|-------|-------------------------|
| **Kayıt, Misafir Tadımı, Profil & Ayarlar** | ✅ Hazır | Sign in with Apple (Kural 4.8), Google Sign-In, E-posta (8 krk parola + App Review demo hesap), `GuestTasteView`, `ProfileSetupView`, atomik `@username` + 14 gün bekleme, Hesap Silme (Kural 5.1.1v) ve ayrı Ayarlar + Geri Bildirim ekranı. |
| **3 Slaytlı Onboarding, Bento & Değerlendirme** | ✅ Hazır | ASCII suşi 3 slaytlı `OnboardingView`, 12 kategori + 24 merak merceği + Şefin Seçimi, `PostSourceView` birincil kaynakça, `DeepDiveSheetView`, 15–25 sn Cooldown, `reportAIPost` ve Kural 5.6.1/5.6.3 uyumlu yerel `RatingPromptManager` (`StoreKit.AppStore.requestReview`). |
| **Ana Ekran / Kilit Ekranı Widget (`omakaseWidget/`)** | ✅ Hazır | WidgetKit uzantısı (`OmakaseWidget.swift`), `WidgetDataBridge.swift` ve `group.kuzeysinay.omakase` App Group + ayrı `PrivacyInfo.xcprivacy` (`1C8F.1`). |
| **Export Studio (`ExportPostSheet`)** | ✅ Hazır | 3D önizleme, 3 oran (`1080×1920`, `1080×1350`, `1080×1080`), 4 tema, Instagram Stories / WhatsApp / X / Fotoğraflar / Kopyala / Paylaş. |
| **Topluluk & Mission Control (`admin-web/`)** | ✅ Hazır & Canlıda | Keşfet/Takip akışı, `FollowListSheet` (takipçi/takip listeleri), `contentModerationService`, gönderi/yorum/profil/AI şikayet (`moderation_reports`), `blockUser` ve Firebase Hosting üzerinde 24 saatlik moderasyon triyaj paneli. |
| **Monetizasyon, Cihaz Kotası & 7 Dil** | ✅ Hazır | `RevenueCat` `5.103.2` (StoreKit 2 + `ProWelcomeView`), 3 post/gün (1 Letterboxd/gün) + 1 Deep Dive (`+1` paylaşım ödülü), Keychain `device_usage` koruması, bağlam içi bildirim, Haptic (`HapticManager`) ve **7 dilde 528 anahtar** (`en, tr, ja, de, fr, es, ko`). |
| **Web Tanıtım & Yasal Sayfalar (`web/`)** | ✅ Kod Güncellendi | Yenilenen `index.html` / `en/index.html`, `privacy.html` & `terms.html` (26 Kasım 2026, `support@getomakase.app`) ve güvenlik başlıkları (`_headers`) hazır. |
| **App Store Ekran Görüntüleri & Metadata** | ✅ Yüklendi | 9 yerel ayara **72 × `1320×2868`** ekran görüntüsü yüklendi (`Asset Library` 72/72 temizlendi); repo içinde `app-store-screenshots/exports/ios/` altında 4 iPhone boyutunda (`1125×2436`, `1206×2622`, `1284×2778`, `1320×2868`) arşivlendi. |

---

## 6. App Store Connect Gönderim Özeti & Kontrol Listesi (Checklist)

### Tamamlanan Kod, Dağıtım ve Gönderim Maddeleri
- [x] **1. `PrivacyInfo.xcprivacy` (8 Veri Tipi + Widget):** Ana uygulamada `CA92.1` + `1C8F.1` + 8 veri tipi (`DeviceID` dahil); `omakaseWidget` için `1C8F.1` + `[]` ve App Store Connect **App Privacy** yayını tamamlandı.
- [x] **2. Sign in with Apple, Misafir Tadımı & Demo Hesap (Kural 4.8):** SHA256 nonce, Keychain `appleIDUser`, `getCredentialState`, `ProfileSetupView`, `GuestTasteView`, Firebase Email/Password sağlayıcısı ve App Review demo hesabı (`reviewer@getomakase.app` / `@appreview`) doğrulandı.
- [x] **3. Tam Hesap Silme, UGC & AI Moderasyon (Kural 1.2 & 5.1.1v):** Apple token iptali + Firestore/SwiftData/`BookmarkStore` temizliği, gönderi/yorum/profil/AI şikayet (`reportAIPost`), `blockUser` ve Mission Control Moderasyon triyajı canlıda.
- [x] **4. İletişim, Geri Bildirim & Yasal Sayfalar (Kural 1.2 & 1.5):** `mailto:support@getomakase.app`, `FeedbackSheetView`, `web/privacy.html`, `web/terms.html` (26 Kasım 2026) ve 9 yerel ayar açıklamalarına EULA/Privacy bağlantıları eklendi.
- [x] **5. `Info.plist`, Entitlements, Widget & Otomatik Testler:** `ITSAppUsesNonExemptEncryption = false`, `TARGETED_DEVICE_FAMILY = 1`, `group.kuzeysinay.omakase`, dinamik StoreKit paywall, **528×7** yerelleştirme anahtarı, **38/38** backend birim testi ve **12** XCUITest tamamlandı.
- [x] **6. Backend, `firestore.rules` (7 Dil) & Mission Control Canlı Dağıtımı:** Cloud Run `omakase-backend-00023-68f` (`us-central1`) ve Firebase `firestore:rules` + `hosting` canlıya alındı.
- [x] **7. App Store Connect `v1.0 (1)` İnceleme Gönderimi (`Waiting for Review`):**
  - `APP_ID: 6838044134` · Version ID `a74793e1-4827-428c-a77d-ea141b16d9f3` · Build `1.0 (1)`.
  - Kategori: `EDUCATION` (Primary) / `REFERENCE` (Secondary) · Copyright: `2026 Kuzey Sınay` · Yaş Sınırı (24 alan, `userGeneratedContent: true`).
  - **9 yerel ayar** metadata + **72 × `1320×2868`** ekran görüntüsü yüklendi; **Çin anakarası (`CHN`)** CAC/AIGC uyumu gereği kapatıldı (174 ülke aktif).
  - **Review Submission (`243fa22d-ed73-4dc8-a8e8-ad362f0dc071`):** `iOS App 1.0`, `omakase pro` grubu, `omakase Pro Monthly` ve `omakase Pro Yearly` birlikte `Waiting for Review` kuyruğuna gönderildi.

### Onay / Yayın Günü İzlenecek Kalan Operasyonel Adımlar
- [ ] **A. Web & Smart App Banner:** `web/` Cloudflare (`npx wrangler deploy`) yayını doğrulandığında ve App Store onayı çıktığında `index.html` / `en/index.html` içine `app-id=6838044134` Smart App Banner ve mağaza URL'si bağlanacak.
- [ ] **B. Bildirim & RevenueCat Prodüksiyon Kontrolleri:** Firebase Console'da **APNs `.p8`** / Cloud Scheduler (`/notifications/process-queue`) ve RevenueCat Webhook Sandbox/Production olaylarının son kontrolü yapılacak.

---

## 7. Apple Agent Kit İzlenebilirlik Özeti

`.agents/AGENTS.md` kuralları gereğince bu denetim ve uygulama sürecinde kullanılan yönlendirme zinciri:

1. **Seçilen Workflow'lar:** [`workflow.app-store-submission`](file:///Users/kuzey/projects/omakase/.agents/workflows/app-store-submission/WORKFLOW.md), [`workflow.authentication`](file:///Users/kuzey/projects/omakase/.agents/workflows/authentication/WORKFLOW.md)
2. **Sırasıyla Çalıştırılan Skill'ler:** [`skill.app-store-review-guidelines.submission`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-review-guidelines/SKILL.md), [`skill.privacy.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/privacy/SKILL.md), [`skill.xcode.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/xcode/SKILL.md), [`skill.authenticationservices.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/authenticationservices/SKILL.md), [`skill.security.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/security/SKILL.md), [`skill.style-guide.writing`](file:///Users/kuzey/projects/omakase/.agents/skills/style-guide/SKILL.md), [`skill.accessibility.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/accessibility/SKILL.md)
3. **Yüklenen Knowledge Contracts:** [`app-completeness.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/app-completeness.md), [`demo-account.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/demo-account.md), [`login-services-equivalent-option.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/login-services-equivalent-option.md), [`user-generated-content-moderation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/user-generated-content-moderation.md), [`developer-contact-information.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/developer-contact-information.md), [`data-security.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/data-security.md), [`privacy-manifest.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/privacy-manifest.md), [`privacy-nutrition-label.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/privacy-nutrition-label.md), [`manifest-file-structure-and-scope.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/manifest-file-structure-and-scope.md), [`required-reason-api-declarations.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/required-reason-api-declarations.md), [`collected-data-types-declaration.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/collected-data-types-declaration.md), [`tracking-domains-and-third-party-sdk-signatures.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/tracking-domains-and-third-party-sdk-signatures.md), [`sign-in-with-apple-request-and-credential.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/sign-in-with-apple-request-and-credential.md), [`nonce-and-identity-token-verification.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/nonce-and-identity-token-verification.md), [`credential-state-and-revocation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/credential-state-and-revocation.md), [`session-persistence-and-sign-out.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/session-persistence-and-sign-out.md), [`keychain-item-crud.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/security/keychain-item-crud.md), [`keychain-accessibility-levels.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/security/keychain-accessibility-levels.md), [`sign-in-and-authentication-terminology.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/style-guide/sign-in-and-authentication-terminology.md), [`accessibility-labels.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/accessibility/accessibility-labels.md), [`build-configurations.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/build-configurations.md), [`entitlements-capabilities.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/entitlements-capabilities.md), [`archive-process.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/archive-process.md), [`export-options.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/export-options.md).