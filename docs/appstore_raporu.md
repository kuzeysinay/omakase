# 🍣 Omakase — App Store Gönderim Denetimi & Prodüksiyon Raporu

> **Son Güncelleme:** 12 Kasım 2026  
> **Denetim Metodolojisi:** Apple Agent Kit — `workflow.app-store-submission` (`skill.app-store-review-guidelines.submission` → `skill.privacy.foundations` → `skill.xcode.foundations`)  
> **Amaç:** Uygulamanın ve web altyapısının (`omakase/`, `backend/`, `web/`) son haline göre App Store Connect gönderimi öncesindeki **mevcut durumu**, **kritik eksikleri (red sebeplerini)** ve **düzeltilmesi gereken yapılandırmaları** somut dosya kanıtlarıyla ortaya koymak.

---

## İçindekiler

1. [Yönetici Özeti: Gönderim Öncesi Kırmızı Bayraklar (Red Sebepleri)](#1-yönetici-özeti-gönderim-öncesi-kırmızı-bayraklar)
2. [Kapı 1: App Review Kılavuzu Uyumluluk Denetimi (`skill.app-store-review-guidelines.submission`)](#2-kapı-1-app-review-kılavuzu-uyumluluk-denetimi)
3. [Kapı 2: Gizlilik Manifestosu ve Veri Beyanı Denetimi (`skill.privacy.foundations`)](#3-kapı-2-gizlilik-manifestosu-ve-veri-beyanı-denetimi)
4. [Kapı 3: Xcode, İmzalama, Güvenlik ve Arşiv Denetimi (`skill.xcode.foundations`)](#4-kapı-3-xcode-imzalama-güvenlik-ve-arşiv-denetimi)
5. [Güncel Sistem Mimarisi ve Bileşen Durumu](#5-güncel-sistem-mimarisi-ve-bileşen-durumu)
6. [Adım Adım Yayına Hazırlık Eylem Planı (Checklist)](#6-adım-adım-yayına-hazırlık-eylem-planı-checklist)
7. [Apple Agent Kit İzlenebilirlik Özeti (Workflow, Skill ve Knowledge Contracts)](#7-apple-agent-kit-izlenebilirlik-özeti)

---

## 1. Yönetici Özeti: Gönderim Öncesi Kırmızı Bayraklar

Kod tabanında yapılan denetim sonucunda, uygulamanın şu anki haliyle App Store Connect'e yüklenmesi veya incelemeye (App Review) gönderilmesi durumunda **kesin olarak reddedilmesine (veya yükleme anında engellenmesine)** yol açacak **7 kritik bulgu** tespit edilmiştir:

| # | Önem | Kategori / Kural | Mevcut Durum (Eksik / Yanlış) | İlgili Dosya |
|---|------|------------------|-------------------------------|--------------|
| **1** | 🔴 **KRİTİK (Yükleme Engeli)** | **Kural 5.1.2** — `PrivacyInfo.xcprivacy` | Projede `PrivacyInfo.xcprivacy` dosyası **hiç yok**. `@AppStorage` / `UserDefaults` kullanıldığı için App Store Connect binary yüklemesini reddeder. | `omakase/omakase/` |
| **2** | 🔴 **KRİTİK (Kesin Red)** | **Kural 4.8** — Sign in with Apple | Birincil hesap girişi için **Google Sign-In** sunuluyor ancak eşdeğer gizlilik özellikli **Sign in with Apple** seçeneği **yok**. | `Auth/AuthView.swift`, `Auth/AuthService.swift` |
| **3** | 🔴 **KRİTİK (Kesin Red)** | **Kural 5.1.1(v)** — Hesap Silme | Uygulama içinde hesap oluşturma (3 adımlı E-posta + `@username` ve Google) var, ancak Profil ekranında **Hesabı Sil (`deleteAccount`)** özelliği **yok** (yalnızca Çıkış Yap mevcut). | `Auth/AuthService.swift`, `Social/UserProfileSheet.swift` |
| **4** | 🔴 **KRİTİK (Kesin Red)** | **Kural 1.2** — UGC Moderasyon (Kullanıcı Engelleme & Gönderi Şikayeti & Filtre) | 1) Kötü niyetli kullanıcıları **Engelleme (Block User)** özelliği hiç yok.<br>2) Topluluk gönderilerini (`SharedPost`) **Bildir (Report)** butonu yok (sadece yorumlarda var).<br>3) Yorum gönderirken (`CommentsView`) ve `@kullanıcı_adı` / görünür isim alırken (`AuthView`) `ContentModerationService` filtresi çalıştırılmıyor. | `Social/TimelinePostCard.swift`, `Social/UserProfileSheet.swift`, `Social/CommentsView.swift`, `Auth/AuthView.swift` |
| **5** | 🔴 **KRİTİK (Kesin Red)** | **Kural 1.2, 1.5 & 5.1.1(i)** — Uygulama İçi İletişim & Yasal Web Sayfaları | `web/index.html` üzerinde `mailto:destek@getomakase.app` yer alsa da; hem uygulama içinde (`MyProfileSheet`) **Destek / İletişim**, **Gizlilik Politikası** ve **Kullanım Koşulları (EULA)** bağlantıları yok, hem de `web/` altında bağımsız `/privacy` ve `/terms` sayfaları henüz yayınlanmamış. | `Social/UserProfileSheet.swift`, `web/index.html` |
| **6** | 🔴 **KRİTİK (Güvenlik Açığı)** | **Kural 1.6** — Veri Güvenliği (`firestore.rules`) | `firestore.rules` içinde `allow read, write: if request.auth != null;` kuralı var. Giriş yapmış herhangi bir kullanıcı başka birinin profilini veya gönderisini silebilir/değiştirebilir. | `firestore.rules` |
| **7** | 🟠 **YÜKSEK (İnceleme & ATS)** | **Kural 1.6 & 2.1(a)** — `Info.plist` ATS İstisnaları & Demo Hesap | 1) `Info.plist` içinde yerel geliştirme IP'si (`172.20.10.14`) için güvensiz HTTP istisnası (`NSExceptionAllowsInsecureHTTPLoads`) unutulmuş.<br>2) Uygulama açılışta zorunlu giriş (`AuthView`) istediği için App Store Connect inceleme notlarında **aktif bir Demo Hesap** verilmesi şarttır. | `omakase/omakase/Info.plist`, `ContentView.swift` |

---

## 2. Kapı 1: App Review Kılavuzu Uyumluluk Denetimi (`skill.app-store-review-guidelines.submission`)

### 2.1. Giriş Servisleri ve Eşdeğer Seçenek Zorunluluğu — Kural 4.8
* **Dayanak:** `knowledge.app-store-review-guidelines.login-services-equivalent-option`
* **Kural Özeti:** Bir uygulama kullanıcının **birincil hesabını (primary account)** oluşturmak veya doğrulamak için üçüncü taraf/sosyal bir giriş servisi (örn. Google Sign-In) kullanıyorsa; veri toplamayı yalnızca ad ve e-posta ile sınırlayan, kullanıcının e-posta adresini gizlemesine olanak tanıyan ve reklam amacıyla etkileşim toplamayan eşdeğer bir giriş seçeneğini (**Sign in with Apple**) **aynı akışta ve eşit görünürlükte** sunmak zorundadır.
* **Kod Tabanı Bulgusu (❌ Yanlış / Eksik):**
  - [`ContentView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/ContentView.swift) (`!authService.isAuthenticated`) ve [`AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift) incelendiğinde, kullanıcının uygulamaya erişmek için kurduğu hesap birincil hesaptır.
  - [`AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift) üzerinde **"Google ile devam et"** ve 3 adımlı **"E-posta ile Hesap Oluştur"** seçenekleri bulunmaktadır. Standart e-posta/şifre kaydı Apple'ın 4.8 kapsamındaki 3 şartını (özellikle e-posta adresini gizleyerek hesap açma şartını) **karşılamaz** ve 5 muafiyetten (yalnızca kendi birinci parti hesap sistemini kullanma muafiyeti, Google Sign-In eklendiği anda düşer) hiçbirine girmez.
* **Çözüm:** `AuthenticationServices` çerçevesi (`ASAuthorizationAppleIDProvider` / `SignInWithAppleButton`) kullanılarak Firebase Auth üzerinde Apple sağlayıcısı etkinleştirilmeli ve [`AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift) karşılama ekranına Google Sign-In ile eşit boyutta **"Apple ile devam et"** butonu eklenmelidir.

### 2.2. Kullanıcı Tarafından Oluşturulan İçerik (UGC) Moderasyonu — Kural 1.2
* **Dayanak:** `knowledge.app-store-review-guidelines.user-generated-content-moderation`
* **Kural Özeti:** Bir kullanıcının oluşturduğu içeriğin (paylaşılan gönderi, yorum, görünür isim, `@kullanıcı_adı`) başka kullanıcılara gösterildiği her uygulama **4 zorunlu mekanizmayı** eksiksiz içermelidir:
  1. **Yayın Öncesi Sakıncalı İçerik Filtresi (Rule 1):** İçerik yayınlanmadan *önce* filtrelenmelidir.
  2. **Şikayet Mekanizması ve Zamanında Müdahale (Rule 2):** Saldırgan içerikleri bildirme (`Report`) mekanizması.
  3. **Kötü Niyetli Kullanıcıları Engelleme (Rule 3):** Kullanıcıyı servisten engelleme (`Block User`) — sadece sessize alma (mute) yeterli değildir.
  4. **Yayınlanmış İletişim Bilgisi (Rule 4):** Uygulama içinden erişilebilir geliştirici iletişim bilgisi.
* **Kod Tabanı Bulgusu (❌ Eksikler):**
  - **Filtreleme Eksiği:** [`ContentModerationService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/ContentModerationService.swift) ve backend `_BLOCKLIST_RE` yalnızca ilgi alanı (`interests`) seçiminde ve AI üretiminde çalışmaktadır. Ancak:
    - [`CommentsView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/CommentsView.swift) içindeki `sendComment()` fonksiyonu yorum metnini `ContentModerationService.isAppropriate(text)` ile **kontrol etmeden** doğrudan Firestore'a yazmaktadır.
    - [`AuthView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthView.swift) içindeki `displayName` ve `@username` adımlarında uygunsuz kelime filtresi **çalıştırılmamaktadır**.
  - **Gönderi ve Profil Şikayet Eksiği:** [`CommentsView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/CommentsView.swift) içinde yorumlar için `reportComment` mevcuttur; ancak [`TimelinePostCard.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/TimelinePostCard.swift) (toplulukta paylaşılan gönderiler) ve [`UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift) (kullanıcı profilleri) üzerinde **Bildir (Report)** seçeneği **bulunmamaktadır**.
  - **Kullanıcı Engelleme (Block User) Eksiği:** [`FirestoreService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift), [`UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift) ve [`TimelineView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/TimelineView.swift) içinde bir kullanıcıyı engelleme (`blockUser`) işlevi **hiç yoktur**. Bir kullanıcı engellendiğinde, o kullanıcının gönderileri ve yorumları akıştan anında kaldırılmalı ve etkileşimi kesilmelidir.

### 2.3. Geliştirici İletişim Bilgileri ve Web Sayfaları — Kural 1.5 & 5.1.1(i)
* **Dayanak:** `knowledge.app-store-review-guidelines.developer-contact-information`
* **Kural Özeti:** Hem App Store Connect üzerindeki **Support URL** hem de **uygulamanın kendisi** (`MyProfileSheet` / Ayarlar ekranı) kullanıcıların geliştiriciye kolayca ulaşabileceği güncel bir iletişim yolu içermelidir.
* **Kod Tabanı Bulgusu (❌ Eksik):**
  - [`web/index.html`](file:///Users/kuzey/projects/omakase/web/index.html#L783) alt bilgisinde `mailto:destek@getomakase.app` yer almaktadır; ancak `MyProfileSheet` ([`Social/UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift)) içinde yalnızca Tercihler (Dil, Görünüm, Letterboxd), Gönderiler ve Çıkış Yap bölümleri vardır.
  - Uygulama içinde **"Destek / Bize Ulaşın"** (`mailto:destek@getomakase.app`), **"Gizlilik Politikası"** (`https://getomakase.app/privacy`) ve **"Kullanım Koşulları (EULA)"** (`https://getomakase.app/terms`) bağlantıları bulunmamaktadır.

### 2.4. Veri Toplama, Saklama ve Hesap Silme — Kural 5.1.1
* **Dayanak:** `knowledge.app-store-review-guidelines.privacy-nutrition-label` & Guideline 5.1.1(v)
* **Kod Tabanı Bulgusu (❌ Eksik):**
  - **Hesap Silme (`deleteAccount`) Yok:** [`AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift) ve `MyProfileSheet` ([`UserProfileSheet.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Social/UserProfileSheet.swift)) içinde hesap silme işlevi henüz yazılmamıştır. Hesap açabilen her iOS uygulaması, kullanıcının hesabını ve ilişkili Firestore verilerini (`users/{uid}`, `shared_posts`) uygulama içinden kalıcı olarak silebilmesini zorunlu kılar.
  - **Giriş Zorunlu Yapı (Login-Gated):** [`ContentView.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/ContentView.swift#L28) satırında `if !authService.isAuthenticated { AuthView(authService: authService) }` kontrolü bulunduğu için uygulama açılışta giriş zorunludur.

### 2.5. Uygulama Tamlığı ve Demo Hesap Zorunluluğu — Kural 2.1
* **Dayanak:** `knowledge.app-store-review-guidelines.app-completeness`, `knowledge.app-store-review-guidelines.demo-account`
* **Kural Özeti:**
  - Giriş ekranı arkasında kalan tüm özelliklerin incelenebilmesi için App Store Connect inceleme notlarında (**App Review Information**) çalışan bir **Demo Hesap (E-posta ve Şifre)** verilmesi ve inceleme süresince backend'in (`omakase-backend` Cloud Run servisi + Firebase) aktif olması zorunludur (`demo-account` Rule 1 & Rule 2).
  - Uygulama içinde "Yakında / Coming Soon" gibi yer tutucu (placeholder) ekranlar bulunmamaktadır (`app-completeness` Rule 1 — ✅ Uyumlu).

### 2.6. Üçüncü Taraf İçerik Lisanslama (Letterboxd RSS) — Kural 5.2.1–5.2.3
* **Dayanak:** `knowledge.app-store-review-guidelines.third-party-content-licensing`
* **Durum (✅ Uyumlu):**
  - Letterboxd logosu veya ticari markası görsel olarak kullanılmamakta, yalnızca kamuya açık RSS beslemesinden film adları okunarak Gemini ile özgün kültür/sinema yazıları üretilmektedir.

---

## 3. Kapı 2: Gizlilik Manifestosu ve Veri Beyanı Denetimi (`skill.privacy.foundations`)

* **Dayanak:**
  - `knowledge.privacy.manifest-file-structure-and-scope`
  - `knowledge.privacy.required-reason-api-declarations`
  - `knowledge.privacy.collected-data-types-declaration`
  - `knowledge.privacy.tracking-domains-and-third-party-sdk-signatures`

### 3.1. `PrivacyInfo.xcprivacy` Dosyası Eksikliği (❌ Kritik Engel)
Uygulama iOS 17+ hedeflidir ve `UserDefaults` (`@AppStorage("omakase.hasOnboarded")`, `@AppStorage("omakase.interests")`, `@AppStorage("omakase.language")`, `@AppStorage("omakase.appearance")`, `@AppStorage("omakase.letterboxd_username")`) kullanmaktadır.
- `required-reason-api-declarations` **Rule 5** uyarınca: `UserDefaults` gibi Required-Reason API kullanan ancak `PrivacyInfo.xcprivacy` içinde geçerli gerekçe kodu bildirmeyen uygulamalar **App Store Connect tarafından yükleme anında reddedilir**.

### 3.2. Oluşturulması Gereken `omakase/omakase/PrivacyInfo.xcprivacy` Şeması
Dosya tam olarak uygulama hedefinin kök kaynaklarında (`omakase/omakase/PrivacyInfo.xcprivacy`) yer almalı ve yalnızca Apple'ın belgelediği enum sabitlerini içermelidir:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>CA92.1</string>
			</array>
		</dict>
	</array>
	<key>NSPrivacyCollectedDataTypes</key>
	<array>
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeName</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array>
				<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeEmailAddress</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array>
				<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeUserID</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array>
				<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```

### 3.3. Üçüncü Taraf SDK İmzaları ve Gizlilik Raporu (`tracking-domains-and-third-party-sdk-signatures`)
- Projede kullanılan `FirebaseAuth`, `FirebaseFirestore`, `FirebaseCore` ve `GoogleSignIn` paketleri, Apple'ın **"Privacy Manifest and Signature Required"** listesindedir.
- Arşiv alındıktan sonra Xcode Organizer üzerinden **Product → Archive → Arşive Sağ Tıkla → Generate Privacy Report** (`manifest-file-structure-and-scope` Rule 5) çalıştırılarak hem uygulamanın hem de bağlı Firebase/GoogleSignIn SDK'larının beyanlarının eksiksiz birleştiği doğrulanmalıdır.

---

## 4. Kapı 3: Xcode, İmzalama, Güvenlik ve Arşiv Denetimi (`skill.xcode.foundations`)

* **Dayanak:**
  - `knowledge.app-store-review-guidelines.data-security`
  - `knowledge.xcode.build-configurations`
  - `knowledge.xcode.entitlements-capabilities`
  - `knowledge.xcode.archive-process`
  - `knowledge.xcode.export-options`

### 4.1. Veri Güvenliği ve `firestore.rules` İhlali (❌ Kritik Güvenlik Açığı)
* **Dayanak:** `knowledge.app-store-review-guidelines.data-security` (Rule 1, 2, 5)
* **Mevcut Durum:** [`firestore.rules`](file:///Users/kuzey/projects/omakase/firestore.rules) dosyası şu şekildedir:
  ```javascript
  match /{document=**} {
    allow read, write: if request.auth != null;
  }
  ```
* **Sorun:** Kimliği doğrulanmış herhangi bir kullanıcı tüm `users`, `shared_posts`, `comments` ve `reactions` koleksiyonlarında başka kullanıcıların verilerini değiştirebilir veya silebilir.
* **Çözüm:**
  - `users/{userId}`: Okuma herkese (`request.auth != null`), yazma/silme yalnızca `request.auth.uid == userId` (ve `followers` alt koleksiyonu için takip eden kullanıcının kendi UID'si).
  - `shared_posts/{postId}`: Oluşturma `request.resource.data.authorId == request.auth.uid`, silme `resource.data.authorId == request.auth.uid`.

### 4.2. `Info.plist` App Transport Security (ATS) ve Yapılandırma Ayrımı (❌ Yanlış Yapılandırma)
* **Dayanak:** `knowledge.app-store-review-guidelines.data-security` (Rule 2) & `knowledge.xcode.build-configurations` (Rule 1)
* **Mevcut Durum:** [`omakase/omakase/Info.plist`](file:///Users/kuzey/projects/omakase/omakase/omakase/Info.plist#L16-L40) içinde:
  - `172.20.10.14`, `127.0.0.1` ve `localhost` için `NSExceptionAllowsInsecureHTTPLoads = true` ve `NSAllowsLocalNetworking = true` tanımlıdır.
* **Sorun:** Canlı backend zaten HTTPS (`https://omakase-backend-20235796246.us-central1.run.app`) üzerinde çalışmaktadır. Release / App Store paketinde geliştiricinin yerel ağ IP'si (`172.20.10.14`) ve HTTP istisnalarının bulunması App Review sırasında ATS incelemesini tetikler.
* **Çözüm:** `Info.plist` içindeki `172.20.10.14` istisnası tamamen kaldırılmalı; `OMAKASE_API_URL` ve ATS ayarları Debug / Release yapılandırmalarına (`knowledge.xcode.build-configurations` Rule 1) göre ayrıştırılmalıdır.

### 4.3. Yetenekler (Capabilities) ve Entitlements (`knowledge.xcode.entitlements-capabilities`)
- **Sign in with Apple** eklendiğinde, yetenek mutlaka Xcode üzerinden **Signing & Capabilities → + Capability → Sign in with Apple** (`entitlements-capabilities` Rule 1) adımıyla eklenmelidir. Böylece `omakase.entitlements` dosyasında `com.apple.developer.applesignin` anahtarı oluşturulur ve Apple Developer Portal üzerindeki App ID / Provisioning Profile otomatik güncellenir.

### 4.4. Uygulama İkonu (`AppIcon.appiconset`) Kontrolü
- [`AppIcon.appiconset/Contents.json`](file:///Users/kuzey/projects/omakase/omakase/omakase/Assets.xcassets/AppIcon.appiconset/Contents.json) içinde `omakase.png` (1024×1024, standart, dark ve tinted varyantları) tanımlıdır. İkonun alfa kanalı (şeffaflık) içermediği Organizer doğrulamasında teyit edilmelidir.

### 4.5. Arşivleme ve Dağıtım Süreci (`knowledge.xcode.archive-process` & `export-options`)
1. Hedef cihaz olarak Simulator değil, **"Any iOS Device (arm64)"** veya fiziksel iPhone seçilmelidir (`archive-process` Rule 1).
2. Scheme'in `Archive` eyleminin **Release** yapılandırmasında olduğundan emin olunmalıdır (`archive-process` Rule 4).
3. **Product → Archive** tamamlandıktan sonra Organizer penceresinde **"Distribute App"** adımına geçmeden önce mutlaka **"Validate App"** çalıştırılmalıdır (`archive-process` Rule 2).
4. Dağıtım yöntemi olarak **App Store Connect** ve otomatik imzalama (**Automatic Signing**) seçilmelidir (`export-options` Rule 1 & Rule 2).
5. Yükleme sonrasında `.xcarchive` paketi (içindeki `dSYMs` sembol dosyaları çökme raporlarını çözmek için tek kaynak olduğundan) **silinmemelidir** (`archive-process` Rule 3).

---

## 5. Güncel Sistem Mimarisi ve Bileşen Durumu

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
                  │ HTTPS (SSE Stream)                 │ Firebase SDK
                  │ POST /feed/stream                  │ (Auth + Cloud Firestore)
                  ▼                                    ▼
┌───────────────────────────────────┐        ┌────────────────────────────┐
│     Google Cloud Run (Canlı)      │        │      Google Firebase       │
│  FastAPI Backend                  │        │  - Email & Google Auth     │
│  - _BLOCKLIST_RE Moderasyon       │        │  - Cloud Firestore         │
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

| Bileşen | Durum | App Store Hazırlık Notu |
|---------|-------|-------------------------|
| **Kayıt & Giriş (`AuthView`)** | ⚠️ Kısmen Hazır | 3 adımlı E-posta kaydı (`displayName` + `@username` + canlı önizleme) ve Google Sign-In tamamlandı. **Sign in with Apple (Kural 4.8)** ve **Hesap Silme (Kural 5.1.1v)** eklenecek. |
| **Kişisel Akış & Kategori Seçici (`BentoTasteBox`)** | ✅ Hazır | Gönderi yokken tam ekran açılan kategori sayfası, yatay kaydırmalı 12 kategori, 6'lı kompakt alt konu ızgarası, özel konu girişi ve Deep Dive bottom sheet modal tamamlandı. |
| **Topluluk (`TimelineView`)** | ⚠️ Kısmen Hazır | Arama çubuğu, `@kullanıcı_adı` gösterimi, 5'li reaksiyonlar ve yorum raporlama aktif. **Kullanıcı Engelleme (Block User)**, **Gönderi Raporlama** ve **Yorum Filtresi (Kural 1.2)** eklenecek. |
| **Web Tanıtım Sitesi (`web/`)** | ⚠️ Kısmen Hazır | `getomakase.app` arayüzü, interaktif demo ve iletişim e-postası (`destek@getomakase.app`) hazır. `/privacy` ve `/terms` yasal metin sayfaları eklenecek. |
| **Gizlilik Manifestosu (`PrivacyInfo.xcprivacy`)** | ❌ Eksik | Paket kök dizinine `PrivacyInfo.xcprivacy` eklenecek (`CA92.1` + toplanan veri tipleri). |
| **Firestore Güvenlik Kuralları** | ❌ Güvensiz | `firestore.rules` kullanıcı bazlı yetkilendirme (`request.auth.uid == userId`) ile sıkılaştırılacak. |
| **Canlı Backend (Cloud Run)** | ✅ Hazır | `https://omakase-backend-20235796246.us-central1.run.app` üzerinde HTTPS ile çalışıyor; `GEMINI_API_KEY` istemcide değil sunucuda korunuyor (`data-security` Rule 3). |

---

## 6. Adım Adım Yayına Hazırlık Eylem Planı (Checklist)

App Store'a göndermeden önce sırasıyla tamamlanması gereken iş listesi:

- [ ] **1. `PrivacyInfo.xcprivacy` Oluşturulması (Kapı 2):** `omakase/omakase/PrivacyInfo.xcprivacy` dosyasını oluşturup Xcode hedefine dahil et (`NSPrivacyAccessedAPICategoryUserDefaults` -> `CA92.1` ve `NSPrivacyCollectedDataTypes` beyanları).
- [ ] **2. Sign in with Apple Entegrasyonu (Kapı 1 — Kural 4.8):** Xcode'da `Sign in with Apple` capability'sini ekle, Firebase Auth Apple sağlayıcısını aç ve `AuthView.swift` ekranına "Apple ile devam et" butonunu yerleştir.
- [ ] **3. Hesap Silme Özelliği (Kapı 1 — Kural 5.1.1v):** `AuthService.deleteAccount()` fonksiyonunu yaz (kullanıcının Firestore `users/{uid}` belgesini, paylaşımlarını ve Firebase Auth kaydını silen akış) ve `MyProfileSheet` içine "Hesabı Sil" butonu ekle.
- [ ] **4. UGC Moderasyon Tamamlaması (Kapı 1 — Kural 1.2):**
  - `CommentsView.sendComment()` ve `AuthView` (`displayName` / `username`) içine `ContentModerationService.isAppropriate` kontrolü ekle.
  - `TimelinePostCard` içine "Gönderiyi Bildir" (`reportPost`) seçeneği ekle.
  - `UserProfileSheet` ve `TimelinePostCard` içine **"Kullanıcıyı Engelle" (`blockUser`)** özelliği ekle ve engellenen kullanıcıların içeriklerini akıştan filtrele.
- [ ] **5. Uygulama İçi İletişim ve Yasal Bağlantılar (Kapı 1 — Kural 1.2 & 1.5):** `MyProfileSheet` içerisine "Destek / İletişim (`mailto:destek@getomakase.app`)", "Gizlilik Politikası" ve "Kullanım Koşulları" satırlarını ekle; `web/` üzerinde yasal sayfaları yayınla.
- [ ] **6. `firestore.rules` Sıkılaştırması (Kapı 1 & 3 — Kural 1.6):** Herkesin her veriyi yazabildiği genel kuralı kaldırıp sahip bazlı (`authorId == request.auth.uid`, `userId == request.auth.uid`) kuralları devreye al.
- [ ] **7. `Info.plist` Temizliği (Kapı 3 — Kural 1.6):** `Info.plist` içindeki `172.20.10.14` yerel IP HTTP istisnasını kaldır.
- [ ] **8. Demo Hesap ve Arşiv Doğrulaması (Kapı 1 & 3 — Kural 2.1):** App Store Connect inceleme notları için bir demo hesap oluştur, Xcode Organizer'da **Validate App** ve **Generate Privacy Report** kontrollerini çalıştır.

---

## 7. Apple Agent Kit İzlenebilirlik Özeti

`.agents/AGENTS.md` kuralları gereğince bu raporun hazırlanmasında kullanılan yönlendirme zinciri:

1. **Seçilen Workflow:** [`workflow.app-store-submission`](file:///Users/kuzey/projects/omakase/.agents/workflows/app-store-submission/WORKFLOW.md)
   - *Neden:* Görev, uygulamanın App Store'a gönderilmeden önce inceleme kuralları, gizlilik manifestosu ve Xcode paketleme/güvenlik açısından uçtan uca denetlenmesini kapsamaktadır.
2. **Sırasıyla Çalıştırılan Skill'ler:**
   - [`skill.app-store-review-guidelines.submission`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-review-guidelines/SKILL.md)
   - [`skill.privacy.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/privacy/SKILL.md)
   - [`skill.xcode.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/xcode/SKILL.md)
3. **Yüklenen Knowledge Contracts ve Gerekçeleri:**
   - [`app-completeness.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/app-completeness.md) & [`demo-account.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/demo-account.md): Giriş zorunlu (login-gated) yapı nedeniyle demo hesap gereksinimi ve uygulama tamlığı kontrolü için.
   - [`login-services-equivalent-option.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/login-services-equivalent-option.md): Google Sign-In kullanımının Kural 4.8 kapsamında Sign in with Apple zorunluluğunu tetiklediğini doğrulamak için.
   - [`user-generated-content-moderation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/user-generated-content-moderation.md): Topluluk akışı ve yorumlar için Kural 1.2'nin 4 zorunlu mekanizmasını (filtre, raporlama, kullanıcı engelleme, iletişim) denetlemek için.
   - [`developer-contact-information.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/developer-contact-information.md): Kural 1.5 uyarınca uygulama içi iletişim bilgisi zorunluluğunu denetlemek için.
   - [`data-security.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/data-security.md): Kural 1.6 kapsamında `Info.plist` ATS istisnaları, API anahtarı güvenliği ve `firestore.rules` yetki kontrolü için.
   - [`privacy-manifest.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/privacy-manifest.md) & [`privacy-nutrition-label.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/privacy-nutrition-label.md): Kural 5.1.1 ve 5.1.2 gizlilik beyanı gereksinimleri için.
   - [`third-party-content-licensing.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/third-party-content-licensing.md): Letterboxd RSS entegrasyonunun Kural 5.2.1–5.2.3 karşısındaki durumunu değerlendirmek için.
   - [`manifest-file-structure-and-scope.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/manifest-file-structure-and-scope.md), [`required-reason-api-declarations.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/required-reason-api-declarations.md), [`collected-data-types-declaration.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/collected-data-types-declaration.md), [`tracking-domains-and-third-party-sdk-signatures.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/privacy/tracking-domains-and-third-party-sdk-signatures.md): Eksik olan `PrivacyInfo.xcprivacy` dosyasının tam şemasını, `CA92.1` gerekçe kodunu ve Firebase/GoogleSignIn SDK imza gereksinimlerini belirlemek için.
   - [`build-configurations.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/build-configurations.md), [`entitlements-capabilities.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/entitlements-capabilities.md), [`archive-process.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/archive-process.md), [`export-options.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/xcode/export-options.md): Debug/Release yapılandırma ayrımı, capability ekleme kuralları ve Organizer Validate/Distribute adımlarını doğrulamak için.
