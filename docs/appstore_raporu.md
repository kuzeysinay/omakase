# 🍣 Omakase — App Store'a Çıkış & Prodüksiyon Raporu

> **Son Güncelleme:** 11 Eylül 2026  
> **Kapsam:** Canlı Cloud Run mimarisi, Gemini 3.5 Flash model analizi, Letterboxd ve Bento entegrasyonları, App Store Review uyumluluğu, güvenlik ve monetizasyon stratejisi.

---

## İçindekiler

1. [Mevcut Durum & Sistem Mimarisi](#1-mevcut-durum--sistem-mimarisi)
2. [Canlı Altyapı Mimarisi (Google Cloud Run)](#2-canlı-altyapı-mimarisi)
3. [Gemini 3.5 Flash Maliyet & Performans Analizi](#3-gemini-35-flash-maliyet--performans-analizi)
4. [App Store Review Kılavuzu Uyumluluğu](#4-app-store-review-kılavuzu-uyumluluğu)
5. [Letterboxd & Üçüncü Taraf Entegrasyon Uyumluluğu](#5-letterboxd--üçüncü-taraf-entegrasyon-uyumluluğu)
6. [Güvenlik & İçerik Moderasyonu](#6-güvenlik--içerik-moderasyonu)
7. [Abonelik Modeli (StoreKit 2)](#7-abonelik-modeli-storekit-2)
8. [Lansman Öncesi Yapılacaklar (Checklist)](#8-lansman-öncesi-yapılacaklar)

---

## 1. Mevcut Durum & Sistem Mimarisi

### Güncel Mimari Şeması

```
┌─────────────────────────────────────────────────────────────┐
│                       iOS Client                            │
│  - SwiftUI (iOS 17+)                                        │
│  - Reels-Style Fullscreen Vertical Paging                   │
│  - BentoTasteBox (2048-style Gamified Discovery Engine)     │
│  - Letterboxd RSS Entegrasyonu (50 Film + Trivia Önceliği)  │
│  - Reading Cooldown (Metin Boyutuna Göre Akıllı Kilit)      │
└──────────────┬───────────────────────────────┬──────────────┘
               │                               │
               │ HTTPS (SSE Stream)            │ Firebase SDK
               │ POST /feed/stream             │ (Google Sign-In + Firestore)
               ▼                               ▼
┌──────────────────────────────┐       ┌──────────────────────┐
│  Google Cloud Run (Live)     │       │  Google Firebase     │
│  FastAPI Backend             │       │  - Firebase Auth     │
│  - python-dotenv & pydantic  │       │  - Cloud Firestore   │
│  - _BLOCKLIST_RE Moderasyon  │       │  - firestore.rules   │
│  - Server-Sent Events (SSE)  │       └──────────────────────┘
└──────────────┬───────────────┘
               │
               │ google-genai SDK (v1.0+)
               ▼
┌──────────────────────────────┐
│   Google Gemini API          │
│   - gemini-3.5-flash (Feed)  │
│   - gemini-3.1-flash-lite    │
└──────────────────────────────┘
```

### Bileşen Durum Tablosu

| Bileşen | Durum | Açıklama |
|---------|-------|----------|
| **iOS Client** | ✅ Tamamlandı | Reels tarzı tam ekran sayfalama, BentoTasteBox, Letterboxd kutusu, okuma süresi kilitleri |
| **Backend Altyapısı** | ✅ Canlıda | Google Cloud Run üzerinde `omakase-backend` servisi (us-central1, HTTPS) |
| **Yapay Zeka Modelleri** | ✅ Güncel | Akışta **gemini-3.5-flash** (düşünme evresiz anlık token stream), kategoride **gemini-3.1-flash-lite** |
| **Letterboxd Entegrasyonu** | ✅ Tamamlandı | Kamuya açık RSS'ten 50 film çekimi, doğrulanmış kamera arkası fun-fact kurgusu, telifsiz sinema rozeti |
| **Okuma Süresi (Cooldown)** | ✅ Tamamlandı | Metin uzunluğuna göre 15-25 sn akıllı bekleme, buton kilitleri ve canlı geri sayım sayacı |
| **Firebase Auth & Firestore**| ✅ Tamamlandı | Google Sign-In, Firestore sosyal gönderi paylaşımı, `firestore.rules` kuralları |
| **İçerik Moderasyonu** | ✅ Tamamlandı | Çift katmanlı koruma (`ContentModerationService` istemcide + `_BLOCKLIST_RE` backend sınırında) |
| **Otomasyon & Test** | ✅ Tamamlandı | Sweetpad eşdeğeri `launch-ios.sh` betiği ile fiziksel iPhone'a tek komutla kurulum |
| **Abonelik (StoreKit 2)** | 🔄 Sırada | App Store Connect ürün tanımları ve StoreKit 2 altyapısı entegre edilecek |

---

## 2. Canlı Altyapı Mimarisi

* **Cloud Run Servis URL:** `https://omakase-backend-20235796246.us-central1.run.app`
* **Otomatik Ölçekleme (Auto-scaling):** Minimum 0 instance (cold start optimize), maksimum 10 instance.
* **HTTPS & ATS:** Cloud Run varsayılan olarak geçerli Google SSL sertifikası sağlar. Bu sayede iOS `App Transport Security (ATS)` kurallarına tam uyumludur; herhangi bir `NSAllowsArbitraryLoads` veya HTTP istisnasına gerek duymaz.
* **SSE Desteği:** `X-Accel-Buffering: no` başlığı ile FastAPI ve Cloud Run üzerinden token tamponlaması olmadan canlı harf harf akış sağlanır.

---

## 3. Gemini 3.5 Flash Maliyet & Performans Analizi

### Neden Gemini 3.5 Flash?
Feed akışında en kritik metrik **"İlk Token Gecikmesi" (Time-to-First-Token - TTFT)** süresidir. `gemini-3.5-flash`:
1. Akıl yürütme (thinking) evresi gerektirmediği için istek atıldığı anda milisaniyeler içinde token üretmeye başlar.
2. Türkçe dil kabiliyeti ve yaratıcı mikro-format yazımı son derece güçlüdür.

### Maliyet Tahmini (Ortalama Post Başına)
* **Girdi Token (Prompt + Format Şablonu + Letterboxd Bağlamı):** ~300 - 500 token
* **Çıktı Token (40 - 90 Kelimelik Gönderi):** ~100 - 150 token
* **1.000 Post Maliyeti:** Yaklaşık **$0.05 - $0.08** (Cent seviyesinde son derece ekonomik).
* **Günlük 1.000 Aktif Kullanıcı (Kullanıcı başı 10 post):** Günlük maliyet ~$0.60 - $0.80 civarındadır.

---

## 4. App Store Review Kılavuzu Uyumluluğu

Apple App Store inceleme sürecinde en çok red alınan kategoriler ve Omakase'nin hazırlığı:

### A. Kural 1.2 — Kullanıcı Tarafından Oluşturulan İçerik ve AI Çıktıları
* **Zorunluluk:** AI tarafından üretilen veya kullanıcıların paylaştığı içeriklerde sakıncalı materyalin önlenmesi, şikayet (report) ve engelleme (block) mekanizması.
* **Omakase Uyumluluğu:**
  - `ContentModerationService`: İstemci tarafında küfür, şiddet, nefret söylemi ve NSFW anahtar kelimelerini filtreler.
  - Backend `_BLOCKLIST_RE`: API kapısında zararlı girdileri Gemini'ye ulaşmadan 400 Bad Request ile keser.
  - Gemini Safety Settings: Şiddet, nefret söylemi ve cinsel içerik filtreleri en katı bloklama seviyesindedir.
  - Sosyal Katmanda Bildir / Sil Butonu: Kullanıcılar uygunsuz sosyal gönderileri Firestore üzerinden anında bildirebilir.

### B. Kural 5.1.1 — Veri Toplama ve Gizlilik
* **Hesap Gereksinimi:** Uygulama genel feed deneyimi için zorunlu kayıt istemez; kullanıcı anonim olarak hemen akışı deneyimleyebilir. Sadece sosyal paylaşım için Google Sign-In kullanılır.
* **Hesap Silme:** Apple kılavuzuna uygun olarak Profil sekmesinde hesap silme (`authService.deleteAccount`) işlevi yer almalıdır.

### C. Kural 2.1 — Uygulama Tamlığı ve Hata Yönetimi
* Ağ bağlantısı koptuğunda `isOffline` durumu algılanarak çevrimdışı önbellek (`PostCacheService`) devreye girer.
* Okuma süresi sayacı (`readingCooldownRemaining`) kullanıcıya şık bir kum saati ve süre bildirimi sunarak arayüzün kilitlendiği hissini önler.

---

## 5. Letterboxd & Üçüncü Taraf Entegrasyon Uyumluluğu

1. **Marka İhlalinden Kaçınma:**
   - Letterboxd'nin resmi 3 renkli daire logosunu taklit eden tasarımlar kaldırılmış, yerine hukuken tamamen bağımsız neon yeşili sinema patlamış mısırı rozeti (`popcorn.fill`) yerleştirilmiştir.
   - Arayüzde açıkça *"Letterboxd hesabınızın herkese açık izleme günlüğü kullanılır"* ifadesi yer alır.
2. **Kimlik Doğrulama / Şifre Güvenliği:**
   - Letterboxd şifresi veya özel erişim token'ı istenmez. Sadece kullanıcının herkese açık kullanıcı adından üretilen kamuya açık RSS feed'i (`letterboxd.com/username/rss/`) okunur. Bu yaklaşım Apple'ın 3. parti veri güvenliği kriterlerine %100 uygundur.
3. **Halüsinasyon Önleme & Fun-Fact Doğruluğu:**
   - Prompt seviyesinde uydurma kamera arkası hikayeleri yasaklanmış, yalnızca doğrulanmış prodüksiyon anekdotlarına öncelik verilmiştir.

---

## 6. Güvenlik & İçerik Moderasyonu

* **API Anahtarları:** `GEMINI_API_KEY` kesinlikle iOS istemci kodunda yer almaz; Cloud Run ortam değişkenlerinde şifreli olarak tutulur.
* **Firestore Security Rules:** `firestore.rules` ile sadece kimliği doğrulanmış kullanıcıların kendi adlarına post oluşturmasına ve yetkisiz alanlara yazamamasına izin verilir.

---

## 7. Abonelik Modeli (StoreKit 2)

| Katman | Özellikler | Fiyat Önerisi |
|--------|------------|---------------|
| **Ücretsiz (Free)** | Günlük 25 dinamik post, Bento keşif motoru, Letterboxd entegrasyonu | Ücretsiz |
| **Omakase Pro** | Sınırsız post, Deep Dive, Spotify & Goodreads entegrasyonu (v2), reklamsız akış | ₺59.99/ay veya $2.99/ay |

---

## 8. Lansman Öncesi Yapılacaklar (Checklist)

- [x] Backend Cloud Run üzerinde canlıya alındı ve HTTPS doğrulandı.
- [x] BentoTasteBox ve Letterboxd 50 film entegrasyonu tamamlandı.
- [x] Okuma süresi (reading cooldown) ve scroll engeli mekanizması test edildi.
- [x] Sweetpad / `scripts/launch-ios.sh` ile fiziksel cihaz kurulumu otomatikleştirildi.
- [ ] 1024x1024 App Store uygulama ikonu (`AppIcon`) eklenecek.
- [ ] Gizlilik Politikası (Privacy Policy) ve EULA metinleri web sayfasına yüklenecek.
- [ ] App Store Connect kaydı açılıp TestFlight beta dağıtımı yapılacak.
