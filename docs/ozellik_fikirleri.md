# 🍣 Omakase — Özellik Haritası & Yeni Fikirler

> **Son Güncelleme:** 11 Eylül 2026  
> **Kapsam:** Hayata geçirilen özelliklerin güncel durumu, önceliklendirilmiş v2 ve v3 ürün yol haritası.

---

## Öncelik Skalası

| Rozet | Anlam | Açıklama |
|-------|-------|----------|
| ✅ | **Tamamlandı** | Canlı kod tabanında aktif ve test edilmiş özellikler |
| 🔴 | **Kritik (v2.0)** | Kullanıcı retention'ı ve derinlik için ilk sırada yapılacaklar |
| 🟡 | **Yüksek (v2.1)** | Kullanıcı deneyimini belirgin şekilde zenginleştiren adımlar |
| 🟢 | **Orta (v2.5)** | Ürünü parlatan ve sosyal viraliteyi artıran eklentiler |
| 🔵 | **Vizyon (v3.0)** | Uzun vadeli çoklu ortam ve büyük altyapı adımları |

---

## 1. Tamamlanan Temel Özellikler ✅

Aşağıdaki özellikler başarıyla geliştirilmiş, test edilmiş ve ana mimariye dahil edilmiştir:

### ✅ 1. Bento Keşif Motoru (BentoTasteBox)
* **2048 Tarzı Dokunsal Izgara:** 6 ana kategori (Film, Bilim, Felsefe, Sanat, Teknoloji, Edebiyat vb.).
* **Dinamik Kategori Çevirme (Roll):** 3D kart çevirme animasyonu ile 6 yeni kategoriyi anında masaya getirme.
* **AI Destekli Kategori Genişletme:** Bir kategoriye dokunulduğunda Gemini 3.1 Flash-Lite ile anında o alana özel 10 mikro-konu üretimi.
* **Tek Dokunuşla Post:** Alt konulardan birine dokunulduğunda akışta doğrudan o konuya kilitlenmiş gönderi üretimi.

### ✅ 2. Letterboxd Entegrasyonu & Kültürel Post Motoru
* **50 Film RSS Beslemesi:** Kullanıcının Letterboxd günlüğünden son 50 filmi tek seferde çekme.
* **Rastgele Çeşitlilik Kilidi:** Gemini'nin hep aynı filme takılmasını önleyen Python seviyesinde rastgele film seçimi (`random.choice`).
* **Doğrulanmış Kamera Arkası (Fun-Fact) Önceliği:** Halüsinasyonu sıfırlayan, gerçek prodüksiyon anekdotlarını öne çıkaran prompt mimarisi.
* **Özgün Marka Arayüzü:** Resmi logoyu taklit etmeyen telifsiz neon yeşili sinema rozeti tasarımı.

### ✅ 3. Okuma Süresi & Doomscrolling Karşıtı Kilit Sistemi
* **Dinamik Süre Hesabı:** Post metninin kelime sayısına göre 15 - 25 saniye arasında akıllı bekleme süresi.
* **Normal Scroll Koruması:** Kullanıcı aşağı kaydırsa dahi okuma süresi dolana kadar yeni post üretimini bloke eden koruma.
* **Canlı Kum Saati Sayacı:** Son kartta ve Bento başlığında kalan saniyeyi gösteren animasyonlu geri sayım.
* **Bento Buton Kilitleri:** Okuma süresi bitene kadar tüm kategori ve konu butonlarının devre dışı bırakılması.

### ✅ 4. Reels Tarzı Tam Ekran Dikey Akış
* Instagram Reels / TikTok formatında tek ekranda tek post gösteren pürüzsüz sayfalama (`.scrollTargetBehavior(.viewAligned)`).
* Harf harf gerçek zamanlı daktilo efekti sağlayan SSE (Server-Sent Events) istemcisi.

### ✅ 5. Deep Dive Modu
* Post altındaki butona basıldığında mevcut konunun tavşan deliğine inen, daha derin bir follow-up gönderi üretimi.

### ✅ 6. Zengin Post Formatları
* `DEBATE`, `TIMELINE`, `VERSUS`, `LETTERBOXD DIARY`, `MYTHBUSTER`, `ANECDOTE`, `IF YOU LIKE X TRY Y`.

### ✅ 7. Geliştirici Otomasyonu (Sweetpad Eşdeğeri Launch)
* `scripts/launch-ios.sh` betiği ile fiziksel iPhone'a (`ADFC2ADA-EA3F-51A7-9C82-E2554869B97D`) tek komutla derleme, kurma ve başlatma.
* `.agents/rules/sweetpad-launch.md` ve `.vscode/tasks.json` (`Cmd + Shift + B`) entegrasyonu.

---

## 2. Gelecek Özellikler Yol Haritası (v2 & v3)

### 🔴 Spotify "Recently Played" Bento Kutusu (v2.0)
Letterboxd'nin sinemada yarattığı büyüyü müzik alanına taşıma:
* **Nasıl Çalışacak?** Bento kutusunda Film kategorisindeki Letterboxd gibi, Müzik kategorisinde en başta kalıcı bir **Spotify Kutusu** yer alacak.
* **İçerik:** Kullanıcının son dinlediği şarkı/albüm üzerinden şarkının kayıt hikayesi, kullanılan sample'ın kökeni veya prodüktörün gizli kalmış bir kararı anlatılacak.
* **Teknik:** Spotify Web API (Recently Played Tracks endpoint'i).

---

### 🟡 Sesli Dinleme / Yürüyüş Modu (TTS - v2.1)
* **Ne Sağlar?** Kullanıcı yürürken veya spor yaparken postları ekrana bakmadan kulaklıkla dinleyebilir.
* **Teknik:**
  - Faz 1: Apple'ın yerel `AVSpeechSynthesizer` motoru (sıfır maliyet, tamamen çevrimdışı çalışır).
  - Faz 2: Google Cloud Text-to-Speech API ile stüdyo kalitesinde ultra-doğal Türkçe/İngilizce sesler.

---

### 🟡 Günlük Sabah Şef Menüsü (Daily Digest Notification - v2.1)
* **Ne Sağlar?** Her sabah saat 08:30'da push bildirim: *"Günün Omakase menüsü hazır 🍣"*.
* **Deneyim:** Kullanıcı uygulamayı açtığında beklemeden o günün aktif ilgi alanlarına göre arka planda taze hazırlanmış 3 post hazır bekler.
* **Teknik:** Firebase Cloud Messaging (FCM) + Cloud Scheduler cron tetiklemesi.

---

### 🟢 Instagram & X İçin Hikaye Kartı Export (v2.5)
* **Ne Sağlar?** Beğenilen bir postu tek dokunuşla 9:16 oranında tipografik bir görsel olarak Instagram Story veya X'e aktarma.
* **Teknik:** SwiftUI `ImageRenderer` API'si ile vektörel ekran görüntüsü render edilip sistem paylaşım sayfasına (UIActivityViewController) iletilecek.
* **Büyüme Etkisi:** Organik kullanıcı ediniminde en yüksek dönüşüm sağlayan mekanizma.

---

### 🟢 Goodreads / Kitap Entegrasyonu (v2.5)
* Kullanıcının son okuduğu kitaplar üzerinden yazarın biyografisinden bilinmeyen bir detay veya kitabın yazılış felsefesi üzerine post üretimi.

---

### 🔵 Çok Modlu (Multimodal) Görsel Analiz (v3.0)
* Gemini multimodal yetenekleri kullanılarak post metinlerine ek olarak arşiv fotoğrafları, sahne analizleri veya AI üretimi görsel illüstrasyonların dahil edilmesi.
