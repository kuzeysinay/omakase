# 🍣 Omakase — Master Rapor (Mimari, Ürün/PMF, Küresel Pazarlama, App Store & Siber Güvenlik Özeti)

> **Son Güncelleme:** 26 Kasım 2026 (`v1.0 (1)` **Apple App Review'a Gönderildi — `Waiting for Review`** · `APP_ID: 6838044134`)  
> **Kapsam:** `docs/` altındaki 7 uzman raporun ([`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md), [`founder_100_musteri_raporu.md`](file:///Users/kuzey/projects/omakase/docs/founder_100_musteri_raporu.md), [`siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md), [`appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md), [`aso_ve_seo_raporu.md`](file:///Users/kuzey/projects/omakase/docs/aso_ve_seo_raporu.md), [`urun_analizi_ve_pazarlama.md`](file:///Users/kuzey/projects/omakase/docs/urun_analizi_ve_pazarlama.md), [`pazarlama_ve_dagitim_stratejisi.md`](file:///Users/kuzey/projects/omakase/docs/pazarlama_ve_dagitim_stratejisi.md)) tek bir yönetici dokümanında birleştirilmiş güncel master özeti.

---

## İçindekiler

1. [Yönetici Özeti & Proje Durum Panosu](#1-yönetici-özeti--proje-durum-panosu)
2. [Ürün Mimarisi, WidgetKit, Export Studio, Mission Control & 7 Dil (`proje_durum_ve_mimari_raporu.md`)](#2-ürün-mimarisi-widgetkit-export-studio-mission-control--7-dil)
3. [Ürün Tezi, PMF, Birim Ekonomisi & 100 Müşteri Doğrulaması (`urun_analizi_ve_pazarlama.md` & `founder_100_musteri_raporu.md`)](#3-ürün-tezi-pmf-birim-ekonomisi--100-müşteri-doğrulaması)
4. [Küresel Pazarlama, TikTok Otomasyonu & Dağıtım (`pazarlama_ve_dagitim_stratejisi.md`)](#4-küresel-pazarlama-tiktok-otomasyonu--dağıtım)
5. [App Store Uyumluluk & Prodüksiyon Denetimi (`appstore_raporu.md` & `aso_ve_seo_raporu.md`)](#5-app-store-uyumluluk--prodüksiyon-denetimi)
6. [Siber Güvenlik & Sertleştirme Karnesi (`siber_guvenlik_raporu.md`)](#6-siber-güvenlik--sertleştirme-karnesi)
7. [Savunma Hattı (Moat) & v2/v3 Ürün Yol Haritası](#7-savunma-hattı-moat--v2v3-ürün-yol-haritası)
8. [Canlı Ortam, App Review Gönderimi & Kalan Yayın Günü Aksiyonları](#8-canlı-ortam-app-review-gönderimi--kalan-yayın-günü-aksiyonları)
9. [Apple Agent Kit İzlenebilirlik Özeti](#9-apple-agent-kit-izlenebilirlik-özeti)

---

## 1. Yönetici Özeti & Proje Durum Panosu

**Omakase**, algoritmik sosyal medya gürültüsü (*doomscrolling / brainrot*) ile sohbet botlarının boş ekran sendromu (*prompt paralysis*) arasındaki boşluğu dolduran, **kağıt/mürekkep estetiğine, zorunlu birincil kaynakça doğrulamasına, WidgetKit uzantısına, Export Studio'ya ve 7 dile sahip kişisel kültür ve mikro-bilgi platformudur.** `v1.0 (1)` sürümü **26 Kasım 2026** itibarıyla **Apple App Review** incelemesine gönderilmiştir (`Waiting for Review`).

| Alan | Durum | Özet Durum | Detay Rapor |
|------|-------|------------|-------------|
| **Ürün, Bento, WidgetKit, Export Studio & 7 Dil** | ✅ **%100 Hazır** | 12 disiplin + **24 merak merceği**, başparmak bölgesi **Şefin Seçimi**, 14 editoryal format, 7 dilde **528 anahtar** (`en, tr, ja, de, fr, es, ko`), tıklanabilir birincil kaynakça ([`PostSourceView`](file:///Users/kuzey/projects/omakase/omakase/omakase/Theme/PostSourceView.swift)), 15–25 sn `Reading Cooldown`, **Derin İnceleme**, **Export Studio** (3 oran × 4 tema), **`omakaseWidget`** (`group.kuzeysinay.omakase`), **`GuestTasteView`** (kayıtsız tadım), `ProfileSetupView`, **`FollowListSheet`**, **`RatingPromptManager`** ve **`HapticManager`**. | [`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md) |
| **Monetizasyon, Cihaz Kotası & Bildirim** | ✅ **Canlı & Hazır** | RevenueCat (`5.103.2` + v2 API) Pro (\$29.99/yıl · 7 gün deneme veya \$3.99/ay), günde **3 ücretsiz post** (**1 Letterboxd/gün** dahil, `Kalan: X/3`) + 1 Derin İnceleme (`+1` paylaşım bonusu), dinamik fiyatlı ASCII suşi paywall + **`ProWelcomeView`**, Keychain + SHA-256 **cihaz bazlı anti-abuse kotası**, 7-dilli APNs/FCM + yerel bildirim ve `OmakaseError` + Crashlytics. | [`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md) |
| **Mission Control, Web & Ekran Görüntüleri** | ✅ **Canlı & Yüklendi** | Firebase Hosting'de izole **Mission Control** ([`admin-web/`](file:///Users/kuzey/projects/omakase/admin-web) — 5 sekme, RevenueCat v2, `FeedbackSheetView`, `Agent'a Aktar`), yenilenen `web/` (SEO/GEO, statik `en/index.html`, 26 Kasım tarihli `privacy.html` & `terms.html`), **72 × `1320×2868`** App Store ekran görüntüsü (9 yerel ayara yüklendi + 4 boyutta repoda yedeklendi), **38/38** backend testi ve **12** XCUITest hazır. | [`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md), [`aso_ve_seo_raporu.md`](file:///Users/kuzey/projects/omakase/docs/aso_ve_seo_raporu.md) |
| **100 Müşteri & Fiyat Doğrulaması** | ✅ **1. Tur %1 → 2. Tur %72** | `founder-skill` ile 100 persona test edildi: 5 tabak + kaynakçasız teklifte `%1` olan dönüşüm; 3 post + birincil kaynakça + `\$2.49/ay` yıllık çerçevesinde **`%72`** sıçradı (Van Westendorp `IPP: $2.53`). Üzerine cihaz kotası, Letterboxd 1/gün, `GuestTasteView`, `ProWelcomeView` ve `omakaseWidget` eklendi. | [`founder_100_musteri_raporu.md`](file:///Users/kuzey/projects/omakase/docs/founder_100_musteri_raporu.md) |
| **App Store Uyumluluğu & İnceleme** | 🚀 **`Waiting for Review`** | `PrivacyInfo.xcprivacy` (`CA92.1` + `1C8F.1` + **8 veri tipi**, `DeviceID` dahil) + `omakaseWidget/PrivacyInfo.xcprivacy`, `TARGETED_DEVICE_FAMILY = 1`, `ITSAppUsesNonExemptEncryption = false`, Firebase Email/Password + Demo Hesap (`reviewer@getomakase.app`), **App Privacy** yayını ve 4 kalemli (`iOS App 1.0` + `omakase pro` aylık/yıllık) Review Submission (`243fa22d-ed73-4dc8-a8e8-ad362f0dc071`, 174 ülke — `CHN` kapalı) gönderildi. | [`appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md), [`aso_ve_seo_raporu.md`](file:///Users/kuzey/projects/omakase/docs/aso_ve_seo_raporu.md) |
| **Siber Güvenlik** | ✅ **28/28 Çözüldü & Canlıda** | `S-01`–`S-28` tamamı kapatıldı (`S-03` iOS/Browser GCP API anahtar kısıtlamaları, `S-16`–`S-24` yeniden denetim + `S-25` UTC kota kilidi, `S-26` fail-closed Firestore `503`, `S-27` admin export kaçışı, `S-28` `check_revoked=True` ve 7-dil `firestore.rules` dahil); **38/38** test geçti, Cloud Run (`omakase-backend-00023-68f`) ve Firebase (`firestore:rules`, `hosting`) canlıya alındı. Açık güvenlik bulgusu kalmadı. | [`siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md) |
| **Birim Ekonomisi & Küresel Dağıtım** | 🚀 **%96 Brüt Marj & Strateji Hazır** | Yoğun bir kullanıcının aylık AI (`gemini-3.5-flash` + `gemini-3.1-flash-lite`) ve bulut maliyeti **~\$0.10 – \$0.14** (~%96 brüt marj). Tier-1 pazarlar (US/UK/EU) + 9 App Store yerel ayarı + 7 dil havuzu için TikTok Photo Mode & Export Studio viral döngüsü hazır. | [`urun_analizi_ve_pazarlama.md`](file:///Users/kuzey/projects/omakase/docs/urun_analizi_ve_pazarlama.md), [`pazarlama_ve_dagitim_stratejisi.md`](file:///Users/kuzey/projects/omakase/docs/pazarlama_ve_dagitim_stratejisi.md) |

---

## 2. Ürün Mimarisi, WidgetKit, Export Studio, Mission Control & 7 Dil

Omakase ekosistemi beş ana bileşenden oluşur: **SwiftUI iOS 17+ İstemcisi (`omakase/` + 12 XCUITest)**, **WidgetKit Uzantısı (`omakaseWidget/`)**, **Google Cloud Run FastAPI + GenAI Mikroservisi (`backend/` — 7 router, 38/38 birim testi)**, **Mission Control Admin Paneli (`admin-web/` — Firebase Hosting)** ve **Tanıtım Web Sitesi (`web/` — Cloudflare `getomakase.app`)**.

1. **Bento Keşif Motoru (`BentoTasteBox`) & Şefin Seçimi:** 12 ana kültür disiplini, `gemini-3.1-flash-lite` ile **24 dikey merak merceği** (`10.626` kombinasyon) kullanılarak ön-ısıtmalı üretilen alt konular ve başparmak bölgesinden tek dokunuş/çekme **Şefin Seçimi (Chef's Pick)** akışı; manuel serbest metin girişi kaldırılarak boş ekran sürtünmesi sıfırlandı.
2. **14 Dönüşümlü Format, Birincil Kaynakça (`PostSourceView`) & Derin İnceleme:** 40–90 kelimelik mikro-hikayeler ve her kartın altında **gerçek birincil kaynak** ("Wikipedia" yasak); dokunulunca tam kaynak popover'ı ve tarayıcı araması açılır. Tek dokunuşla 150–250 kelimelik **Derin İnceleme** penceresi açılır.
3. **Export Studio (`ExportPostSheet` + `ShareCardView`) & WidgetKit (`omakaseWidget/`):** 3D sürükleme eğimli önizleme, **3 oran** (`Story` `1080×1920`, `Post` `1080×1350`, `Kare` `1080×1080`), **4 monokrom tema** (`Paper`, `Ink`, `Editorial`, `Midnight`), `getomakase.app` kopyala barı ve Instagram Stories / WhatsApp / X / Fotoğraflar'a Kaydet rıhtımı. Ayrıca `WidgetDataBridge` + `group.kuzeysinay.omakase` App Group üzerinden beslenen **Ana Ekran / Kilit Ekranı WidgetKit** deneyimi sunar.
4. **7 Dil Desteği (`528` Anahtar × 7 Dil — `en, tr, ja, de, fr, es, ko`):** iOS `.lproj` (`528` anahtar/dil) + `AppLanguage.systemDefault`, backend `normalize_language`, 7 dilli prompt kaynak önekleri, 7 dilli push metinleri ve **9 App Store yerel ayarında 72 × `1320×2868`** ekran görüntüsü (`app-store-screenshots/`).
5. **Misafir Tadımı (`GuestTasteView`), Sürtünmesiz Kayıt & `RatingPromptManager`:** Kayıt olmadan önce uygulama tadımı sağlayan `GuestTasteView` + `GuestStaticCatalog`; ardından Sign in with Apple, Google Sign-In ve E-posta sonrası `ProfileSetupView` (`MonogramAvatarView` ve atomik `usernames/{handle}` — **14 gün değişim beklemesi**) ve 3 slaytlı ASCII suşi tanıtımı. 3 tamamlanmış okuma sonrasında Kural 5.6.1/5.6.3 uyumlu yerel `StoreKit.AppStore.requestReview` (`RatingPromptManager`) tetiklenir.
6. **Topluluk (`Discover` / `Takip`), AI Raporlama & Hesap Silme:** Round-robin harmanlı Keşfet akışı, `+ Takip et`, `FollowListSheet`, yorum/tepki, SwiftData önbellek hidrasyonu (`PostCacheService`), ana akış menüsünden AI üretimi post raporlama (`reportAIPost`) ve hesap silmede tüm yerel önbellek/yer imi temizliği.
7. **Mission Control (`admin-web/`) & Telemetri (`TelemetryService`):** Firebase Auth korumalı 5 sekmeli komuta merkezi (`Genel Bakış`, `Gelir & AI`, `Geri Bildirim`, `Moderasyon`, `Kullanıcılar`), `FeedbackSheetView` gelen kutusu, RevenueCat v2 + Gemini birim ekonomisi ve **Agent'a Aktar** (`launch`, `conversion`, `triage`, `growth`) Markdown/JSON çıktıları.

---

## 3. Ürün Tezi, PMF, Birim Ekonomisi & 100 Müşteri Doğrulaması

* **Aha! Anı (< 45 Saniye):** Kayıtsız tadım (`GuestTasteView`) veya sürtünmesiz başlangıç → Bento alt konu/Şefin Seçimi dokunuşu → SSE daktilo akışı → `PostSourceView` incelemesi + 15–25 sn okuma molası → Derin İnceleme veya Export Studio.
* **North Star Metric:** **WCCR (Weekly Completed Cooldown Reads)** — `TelemetryService` üzerinden `cooldown_completed` ve `source_tap_rate_pct` ile Mission Control'de canlı ölçülür.
* **PMF Hedef Eşikleri:** D1 ≥ %45, D7 ≥ %25, D30 ≥ %15; Sean Ellis ≥ %40.
* **Birim Ekonomisi (`gemini-3.5-flash` + `gemini-3.1-flash-lite`):** Alt konu ~\$0.00004 · Standart post ~\$0.00025 · Derin İnceleme ~\$0.00040 · Yoğun kullanıcı MAU maliyeti **~\$0.10–\$0.14/ay** → Pro abonelikte **~%96 brüt kar marjı**.
* **100 Müşteri Simülasyonu (`founder-skill`, 22 Kasım):** 1. Tur (`%1`) → 2. Tur (`%72`, Van Westendorp `IPP: $2.53`). Üzerine **cihaz-bazlı kota kilidi (`device_usage`)**, **Letterboxd 1/gün sınırı**, **`GuestTasteView`**, **`omakaseWidget`**, **`ProWelcomeView`** ve **Export Studio** eklenerek dönüşüm ve viral paylaşım mekaniği güçlendirildi.

---

## 4. Küresel Pazarlama, TikTok Otomasyonu & Dağıtım

* **Konumlandırma ("Anti-Brainrot" + "Chatbotlar Sorunu Bekler, Omakase Beklemez"):** Tier-1 pazarlara (ABD/UK/EU) ve 7 dil havuzuna (9 App Store yerel ayarı, `es-MX` ABD çapraz indeksleme dahil) yönelik dağıtım stratejisi.
* **Otomatize TikTok Photo Mode & Reels (%70 Carousel + %30 B-Roll):** `prompts.py` + `ShareCardView` formatında günde 2–3 İngilizce Photo Mode gönderisi, US eSIM geo-targeting ve telefondan Drafts üzerinden trend sesle yayın.
* **Sıfır Bütçeli Kanallar & Kaldıraçlı Reklam:** İlk 6 hafta \$0 bütçe (`r/nosurf`, `r/digitalminimalism`, `r/Letterboxd`, `Show HN` + `getomakase.app` Canlı Tadım, Product Hunt); Hafta 6+ sonrası Apple Search Ads (\$100 kredi) ve organik kazanan postlara TikTok Spark Ads (\$15/gün).

---

## 5. App Store Uyumluluk & Prodüksiyon Denetimi

[`docs/appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md) ve [`docs/aso_ve_seo_raporu.md`](file:///Users/kuzey/projects/omakase/docs/aso_ve_seo_raporu.md) kapsamında **tüm kritik red sebepleri** giderilmiş ve `v1.0 (1)` (`APP_ID: 6838044134`) incelemeye sunulmuştur:
1. **Kural 5.1.2 (`PrivacyInfo.xcprivacy` + App Privacy):** `UserDefaults` (`CA92.1` + `1C8F.1`), `NSPrivacyTracking: false`, **8 veri tipi** (`Name`, `EmailAddress`, `UserID`, `PurchaseHistory`, `CrashData`, `OtherUserContent`, `ProductInteraction`, `DeviceID`) ve `omakaseWidget/PrivacyInfo.xcprivacy` (`1C8F.1`, `[]`); App Store Connect App Privacy anketi **yayınlandı**.
2. **Kural 4.8 (Sign in with Apple) & Demo Hesap:** SHA-256 Nonce, Keychain (`appleIDUser`), `getCredentialState`, `credentialRevokedNotification`, `ProfileSetupView`, `GuestTasteView` ve App Review doğrulaması için Firebase Email/Password + canlı demo hesap (`reviewer@getomakase.app` / `@appreview`).
3. **Kural 5.1.1(v) (Hesap Silme):** Apple token iptali + Firestore + Auth + SwiftData + `BookmarkStore` temizliği.
4. **Kural 1.2 (UGC & AI Moderasyon):** Ön filtre, gönderi/yorum/profil/AI post (`reportAIPost`) şikayeti, `blockUser` ve Mission Control Moderasyon sekmesi.
5. **Kural 1.5 & 5.1.1(i):** `mailto:support@getomakase.app`, `FeedbackSheetView`, güncellenmiş `privacy.html` & `terms.html` (26 Kasım) ve tüm yerel ayar açıklamalarında EULA/Gizlilik bağlantıları.
6. **Kural 1.6 & Xcode Ayarları:** ATS/debug log temizliği, `ITSAppUsesNonExemptEncryption = false`, `TARGETED_DEVICE_FAMILY = 1` (iPhone-only), dinamik StoreKit paywall ve Export Studio izinleri.
7. **ASO 9 Yerel Ayar & 72 Ekran Görüntüsü (`1320×2868`):** `Education` / `Reference`, `es-MX` ABD çapraz indekslemesi, **9 yerel ayara 72 × `1320×2868`** ekran görüntüsü yüklendi (`Asset Library` 72/72 temiz) ve Çin anakarası (`CHN`) CAC/AIGC uyumu gereği kapatıldı (174 ülke aktif).

---

## 6. Siber Güvenlik & Sertleştirme Karnesi

[`docs/siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md) kapsamında `S-01`, `S-02` ve `S-04`–`S-15` kod seviyesinde kapatılmıştır:
* **API & Admin (`S-01`, `S-02`, `S-12`, `S-14`):** Firebase ID Token + `verify_admin_user` (`ADMIN_UIDS` / verified `ADMIN_EMAILS`), sliding-window rate limits, Pydantic sınırları; `admin-web/` Firebase Hosting'de `noindex, nofollow`, COOP, HSTS ve sıkı CSP ile izole.
* **Cihaz-Bazlı Kota & Kimlik (`S-04`, `S-13`, `S-15`):** `users/{uid}` `email`/`photoURL` temizliği, `usernames/{handle}` atomikliği + 14 gün bekleme, Keychain `quotaDeviceID` + SHA-256 `device_usage` ile hesap değiştirme/silme suistimalinin önlenmesi.
* **Firestore Rules, SSRF & AI (`S-05`–`S-11`):** Letterboxd SSRF/XXE engeli, `<user_context>` prompt izolasyonu, non-root `appuser` `Dockerfile`, tüm kullanıcı belgelerinde `hasOnly` + `reportedBy` değişmezliği, sunucu koleksiyonlarında (`entitlements`, `usage`, `device_usage`, `metrics_daily`, `daily_active`, `user_feedback`, `notification_*`) yazım/erişim kilidi.

### 6.1. Bağımsız Yeniden Denetim & Ek Sertleştirme — `security-audit-skill` Run 1 (26 Kasım 2026)

Cloudflare [`security-audit-skill`](https://github.com/cloudflare/security-audit-skill) metodolojisiyle tespit edilen **9 bulgu (`S-16`–`S-24`)** ile ek doğrulama sırasında yakalanan **4 sertleştirme bulgusu (`S-25`–`S-28`)** ve 7-dil `firestore.rules` genişletmesi **tamamen kapatılmış, `38/38` testten geçirilmiş ve Cloud Run (`omakase-backend-00023-68f`) + Firebase (`firestore:rules`, `hosting`) ortamlarına canlıya alınmıştır (`0965ee9`)**:

| # | Önem | Alan | Bulgu | Durum |
|---|------|------|-------|-------|
| **S-16** | 🟠 Orta | Backend / Kota | SSE bağlantısı kesildiğinde günlük kota düşülmüyor; Gemini maliyeti kotasız üretilebiliyor | ✅ Çözüldü & Canlıda |
| **S-17** | 🟠 Orta | Backend / Bildirim | Sosyal bildirimler gerçek yorum/reaksiyon kaydına bağlı değil; sahte push ve içerik enjeksiyonu | ✅ Çözüldü & Canlıda |
| **S-18** | 🟡 Düşük | Firestore / Bütünlük | Gönderi sayaçları (`reactionCounts`, `totalReactions`) keyfi değiştirilebiliyor | ✅ Çözüldü & Canlıda |
| **S-19** | 🟡 Düşük | Firestore / PII | `users/{uid}` kuralları `email` alanını kabul ediyor ve tüm oturum açmış kullanıcılara okutuyor | ✅ Çözüldü & Canlıda |
| **S-20** | 🟡 Düşük | Backend / DoS | Hız sınırlayıcı süreç içi ve sınırsız büyüyor; çoklu Cloud Run örneklerinde aşılabilir | ✅ Çözüldü & Canlıda |
| **S-21** | 🟡 Düşük | Yapılandırma | Yönetici UID'si ve 50 tabak kota istisnası kaynak kodda varsayılan gömülü | ✅ Çözüldü & Canlıda |
| **S-22** | 🟡 Düşük | Admin / CSP | Mission Control CSP'si `'unsafe-inline'` script ve üretimde localhost `connect-src` içeriyor | ✅ Çözüldü & Canlıda |
| **S-23** | 🟡 Düşük | Firestore / Moderasyon | `reportedBy` listesi kısmen değiştirilebiliyor; moderasyon kanıtı silinebilir | ✅ Çözüldü & Canlıda |
| **S-24** | 🟡 Düşük | Kota / Anti-abuse | Cihaz kotası istemci başlığına bağlı; başlık atlanarak/döndürülerek `S-13` koruması devre dışı bırakılabilir | ✅ Çözüldü & Canlıda |
| **S-25** | 🟠 Orta | Backend / Kota | İstemci saat dilimi (`X-Omakase-Timezone`) manipülasyonuyla günlük kota penceresini çoğaltma | ✅ Çözüldü & Canlıda |
| **S-26** | 🟠 Orta | Backend / Dayanıklılık | Kalıcı Firestore başlatma hatası kilidi ve fail-open kota atlatma (`503` zorunlu) | ✅ Çözüldü & Canlıda |
| **S-27** | 🟡 Düşük | Admin / AI | `/admin/export?format=markdown` çıktısında dolaylı prompt / Markdown enjeksiyonu | ✅ Çözüldü & Canlıda |
| **S-28** | 🟠 Orta | Backend / Kimlik | İptal edilmiş/devre dışı Firebase ID token'larının 300 sn önbellek penceresinde kabulü | ✅ Çözüldü & Canlıda |
| **S-03** | 🔴 Yüksek (koşullu) | GCP / Anahtar | Firebase iOS API anahtarının GCP kısıtlamaları (`kuzeysinay.omakase` + 7 minimal API; Browser key + 5 API) | ✅ Çözüldü & Canlıda |

**Denetim artefaktları & doğrulama:** `findings.json` (13 bulgu) ve `coverage-ledger.json` (14 kapsam birimi) `validate-findings.cjs` / `validate-coverage-ledger.cjs` doğrulayıcılarından **PASS** almış; tüm `S-03` ve `S-16`–`S-28` kapatmaları sonrasında **38/38 backend birim testi**, iOS fiziksel cihaz derlemesi ve GCP `api-keys` doğrulaması geçilmiştir. Ayrıntılı analiz ve uygulanan çözümler [`siber_guvenlik_raporu.md` Bölüm 9](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md#9-bölüm-7-bağımsız-yeniden-denetim-26-kasım-2026--security-audit-skill-run-1) içindedir. **Tüm 28/28 güvenlik bulgusu kapatılmıştır.**

---

## 7. Savunma Hattı (Moat) & v2/v3 Ürün Yol Haritası

### 7.1. Omakase'nin 5 Katmanlı Savunma Hattı
1. **Bento Keşif Matrisi (`BentoTasteBox` + 24 Merak Merceği):** Chatbotlardaki boş ekran sürtünmesini tek dokunuşla sıfırlar.
2. **Doyum & Cooldown Ritüeli:** 15–25 saniyelik okuma kilidiyle *doomscrolling*'i entelektüel doyuma çevirir.
3. **Mikro-Hikaye → Derin İnceleme & Birincil Kaynakça:** `PostSourceView` ile doğrulanabilir kaynak güveni sağlar.
4. **Export Studio, WidgetKit & `@username` Topluluk Ağı:** `Story`/`Post`/`Kare` monokrom kartlar, Ana Ekran/Kilit Ekranı Widget'ları ve Keşfet/Takip kürasyon ağıyla organik büyüme ve geri dönüş üretir.
5. **Kültürel Günlük Bağlantıları:** Letterboxd (ücretsiz 1/gün, Pro sınırsız) ile başlayıp Spotify ve Goodreads ile genişleyecek kişisel kültür izi sentezi.

### 7.2. v1.0 Lansman Kapsamı & v2 / v3 Yol Haritası
* **v1.0 (App Review — `Waiting for Review`):** RevenueCat Pro (\$29.99/yıl · 7 gün deneme / \$3.99/ay), 3 post/gün (1 Letterboxd/gün) + 1 Derin İnceleme (`+1` paylaşım bonusu), cihaz-bazlı anti-abuse, 7 dil (`528` anahtar), `omakaseWidget`, `GuestTasteView`, `ProWelcomeView`, `FollowListSheet`, `RatingPromptManager`, Export Studio, yerel + APNs/FCM bildirimler, Crashlytics, `TelemetryService` + Mission Control (`admin-web/`).
* **v2.0:** **Spotify "Recently Played"** entegrasyonu.
* **v2.1:** **Sesli Dinleme / Yürüyüş Modu (TTS)** ve Export Studio kartlarına `@username` imzası.
* **v2.5:** **Goodreads / Kitap Günlüğü** RSS entegrasyonu.

---

## 8. Canlı Ortam, App Review Gönderimi & Kalan Yayın Günü Aksiyonları

- [x] **1. Güvenlik Sertleştirmesi (`S-16`–`S-28`) & 7-Dil `firestore.rules`:**
  - `S-16`–`S-28` tamamı kapatıldı ve **38/38** testten geçti; `firestore.rules` 7-dil beyaz listesiyle güncellendi.
- [x] **2. Backend + Firestore Rules + Mission Control Canlı Dağıtımı (`0965ee9`):**
  - Cloud Run `omakase-backend-00023-68f` (`us-central1`) ve Firebase `firestore:rules` + `hosting` (`https://gen-lang-client-0120875563.web.app`) canlıya alındı.
- [x] **3. GCP API Anahtar Kısıtlamaları (`S-03`) & Firebase Auth Demo Hesabı:**
  - iOS ve Browser API anahtarları kısıtlandı; Firebase Auth Email/Password sağlayıcısı etkinleştirilip App Review demo hesabı (`reviewer@getomakase.app` / `@appreview`) doğrulandı.
- [x] **4. Yasal Sayfalar, SEO/GEO & 9 Yerel Ayar Ekran Görüntüleri (`web/`, `app-store-screenshots/`):**
  - `web/privacy.html` & `web/terms.html` (26 Kasım 2026), statik `web/en/index.html`, Schema.org, WebP vitrin ve `_headers` tamamlandı; `72 × 1320×2868` ekran görüntüsü App Store Connect'e yüklenip `app-store-screenshots/exports/ios/` altında repoya arşivlendi.
- [x] **5. App Store Connect `v1.0 (1)` İnceleme Gönderimi (`Waiting for Review`):**
  - `APP_ID: 6838044134`, `omakase pro` (`Monthly` + `Yearly`) bağlı, App Privacy (8 veri tipi) yayınlı, 174 ülke (`CHN` kapalı) için 4 kalemli Review Submission (`243fa22d-ed73-4dc8-a8e8-ad362f0dc071`) gönderildi.
- [ ] **6. Yayın Günü Web & Konsol Son Kontrolleri:**
  - `web/` klasörünü Cloudflare'e (`npx wrangler deploy`) yayınlayıp App Store onayı sonrası `index.html` / `en/index.html` içinde `app-id=6838044134` Smart App Banner ve mağaza URL'sini açın.
  - Firebase Console'da **APNs `.p8`** / Cloud Scheduler (`/notifications/process-queue`), App Check + Email Enumeration Protection ve RevenueCat Webhook olaylarını son kez doğrulayın.

---

## 9. Apple Agent Kit İzlenebilirlik Özeti

`.agents/AGENTS.md` kuralları gereğince bu master raporda sentezlenen Apple platform uyumluluk, güvenlik ve ürün sayfası kararlarının dayandığı yönlendirme zinciri:

1. **Kapsanan Workflow'lar:** [`workflow.app-store-submission`](file:///Users/kuzey/projects/omakase/.agents/workflows/app-store-submission/WORKFLOW.md), [`workflow.authentication`](file:///Users/kuzey/projects/omakase/.agents/workflows/authentication/WORKFLOW.md)
2. **Kapsanan Skill'ler:** [`skill.app-store-product-page.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-product-page/SKILL.md), [`skill.app-store-review-guidelines.submission`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-review-guidelines/SKILL.md), [`skill.privacy.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/privacy/SKILL.md), [`skill.xcode.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/xcode/SKILL.md), [`skill.authenticationservices.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/authenticationservices/SKILL.md), [`skill.security.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/security/SKILL.md), [`skill.networking.urlsession`](file:///Users/kuzey/projects/omakase/.agents/skills/networking/SKILL.md)
3. **Temel Knowledge Contracts:** [`header-and-search-result-messaging.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-product-page/header-and-search-result-messaging.md), [`asset-sequencing-and-story.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-product-page/asset-sequencing-and-story.md), [`third-party-content-licensing.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/third-party-content-licensing.md), [`user-generated-content-moderation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/user-generated-content-moderation.md), [`data-security.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/data-security.md), [`authenticated-requests.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/networking/authenticated-requests.md).
