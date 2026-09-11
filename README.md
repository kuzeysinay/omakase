# 🍣 Omakase

> **Kişisel Yapay Zeka Kültür & Bilgi Akışı**  
> Kullanıcının ilgi alanlarını ve Letterboxd izleme günlüğünü gerçek zamanlı olarak derinlikli, doğrulanmış mikro-hikayelere dönüştüren yerel iOS ve Cloud Run uygulaması.

---

```
┌─────────────────────────────────────────────────────────────┐
│                    SwiftUI iOS Client                       │
│  - iOS 17+ • Reels Tarzı Tam Ekran Dikey Akış              │
│  - BentoTasteBox (2048 Tarzı Dokunsal Keşif Izgarası)       │
│  - Letterboxd RSS Entegrasyonu (Son 50 Film + Fun-Fact)     │
│  - Okuma Süresi Sayacı (Reading Cooldown & Scroll Kilidi)   │
└──────────────┬───────────────────────────────┬──────────────┘
               │                               │
               │ HTTPS Server-Sent Events      │ Firebase SDK
               │ POST /feed/stream             │ (Google Sign-In + Firestore)
               ▼                               ▼
┌──────────────────────────────┐       ┌──────────────────────┐
│  Google Cloud Run (Canlı)    │       │  Google Firebase     │
│  FastAPI Backend             │       │  - Firebase Auth     │
│  - Çift Katmanlı Moderasyon  │       │  - Cloud Firestore   │
│  - Server-Sent Events (SSE)  │       │  - firestore.rules   │
└──────────────┬───────────────┘       └──────────────────────┘
               │
               │ google-genai SDK
               ▼
┌──────────────────────────────┐
│   Google Gemini API          │
│   - gemini-3.5-flash (Feed)  │
│   - gemini-3.1-flash-lite    │
└──────────────────────────────┘
```

---

## 🚀 Öne Çıkan Özellikler

* **🍱 BentoTasteBox (2048 Tarzı Keşif Izgarası):**
  Altı ana kategori (Film, Bilim, Felsefe, Edebiyat vb.), dokunsal 3D kart çevirme ("Döndür") ve her kategoriye tıklandığında **Gemini 3.1 Flash-Lite** ile anında türetilen 10 dinamik alt konu karosu.
* **🎬 Letterboxd Entegrasyonu:**
  Kullanıcının Letterboxd günlüğünden son 50 filmi tek seferde çeker. Python seviyesinde rastgele hedef film kilidiyle (`random.choice`) çeşitliliği garanti eder ve doğrulanmış kamera arkası prodüksiyon anekdotlarına öncelik verir.
* **⏳ Okuma Süresi & Doomscrolling Koruması (Reading Cooldown):**
  Metin uzunluğuna göre 15 - 25 saniye akıllı sindirme süresi uygular. Bu sürede normal scroll ve butonlar kilitlenir; son kartta animasyonlu bir kum saati canlı geri sayım yapar.
* **📱 Reels Tarzı Tam Ekran Dikey Akış:**
  Instagram Reels formatında sayfalama (`.viewAligned`). SSE üzerinden gelen kelimeler daktilo efektiyle anlık olarak ekrana akar.
* **🐇 Deep Dive (Tavşan Deliği):**
  Bir konuyu daha derin öğrenmek istediğinizde tek tıkla o konuya özel uzun follow-up gönderisi üretir.
* **👥 Sosyal & Yer İmleri:**
  Google Sign-In ile profil oluşturma, beğenilen şef postlarını Firestore timeline'ında toplulukla paylaşma ve çevrimdışı yer imleme (`BookmarkStore`).

---

## 📂 Proje Dizin Yapısı

```
omakase/
├── .agents/                 # Antigravity kural ve yetenek tanımları
│   └── rules/sweetpad-launch.md
├── .vscode/                 # IDE ayarları ve derleme görevleri (Cmd+Shift+B)
│   └── tasks.json
├── backend/                 # FastAPI & Google GenAI mikroservisi
│   ├── Dockerfile           # Cloud Run deployment konteyneri
│   ├── main.py              # SSE stream ve Letterboxd endpoint'leri
│   └── requirements.txt
├── docs/                    # Detaylı mimari, strateji ve hukuk raporları
│   ├── appstore_raporu.md   # App Store prodüksiyon ve review kılavuzu
│   ├── fikri_mulkiyet.md    # Marka, telif ve Letterboxd adil kullanım raporu
│   ├── gelecek_stratejisi.md# Moat, büyüme ve kültürel entegrasyon vizyonu
│   ├── ozellik_fikirleri.md # Tamamlananlar ve v2/v3 özellik yol haritası
│   └── xcode_konfigurasyon.md # Xcode derleme ve ATS ayarları raporu
├── omakase/                 # SwiftUI iOS projesi
│   ├── omakase.xcodeproj    # Xcode proje paketi
│   └── omakase/             # Swift kaynak kodları
│       ├── Feed/            # ReelsPostCard, FeedView, FeedViewModel
│       ├── Interests/       # BentoTasteBox, InterestCategory
│       ├── Networking/      # SSEClient, LetterboxdService
│       ├── Social/          # TimelineView, TimelinePostCard
│       └── Services/        # ContentModerationService, PostCacheService
├── scripts/
│   └── launch-ios.sh        # Fiziksel iPhone'a otomatik derleme & başlatma betiği
├── firestore.rules          # Firestore güvenlik kuralları
├── GEMINI.md                # Çalışma alanı geliştirici kuralları
└── README.md
```

---

## 🛠️ Hızlı Başlangıç

### 1. iOS Uygulamasını Fiziksel Cihazda Çalıştırma (Sweetpad / Script)

Uygulama, bağlı olan iPhone'unuzu otomatik tespit edip derleyen ve açan özel bir betikle donatılmıştır:

```bash
# Terminalden:
./scripts/launch-ios.sh

# Veya IDE içerisinden:
# Cmd + Shift + B kısayolu ile doğrudan çalıştırabilirsiniz.
```

### 2. Canlı Backend Bilgisi

Backend Google Cloud Run üzerinde canlı yayındadır:
* **Canlı URL:** `https://omakase-backend-20235796246.us-central1.run.app`
* **Sağlık Kontrolü:** `curl https://omakase-backend-20235796246.us-central1.run.app/health`

İstemci varsayılan olarak bu canlı servise bağlanır. Dilerseniz lokal olarak çalıştırmak için:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

## 📚 Kapsamlı Dokümantasyon Dizini

Detaylı rapor ve analizler için `docs/` klasörünü inceleyebilirsiniz:

| Doküman | Açıklama |
|---------|----------|
| [📄 App Store Raporu](docs/appstore_raporu.md) | Canlı Cloud Run mimarisi, Gemini 3.5 Flash maliyeti, Apple Review uyumluluğu ve StoreKit 2. |
| [⚖️ Fikri Mülkiyet Raporu](docs/fikri_mulkiyet.md) | Letterboxd RSS kullanımının hukuki boyutu, marka koruması ve prompt ticari sırları. |
| [🔮 Gelecek Stratejisi](docs/gelecek_stratejisi.md) | Moat analizi, doomscrolling karşıtı doyum psikolojisi ve Spotify/Goodreads vizyonu. |
| [💡 Özellik Haritası](docs/ozellik_fikirleri.md) | Tamamlanan 7 temel sistem ve v2/v3 önceliklendirilmiş özellik havuzu. |
| [🔧 Xcode Konfigürasyon Raporu](docs/xcode_konfigurasyon.md) | ATS yönetimi, Release build hazırlığı ve launch otomasyonu. |
