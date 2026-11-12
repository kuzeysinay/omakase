# 🍣 Omakase — Özellik Haritası & Yeni Fikirler

> **Son Güncelleme:** 12 Kasım 2026  
> **Kapsam:** iOS istemcisi (`omakase/`), FastAPI backend (`backend/`) ve Web platformu (`web/`) üzerinde hayata geçirilen güncel özelliklerin durumu ve önceliklendirilmiş v2 / v3 ürün yol haritası.

---

## Öncelik Skalası

| Rozet | Anlam | Açıklama |
|-------|-------|----------|
| ✅ | **Tamamlandı** | Canlı kod tabanında aktif ve test edilmiş özellikler |
| 🔴 | **Kritik (v1.0 App Store)** | App Store yayını öncesi tamamlanacak uyumluluk adımları |
| 🟠 | **Yüksek (v2.0)** | Kullanıcı bağlılığı (retention) ve kültürel derinlik için ilk sırada yapılacaklar |
| 🟡 | **Orta (v2.1)** | Kullanıcı deneyimini zenginleştiren çoklu ortam ve bildirim adımları |
| 🟢 | **Büyüme (v2.5)** | Ürünü parlatan ve sosyal viraliteyi artıran eklentiler |

---

## 1. Tamamlanan Temel Özellikler ✅

Aşağıdaki sistemler başarıyla geliştirilmiş, test edilmiş ve ana mimariye dahil edilmiştir:

### ✅ 1. Bento Keşif Motoru (`BentoTasteBox`)
* **12 Ana Kültür Kategorisi:** Yatay kaydırmalı (horizontal scroll) kompakt kapsül barı (*Sinema, Bilim, Felsefe, Sanat, Teknoloji, Tarih, Müzik, Edebiyat, Psikoloji, Mimari, Gastronomi, Uzay*).
* **Kompakt 6'lı Alt Konu Izgarası:** Seçilen kategoride 2 sütunlu, sıkılaştırılmış 6 alt konu karosu (`prefix(6)`).
* **Akıllı Kategori Önbelleği & Manuel Yenileme:** Kategoriler arası geçiş yaparken mevcut alt konuları koruyan ve yalnızca kullanıcı yenile (`arrow.clockwise`) butonuna bastığında Gemini 3.1 Flash-Lite ile yeni alt konular üreten sürtünmesiz deneyim.
* **Özel Konu Girişi (Custom Topic Input):** Kullanıcının kendi merak ettiği spesifik bir başlığı doğrudan yazıp şefe sipariş verebilmesi.
* **Tam Ekran ve Sayfa Sonu Uyumu:** Gönderi yokken tam ekran açılan, gönderi üretildiğinde ise dikey sayfalama akışının en altında (`id: -1`) tam ekran yüksekliğinde (`containerRelativeFrame(.vertical)`) taşma yapmadan konumlanan temiz mimari.

### ✅ 2. Sürtünmesiz Kayıt, `@kullanıcı_adı` ve Kimlik Doğrulama (`AuthView` & `AuthService`)
* **Twitter/X Tarzı 3 Adımlı Kayıt Akışı:**
  1. **Görünür İsim (`displayName`):** Canlı profil önizleme kartı ile anlık görsel geri bildirim.
  2. **Benzersiz `@kullanıcı_adı` (`@username`):** Firestore üzerinden gerçek zamanlı müsaitlik kontrolü (350ms debounce), otomatik kullanıcı adı öneri kapsülleri ve karakter doğrulaması (`a-z, 0-9, _`).
  3. **E-posta & Şifre:** Şifre güç göstergesi ile güvenli hesap tamamlama.
* **Google Sign-In & E-posta Girişi:** Tek dokunuşla Google hesabı veya mevcut e-posta/şifre ile oturum açma.

### ✅ 3. Topluluk Akışı, Arama ve Sosyal Etkileşim (`TimelineView`)
* **Topluluk Sekmesi (`Community`):** Kullanıcıların beğendikleri şef yazılarını tek dokunuşla kendi `@kullanıcı_adı` profilleri üzerinden paylaştıkları sosyal akış.
* **Entegre Arama Çubuğu & Kişi Arama (`UserSearchView`):** Gönderi başlığı, içerik, kategori, yazar ismi veya `@username` üzerinden anlık filtreleme ve okur keşfi.
* **İfadeler (Reactions) & Yorumlar (`CommentsView`):** Gönderilere 5 farklı ifade (`🔥, 🧠, ❤️, 👏, 🤯`) bırakma, gerçek zamanlı yorumlaşma ve kullanıcı takip sistemi (`followUser` / `unfollowUser`).
* **Çevrimdışı Yer İmleri (`BookmarkStore`):** Beğenilen mikro-hikayeleri cihazda yerel olarak kaydetme ve okuma.

### ✅ 4. Letterboxd Entegrasyonu & Doğrulanmış Sinema Anekdotları
* **50 Film RSS Beslemesi:** Kullanıcının Letterboxd günlüğünden son 50 filmi tek seferde çekme (`LetterboxdService`).
* **Rastgele Çeşitlilik Kilidi:** Python seviyesinde rastgele film seçimi (`random.choice`) ile her seferinde farklı bir film üzerinden üretim.
* **Halüsinasyon Önleyici Prompt Çerçevesi:** Kurgusal uydurmaları engelleyen, doğrulanmış prodüksiyon ve kamera arkası kayıtlarına odaklanan sıkı sistem yönergeleri.

### ✅ 5. Okuma Süresi & Doomscrolling Karşıtı Kilit Sistemi (Reading Cooldown)
* **Dinamik Süre Hesabı:** Post metninin kelime sayısına göre 15–25 saniye arasında akıllı sindirme süresi.
* **Canlı Kum Saati & Scroll Koruması:** Süre dolana kadar yeni post üretimini ve kategori butonlarını kilitleyen, animasyonlu kum saati (`hourglass`) ile geri sayım yapan odaklanma mekanizması.

### ✅ 6. Reels Tarzı Dikey Akış, Deep Dive Modal & Monokrom Tema (`OmakaseTheme`)
* **Tam Ekran Dikey Sayfalama:** `.scrollTargetBehavior(.viewAligned)` ile pürüzsüz geçiş ve SSE (Server-Sent Events) ile gerçek zamanlı metin akışı.
* **Deep Dive Bottom Sheet Modal (`DeepDiveSheetView`):** Bir konunun derinliklerine inmek istendiğinde satır içi (inline) karmaşa yaratmadan açılan, kendi SSE akışına sahip özel okuma penceresi.
* **Mürekkep ve Kağıt Estetiği (`OmakaseTheme`):** Karanlık, Aydınlık ve Sistem görünüm modlarını destekleyen monokrom tasarım dili ve çift dil (`TR` / `EN` — `L10n.swift`) desteği.

### ✅ 7. İnteraktif Web Platformu (`web/` — `getomakase.app`)
* **Canlı Tadım Simülatörü:** Web ziyaretçilerinin iOS uygulamasındaki kategori seçimi, daktilo akışı, Deep Dive modalı ve okuma sayacını tarayıcıda deneyimleyebildiği interaktif önizleme.
* **Çoklu Dağıtım Altyapısı:** Hem Cloudflare (`wrangler.json` — `getomakase`) hem de Firebase Hosting (`firebase.json`) ile statik dağıtım ve TestFlight bekleme listesi.

### ✅ 8. Çift Modlu Geliştirici Otomasyonu (`scripts/`)
* [`scripts/launch-ios.sh`](file:///Users/kuzey/projects/omakase/scripts/launch-ios.sh): Fiziksel iPhone'a (`ADFC2ADA-EA3F-51A7-9C82-E2554869B97D`) tek komutla derleme, kurma ve başlatma.
* [`scripts/launch-simulator.sh`](file:///Users/kuzey/projects/omakase/scripts/launch-simulator.sh): iOS Simulator (`iPhone 17`) üzerinde otomatik derleme ve başlatma.
* [`.agents/`](file:///Users/kuzey/projects/omakase/.agents): Apple Agent Kit (v2.5.1) mimari, tasarım ve App Store denetim sözleşmeleri.

---

## 2. Sıradaki Adımlar ve Gelecek Yol Haritası

### 🔴 v1.0 App Store Yayın Tamamlaması (Öncelik 1)
[`docs/appstore_raporu.md`](file:///Users/kuzey/projects/omakase/docs/appstore_raporu.md) denetiminde belirlenen yayın öncesi zorunlu adımlar:
1. `omakase/omakase/PrivacyInfo.xcprivacy` dosyasının eklenmesi (`CA92.1` + toplanan veri beyanları).
2. **Sign in with Apple** entegrasyonu (Guideline 4.8).
3. Uygulama içi **Hesap Silme (`deleteAccount`)** özelliği (Guideline 5.1.1v).
4. **Kullanıcı Engelleme (`blockUser`)**, **Gönderi Bildirme (`reportPost`)** ve yorum/kullanıcı adı moderasyon filtresi (Guideline 1.2).
5. `MyProfileSheet` içine **Destek / İletişim**, **Gizlilik Politikası** ve **Kullanım Koşulları** bağlantılarının eklenmesi + `firestore.rules` yetkilendirme sıkılaştırması.

---

### 🟠 Spotify "Recently Played" Entegrasyonu (v2.0)
Letterboxd entegrasyonunun sinema alanında yarattığı kişisel deneyimi müzik kategorisine taşıma:
* **Deneyim:** Kullanıcının son dinlediği şarkı/albüm üzerinden kayıt hikayesi, kullanılan sample'ın kökeni veya prodüksiyon anekdotları üretilir.
* **Teknik:** Spotify Web API (`Recently Played Tracks` endpoint'i).

---

### 🟡 Sesli Dinleme / Yürüyüş Modu (TTS — v2.1)
* **Deneyim:** Kullanıcı yürürken veya toplu taşımadayken şef yazılarını kulaklıkla dinleyebilir.
* **Teknik:** Faz 1'de yerel `AVSpeechSynthesizer`, Faz 2'de doğal bulut tabanlı seslendirme.

---

### 🟡 Günlük Sabah Şef Menüsü (Daily Digest Notification — v2.1)
* **Deneyim:** Her sabah belirlenen saatte kullanıcının seçili ilgi alanlarına göre taze demlenmiş 3 mikro-hikaye bildirimle sunulur.
* **Teknik:** `UserNotifications` + Firebase Cloud Messaging (FCM).

---

### 🟢 Instagram & X İçin Tipografik Hikaye Kartı Export (v2.5)
* **Deneyim:** Beğenilen bir postu tek dokunuşla 9:16 oranında monokrom kağıt/mürekkep estetiğinde görsel karta dönüştürüp sosyal medyada paylaşma.
* **Teknik:** SwiftUI `ImageRenderer` API'si.

---

### 🟢 Goodreads / Kitap Günlüğü Entegrasyonu (v2.5)
* Kullanıcının okuduğu kitapların RSS beslemesi üzerinden yazarın biyografik arka planı ve eserin tarihsel bağlamı üzerine mikro-hikaye üretimi.
