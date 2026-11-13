# 🍣 Omakase — App Store Gönderim Denetimi & Prodüksiyon Raporu

> **Son Güncelleme:** 12 Kasım 2026 (Tüm Kod & Altyapı Düzeltmeleri Tamamlandı)  
> **Denetim Metodolojisi:** Apple Agent Kit — `workflow.app-store-submission` (`skill.app-store-review-guidelines.submission` → `skill.privacy.foundations` → `skill.xcode.foundations`) & `workflow.authentication` (`skill.authenticationservices.foundations` → `skill.security.foundations` → `skill.style-guide.writing` → `skill.accessibility.foundations`)  
> **Amaç:** Uygulamanın ve web altyapısının (`omakase/`, `backend/`, `web/`, `firestore.rules`) App Store Connect gönderimi öncesinde tespit edilen tüm kritik red sebeplerinin giderilmesi ve yapılan prodüksiyon güncellemelerinin belgelenmesi.

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

İlk denetimde tespit edilen **7 kritik bulgunun tamamı** kod tabanında, güvenlik kurallarında ve web yasal sayfalarında çözülmüştür:

| # | Durum | Kategori / Kural | Yapılan Düzeltme & Uygulama Özeti | İlgili Dosya |
|---|-------|------------------|-----------------------------------|--------------|
| **1** | ✅ **ÇÖZÜLDÜ** | **Kural 5.1.2** — `PrivacyInfo.xcprivacy` | Uygulama hedefinde `PrivacyInfo.xcprivacy` oluşturuldu (`NSPrivacyAccessedAPICategoryUserDefaults` → `CA92.1` ve `Name`, `EmailAddress`, `UserID` veri beyanları eklendi). | [`omakase/omakase/PrivacyInfo.xcprivacy`](file:///Users/kuzey/projects/omakase/omakase/omakase/PrivacyInfo.xcprivacy) |
| **2** | ✅ **ÇÖZÜLDÜ** | **Kural 4.8** — Sign in with Apple | `AuthenticationServices` + `CryptoKit` (SHA256 Nonce) + Keychain (`appleIDUser`) + `getCredentialState` + `credentialRevokedNotification` ile tam **Sign in with Apple** akışı ve Google ile eşit görünürlükte buton eklendi. | [`Auth/AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift), [`Auth/AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift) |
| **3** | ✅ **ÇÖZÜLDÜ** | **Kural 5.1.1(v)** — Hesap Silme | `AuthService.deleteAccount(l10n:)` ve `FirestoreService.deleteAllUserData(uid:)` eklendi. `MyProfileSheet` içine onay uyarılı **Hesabı Sil (`Delete Account`)** butonu yerleştirildi. | [`Auth/AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift), [`Services/FirestoreService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift), [`Social/UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift) |
| **4** | ✅ **ÇÖZÜLDÜ** | **Kural 1.2** — UGC Moderasyon (Kullanıcı Engelleme, Gönderi/Profil Şikayeti & Ön Filtre) | 1) `blockUser` / `unblockUser` eklendi; engellenen kullanıcının gönderileri, yorumları ve arama sonuçları anında gizleniyor.<br>2) Gönderi (`reportPost`), Yorum (`reportComment`) ve Profil (`reportUser`) şikayetleri `moderation_reports` koleksiyonuna yazılıyor.<br>3) Yorumlarda (`CommentsView`) ve kayıt sırasında (`displayName`, `@username`) `ContentModerationService.isAppropriate` ön filtresi zorunlu kılındı. | [`Services/ContentModerationService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/ContentModerationService.swift), [`Services/FirestoreService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift), [`Social/TimelinePostCard.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/TimelinePostCard.swift), [`Social/CommentsView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/CommentsView.swift), [`Social/UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift), [`Social/UserSearchView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserSearchView.swift) |
| **5** | ✅ **ÇÖZÜLDÜ** | **Kural 1.2, 1.5 & 5.1.1(i)** — Uygulama İçi İletişim & Yasal Web Sayfaları | `MyProfileSheet` ve `AuthView` içine **Destek & İletişim (`mailto:destek@getomakase.app`)**, **Gizlilik Politikası (`https://getomakase.app/privacy.html`)** ve **Kullanım Koşulları (`https://getomakase.app/terms.html`)** eklendi; `web/privacy.html` ve `web/terms.html` oluşturuldu. | [`Social/UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift), [`Auth/AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift), [`web/privacy.html`](file:///Users/kuzey/projects/omakase/web/privacy.html), [`web/terms.html`](file:///Users/kuzey/projects/omakase/web/terms.html) |
| **6** | ✅ **ÇÖZÜLDÜ** | **Kural 1.6** — Veri Güvenliği (`firestore.rules`) | Herkese yazma izni veren `allow read, write: if request.auth != null;` kaldırıldı; `users`, `following`, `followers`, `blocked_users`, `shared_posts`, `reactions`, `comments` ve `moderation_reports` için sıkı sahip/şema doğrulamalı kurallar yazıldı. | [`firestore.rules`](file:///Users/kuzey/projects/omakase/firestore.rules) |
| **7** | ✅ **ÇÖZÜLDÜ** | **Kural 1.6 & 2.1(a)** — `Info.plist` ATS, `NSLocalNetworkUsageDescription` & Debug Telemetri Temizliği | 1) `Info.plist` içindeki `172.20.10.14` ve yerel HTTP istisnaları kaldırıldı.<br>2) `INFOPLIST_KEY_NSLocalNetworkUsageDescription` Release yapılandırmasından çıkarıldı.<br>3) `SSEClient.swift` ve `FeedViewModel.swift` içindeki `127.0.0.1:7607` `AgentDebugLog` telemetri kodları temizlendi, geliştirici hata mesajları kullanıcı dostu hale getirildi. | [`omakase/omakase/Info.plist`](file:///Users/kuzey/projects/omakase/omakase/omakase/Info.plist), [`omakase/omakase.xcodeproj/project.pbxproj`](file:///Users/kuzey/projects/omakase/omakase/omakase.xcodeproj/project.pbxproj), [`Networking/SSEClient.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift), [`Feed/FeedViewModel.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/FeedViewModel.swift), [`L10n.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/L10n.swift) |

---

## 2. Kapı 1: App Review Kılavuzu Uyumluluk Denetimi (`skill.app-store-review-guidelines.submission`)

### 2.1. Giriş Servisleri ve Eşdeğer Seçenek Zorunluluğu — Kural 4.8 (✅ Tamamlandı)
* **Dayanak:** `knowledge.app-store-review-guidelines.login-services-equivalent-option`, `workflow.authentication`
* **Yapılan Uygulama:**
  - [`AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift) içinde `AuthenticationServices` ve `CryptoKit` kullanılarak `signInWithApple()` metodu, kriptografik olarak güvenli rastgele nonce + SHA256 özeti (`sha256(_:)`), yalnızca ilk girişte dönen `fullName` bilgisinin yakalanıp Firebase Auth profiline ve Firestore `users/{uid}` belgesine kaydedilmesi sağlandı.
  - Apple kullanıcı tanımlayıcısı (`credential.user`) arka plan iş parçacığında (`Task.detached`) iOS Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) üzerinde saklanmakta, uygulama açılışında ve ön plana gelişinde `ASAuthorizationAppleIDProvider().getCredentialState(forUserID:)` kontrol edilmekte ve `ASAuthorizationAppleIDProvider.credentialRevokedNotification` dinlenerek iptal durumunda oturum kapatılmaktadır.
  - [`AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift) karşılama ve giriş ekranlarında **"Apple ile devam et" / "Continue with Apple"** butonu Google Sign-In butonunun hemen üstünde, eşit boyut ve görsel ağırlıkta konumlandırılmıştır.

### 2.2. Kullanıcı Tarafından Oluşturulan İçerik (UGC) Moderasyonu — Kural 1.2 (✅ Tamamlandı)
* **Dayanak:** `knowledge.app-store-review-guidelines.user-generated-content-moderation`
* **Yapılan Uygulama (4 Zorunlu Mekanizma):**
  1. **Yayın Öncesi Sakıncalı İçerik Filtresi (Rule 1):**
     - [`ContentModerationService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/ContentModerationService.swift) içindeki TR/EN küfür, nefret söylemi, taciz, şiddet ve müstehcen içerik regex listesi genişletildi ve `isAppropriate(_:maxLength:)` desteği eklendi.
     - [`CommentsView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/CommentsView.swift) içindeki `sendComment()` fonksiyonu, yorumu Firestore'a göndermeden önce `ContentModerationService.isAppropriate(trimmed, maxLength: 500)` kontrolünden geçirir; uygunsuz içerikte hata uyarısı gösterir.
     - [`AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift) ve [`AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift) içinde görünür ad (`displayName`) ve `@kullanıcı_adı` (`username`) kayıt adımlarında `ContentModerationService.isAppropriate` kontrolü zorunlu hale getirildi.
  2. **Şikayet Mekanizması (Rule 2):**
     - [`FirestoreService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift) içinde `reportPost`, `reportComment` ve `reportUser` fonksiyonları tüm şikayetleri merkezi `moderation_reports` koleksiyonuna yazar.
     - [`TimelinePostCard.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/TimelinePostCard.swift) üzerinde diğer kullanıcıların gönderileri için üç nokta (`ellipsis`) menüsü ile **"Gönderiyi Bildir" (`Report Post`)** ve **"Kullanıcıyı Engelle" (`Block User`)** aksiyonları eklendi.
     - [`UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift) üst barına diğer kullanıcı profilleri için **"Kullanıcıyı Bildir" (`Report User`)** ve **"Kullanıcıyı Engelle / Engeli Kaldır"** menüsü eklendi.
  3. **Kötü Niyetli Kullanıcıları Engelleme (Rule 3):**
     - [`FirestoreService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift) içinde `blockUser(targetUid:currentUid:)` çağrıldığında hedef kullanıcı `users/{uid}/blocked_users/{targetUid}` koleksiyonuna kaydedilir, karşılıklı takip ilişkisi koparılır ve `.omakaseDidUpdateBlockedUsers` bildirimi yayınlanır.
     - [`TimelineViewModel.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/TimelineViewModel.swift), [`CommentsView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/CommentsView.swift) ve [`UserSearchView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserSearchView.swift) bu bildirimi dinleyerek engellenen kullanıcının tüm gönderilerini, yorumlarını ve arama sonuçlarını anında ekrandan kaldırır.
  4. **Yayınlanmış İletişim Bilgisi (Rule 4):**
     - Hem `MyProfileSheet` hem de `AuthView` içinde `mailto:destek@getomakase.app` doğrudan erişilebilir durumdadır.

### 2.3. Geliştirici İletişim Bilgileri ve Yasal Web Sayfaları — Kural 1.5 & 5.1.1(i) (✅ Tamamlandı)
* **Dayanak:** `knowledge.app-store-review-guidelines.developer-contact-information`
* **Yapılan Uygulama:**
  - `MyProfileSheet` ([`Social/UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift)) içerisine **"Destek ve Yasal" (`Support & Legal`)** bölümü eklendi:
    - **Destek ve İletişim:** `mailto:destek@getomakase.app`
    - **Gizlilik Politikası:** `https://getomakase.app/privacy.html`
    - **Kullanım Koşulları (EULA):** `https://getomakase.app/terms.html`
  - Web dizininde çift dilli (TR/EN) [`web/privacy.html`](file:///Users/kuzey/projects/omakase/web/privacy.html) ve [`web/terms.html`](file:///Users/kuzey/projects/omakase/web/terms.html) sayfaları oluşturuldu, [`web/index.html`](file:///Users/kuzey/projects/omakase/web/index.html) alt bilgisine bağlantıları eklendi ve [`firebase.json`](file:///Users/kuzey/projects/omakase/firebase.json) içinde `"cleanUrls": true` aktif edildi.

### 2.4. Veri Toplama, Saklama ve Hesap Silme — Kural 5.1.1(v) (✅ Tamamlandı)
* **Dayanak:** `knowledge.app-store-review-guidelines.privacy-nutrition-label` & Guideline 5.1.1(v)
* **Yapılan Uygulama:**
  - [`FirestoreService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift) içindeki `deleteAllUserData(uid:)` kullanıcının paylaştığı gönderileri (`shared_posts`), takip/takipçi bağlantılarının karşı kayıtlarını, `following`, `followers`, `blocked_users` alt koleksiyonlarını ve `users/{uid}` belgesini siler.
  - [`AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift) içindeki `deleteAccount(l10n:)` tüm Firestore verilerini temizledikten sonra `Auth.auth().currentUser?.delete()` çağrısını yapar, Keychain'deki Apple kimlik kaydını ve yerel `@AppStorage` verilerini sıfırlar.
  - `MyProfileSheet` ([`Social/UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift)) en altına yıkıcı (`role: .destructive`) **"Hesabı Sil" (`Delete Account`)** butonu ve onay uyarısı eklendi.

---

## 3. Kapı 2: Gizlilik Manifestosu ve Veri Beyanı Denetimi (`skill.privacy.foundations`)

* **Dayanak:**
  - `knowledge.privacy.manifest-file-structure-and-scope`
  - `knowledge.privacy.required-reason-api-declarations`
  - `knowledge.privacy.collected-data-types-declaration`
  - `knowledge.privacy.tracking-domains-and-third-party-sdk-signatures`

### 3.1. `PrivacyInfo.xcprivacy` Dosyası (✅ Tamamlandı)
[`omakase/omakase/PrivacyInfo.xcprivacy`](file:///Users/kuzey/projects/omakase/omakase/omakase/PrivacyInfo.xcprivacy) oluşturuldu ve `plutil -lint` ile doğrulandı (`OK`). Proje `PBXFileSystemSynchronizedRootGroup` kullandığı için dosya otomatik olarak uygulama paketinin köküne (`omakase.app/PrivacyInfo.xcprivacy`) dahil edilmektedir.
- `NSPrivacyTracking`: `false`
- `NSPrivacyTrackingDomains`: `[]`
- `NSPrivacyAccessedAPITypes`: `NSPrivacyAccessedAPICategoryUserDefaults` (`CA92.1`)
- `NSPrivacyCollectedDataTypes`:
  - `NSPrivacyCollectedDataTypeName` (Linked: `true`, Tracking: `false`, Purpose: `AppFunctionality`)
  - `NSPrivacyCollectedDataTypeEmailAddress` (Linked: `true`, Tracking: `false`, Purpose: `AppFunctionality`)
  - `NSPrivacyCollectedDataTypeUserID` (Linked: `true`, Tracking: `false`, Purpose: `AppFunctionality`)

---

## 4. Kapı 3: Xcode, İmzalama, Güvenlik ve Arşiv Denetimi (`skill.xcode.foundations`)

### 4.1. Veri Güvenliği ve `firestore.rules` Sıkılaştırması (✅ Tamamlandı)
* **Dayanak:** `knowledge.app-store-review-guidelines.data-security` (Rule 1, 2, 5)
* **Yapılan Uygulama:** [`firestore.rules`](file:///Users/kuzey/projects/omakase/firestore.rules) dosyası `firestore-rules-author` alt ajanı tarafından tamamen yenilendi:
  - `users/{userId}`: Okuma yalnızca oturum açmış kullanıcılara (`isSignedIn()`), oluşturma/güncelleme/silme yalnızca hesap sahibine (`isOwner(userId)`) ve alan bazlı şema/tip/uzunluk kontrollerine bağlandı.
  - `users/{userId}/following/{targetUid}` & `blocked_users/{blockedUid}`: Yalnızca hesap sahibi (`isOwner(userId)`) okuyup yazabilir.
  - `users/{userId}/followers/{followerUid}`: Hesap sahibi veya takipçi (`isOwner(userId) || isOwner(followerUid)`) tarafından yönetilebilir.
  - `shared_posts/{postId}`: Oluşturma ve silme yalnızca gönderi sahibine (`authorId == request.auth.uid`), güncelleme ise yalnızca `reactionCounts` haritası veya `commentCount` sayacının ±1 değişimiyle sınırlandırıldı.
  - `moderation_reports/{reportId}`: Yalnızca `reporterUid == request.auth.uid` ile rapor oluşturulabilir; istemciden okuma, güncelleme ve silme tamamen kapatıldı (`allow read, update, delete: if false;`).

### 4.2. `Info.plist` ATS, `NSLocalNetworkUsageDescription` ve Telemetri Temizliği (✅ Tamamlandı)
* [`omakase/omakase/Info.plist`](file:///Users/kuzey/projects/omakase/omakase/omakase/Info.plist) içindeki `NSAppTransportSecurity` (`172.20.10.14`, `127.0.0.1`, `localhost` HTTP istisnaları) tamamen kaldırıldı.
* [`omakase/omakase.xcodeproj/project.pbxproj`](file:///Users/kuzey/projects/omakase/omakase/omakase.xcodeproj/project.pbxproj) içinde `INFOPLIST_KEY_NSLocalNetworkUsageDescription` anahtarı `Release` yapılandırmasından çıkarıldı (yalnızca `Debug` yapılandırmasında bırakıldı).
* [`Networking/SSEClient.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift) ve [`Feed/FeedViewModel.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/FeedViewModel.swift) içindeki `http://127.0.0.1:7607/ingest/...` adresine istek atan `AgentDebugLog` kodları tamamen silindi.
* [`L10n.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/L10n.swift) içindeki geliştiriciye yönelik bağlantı hata metinleri (`OMAKASE_API_URL`, `uvicorn` vb.) son kullanıcıya uygun mesajlarla değiştirildi.
* `AppIcon.appiconset/omakase.png` dosyası `sips -g all` ile kontrol edildi: `1024×1024`, `RGB`, `hasAlpha: no`, `sRGB IEC61966-2.1` (✅ App Store ikon standartlarına tam uyumlu).

### 4.3. Derleme Yapılandırmaları (`Debug` vs `Release`), Yetenekler (`Capabilities`) ve Cihaz Otomasyonu
* **Dayanak:** [`knowledge.xcode.build-configurations`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/build-configurations.md) (Rule 1–3) & [`knowledge.xcode.entitlements-capabilities`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/entitlements-capabilities.md) (Rule 1–4)
* **Per-Configuration Yapılandırma (`build-configurations` Rule 1–3):** `Debug` ve `Release` arasında farklı olması gereken değerler **"Any Configuration"** yerine ilgili sütuna tanımlanmalı; `#if DEBUG` koşulları `SWIFT_ACTIVE_COMPILATION_CONDITIONS` üzerinden doğrulanmalıdır.

| Ortam | `OMAKASE_API_URL` Değeri | Kullanım Amacı |
|-------|--------------------------|----------------|
| **Canlı (Cloud Run — Varsayılan)** | `https://omakase-backend-20235796246.us-central1.run.app` | Fiziksel cihaz, Simulator, TestFlight ve App Store Release |
| **Lokal (Localhost — Geliştirme)** | `http://127.0.0.1:8000` | Yalnızca lokal FastAPI (`uvicorn`) testi yapılırken |

* **Capabilities & Entitlements (`entitlements-capabilities` Rule 1–4):** `Sign in with Apple` yeteneği `.entitlements` dosyası elle düzenlenerek değil, mutlaka Xcode'da **omakase target → Signing & Capabilities → + Capability** üzerinden eklenmelidir ki Apple Developer Portal üzerindeki App ID ve Provisioning Profile otomatik güncellensin.
* **Otomasyon Betikleri:** Fiziksel iPhone doğrulaması için [`scripts/launch-ios.sh`](file:///Users/kuzey/projects/omakase/scripts/launch-ios.sh) (`ADFC2ADA-EA3F-51A7-9C82-E2554869B97D`), Simulator doğrulaması için [`scripts/launch-simulator.sh`](file:///Users/kuzey/projects/omakase/scripts/launch-simulator.sh) (`45BCCBC2-5804-4E7A-BF2C-8E3FE4C47134`) kullanılmaktadır.

### 4.4. App Store Arşivleme (`Archive`) ve Dağıtım (`Export`) Prosedürü
* **Dayanak:** [`knowledge.xcode.archive-process`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/archive-process.md) & [`knowledge.xcode.export-options`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/export-options.md)

App Store Connect veya TestFlight'a paket gönderirken uyulması gereken zorunlu sıra:

1. **Hedef Cihaz Seçimi (`archive-process` Rule 1):** Xcode üst çubuğunda hedef olarak bir Simulator değil, **"Any iOS Device (arm64)"** veya bağlı fiziksel iPhone seçilmelidir (Simulator seçiliyken `Product → Archive` menüsü devre dışıdır).
2. **Release Konfigürasyonu Kontrolü (`archive-process` Rule 4):** `Edit Scheme → Archive` altında Build Configuration değerinin **Release** olduğu doğrulanmalıdır.
3. **Gizlilik Raporu Kontrolü (`manifest-file-structure-and-scope` Rule 5):** `Product → Archive` tamamlandıktan sonra açılan Organizer penceresinde arşive sağ tıklayıp **Generate Privacy Report** seçilerek uygulama ve Firebase/GoogleSignIn SDK gizlilik bildirimlerinin birleştiği teyit edilmelidir.
4. **Yerel Doğrulama (`archive-process` Rule 2 & `export-options` Rule 3):** **"Distribute App"** butonuna basmadan önce mutlaka **"Validate App"** çalıştırılmalı; dağıtım yöntemi veya imzalama seçeneği değiştirilirse yeniden doğrulama yapılmalıdır.
5. **Dağıtım ve Otomatik İmzalama (`export-options` Rule 1 & Rule 2):** **Distribute App → App Store Connect** seçilmeli ve proje Automatic Signing kullandığı için dışa aktarım sırasında da **Automatic Signing** tercih edilmelidir.
6. **Arşivin ve `dSYMs` Sembollerinin Saklanması (`archive-process` Rule 3):** Yükleme başarılı olduktan sonra Organizer içindeki `.xcarchive` **kesinlikle silinmemelidir**; üretim ortamındaki çökme raporlarını (crash logs) sembolize etmek için gereken `dSYMs` dosyaları yalnızca bu arşiv içinde yer alır.

---

## 5. Güncel Sistem Mimarisi ve Bileşen Durumu

| Bileşen | Durum | App Store Hazırlık Notu |
|---------|-------|-------------------------|
| **Kayıt & Giriş (`AuthView`, `AuthService`)** | ✅ Hazır | Sign in with Apple (Kural 4.8), Google Sign-In, 3 adımlı E-posta kaydı (`displayName` + `@username` moderasyon filtreli) ve Hesap Silme (`deleteAccount` — Kural 5.1.1v) tamamlandı. |
| **Kişisel Akış & Kategori Seçici (`BentoTasteBox`)** | ✅ Hazır | 12 kategori, dinamik alt konular, özel konu moderasyonu ve Deep Dive bottom sheet modal hazır. `AgentDebugLog` yerel port çağrıları temizlendi. |
| **Topluluk (`TimelineView`, `CommentsView`, `UserProfileSheet`, `UserSearchView`)** | ✅ Hazır | Gönderi/Yorum/Profil Şikayet Etme (`moderation_reports`), Kullanıcı Engelleme (`blockUser` / `unblockUser` + anlık akış filtresi) ve yorum ön moderasyonu (Kural 1.2) tamamlandı. |
| **Web Tanıtım & Yasal Sayfalar (`web/`)** | ✅ Hazır | `web/privacy.html` (Gizlilik Politikası) ve `web/terms.html` (Kullanım Koşulları / EULA + sıfır tolerans UGC politikası) oluşturuldu ve hem uygulama içinden hem `web/index.html` alt bilgisinden bağlandı. |
| **Gizlilik Manifestosu (`PrivacyInfo.xcprivacy`)** | ✅ Hazır | `omakase/omakase/PrivacyInfo.xcprivacy` oluşturuldu ve `plutil -lint` ile doğrulandı (`CA92.1` + `Name`, `EmailAddress`, `UserID`). |
| **Firestore Güvenlik Kuralları (`firestore.rules`)** | ✅ Hazır | Sahip bazlı ve şema doğrulamalı güvenlik kuralları yazıldı. |
| **Canlı Backend (Cloud Run)** | ✅ Hazır | `https://omakase-backend-20235796246.us-central1.run.app` üzerinde HTTPS ile çalışıyor; `GEMINI_API_KEY` sunucuda korunuyor. |

---

## 6. Adım Adım Yayına Hazırlık Eylem Planı (Checklist)

### Tamamlanan Kod ve Yapılandırma Maddeleri
- [x] **1. `PrivacyInfo.xcprivacy` Oluşturulması (Kapı 2):** [`omakase/omakase/PrivacyInfo.xcprivacy`](file:///Users/kuzey/projects/omakase/omakase/omakase/PrivacyInfo.xcprivacy) oluşturuldu (`NSPrivacyAccessedAPICategoryUserDefaults` -> `CA92.1` ve `NSPrivacyCollectedDataTypes` beyanları).
- [x] **2. Sign in with Apple Kod Entegrasyonu (Kapı 1 — Kural 4.8):** `AuthService.swift` ve `AuthView.swift` içinde SHA256 nonce, Keychain `appleIDUser` saklama, `getCredentialState` kontrolü ve eşit görünürlükte "Apple ile devam et" butonu eklendi.
- [x] **3. Hesap Silme Özelliği (Kapı 1 — Kural 5.1.1v):** `AuthService.deleteAccount(l10n:)` ve `FirestoreService.deleteAllUserData(uid:)` yazıldı; `MyProfileSheet` içine onay uyarılı "Hesabı Sil" butonu eklendi.
- [x] **4. UGC Moderasyon Tamamlaması (Kapı 1 — Kural 1.2):**
  - `CommentsView.sendComment()` ve `AuthView` (`displayName` / `username`) içine `ContentModerationService.isAppropriate` kontrolü eklendi.
  - `TimelinePostCard` içine "Gönderiyi Bildir" (`reportPost`) ve "Kullanıcıyı Engelle" (`blockUser`) seçenekleri eklendi.
  - `UserProfileSheet` içine "Kullanıcıyı Bildir" (`reportUser`) ve "Kullanıcıyı Engelle / Engeli Kaldır" (`blockUser` / `unblockUser`) eklendi; engellenen kullanıcıların içerikleri akıştan, yorumlardan ve aramadan anında filtrelendi.
- [x] **5. Uygulama İçi İletişim ve Yasal Bağlantılar (Kapı 1 — Kural 1.2 & 1.5):** `MyProfileSheet` ve `AuthView` içerisine "Destek ve İletişim (`mailto:destek@getomakase.app`)", "Gizlilik Politikası (`https://getomakase.app/privacy.html`)" ve "Kullanım Koşulları (`https://getomakase.app/terms.html`)" eklendi; `web/privacy.html` ve `web/terms.html` hazırlandı.
- [x] **6. `firestore.rules` Sıkılaştırması (Kapı 1 & 3 — Kural 1.6):** Sahip bazlı (`authorId == request.auth.uid`, `userId == request.auth.uid`) ve şema doğrulamalı kurallar yazıldı.
- [x] **7. `Info.plist` ve Debug Telemetri Temizliği (Kapı 3 — Kural 1.6):** `Info.plist` içindeki `172.20.10.14` HTTP istisnası, Release `NSLocalNetworkUsageDescription` anahtarı ve `127.0.0.1:7607` `AgentDebugLog` çağrıları kaldırıldı.

### Gönderim Öncesi Manuel Konsol & Xcode GUI Adımları (Geliştirici Aksiyonları)
- [ ] **A. Xcode Lisans Onayı ve Capability Ekleme:**
  1. macOS'ta Xcode güncellendiği için terminalde bir kez `sudo xcodebuild -license accept` çalıştırın (veya Xcode'u açıp yeni lisans sözleşmesini onaylayın).
  2. `knowledge.xcode.entitlements-capabilities` **Rule 1** uyarınca `.entitlements` dosyası elle düzenlenmemelidir; Xcode'da **omakase target → Signing & Capabilities → + Capability → Sign in with Apple** ekleyerek provisioning profile'ın otomatik güncellenmesini sağlayın.
- [ ] **B. Firebase Console & Dağıtım:**
  1. Firebase Console → **Authentication → Sign-in method** altından **Apple** sağlayıcısını etkinleştirin.
  2. Güncellenen Firestore kurallarını ve yasal web sayfalarını canlıya alın:
     ```bash
     firebase deploy --only firestore:rules,hosting
     ```
- [ ] **C. App Store Connect & Arşiv Doğrulaması:**
  1. App Store Connect → **App Review Information** bölümüne inceleme ekibi için aktif bir **Demo Hesap (E-posta ve Şifre)** girin (`knowledge.app-store-review-guidelines.demo-account` Rule 1).
  2. Xcode'da **Any iOS Device (arm64)** seçerek **Product → Archive** alın; Organizer'da **Validate App** ve **Generate Privacy Report** kontrollerini çalıştırıp **Distribute App** ile gönderin.

---

## 7. Apple Agent Kit İzlenebilirlik Özeti

`.agents/AGENTS.md` kuralları gereğince bu denetim ve uygulama sürecinde kullanılan yönlendirme zinciri:

1. **Seçilen Workflow'lar:**
   - [`workflow.app-store-submission`](file:///Users/kuzey/projects/omakase/.agents/workflows/app-store-submission/WORKFLOW.md): Uygulamanın App Store gönderimi öncesinde inceleme kuralları, gizlilik manifestosu ve Xcode/güvenlik kapılarından geçirilmesi için.
   - [`workflow.authentication`](file:///Users/kuzey/projects/omakase/.agents/workflows/authentication/WORKFLOW.md): Kural 4.8 kapsamında zorunlu olan **Sign in with Apple** akışının kimlik doğrulama, Keychain saklama, UI metin stili ve erişilebilirlik kurallarına uygun olarak uçtan uca geliştirilmesi için.
2. **Sırasıyla Çalıştırılan Skill'ler:**
   - [`skill.app-store-review-guidelines.submission`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-review-guidelines/SKILL.md)
   - [`skill.privacy.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/privacy/SKILL.md)
   - [`skill.xcode.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/xcode/SKILL.md)
   - [`skill.authenticationservices.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/authenticationservices/SKILL.md)
   - [`skill.security.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/security/SKILL.md)
   - [`skill.style-guide.writing`](file:///Users/kuzey/projects/omakase/.agents/skills/style-guide/SKILL.md)
   - [`skill.accessibility.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/accessibility/SKILL.md)
3. **Yüklenen Knowledge Contracts ve Gerekçeleri:**
   - [`app-completeness.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/app-completeness.md) & [`demo-account.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/demo-account.md): Giriş zorunlu (login-gated) yapı nedeniyle demo hesap gereksinimi ve uygulama tamlığı kontrolü için.
   - [`login-services-equivalent-option.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/login-services-equivalent-option.md): Google Sign-In kullanımının Kural 4.8 kapsamında Sign in with Apple zorunluluğunu tetiklediğini doğrulamak için.
   - [`user-generated-content-moderation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/user-generated-content-moderation.md): Topluluk akışı, profiller ve yorumlar için Kural 1.2'nin 4 zorunlu mekanizmasını (ön filtre, şikayet etme, kullanıcı engelleme, iletişim) uygulamak için.
   - [`developer-contact-information.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/developer-contact-information.md): Kural 1.5 uyarınca uygulama içi iletişim bilgisi ve yasal bağlantıları eklemek için.
   - [`data-security.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/data-security.md): Kural 1.6 kapsamında `Info.plist` ATS istisnalarını temizlemek ve `firestore.rules` yetki kurallarını sıkılaştırmak için.
   - [`privacy-manifest.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/privacy-manifest.md), [`privacy-nutrition-label.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/privacy-nutrition-label.md), [`manifest-file-structure-and-scope.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/manifest-file-structure-and-scope.md), [`required-reason-api-declarations.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/required-reason-api-declarations.md), [`collected-data-types-declaration.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/collected-data-types-declaration.md), [`tracking-domains-and-third-party-sdk-signatures.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/tracking-domains-and-third-party-sdk-signatures.md): `PrivacyInfo.xcprivacy` dosyasını Apple şemasına (`CA92.1` ve toplanan veri tipleri) uygun olarak oluşturmak için.
   - [`sign-in-with-apple-request-and-credential.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/sign-in-with-apple-request-and-credential.md), [`nonce-and-identity-token-verification.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/nonce-and-identity-token-verification.md), [`credential-state-and-revocation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/credential-state-and-revocation.md), [`session-persistence-and-sign-out.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/authenticationservices/session-persistence-and-sign-out.md): Sign in with Apple akışında SHA256 nonce, ilk girişte `fullName` yakalama, `getCredentialState` ve `credentialRevokedNotification` kurallarını eksiksiz uygulamak için.
   - [`keychain-item-crud.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/security/keychain-item-crud.md) & [`keychain-accessibility-levels.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/security/keychain-accessibility-levels.md): Apple `user` kimliğini arka plan iş parçacığında (`Task.detached`) ve `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` seviyesinde Keychain'de saklamak için.
   - [`sign-in-and-authentication-terminology.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/style-guide/sign-in-and-authentication-terminology.md) & [`accessibility-labels.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/accessibility/accessibility-labels.md): Kimlik doğrulama buton metinlerini ve ikon butonlarının VoiceOver erişilebilirlik etiketlerini (`accessibilityLabel`) standartlara uygun yazmak için.
   - [`build-configurations.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/build-configurations.md), [`entitlements-capabilities.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/entitlements-capabilities.md), [`archive-process.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/archive-process.md), [`export-options.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/export-options.md): Debug/Release yapılandırma ayrımı ve capability/arşivleme kurallarını uygulamak için.
