# 🍣 Omakase — Master Rapor (Mimari, Ürün/PMF, Küresel Pazarlama, App Store & Siber Güvenlik Özeti)

> **Son Güncelleme:** 15 Kasım 2026  
> **Kapsam:** `docs/` altındaki 6 temel raporun ([`pazarlama_ve_dagitim_stratejisi.md`](file:///Users/kuzey/projects/omakase/docs/pazarlama_ve_dagitim_stratejisi.md), [`urun_analizi_ve_pazarlama.md`](file:///Users/kuzey/projects/omakase/docs/urun_analizi_ve_pazarlama.md), [`appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md), [`siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md), [`gelecek_stratejisi.md`](file:///Users/kuzey/projects/omakase/docs/gelecek_stratejisi.md), [`ozellik_fikirleri.md`](file:///Users/kuzey/projects/omakase/docs/ozellik_fikirleri.md)) tek bir yönetici dokümanında birleştirilmiş master özeti.

---

## İçindekiler

1. [Yönetici Özeti & Proje Durum Panosu](#1-yönetici-özeti--proje-durum-panosu)
2. [Ürün Mimarisi & Tamamlanan 8 Çekirdek Sistem (`ozellik_fikirleri.md`)](#2-ürün-mimarisi--tamamlanan-8-çekirdek-sistem)
3. [Ürün Tezi, PMF & Birim Ekonomisi (`urun_analizi_ve_pazarlama.md`)](#3-ürün-tezi-pmf--birim-ekonomisi)
4. [Küresel Pazarlama, TikTok Otomasyonu & Dağıtım (`pazarlama_ve_dagitim_stratejisi.md`)](#4-küresel-pazarlama-tiktok-otomasyonu--dağıtım)
5. [App Store Uyumluluk & Prodüksiyon Denetimi (`appstore_raporu.md`)](#5-app-store-uyumluluk--prodüksiyon-denetimi)
6. [Siber Güvenlik & Sertleştirme Karnesi (`siber_guvenlik_raporu.md`)](#6-siber-güvenlik--sertleştirme-karnesi)
7. [Savunma Hattı (Moat) & v2/v3 Ürün Yol Haritası (`gelecek_stratejisi.md`)](#7-savunma-hattı-moat--v2v3-ürün-yol-haritası)
8. [Canlıya Geçiş Öncesi Kalan Manuel Konsol & CLI Aksiyonları](#8-canlıya-geçiş-öncesi-kalan-manuel-konsol--cli-aksiyonları)
9. [Apple Agent Kit İzlenebilirlik Özeti](#9-apple-agent-kit-izlenebilirlik-özeti)

---

## 1. Yönetici Özeti & Proje Durum Panosu

**Omakase**, algoritmik sosyal medya gürültüsü (*doomscrolling / brainrot*) ile sohbet botlarının boş ekran sendromu (*prompt paralysis*) arasındaki boşluğu dolduran, **kağıt/mürekkep estetiğine sahip kişisel kültür ve mikro-bilgi platformudur.**

| Alan | Durum | Özet Durum | Detay Rapor |
|------|-------|------------|-------------|
| **Ürün & Çekirdek Özellikler** | ✅ **%100 Hazır** | 12 disiplinli `BentoTasteBox`, 12 editoryal format, SSE daktilo akışı, 15–25 sn `Reading Cooldown`, `DeepDiveSheetView`, `@username` Topluluk ağı, `ShareCardView` ve `getomakase.app` canlı web simülatörü aktif. | [`ozellik_fikirleri.md`](file:///Users/kuzey/projects/omakase/docs/ozellik_fikirleri.md) |
| **App Store Uyumluluğu** | ✅ **7/7 Çözüldü** | `PrivacyInfo.xcprivacy`, Sign in with Apple (Kural 4.8), Hesap Silme (5.1.1v), 4 katmanlı UGC Moderasyon/Engelleme/Şikayet (1.2), Yasal sayfalar (`privacy.html`, `terms.html`) ve ATS temizliği tamamlandı. | [`appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md) |
| **Siber Güvenlik** | ✅ **9/10 Kodda Kapatıldı** | Firebase JWT doğrulaması (`APITokenProvider`), sliding-window Rate Limiting, PII (`email`) temizliği, sıkı `firestore.rules`, SSRF/XXE koruması, `<user_context>` prompt izolasyonu ve CSP/HSTS başlıkları eklendi (yalnızca GCP Console API key kısıtlaması manuel adım olarak bekliyor). | [`siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md) |
| **Birim Ekonomisi & PMF** | ✅ **%96 Brüt Marj** | Yoğun bir kullanıcının aylık AI (`gemini-3.5-flash` + `gemini-3.1-flash-lite`) ve bulut maliyeti **~\$0.10 – \$0.14**. \$3.99/ay veya \$29.99/yıl Pro abonelikte ~%96 brüt karlılık. | [`urun_analizi_ve_pazarlama.md`](file:///Users/kuzey/projects/omakase/docs/urun_analizi_ve_pazarlama.md) |
| **Küresel Dağıtım & Büyüme** | 🚀 **Strateji Hazır** | Tier-1 İngilizce pazarlara (ABD, İngiltere, Avrupa) odaklanan "Anti-Brainrot" konumlandırması, yarı-otomatik TikTok Photo Mode (Carousel) içerik motoru ve aşamalı ASA/Spark Ads planı kurgulandı. | [`pazarlama_ve_dagitim_stratejisi.md`](file:///Users/kuzey/projects/omakase/docs/pazarlama_ve_dagitim_stratejisi.md) |

---

## 2. Ürün Mimarisi & Tamamlanan 8 Çekirdek Sistem

Omakase ekosistemi üç ana katmandan oluşur: **SwiftUI iOS 17+ İstemcisi (`omakase/`)**, **Google Cloud Run üzerindeki FastAPI + Google GenAI Mikroservisi (`backend/`)** ve **İnteraktif Web Simülatörü (`web/` — `getomakase.app`)**.

1. **Bento Keşif Motoru (`BentoTasteBox`):** 12 ana kültür disiplini (*Sinema, Bilim, Felsefe, Sanat, Teknoloji, Tarih, Müzik, Edebiyat, Psikoloji, Mimari, Gastronomi, Uzay*), her kategoride korunan 6'lı alt konu ızgarası, `gemini-3.1-flash-lite` ile isteğe bağlı yenileme ve özel konu girişi.
2. **12 Dönüşümlü Editoryal Format & Deep Dive (`prompts.py`):** Sıfır dolgu cümlesiyle 40–90 kelimelik doğrulanmış mikro-hikayeler üreten 12 şablon (`FUN FACT DROP`, `NICHES & NUANCE`, `UNLIKELY CONNECTION`, `TINY RECOMMENDATION`, `REFRAME`, `THE THING NOBODY TALKS ABOUT`, `CURSED TRIVIA`, `DEBATE`, `TIMELINE`, `VERSUS`, `MYTHBUSTER`, `IF_YOU_LIKE_X_TRY_Y`) ve tek dokunuşla açılan 150–250 kelimelik **Deep Dive Modal** (`DeepDiveSheetView`).
3. **Okuma Süresi & Doomscrolling Koruması (`Reading Cooldown`):** Kelime sayısına göre 15–25 saniye boyunca yeni post üretimini kilitleyen animasyonlu kum saati sayacı. Hem metnin sindirilmesini sağlar hem de doğal bir sunucu maliyet sınırlayıcısı (rate-limiter) görevi görür.
4. **Sürtünmesiz Kimlik Doğrulama (`AuthView`, `AuthService`):** Sign in with Apple, Google Sign-In ve gerçek zamanlı `@kullanıcı_adı` müsaitlik kontrolüne sahip 3 adımlı kayıt akışı.
5. **Topluluk (`Community`) & Arama (`TimelineView`):** Beğenilen şef yazılarını `@username` profili üzerinden paylaşma, gönderi/kişi arama çubuğu, 5'li reaksiyon sistemi (`🔥, 🧠, ❤️, 👏, 🤯`), yorumlar, kullanıcı takip etme ve çevrimdışı yer imleri (`BookmarkStore`).
6. **Sosyal Paylaşım Kartı (`ShareCardView`):** `1080 x 1350` boyutunda, `#F5F0E8` kağıt zemin ve `#1A1A1A` tipografiyle Instagram/TikTok paylaşımına hazır görsel kart üretimi.
7. **Yan Özellik — Letterboxd RSS Sentezi (`LetterboxdService`):** Kullanıcının isteğe bağlı olarak girdiği Letterboxd kullanıcı adından son 50 filmi çekip rastgele birinin doğrulanmış kamera arkası anekdotunu üreten opsiyonel sinema zenginleştirmesi.
8. **İnteraktif Web Deneyimi (`web/`):** Uygulamayı indirmeden önce tarayıcıda canlı kategori seçimi, SSE akışı ve Deep Dive deneyimi sunan çift dilli (`TR`/`EN`) web simülatörü.

---

## 3. Ürün Tezi, PMF & Birim Ekonomisi

### 3.1. Kuzey Yıldızı Metriği ve "Aha! Anı"
* **Aha! Anı (< 45 Saniye):** Kullanıcının ilk oturumunda Bento'dan bir alt konuya dokunup SSE daktilo akışını izlemesi, 15–25 saniyelik okuma süresini tamamlaması ve ilk **Deep Dive** penceresini açması.
* **North Star Metric:** **WCCR (Weekly Completed Cooldown Reads)** — Haftalık tamamlanan nitelikli okuma sayısı.
* **PMF Hedef Eşikleri:** D1 Retention ≥ %45, D7 Retention ≥ %25, D30 Retention ≥ %15; Sean Ellis testinde *"Çok hayal kırıklığına uğrardım"* oranı ≥ %40.

### 3.2. Birim Ekonomisi (Unit Economics)

| İşlem | Model | İşlem Başı Maliyet |
|-------|-------|--------------------|
| **Alt Konu Genişletme (6'lı Karo)** | `gemini-3.1-flash-lite` | ~\$0.00004 |
| **Standart Mikro-Hikaye (40–90 kelime)** | `gemini-3.5-flash` | ~\$0.00025 |
| **Deep Dive (150–250 kelime)** | `gemini-3.5-flash` | ~\$0.00040 |

* **Aylık Kullanıcı Maliyeti:** Günde 8 mikro-hikaye + 2 Deep Dive tüketen aktif bir kullanıcının aylık toplam AI + Cloud Run + Firestore maliyeti **~\$0.10 – \$0.14**'tür.
* **Gelir & Brüt Kar Marjı:** **Omakase Pro** (\$3.99/ay veya 7 gün ücretsiz denemeli \$29.99/yıl) katmanında Apple %15 komisyonu düşüldükten sonra **Brüt Kar Marjı ≈ %96** seviyesindedir (Not: Apple Kural 5.2.2 uyumu için Letterboxd yan özelliği ücretsiz katmanda açık tutulur; ödeme sistemi v1.0 lansmanından itibaren aktiftir).

---

## 4. Küresel Pazarlama, TikTok Otomasyonu & Dağıtım

LLM çağında yazılım geliştirme maliyeti düştüğü için asıl rekabet **dağıtım (distribution)** katmanındadır. Omakase'nin stratejik avantajı, **ürünün ürettiği mikro-hikayelerin doğrudan sosyal medyada en çok viral olan içerik formatı olmasıdır.**

### 4.1. Küresel Konumlandırma (Tier-1 Pazarlar: ABD, İngiltere, Kanada, Avrupa)
* **"AI" Değil, "Anti-Brainrot" Hareketi:** Uygulama küresel pazarda bir yapay zeka aracı olarak değil; **"Entelektüel Espresso"** ve **"Doomscrolling Karşıtı Kültür Ritüeli"** olarak konumlandırılır.
* **Neden Tier-1 İngilizce Pazarlar?** Bulut/token maliyeti aynıyken (\$0.12/ay), ABD/UK pazarında yıllık abonelik dönüşümü Türkiye'ye kıyasla 4–7 kat daha yüksektir ve İngilizce içerik 1.5 milyarlık küresel havuza hitap eder.

### 4.2. Otomatize TikTok Photo Mode & Reels Büyüme Motoru
1. **Format Seçimi (%70 TikTok Photo Mode / 3'lü Kaydırmalı Slayt):**
   - Okuma uygulamalarında kaydırmalı görseller (Carousel), yapay sesli videolardan **2.9x daha fazla yorum** ve **2.6x daha fazla paylaşım** alır.
   - **Slayt 1:** Kağıt zeminde (`#F5F0E8`) merak uyandıran başlık/soru (Hook).
   - **Slayt 2:** `ShareCardView` formatında 60 kelimelik doğrulanmış Omakase mikro-hikayesi.
   - **Slayt 3:** Yarıda kesilen Deep Dive detayı + *"Read the 60-second Deep Dive on Omakase (link in bio)."*
2. **ABD/UK Kitlesine Düşme Kuralı (Geo-Targeting):**
   - TikTok dağıtımı dil seçimine göre değil **SIM kart ve ağ ülkesine göre** yapar. İkinci bir iPhone'da Türk SIM kartı çıkarılıp **US eSIM (Tello/Airalo US)** ve `United States` bölge ayarıyla hesap açılmalıdır.
3. **%95 Otomasyon + %5 Manuel Yayın:**
   - Python betiği her sabah `prompts.py` içindeki `CURSED TRIVIA`, `MYTHBUSTER`, `UNLIKELY CONNECTION` formatlarıyla 10 İngilizce post üretip görsel kartlara basar; paylaşım ise trend müzik ekleyebilmek ve API erişim kısıtlamasına takılmamak için telefondan TikTok Taslakları (Drafts) üzerinden günde 2 dakikada yayınlanır.

### 4.3. Ücretli Reklam (Paid UA) ve Sıfır Bütçeli Kanallar
* **İlk 6 Hafta \$0 Reklam Bütçesi:** Soğuk kitleye doğrudan reklam vermek yerine önce organik TikTok/Reels, **Reddit** (`r/nosurf`, `r/digitalminimalism`, `r/InternetIsBeautiful`), **Hacker News (`Show HN`)** (doğrudan `getomakase.app` Canlı Tadım simülatörüyle) ve **Product Hunt** kullanılır.
* **Kaldıraçlı Reklam (Hafta 6+):**
  1. **Apple Search Ads (US/UK):** Apple'ın \$100 başlangıç kredisiyle yüksek niyetli kelimelere (`anti doomscrolling`, `daily knowledge`, `deepstash`, `readwise`, `micro learning`) reklam verilir.
  2. **TikTok Spark Ads (\$15/gün):** Sıfırdan reklam çekilmez; organik olarak 50.000+ izlenmiş ve yüksek yorum almış TikTok postları ABD'deki iOS kullanıcılarına boost edilir.

---

## 5. App Store Uyumluluk & Prodüksiyon Denetimi

[`docs/appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md) kapsamında yapılan denetimde tespit edilen **7 kritik App Review red sebebinin tamamı** çözülmüştür:

1. **Kural 5.1.2 (`PrivacyInfo.xcprivacy`):** `UserDefaults` (`CA92.1`) ve toplanan veri tipleri (`Name`, `EmailAddress`, `UserID` — `AppFunctionality`, `Tracking: false`) beyan edildi.
2. **Kural 4.8 (Sign in with Apple):** SHA-256 Nonce, Keychain (`appleIDUser`), `getCredentialState` ve `credentialRevokedNotification` destekli tam Sign in with Apple akışı eklendi.
3. **Kural 5.1.1(v) (Hesap Silme):** `deleteAllUserData(uid:)` ve `deleteAccount` ile tüm Firestore, Auth ve Keychain verilerini temizleyen uygulama içi **"Hesabı Sil"** butonu eklendi.
4. **Kural 1.2 (UGC Moderasyon):** Yorum ve kullanıcı adı ön filtresi (`ContentModerationService`), Gönderi/Yorum/Profil Şikayet Etme (`moderation_reports`) ve Kullanıcı Engelleme (`blockUser` + anlık akış gizleme) eklendi.
5. **Kural 1.5 & 5.1.1(i) (İletişim & Yasal Sayfalar):** Uygulama içine ve web'e `mailto:destek@getomakase.app`, `https://getomakase.app/privacy.html` ve `https://getomakase.app/terms.html` bağlandı.
6. **Kural 1.6 & 2.1(a) (ATS & Telemetri Temizliği):** `Info.plist` yerel HTTP istisnaları, `Release` `NSLocalNetworkUsageDescription` anahtarı ve geliştirici debug logları kaldırıldı.
7. **Küresel ASO İlk 3 Ekran Görüntüsü (`skill.app-store-product-page.foundations`):**
   - **Kare 1:** Monokrom Akış (*"Feed your mind, not the algorithm."*)
   - **Kare 2:** 12 Disiplin Bento (*"12 disciplines. Zero prompt paralysis."*)
   - **Kare 3:** Deep Dive Modal (*"60-word sparks. One-tap deep dives."*)

---

## 6. Siber Güvenlik & Sertleştirme Karnesi

[`docs/siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md) kapsamında tüm kod seviyesi zafiyetler kapatılmıştır:

* **S-01 & S-02 (Backend Auth & Rate Limiting — ✅ Çözüldü):** Tüm Cloud Run `POST` uç noktalarına Firebase ID Token (`Bearer`) doğrulaması, kullanıcı başına sliding-window hız sınırı ve sıkı Pydantic girdi boyut sınırları eklendi; iOS tarafında `APITokenProvider` ile single-flight `401` token yenileme kuruldu.
* **S-04 & S-06 (Firestore PII & Sosyal Grafik — ✅ Çözüldü):** Genel `users/{uid}` belgelerinden `email` alanı silindi (`FieldValue.delete()`); `firestore.rules` üzerinde "Forced Follow", sahte reaksiyon ve sayaç/rapor manipülasyonu açıkları kapatıldı.
* **S-05, S-07, S-08, S-09 (SSRF, XXE, Prompt Injection & Web Başlıkları — ✅ Çözüldü):** Letterboxd RSS çekicisine sıkı regex (`^[a-zA-Z0-9_-]{1,40}$`), domain kontrolü, 2 MB limit ve XML `<!DOCTYPE`/`<!ENTITY` engeli eklendi; kullanıcı girdileri `<user_context>` etiketleriyle izole edildi; `Dockerfile` non-root `appuser` (`UID 10001`) olarak ayarlandı; `firebase.json` içine CSP/HSTS güvenlik başlıkları eklendi ve yeni kayıtlarda minimum parola uzunluğu 8 karaktere çıkarıldı.

---

## 7. Savunma Hattı (Moat) & v2/v3 Ürün Yol Haritası

### 7.1. Omakase'nin 5 Katmanlı Savunma Hattı (`gelecek_stratejisi.md`)
1. **Bento Keşif Matrisi (`BentoTasteBox`):** Sohbet botlarındaki "ne soracağım?" sürtünmesini tek dokunuşla sıfırlar.
2. **Doyum & Cooldown Ritüeli:** 15–25 saniyelik okuma kilidiyle tüketim yorgunluğunu (*doomscrolling*) entelektüel doyuma çevirir.
3. **Mikro-Hikaye -> Deep Dive Geçişi:** 60 kelimelik kıvılcım ile 200 kelimelik derin analiz arasında pürüzsüz geçiş sağlar.
4. **`@username` Entelektüel Topluluk Ağı (Taste Graph):** Kullanıcıların kürasyonlarını paylaştığı yüksek sinyal-gürültü oranlı sosyal katman.
5. **Kültürel Günlük Bağlantıları:** Letterboxd ile başlayan, ileride Spotify ve Goodreads ile genişleyecek kişisel kültür izi sentezi.

### 7.2. v1.0 Lansman Kapsamı & v2 / v3 Özellik Yol Haritası (`ozellik_fikirleri.md` & `proje_durum_ve_mimari_raporu.md`)
* **v1.0 (Lansman — Day 1):**
  - **Monetizasyon (`RevenueCat` + StoreKit 2):** **Omakase Pro Paywall** (\$3.99/ay, 7 gün ücretsiz denemeli \$29.99/yıl), sunucu tarafı günlük kota (günde 5 tabak / 1 Deep Dive + paylaşımda +2 ekstra Deep Dive ödülü) ve RevenueCat Webhook/Sync (`entitlements/{uid}`).
  - **Bildirim Sistemi:** Yerel **"Günün Menüsü hazır"** hatırlatıcısı (kullanıcı saatli) + **APNs & FCM sosyal push bildirimleri** (anlık/30 dk gruplu yeni yorum, günlük takipçi/tepki özeti, `22:00–08:00` sessiz saatler).
  - **Hata Mesajları & Telemetri:** Kod bazlı merkezi hata sistemi (`OmakaseError` + `L10n`) ve Firebase Crashlytics non-fatal kaydı.
* **v2.0:** **Spotify "Recently Played"** entegrasyonu (dinlenen şarkıların prodüksiyon ve sample hikayeleri).
* **v2.1:** **Sesli Dinleme / Yürüyüş Modu (TTS)** ve **Akıllı Sabah Kürasyonu** genişletmeleri.
* **v2.5:** **Goodreads / Kitap Günlüğü** RSS entegrasyonu.

---

## 8. Canlıya Geçiş Öncesi Kalan Manuel Konsol & CLI Aksiyonları

Kod tabanındaki tüm geliştirmeler tamamlanmıştır. App Store gönderimi ve tam prodüksiyon güvenliği için yalnızca geliştirici konsolunda yapılması gereken **4 kısa işlem** kalmıştır:

- [ ] **1. Cloud Run & Firebase Canlı Dağıtımı:**
  ```bash
  cd backend && gcloud run deploy omakase-backend --source . --region us-central1 --project gen-lang-client-0120875563
  firebase deploy --only firestore:rules,hosting --project gen-lang-client-0120875563
  ```
- [ ] **2. Google Cloud Console API Anahtarı Kısıtlaması (`S-03`):**
  - GCP Console → **APIs & Services → Credentials** altından iOS `API_KEY` (`AIzaSyBr65...`) için `iOS apps` (`kuzeysinay.omakase`) kısıtlaması ekleyin ve `API restrictions` listesinden `Generative Language API` erişimini kaldırıp yalnızca Firebase/Firestore API'lerini bırakın.
- [ ] **3. Xcode & Firebase Sign in with Apple Yeteneği:**
  - Xcode'da **omakase target → Signing & Capabilities → + Capability → Sign in with Apple** ekleyin ve Firebase Console → **Authentication → Sign-in method** altından **Apple** sağlayıcısını aktif edin.
- [ ] **4. App Store Connect Gönderimi:**
  - App Store Connect → **App Review Information** kısmına inceleme ekibi için aktif bir **Demo Hesap** girin; Xcode'da **Any iOS Device (arm64)** seçip **Product → Archive → Validate App → Distribute App** adımlarını tamamlayın.

---

## 9. Apple Agent Kit İzlenebilirlik Özeti

`.agents/AGENTS.md` kuralları gereğince bu master raporda sentezlenen Apple platform uyumluluk, güvenlik ve ürün sayfası kararlarının dayandığı yönlendirme zinciri:

1. **Kapsanan Workflow'lar:** [`workflow.app-store-submission`](file:///Users/kuzey/projects/omakase/.agents/workflows/app-store-submission/WORKFLOW.md), [`workflow.authentication`](file:///Users/kuzey/projects/omakase/.agents/workflows/authentication/WORKFLOW.md)
2. **Kapsanan Skill'ler:** [`skill.app-store-product-page.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-product-page/SKILL.md), [`skill.app-store-review-guidelines.submission`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-review-guidelines/SKILL.md), [`skill.privacy.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/privacy/SKILL.md), [`skill.xcode.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/xcode/SKILL.md), [`skill.authenticationservices.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/authenticationservices/SKILL.md), [`skill.security.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/security/SKILL.md), [`skill.networking.urlsession`](file:///Users/kuzey/projects/omakase/.agents/skills/networking/SKILL.md)
3. **Temel Knowledge Contracts:** [`header-and-search-result-messaging.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-product-page/header-and-search-result-messaging.md), [`asset-sequencing-and-story.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-product-page/asset-sequencing-and-story.md), [`third-party-content-licensing.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/third-party-content-licensing.md), [`user-generated-content-moderation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/user-generated-content-moderation.md), [`data-security.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/data-security.md), [`authenticated-requests.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/networking/authenticated-requests.md)
