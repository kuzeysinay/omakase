# 🍣 Omakase — Master Rapor (Mimari, Ürün/PMF, Küresel Pazarlama, App Store & Siber Güvenlik Özeti)

> **Son Güncelleme:** 26 Kasım 2026  
> **Kapsam:** `docs/` altındaki 6 uzman raporun ([`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md), [`founder_100_musteri_raporu.md`](file:///Users/kuzey/projects/omakase/docs/founder_100_musteri_raporu.md), [`siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md), [`appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md), [`urun_analizi_ve_pazarlama.md`](file:///Users/kuzey/projects/omakase/docs/urun_analizi_ve_pazarlama.md), [`pazarlama_ve_dagitim_stratejisi.md`](file:///Users/kuzey/projects/omakase/docs/pazarlama_ve_dagitim_stratejisi.md)) tek bir yönetici dokümanında birleştirilmiş güncel master özeti.

---

## İçindekiler

1. [Yönetici Özeti & Proje Durum Panosu](#1-yönetici-özeti--proje-durum-panosu)
2. [Ürün Mimarisi, Export Studio, Mission Control & 7 Dil (`proje_durum_ve_mimari_raporu.md`)](#2-ürün-mimarisi-export-studio-mission-control--7-dil)
3. [Ürün Tezi, PMF, Birim Ekonomisi & 100 Müşteri Doğrulaması (`urun_analizi_ve_pazarlama.md` & `founder_100_musteri_raporu.md`)](#3-ürün-tezi-pmf-birim-ekonomisi--100-müşteri-doğrulaması)
4. [Küresel Pazarlama, TikTok Otomasyonu & Dağıtım (`pazarlama_ve_dagitim_stratejisi.md`)](#4-küresel-pazarlama-tiktok-otomasyonu--dağıtım)
5. [App Store Uyumluluk & Prodüksiyon Denetimi (`appstore_raporu.md`)](#5-app-store-uyumluluk--prodüksiyon-denetimi)
6. [Siber Güvenlik & Sertleştirme Karnesi (`siber_guvenlik_raporu.md`)](#6-siber-güvenlik--sertleştirme-karnesi)
7. [Savunma Hattı (Moat) & v2/v3 Ürün Yol Haritası](#7-savunma-hattı-moat--v2v3-ürün-yol-haritası)
8. [Canlıya Geçiş Öncesi Kalan Güncelleme, Dağıtım & Konsol Aksiyonları](#8-canlıya-geçiş-öncesi-kalan-güncelleme-dağıtım--konsol-aksiyonları)
9. [Apple Agent Kit İzlenebilirlik Özeti](#9-apple-agent-kit-izlenebilirlik-özeti)

---

## 1. Yönetici Özeti & Proje Durum Panosu

**Omakase**, algoritmik sosyal medya gürültüsü (*doomscrolling / brainrot*) ile sohbet botlarının boş ekran sendromu (*prompt paralysis*) arasındaki boşluğu dolduran, **kağıt/mürekkep estetiğine, zorunlu birincil kaynakça doğrulamasına, Export Studio'ya ve 7 dile sahip kişisel kültür ve mikro-bilgi platformudur.**

| Alan | Durum | Özet Durum | Detay Rapor |
|------|-------|------------|-------------|
| **Ürün, Bento, Export Studio & 7 Dil** | ✅ **%100 Hazır** | 12 disiplin + **24 merak merceği**, başparmak bölgesi **Şefin Seçimi**, 14 editoryal format, 7 dil (`en, tr, ja, de, fr, es, ko`), tıklanabilir birincil kaynakça ([`PostSourceView`](file:///Users/kuzey/projects/omakase/omakase/omakase/Theme/PostSourceView.swift)), 15–25 sn `Reading Cooldown`, **Derin İnceleme**, **Export Studio** (3 oran × 4 tema), 3 slaytlı ASCII suşi onboarding + `ProfileSetupView` ve Keşfet/Takip `@username` topluluğu. | [`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md) |
| **Monetizasyon, Cihaz Kotası & Bildirim** | ✅ **Kod Tamamlandı** | RevenueCat (`5.103.2` + v2 API) Pro (\$29.99/yıl · 7 gün deneme veya \$3.99/ay), günde **3 ücretsiz post** (**1 Letterboxd/gün** dahil, `Kalan: X/3`) + 1 Derin İnceleme (`+1` paylaşım bonusu), tek ekranlı ASCII suşi paywall (5 tetikleyici), Keychain + SHA-256 **cihaz bazlı anti-abuse kotası**, APNs/FCM + yerel bildirim ve `OmakaseError` + Crashlytics. | [`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md) |
| **Mission Control, Web & Görseller** | ✅ **Kod & Görseller Hazır** | Firebase Hosting'de izole **Mission Control** ([`admin-web/`](file:///Users/kuzey/projects/omakase/admin-web) — 5 sekme, RevenueCat v2, `FeedbackSheetView`, `Agent'a Aktar`), Cloudflare'de yenilenen `getomakase.app` ([`web/`](file:///Users/kuzey/projects/omakase/web) — 8 slayt & 4 ekranlı canlı maket), **8 slayt × 7 dil** App Store görselleri, **32/32** backend testi ve **12** XCUITest hazır. | [`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md) |
| **100 Müşteri & Fiyat Doğrulaması** | ✅ **1. Tur %1 → 2. Tur %72** | `founder-skill` ile 100 persona test edildi: 5 tabak + kaynakçasız teklifte `%1` olan dönüşüm; 3 post + birincil kaynakça + `\$2.49/ay` yıllık çerçevesinde **`%72`** sıçradı (Van Westendorp `IPP: $2.53`). Üzerine cihaz kotası ve Letterboxd 1/gün duvarı eklendi. | [`founder_100_musteri_raporu.md`](file:///Users/kuzey/projects/omakase/docs/founder_100_musteri_raporu.md) |
| **App Store Uyumluluğu** | ✅ **Kod & Manifest Tamamlandı** | `PrivacyInfo.xcprivacy` (`CA92.1` + **7 veri tipi** — `ProductInteraction` dahil), Sign in with Apple + `ProfileSetupView`, tam Hesap Silme (SwiftData + yer imi temizliği dahil), UGC + **AI gönderi raporlama** ve Mission Control Moderasyon triyajı hazır. *(Yasal web sayfaları güncellenmeli.)* | [`appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md) |
| **Siber Güvenlik** | ✅ **14/15 Kodda Kapatıldı** | `S-01`, `S-02`, `S-04`–`S-15` (JWT, Rate Limit, `verify_admin_user`, `admin-web` Firebase Hosting izolasyonu, `device_usage` SHA-256, atomik `usernames/{handle}` + 14 gün bekleme, `firestore.rules`) kapatıldı; yalnızca GCP `API_KEY` konsol kısıtlaması (`S-03`) ve küçük 7-dil rules genişletmesi bekliyor. | [`siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md) |
| **Birim Ekonomisi & Küresel Dağıtım** | 🚀 **%96 Brüt Marj & Strateji Hazır** | Yoğun bir kullanıcının aylık AI (`gemini-3.5-flash` + `gemini-3.1-flash-lite`) ve bulut maliyeti **~\$0.10 – \$0.14** (~%96 brüt marj). Tier-1 pazarlar (US/UK/EU) + 7 dil havuzu için TikTok Photo Mode & Export Studio viral döngüsü hazır. | [`urun_analizi_ve_pazarlama.md`](file:///Users/kuzey/projects/omakase/docs/urun_analizi_ve_pazarlama.md), [`pazarlama_ve_dagitim_stratejisi.md`](file:///Users/kuzey/projects/omakase/docs/pazarlama_ve_dagitim_stratejisi.md) |

---

## 2. Ürün Mimarisi, Export Studio, Mission Control & 7 Dil

Omakase ekosistemi dört ana bileşenden oluşur: **SwiftUI iOS 17+ İstemcisi (`omakase/` + 12 XCUITest)**, **Google Cloud Run FastAPI + GenAI Mikroservisi (`backend/` — 7 router, 32/32 birim testi)**, **Mission Control Admin Paneli (`admin-web/` — Firebase Hosting)** ve **Tanıtım Web Sitesi (`web/` — Cloudflare `getomakase.app`)**.

1. **Bento Keşif Motoru (`BentoTasteBox`) & Şefin Seçimi:** 12 ana kültür disiplini, `gemini-3.1-flash-lite` ile **24 dikey merak merceği** (`10.626` kombinasyon) kullanılarak ön-ısıtmalı üretilen alt konular ve başparmak bölgesinden tek dokunuş/çekme **Şefin Seçimi (Chef's Pick)** akışı; manuel serbest metin girişi kaldırılarak boş ekran sürtünmesi sıfırlandı.
2. **14 Dönüşümlü Format, Birincil Kaynakça (`PostSourceView`) & Derin İnceleme:** 40–90 kelimelik mikro-hikayeler ve her kartın altında **gerçek birincil kaynak** ("Wikipedia" yasak); dokunulunca tam kaynak popover'ı ve tarayıcı araması açılır. Tek dokunuşla 150–250 kelimelik **Derin İnceleme** penceresi açılır.
3. **Export Studio (`ExportPostSheet` + `ShareCardView`):** 3D sürükleme eğimli önizleme, **3 oran** (`Story` `1080×1920`, `Post` `1080×1350`, `Kare` `1080×1080`), **4 monokrom tema** (`Paper`, `Ink`, `Editorial`, `Midnight`), kaynak/etiket/motif anahtarları, `getomakase.app` kopyala barı ve Instagram Stories / WhatsApp / X / Fotoğraflar'a Kaydet rıhtımı.
4. **7 Dil Desteği (`en, tr, ja, de, fr, es, ko`):** iOS `.lproj` + `AppLanguage.systemDefault`, backend `normalize_language`, 7 dilli prompt kaynak önekleri, 7 dilli push metinleri ve **8 slayt × 7 dil** App Store ekran görüntüsü (`app-store-screenshots/`).
5. **Sürtünmesiz Kayıt, `ProfileSetupView` & 3 Slaytlı Onboarding:** Sign in with Apple, Google Sign-In ve E-posta sonrası `ProfileSetupView` ile `MonogramAvatarView` ve atomik `usernames/{handle}` seçimi (**14 gün değişim beklemesi**); ardından varsayılan ilgi alanı dayatmayan 3 slaytlı ASCII suşi tanıtımı.
6. **Topluluk (`Discover` / `Takip`), AI Raporlama & Hesap Silme:** Round-robin harmanlı Keşfet akışı, `+ Takip et`, yorum/tepki, SwiftData önbellek hidrasyonu (`PostCacheService`), ana akış menüsünden AI üretimi post raporlama (`reportAIPost`) ve hesap silmede tüm yerel önbellek/yer imi temizliği.
7. **Mission Control (`admin-web/`) & Telemetri (`TelemetryService`):** Firebase Auth korumalı 5 sekmeli komuta merkezi (`Genel Bakış`, `Gelir & AI`, `Geri Bildirim`, `Moderasyon`, `Kullanıcılar`), `FeedbackSheetView` gelen kutusu, RevenueCat v2 + Gemini birim ekonomisi ve **Agent'a Aktar** (`launch`, `conversion`, `triage`, `growth`) Markdown/JSON çıktıları.

---

## 3. Ürün Tezi, PMF, Birim Ekonomisi & 100 Müşteri Doğrulaması

* **Aha! Anı (< 45 Saniye):** Sürtünmesiz başlangıç → Bento alt konu/Şefin Seçimi dokunuşu → SSE daktilo akışı → `PostSourceView` incelemesi + 15–25 sn okuma molası → Derin İnceleme veya Export Studio.
* **North Star Metric:** **WCCR (Weekly Completed Cooldown Reads)** — `TelemetryService` üzerinden `cooldown_completed` ve `source_tap_rate_pct` ile Mission Control'de canlı ölçülür.
* **PMF Hedef Eşikleri:** D1 ≥ %45, D7 ≥ %25, D30 ≥ %15; Sean Ellis ≥ %40.
* **Birim Ekonomisi (`gemini-3.5-flash` + `gemini-3.1-flash-lite`):** Alt konu ~\$0.00004 · Standart post ~\$0.00025 · Derin İnceleme ~\$0.00040 · Yoğun kullanıcı MAU maliyeti **~\$0.10–\$0.14/ay** → Pro abonelikte **~%96 brüt kar marjı**.
* **100 Müşteri Simülasyonu (`founder-skill`, 22 Kasım):** 1. Tur (`%1`) → 2. Tur (`%72`, Van Westendorp `IPP: $2.53`). Üzerine **cihaz-bazlı kota kilidi (`device_usage`)**, **Letterboxd 1/gün sınırı** ve **Export Studio** eklenerek dönüşüm ve viral paylaşım mekaniği güçlendirildi.

---

## 4. Küresel Pazarlama, TikTok Otomasyonu & Dağıtım

* **Konumlandırma ("Anti-Brainrot" + "Chatbotlar Sorunu Bekler, Omakase Beklemez"):** Tier-1 pazarlara (ABD/UK/EU) ve 7 dil havuzuna yönelik, monokrom kağıt/mürekkep estetiği ve zorunlu birincil kaynakçayı öne çıkaran dağıtım stratejisi.
* **Otomatize TikTok Photo Mode & Reels (%70 Carousel + %30 B-Roll):** `prompts.py` + `ShareCardView` formatında günde 2–3 İngilizce Photo Mode gönderisi, US eSIM geo-targeting ve telefondan Drafts üzerinden trend sesle yayın.
* **Sıfır Bütçeli Kanallar & Kaldıraçlı Reklam:** İlk 6 hafta \$0 bütçe (`r/nosurf`, `r/digitalminimalism`, `r/Letterboxd`, `Show HN` + `getomakase.app` Canlı Tadım, Product Hunt); Hafta 6+ sonrası Apple Search Ads (\$100 kredi) ve organik kazanan postlara TikTok Spark Ads (\$15/gün).

---

## 5. App Store Uyumluluk & Prodüksiyon Denetimi

[`docs/appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md) kapsamında **7 kritik red sebebi** kodda giderilmiştir:
1. **Kural 5.1.2 (`PrivacyInfo.xcprivacy`):** `UserDefaults` (`CA92.1`), `NSPrivacyTracking: false` ve **7 veri tipi** (`Name`, `EmailAddress`, `UserID`, `PurchaseHistory`, `CrashData`, `OtherUserContent`, `ProductInteraction`).
2. **Kural 4.8 (Sign in with Apple):** SHA-256 Nonce, Keychain (`appleIDUser`), `getCredentialState`, `credentialRevokedNotification` ve `ProfileSetupView`.
3. **Kural 5.1.1(v) (Hesap Silme):** Apple token iptali + Firestore + Auth + SwiftData + `BookmarkStore` temizliği.
4. **Kural 1.2 (UGC & AI Moderasyon):** Ön filtre, gönderi/yorum/profil/AI post (`reportAIPost`) şikayeti, `blockUser` ve Mission Control Moderasyon sekmesi.
5. **Kural 1.5 & 5.1.1(i):** `mailto:destek@getomakase.app`, `FeedbackSheetView`, `privacy.html` & `terms.html`.
6. **Kural 1.6 & `Info.plist`:** ATS/debug log temizliği, Export Studio için yalnızca gereken `NSPhotoLibraryAddUsageDescription` ve `LSApplicationQueriesSchemes`.
7. **ASO 8 Slayt × 7 Dil:** Arama sonuçlarında temel değer önerisini anlatan ilk 3 kare + Deep Dive, Okuma Molası, Topluluk, Letterboxd ve Export Studio (`1206×2622` dahil 4 iPhone boyutu).

---

## 6. Siber Güvenlik & Sertleştirme Karnesi

[`docs/siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md) kapsamında `S-01`, `S-02` ve `S-04`–`S-15` kod seviyesinde kapatılmıştır:
* **API & Admin (`S-01`, `S-02`, `S-12`, `S-14`):** Firebase ID Token + `verify_admin_user` (`ADMIN_UIDS` / verified `ADMIN_EMAILS`), sliding-window rate limits, Pydantic sınırları; `admin-web/` Firebase Hosting'de `noindex, nofollow`, COOP, HSTS ve sıkı CSP ile izole.
* **Cihaz-Bazlı Kota & Kimlik (`S-04`, `S-13`, `S-15`):** `users/{uid}` `email`/`photoURL` temizliği, `usernames/{handle}` atomikliği + 14 gün bekleme, Keychain `quotaDeviceID` + SHA-256 `device_usage` ile hesap değiştirme/silme suistimalinin önlenmesi.
* **Firestore Rules, SSRF & AI (`S-05`–`S-11`):** Letterboxd SSRF/XXE engeli, `<user_context>` prompt izolasyonu, non-root `appuser` `Dockerfile`, tüm kullanıcı belgelerinde `hasOnly` + `reportedBy` değişmezliği, sunucu koleksiyonlarında (`entitlements`, `usage`, `device_usage`, `metrics_daily`, `daily_active`, `user_feedback`, `notification_*`) yazım/erişim kilidi.

---

## 7. Savunma Hattı (Moat) & v2/v3 Ürün Yol Haritası

### 7.1. Omakase'nin 5 Katmanlı Savunma Hattı
1. **Bento Keşif Matrisi (`BentoTasteBox` + 24 Merak Merceği):** Chatbotlardaki boş ekran sürtünmesini tek dokunuşla sıfırlar.
2. **Doyum & Cooldown Ritüeli:** 15–25 saniyelik okuma kilidiyle *doomscrolling*'i entelektüel doyuma çevirir.
3. **Mikro-Hikaye → Derin İnceleme & Birincil Kaynakça:** `PostSourceView` ile doğrulanabilir kaynak güveni sağlar.
4. **Export Studio & `@username` Topluluk Ağı:** `Story`/`Post`/`Kare` monokrom kartlar ve Keşfet/Takip kürasyon ağıyla organik büyüme üretir.
5. **Kültürel Günlük Bağlantıları:** Letterboxd (ücretsiz 1/gün, Pro sınırsız) ile başlayıp Spotify ve Goodreads ile genişleyecek kişisel kültür izi sentezi.

### 7.2. v1.0 Lansman Kapsamı & v2 / v3 Yol Haritası
* **v1.0 (Lansman — Day 1):** RevenueCat Pro (\$29.99/yıl · 7 gün deneme / \$3.99/ay), 3 post/gün (1 Letterboxd/gün) + 1 Derin İnceleme (`+1` paylaşım bonusu), cihaz-bazlı anti-abuse, 7 dil, Export Studio, yerel + APNs/FCM bildirimler, Crashlytics, `TelemetryService` + Mission Control (`admin-web/`).
* **v2.0:** **Spotify "Recently Played"** entegrasyonu.
* **v2.1:** **Sesli Dinleme / Yürüyüş Modu (TTS)** ve Export Studio kartlarına `@username` imzası.
* **v2.5:** **Goodreads / Kitap Günlüğü** RSS entegrasyonu.

---

## 8. Canlıya Geçiş Öncesi Kalan Güncelleme, Dağıtım & Konsol Aksiyonları

- [ ] **1. Son Kod/Yasal Küçük Güncellemeler:**
  - `firestore.rules` (satır 330 & 368) içinde `devices` ve `notification_prefs` `language` kısıtını `['en', 'tr']`'den 7 dile (`en, tr, ja, de, fr, es, ko`) genişletin.
  - `web/privacy.html` ve `web/terms.html` sayfalarına `ProductInteraction` analitiği, uygulama içi geri bildirim (`user_feedback`), 1/gün Letterboxd sınırı ve anonim cihaz kota özeti maddelerini ekleyin.
- [ ] **2. Canlı Altyapı Dağıtımları (Backend + Admin + Web):**
  ```bash
  # Cloud Run (Admin, Telemetri, Device Quota, Letterboxd 1/gün & RC v2 dahil)
  cd backend && gcloud run deploy omakase-backend --source . --region us-central1 --project gen-lang-client-0120875563

  # Firestore Rules + Mission Control (admin-web/)
  firebase deploy --only firestore:rules,hosting --project gen-lang-client-0120875563
  ```
  - `web/` tanıtım sitesini Cloudflare (`wrangler.json`) üzerinden canlıya alın.
- [ ] **3. Google Cloud, Firebase & Bildirim Konsol İşlemleri (`S-03`):**
  - GCP Console → **Credentials** altından iOS `API_KEY` için `iOS apps` (`kuzeysinay.omakase`) kısıtlaması ekleyin ve `Generative Language API` erişimini kaldırın.
  - Firebase Console'da **Apple** Sign-in sağlayıcısını etkinleştirin, **APNs `.p8`** anahtarını yükleyin ve `/notifications/process-queue` için Cloud Scheduler cron'unu bağlayın.
- [ ] **4. App Store Connect, RevenueCat & Xcode Arşiv Gönderimi:**
  - App Store Connect **Paid Apps Agreement (`Active`)**, IAP ürünleri (`omakase.pro.monthly`, `omakase.pro.yearly`), **App Privacy** (7 veri tipi — `ProductInteraction` dahil), **Demo Hesap**, **8 slayt × 7 dil** ekran görüntüleri ve RevenueCat Webhook Sandbox testini tamamlayın.
  - Xcode'da **Any iOS Device (arm64)** seçip **Product → Archive → Generate Privacy Report → Validate App → Distribute App** adımlarını tamamlayın.

---

## 9. Apple Agent Kit İzlenebilirlik Özeti

`.agents/AGENTS.md` kuralları gereğince bu master raporda sentezlenen Apple platform uyumluluk, güvenlik ve ürün sayfası kararlarının dayandığı yönlendirme zinciri:

1. **Kapsanan Workflow'lar:** [`workflow.app-store-submission`](file:///Users/kuzey/projects/omakase/.agents/workflows/app-store-submission/WORKFLOW.md), [`workflow.authentication`](file:///Users/kuzey/projects/omakase/.agents/workflows/authentication/WORKFLOW.md)
2. **Kapsanan Skill'ler:** [`skill.app-store-product-page.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-product-page/SKILL.md), [`skill.app-store-review-guidelines.submission`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-review-guidelines/SKILL.md), [`skill.privacy.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/privacy/SKILL.md), [`skill.xcode.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/xcode/SKILL.md), [`skill.authenticationservices.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/authenticationservices/SKILL.md), [`skill.security.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/security/SKILL.md), [`skill.networking.urlsession`](file:///Users/kuzey/projects/omakase/.agents/skills/networking/SKILL.md)
3. **Temel Knowledge Contracts:** [`header-and-search-result-messaging.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-product-page/header-and-search-result-messaging.md), [`asset-sequencing-and-story.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-product-page/asset-sequencing-and-story.md), [`third-party-content-licensing.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/third-party-content-licensing.md), [`user-generated-content-moderation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/user-generated-content-moderation.md), [`data-security.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/data-security.md), [`authenticated-requests.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/networking/authenticated-requests.md).
