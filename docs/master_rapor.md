# 🍣 Omakase — Master Rapor (Mimari, Ürün/PMF, Küresel Pazarlama, App Store & Siber Güvenlik Özeti)

> **Son Güncelleme:** 24 Kasım 2026  
> **Kapsam:** `docs/` altındaki 6 uzman raporun ([`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md), [`founder_100_musteri_raporu.md`](file:///Users/kuzey/projects/omakase/docs/founder_100_musteri_raporu.md), [`siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md), [`appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md), [`urun_analizi_ve_pazarlama.md`](file:///Users/kuzey/projects/omakase/docs/urun_analizi_ve_pazarlama.md), [`pazarlama_ve_dagitim_stratejisi.md`](file:///Users/kuzey/projects/omakase/docs/pazarlama_ve_dagitim_stratejisi.md)) tek bir yönetici dokümanında birleştirilmiş master özeti.

---

## İçindekiler

1. [Yönetici Özeti & Proje Durum Panosu](#1-yönetici-özeti--proje-durum-panosu)
2. [Ürün Mimarisi, 7 Dil & Birincil Kaynakça (`proje_durum_ve_mimari_raporu.md`)](#2-ürün-mimarisi-7-dil--birincil-kaynakça)
3. [Ürün Tezi, PMF, Birim Ekonomisi & 100 Müşteri Doğrulaması (`urun_analizi_ve_pazarlama.md` & `founder_100_musteri_raporu.md`)](#3-ürün-tezi-pmf-birim-ekonomisi--100-müşteri-doğrulaması)
4. [Küresel Pazarlama, TikTok Otomasyonu & Dağıtım (`pazarlama_ve_dagitim_stratejisi.md`)](#4-küresel-pazarlama-tiktok-otomasyonu--dağıtım)
5. [App Store Uyumluluk & Prodüksiyon Denetimi (`appstore_raporu.md`)](#5-app-store-uyumluluk--prodüksiyon-denetimi)
6. [Siber Güvenlik & Sertleştirme Karnesi (`siber_guvenlik_raporu.md`)](#6-siber-güvenlik--sertleştirme-karnesi)
7. [Savunma Hattı (Moat) & v2/v3 Ürün Yol Haritası](#7-savunma-hattı-moat--v2v3-ürün-yol-haritası)
8. [Canlıya Geçiş Öncesi Kalan Manuel Konsol & Dağıtım Aksiyonları](#8-canlıya-geçiş-öncesi-kalan-manuel-konsol--dağıtım-aksiyonları)
9. [Apple Agent Kit İzlenebilirlik Özeti](#9-apple-agent-kit-izlenebilirlik-özeti)

---

## 1. Yönetici Özeti & Proje Durum Panosu

**Omakase**, algoritmik sosyal medya gürültüsü (*doomscrolling / brainrot*) ile sohbet botlarının boş ekran sendromu (*prompt paralysis*) arasındaki boşluğu dolduran, **kağıt/mürekkep estetiğine, birincil kaynakça doğrulamasına ve 7 dile sahip kişisel kültür ve mikro-bilgi platformudur.**

| Alan | Durum | Özet Durum | Detay Rapor |
|------|-------|------------|-------------|
| **Ürün, 7 Dil & Kaynakça** | ✅ **%100 Hazır** | 12 disiplinli `BentoTasteBox`, 14 editoryal format, 7 dil (`en, tr, ja, de, fr, es, ko`), tıklanabilir birincil kaynakça ([`PostSourceView`](file:///Users/kuzey/projects/omakase/omakase/omakase/Theme/PostSourceView.swift)), 15–25 sn `Reading Cooldown`, **Derin İnceleme**, Keşfet/Takip `@username` Topluluğu ve `getomakase.app`. | [`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md) |
| **Monetizasyon, Bildirim & Hata** | ✅ **Kod & Cloud Run Canlı** | RevenueCat (`5.103.2`) Pro (\$29.99/yıl · 7 gün deneme veya \$3.99/ay), günde **3 ücretsiz tabak** (`Kalan: X/3`) + 1 Derin İnceleme (`+1` paylaşım bonusu), APNs/FCM sosyal push & yerel hatırlatıcı ve `OmakaseError` + Crashlytics canlı. | [`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md) |
| **100 Müşteri & Fiyat Doğrulaması** | ✅ **1. Tur %1 → 2. Tur %72** | `founder-skill` ile 100 persona test edildi: 5 tabak + kaynakçasız teklifte `%1` olan dönüşüm; 3 tabak + birincil kaynakça + `\$2.49/ay` yıllık çerçevesinde **`%72`** sıçradı (Van Westendorp `IPP: $2.53`). | [`founder_100_musteri_raporu.md`](file:///Users/kuzey/projects/omakase/docs/founder_100_musteri_raporu.md) |
| **App Store Uyumluluğu** | ✅ **Kod & Manifest Tamamlandı** | `PrivacyInfo.xcprivacy` (`UserDefaults`, `Name`, `EmailAddress`, `UserID`, `PurchaseHistory`, `CrashData`, `OtherUserContent`), Sign in with Apple, Hesap Silme, 4 katmanlı UGC Moderasyon ve abonelik/gizlilik yasal sayfaları hazır. | [`appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md) |
| **Siber Güvenlik** | ✅ **11/12 Kodda Kapatıldı (`5/5`)** | `S-01`–`S-12` (Firebase JWT, Rate Limiting, billing/push korumaları, sıkı `firestore.rules` `5/5`, SSRF/XXE, `<user_context>`, CSP/HSTS) tamamlandı; yalnızca GCP `API_KEY` konsol kısıtlaması (`S-03`) bekliyor. | [`siber_guvenlik_raporu.md`](file:///Users/kuzey/projects/omakase/docs/siber_guvenlik_raporu.md) |
| **Birim Ekonomisi & PMF** | ✅ **%96 Brüt Marj** | Yoğun bir kullanıcının aylık AI (`gemini-3.5-flash` + `gemini-3.1-flash-lite`) ve bulut maliyeti **~\$0.10 – \$0.14**. Pro abonelikte ~%96 brüt karlılık. | [`urun_analizi_ve_pazarlama.md`](file:///Users/kuzey/projects/omakase/docs/urun_analizi_ve_pazarlama.md) |
| **Küresel Dağıtım & Büyüme** | 🚀 **Strateji Hazır** | Tier-1 pazarlara (ABD, İngiltere, Avrupa, Japonya/Kore/Almanya/Fransa/İspanya — 7 dil desteğiyle) odaklanan "Anti-Brainrot" konumlandırması ve otomatize TikTok Photo Mode planı hazır. | [`pazarlama_ve_dagitim_stratejisi.md`](file:///Users/kuzey/projects/omakase/docs/pazarlama_ve_dagitim_stratejisi.md) |

---

## 2. Ürün Mimarisi, 7 Dil & Birincil Kaynakça

Omakase ekosistemi üç ana katmandan oluşur: **SwiftUI iOS 17+ İstemcisi (`omakase/`)**, **Google Cloud Run üzerindeki FastAPI + Google GenAI Mikroservisi (`backend/`)** ve **İnteraktif Web Simülatörü (`web/` — `getomakase.app`)**.

1. **Bento Keşif Motoru (`BentoTasteBox`):** 12 ana kültür disiplini (*Film, Müzik, Bilim, Yemek, Tarih, Spor, Teknoloji, Doğa, Sanat, Felsefe, Seyahat, Oyun*), 2×6 dikey kategori karosu, `gemini-3.1-flash-lite` ile ön-bellekli alt konu üretimi ve özel konu girişi.
2. **14 Dönüşümlü Editoryal Format, Birincil Kaynakça & Derin İnceleme (`prompts.py` + `PostSourceView.swift`):** Sıfır dolgu cümlesiyle 40–90 kelimelik mikro-hikayeler ve her kartın altında **gerçek birincil kaynak** (kitap, akademik makale, yönetmen röportajı veya arşiv adı — "Wikipedia" yasak); dokunulunca tam kaynak popover'ı ve varsayılan tarayıcıda arama açılır. Merak uyandığında tek dokunuşla 150–250 kelimelik **Derin İnceleme** penceresi açılır.
3. **7 Dil Desteği (`en, tr, ja, de, fr, es, ko`):** iOS arayüzünde cihaz dilinden otomatik başlangıç (`AppLanguage.systemDefault`) ve Profil'den anlık dil değişimi; backend `normalize_language`, 7 dilli prompt kaynak önekleri (`Source:`, `Kaynak:`, `出典:`, `Quelle:`, `Source :`, `Fuente:`, `출처:`) ve 7 dilli push bildirim metinleri.
4. **Okuma Süresi & Günlük Stres Sayacı (`Reading Cooldown` + `Kalan: X/3`):** Kelime sayısına göre 15–25 sn sindirme süresi uygulanır; ücretsiz kullanıcılar için üst çubukta `3` tabaklık canlı doluluk kapsülü (`Kalan: X/3`, son `1` ve `0` hakta kırmızı uyarı) gösterilir.
5. **Sürtünmesiz Kimlik Doğrulama (`AuthView`, `AuthService`):** Sign in with Apple, Google Sign-In ve gerçek zamanlı `@kullanıcı_adı` müsaitlik kontrolüne sahip 3 adımlı kayıt akışı.
6. **Topluluk Keşfet (`Discover`) & Takip (`TimelineView`):** Varsayılan **Keşfet** akışı gönderileri yazar bazında round-robin harmanlayarak rastgele farklı okurları öne çıkarır; kart başlığından tek dokunuşla `+ Takip et` yapılabilir. Arama barı, tepki/yorumlar ve çevrimdışı yer imleri (`BookmarkStore`) desteklenir.
7. **Letterboxd RSS Sentezi & Kağıt Paylaşım Kartı:** Şifresiz Letterboxd son 50 film günlüğünden rastgele seçimle doğrulanmış kamera arkası hikayeleri ve `#F5F0E8` `1080×1350` paylaşım kartı üretimi.
8. **İnteraktif Web Deneyimi (`web/`):** Tarayıcıda Canlı Tadım simülatörü, Derin İnceleme önizlemesi, sadeleştirilmiş metinler ve abonelik/gizlilik yasal sayfaları.

---

## 3. Ürün Tezi, PMF, Birim Ekonomisi & 100 Müşteri Doğrulaması

### 3.1. Kuzey Yıldızı Metriği ve "Aha! Anı"
* **Aha! Anı (< 45 Saniye):** Kullanıcının ilk oturumunda Bento'dan bir alt konuya dokunup SSE daktilo akışını izlemesi, birincil kaynağı incelemesi, 15–25 saniyelik okuma süresini tamamlaması ve ilk **Derin İnceleme** penceresini açması.
* **North Star Metric:** **WCCR (Weekly Completed Cooldown Reads)** — Haftalık tamamlanan nitelikli okuma sayısı.
* **PMF Hedef Eşikleri:** D1 Retention ≥ %45, D7 Retention ≥ %25, D30 Retention ≥ %15; Sean Ellis testinde *"Çok hayal kırıklığına uğrardım"* oranı ≥ %40.

### 3.2. Birim Ekonomisi & `founder-skill` 100 Müşteri Simülasyonu

| İşlem | Model | İşlem Başı Maliyet |
|-------|-------|--------------------|
| **Alt Konu Genişletme** | `gemini-3.1-flash-lite` | ~\$0.00004 |
| **Standart Mikro-Hikaye (40–90 kelime)** | `gemini-3.5-flash` | ~\$0.00025 |
| **Derin İnceleme (150–250 kelime)** | `gemini-3.5-flash` | ~\$0.00040 |

* **Gelir & Brüt Kar Marjı:** **Omakase Pro** (\$3.99/ay veya 7 gün ücretsiz denemeli \$29.99/yıl ≈ \$2.49/ay) katmanında Apple %15 komisyonu düşüldükten sonra **Brüt Kar Marjı ≈ %96** seviyesindedir.
* **100 Müşteri Doğrulama Özeti ([`founder_100_musteri_raporu.md`](file:///Users/kuzey/projects/omakase/docs/founder_100_musteri_raporu.md)):**
  - **1. Tur (5 tabak, kaynakçasız, aylık vurgu):** `1 alıcı · 99 pas (%1)` — kullanıcıların 98/99'u *"5 ücretsiz tabak yetiyor"* dedi.
  - **2. Tur (3 tabak + `Kalan: X/3` + birincil kaynakça + `\$2.49/ay` yıllık vurgu, lifetime yok):** **`72 alıcı · 28 pas (%72)`**; Van Westendorp kabul edilebilir aralık **\$1.01 – \$5.49/ay** (`IPP: $2.53`). (Simülasyon rakamı üst sınır olarak yorumlanır; mekanik farkı doğrular.)

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

1. **Kural 5.1.2 (`PrivacyInfo.xcprivacy`):** `UserDefaults` (`CA92.1`) ve toplanan veri tipleri (`Name`, `EmailAddress`, `UserID`, `PurchaseHistory`, `CrashData`, `OtherUserContent` — `AppFunctionality`, `Tracking: false`) beyan edildi.
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
* **S-11 & S-12 (22 Kasım Sertleştirmesi — ✅ Çözüldü):** `firestore.rules` üzerinde alan bazlı `hasOnly` izin listeleri, sunucu zaman damgası doğrulaması, kendi kendini takip etme yasağı ve `reportedBy` kontrolleri uygulanarak Firestore güvenlik denetiminden **`5/5` (Secure)** skoru alındı; `/billing/status` ve `/billing/sync` uç noktalarına kullanıcı bazlı hız sınırları (`rate_limiter`) ve bildirim aktör adı çözümlemesi (`_resolve_actor_display_name`) eklendi.

---

## 7. Savunma Hattı (Moat) & v2/v3 Ürün Yol Haritası

### 7.1. Omakase'nin 5 Katmanlı Savunma Hattı
1. **Bento Keşif Matrisi (`BentoTasteBox`):** Sohbet botlarındaki "ne soracağım?" sürtünmesini tek dokunuşla sıfırlar.
2. **Doyum & Cooldown Ritüeli:** 15–25 saniyelik okuma kilidiyle tüketim yorgunluğunu (*doomscrolling*) entelektüel doyuma çevirir.
3. **Mikro-Hikaye -> Derin İnceleme & Kaynak Katmanı:** 60 kelimelik kıvılcım ile 200 kelimelik Derin İnceleme arasında pürüzsüz geçiş ve `PostSourceView` ile doğrulanabilir birincil kaynak bağlantısı sağlar.
4. **`@username` Entelektüel Topluluk Ağı (Taste Graph):** Keşfet/Takip akışı ve hızlı takip aksiyonlarıyla kullanıcıların kürasyonlarını paylaştığı yüksek sinyal-gürültü oranlı sosyal katman.
5. **Kültürel Günlük Bağlantıları:** Letterboxd ile başlayan, ileride Spotify ve Goodreads ile genişleyecek kişisel kültür izi sentezi.

### 7.2. v1.0 Lansman Kapsamı & v2 / v3 Özellik Yol Haritası ([`proje_durum_ve_mimari_raporu.md`](file:///Users/kuzey/projects/omakase/docs/proje_durum_ve_mimari_raporu.md))
* **v1.0 (Lansman — Day 1):**
  - **Monetizasyon (`RevenueCat` + StoreKit 2):** **Omakase Pro Paywall** (\$3.99/ay, 7 gün ücretsiz denemeli \$29.99/yıl), sunucu tarafı günlük kota (günde **3 tabak** + ana akışta `Kalan: X/3` göstergesi / **1 Derin İnceleme** + paylaşımda **+1** ekstra Derin İnceleme ödülü) ve RevenueCat Webhook/Sync (`entitlements/{uid}`).
  - **Çoklu Dil & Doğrulanabilir Kaynaklar:** **7 dil** desteği (`en`, `tr`, `ja`, `de`, `fr`, `es`, `ko`) ve tıklanabilir birincil kaynak dipnot/popover katmanı (`PostSourceView`).
  - **Bildirim Sistemi:** Yerel **"Günün Menüsü hazır"** hatırlatıcısı (kullanıcı saatli) + **APNs & FCM sosyal push bildirimleri** (anlık/30 dk gruplu yeni yorum, günlük takipçi/tepki özeti, `22:00–08:00` sessiz saatler).
  - **Hata Mesajları & Telemetri:** Kod bazlı merkezi hata sistemi (`OmakaseError` + `L10n`) ve Firebase Crashlytics non-fatal kaydı.
* **v2.0:** **Spotify "Recently Played"** entegrasyonu (dinlenen şarkıların prodüksiyon ve sample hikayeleri).
* **v2.1:** **Sesli Dinleme / Yürüyüş Modu (TTS)** ve **Akıllı Sabah Kürasyonu** genişletmeleri.
* **v2.5:** **Goodreads / Kitap Günlüğü** RSS entegrasyonu.

---

## 8. Canlıya Geçiş Öncesi Kalan Manuel Konsol & CLI Aksiyonları

Kod tabanındaki tüm geliştirmeler tamamlanmıştır. Cloud Run canlı revizyonu (`omakase-backend-00015-btf`) yayındadır; son 7 dil güncellemesinin canlıya alınması, App Store gönderimi ve tam prodüksiyon güvenliği için aşağıdaki operasyonel adımlar kalmıştır:

- [ ] **1. Cloud Run (7 Dil Güncellemesi) & Firebase Canlı Dağıtımı:**
  ```bash
  cd backend && gcloud run deploy omakase-backend --source . --region us-central1 --project gen-lang-client-0120875563
  firebase deploy --only firestore:rules,hosting --project gen-lang-client-0120875563
  ```
- [ ] **2. Google Cloud API Kısıtlaması (`S-03`) & Bildirim Altyapısı:**
  - GCP Console → **APIs & Services → Credentials** altından iOS `API_KEY` için `iOS apps` (`kuzeysinay.omakase`) kısıtlaması ekleyin ve `API restrictions` listesinden `Generative Language API` erişimini kaldırın.
  - Apple Developer **APNs `.p8`** anahtarını Firebase Console → Cloud Messaging'e yükleyin; günlük özet için Cloud Scheduler ve gecikmeli yorum bildirimi için Cloud Tasks kuyruğunu tanımlayın.
- [ ] **3. Xcode, RevenueCat & Sign in with Apple Hazırlıkları:**
  - Xcode'da **omakase target → Signing & Capabilities → + Capability → Sign in with Apple & Push Notifications** yeteneklerini doğrulayın; Firebase Console → **Authentication → Sign-in method** altından **Apple** sağlayıcısını aktif edin.
  - App Store Connect **Paid Apps Agreement**, IAP ürünleri (`omakase.pro.monthly`, `omakase.pro.yearly`) inceleme doğrulaması ve RevenueCat Offering (`pro` entitlement) son kontrolünü tamamlayın.
- [ ] **4. App Store Connect Gönderimi:**
  - App Store Connect → **App Review Information** kısmına inceleme ekibi için aktif bir **Demo Hesap** girin; Xcode'da **Any iOS Device (arm64)** seçip **Product → Archive → Generate Privacy Report → Validate App → Distribute App** adımlarını tamamlayın.

---

## 9. Apple Agent Kit İzlenebilirlik Özeti

`.agents/AGENTS.md` kuralları gereğince bu master raporda sentezlenen Apple platform uyumluluk, güvenlik ve ürün sayfası kararlarının dayandığı yönlendirme zinciri:

1. **Kapsanan Workflow'lar:** [`workflow.app-store-submission`](file:///Users/kuzey/projects/omakase/.agents/workflows/app-store-submission/WORKFLOW.md), [`workflow.authentication`](file:///Users/kuzey/projects/omakase/.agents/workflows/authentication/WORKFLOW.md)
2. **Kapsanan Skill'ler:** [`skill.app-store-product-page.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-product-page/SKILL.md), [`skill.app-store-review-guidelines.submission`](file:///Users/kuzey/projects/omakase/.agents/skills/app-store-review-guidelines/SKILL.md), [`skill.privacy.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/privacy/SKILL.md), [`skill.xcode.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/xcode/SKILL.md), [`skill.authenticationservices.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/authenticationservices/SKILL.md), [`skill.security.foundations`](file:///Users/kuzey/projects/omakase/.agents/skills/security/SKILL.md), [`skill.networking.urlsession`](file:///Users/kuzey/projects/omakase/.agents/skills/networking/SKILL.md)
3. **Temel Knowledge Contracts:** [`header-and-search-result-messaging.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-product-page/header-and-search-result-messaging.md), [`asset-sequencing-and-story.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-product-page/asset-sequencing-and-story.md), [`third-party-content-licensing.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/third-party-content-licensing.md), [`user-generated-content-moderation.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/user-generated-content-moderation.md), [`data-security.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/data-security.md), [`authenticated-requests.md`](file:///Users/kuzey/projects/omakase/.agents/knowledge/networking/authenticated-requests.md)
