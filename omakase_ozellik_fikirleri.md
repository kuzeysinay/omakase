# 🍣 Omakase — Yeni Özellik Fikirleri

> Mevcut duruma göre önceliklendirilmiş, uygulanabilirlik ve kullanıcı değeri açısından derecelendirilmiş özellik haritası.

---

## Öncelik Skalası

| Emoji | Anlam | Açıklama |
|-------|-------|----------|
| 🔴 | Kritik | Retention ve monetizasyon için şart |
| 🟡 | Yüksek | Belirgin fark yaratır, erken fazda eklenebilir |
| 🟢 | Orta | Ürünü zenginleştirir, v2-v3'te eklenebilir |
| 🔵 | Vizyon | Uzun vadeli diferansiyasyon, büyük mühendislik gerektirir |

---

## 1. İçerik & Feed Deneyimi

### 🔴 Deep Dive Modu (Tamamlandı ✅)
Bir post'un altında **"Daha fazla anlat"** butonu → Gemini'ye aynı konu hakkında daha uzun, daha detaylı bir follow-up post ürettirir. Kullanıcı tavşan deliğine girmek istediğinde feed'den çıkmadan derinleşebilir.

**Neden önemli:** Engagement süresini 2-3x artırır. "Daha fazla" isteği doğal bir kullanıcı dürtüsü.

**Teknik:** Mevcut post'un text'ini context olarak yeni bir `/feed/stream` isteğine eklemek yeterli. Backend'de yeni bir prompt template.

---

### 🔴 Konu Bazlı Filtreleme
Feed'de tag'lere tıklayarak sadece o konudaki postları göster. Şu an tag'ler görsel olarak var ama filtreleme yok.

**Teknik:** Client-side filtreleme (mevcut `posts` array'ini tag'e göre filtrele) + backend'e `focus_tag` parametresi ekleyerek AI'ın sadece o konuya odaklanmasını sağla.

---

### 🟡 Post Kalite Oylaması (👍 / 👎)
Her post'ta basit like/dislike. Kullanıcı feedback'i:
- Sonraki postların prompt'una "kullanıcı bu tarz postları beğendi/beğenmedi" bilgisi eklenir
- Zamanla kişiselleştirilmiş feed kalitesi artar
- Backend'de basit bir preference score tutulabilir

**Pro tier farkı:** Free'de feedback verebilir ama kişiselleştirme sadece Pro'da aktif olur.

---

### 🟡 Günlük Özet / Digest
Sabah 09:00'da push notification: "Bugünün Omakase menüsü hazır 🍣" → Uygulama açılınca önceden üretilmiş 3-5 post bekliyor.

**Neden:** Kullanıcıyı günlük olarak geri getirir. Retention'ın en büyük itici gücü.

**Teknik:** 
- Backend'de bir cron job (Cloud Scheduler) → her kullanıcı için gece postları üret
- Firestore'da `daily_digest/{uid}/{date}` collection
- Push notification: Firebase Cloud Messaging (FCM)

---

### 🟢 Ses ile Dinleme
Post'ları TTS (Text-to-Speech) ile dinleyebilme. "Yürürken Omakase" deneyimi.

**Teknik:** Apple'ın yerleşik `AVSpeechSynthesizer`'ı (ücretsiz, offline) veya daha doğal sesler için Google Cloud TTS API ($4/1M karakter).

---

### 🟢 Post Formatı Çeşitliliği (Tamamlandı ✅)
Mevcut 7 format template'ine ek olarak:
- **"Debate"** — bir konunun iki tarafını kısaca sun
- **"Timeline"** — kronolojik bir mini-tarih (3-4 madde)
- **"Versus"** — iki şeyi karşılaştır (X vs Y)
- **"Mythbuster"** — yaygın bir yanılgıyı çürüt
- **"If You Like X, Try Y"** — çapraz keşif

---

### 🔵 Multimodal Postlar
Gemini'nin görsel üretim/analiz yetenekleriyle post'lara ilgili görseller ekle. Örneğin bir film hakkında post üretirken ilgili bir sahnenin açıklamasını veya AI-generated bir illüstrasyonu göster.

---

## 2. Sosyal & Topluluk

### 🔴 Reaction Sistemi (Tamamlandı ✅)
Shared post'lara emoji reaction (🤯 🔥 💡 😂 🎯). Like'tan daha zengin etkileşim.

**Teknik:** Firestore'da `shared_posts/{postId}/reactions/{uid}` subcollection.

---

### 🟡 Yorum / Tartışma (Tamamlandı ✅)
Shared post'ların altına kısa yorumlar. Karakter limiti 280 (tweet tarzı). Moderasyon için AI-based content filter.

**Dikkat:** Apple Review'da moderation araçları (report, block) zorunlu hale gelir. Önceki raporda zaten belirtildi.

---

### 🟡 Interest-Based Topluluklar
"Film severler", "Tarih meraklıları" gibi otomatik oluşan interest grupları. Kullanıcılar aynı interest'e sahip kişilerin paylaştığı postları keşfedebilir.

**Teknik:** `shared_posts` collection'ında `tags` field'ı zaten var → tag bazlı feed query'si yeterli.

---

### 🟢 Haftalık Leaderboard
En çok reaction alan paylaşımlar haftalık bir "Top Posts" sekmesinde gösterilir. Kullanıcıların paylaşım motivasyonunu artırır.

---

### 🟢 Arkadaş Önerileri
"Siz ve @kullanıcı 5 ortak interest'e sahipsiniz" — interest overlap'e dayalı kullanıcı önerisi.

**Teknik:** Firestore'da interest array karşılaştırması (client-side veya Cloud Function).

---

## 3. Kişiselleştirme & Öğrenme

### 🔴 Interest Ağırlıklandırma
Kullanıcı interest'lerini sıralayabilir veya "çok ilgileniyorum / biraz ilgileniyorum" şeklinde ağırlık verebilir. AI bu ağırlıklara göre post dağılımını ayarlar.

**Teknik:** `interests` array'i yerine `[{name: "Nolan", weight: 0.8}, ...]` yapısı. Prompt'a ağırlık bilgisi eklenir.

---

### 🟡 "Beni Şaşırt" Modu
Interest listesinin tamamen dışına çıkan, rastgele ama zeki öneriler. "Comfort zone'un dışına çık" butonu.

**Teknik:** Prompt'a "kullanıcının mevcut interest'leriyle hiçbir ilgisi olmayan ama zeki bir insan olarak sevebileceği bir konu seç" talimatı.

---

### 🟡 Okuma Geçmişi & "Tekrar Gösterme"
Daha önce görülen post'ların hash'ini tut → AI'a "bunları zaten gördü" bilgisi ver → tekrarlayan içerik üretimini önle.

**Teknik:** Şu an `seen_count` var ama içerik hash'i yok. Firestore'da `users/{uid}/seen_hashes` subcollection.

---

### 🟢 Mood-Based Feed
"Bugün ne ruh halindeyim?" seçici:
- 🧠 "Öğrenmek istiyorum" → bilgi yoğun postlar
- 😂 "Eğlenmek istiyorum" → cursed trivia, fun facts
- 🎯 "Odaklanmak istiyorum" → tek konuya deep dive
- 🎲 "Sürpriz yap" → rastgele format

**Teknik:** Seçilen mood'a göre `_POST_FORMATS` listesinden filtre veya özel prompt injection.

---

### 🔵 Uzun Vadeli Kullanıcı Profili (Memory)
Gemini'ye kullanıcının geçmiş beğenileri, tarzı hakkında özet bir "user persona" oluştur ve her istekte system prompt'a ekle. Zamanla "seni tanıyan" bir feed.

---

## 4. Utility & Pratik Değer

### 🟡 Paylaş (iOS Share Sheet) (Tamamlandı ✅)
Post'u Instagram Stories, Twitter, iMessage ile paylaş. Güzel formatlı bir kart görseli oluştur (SwiftUI → UIImage render).

**Neden:** Viral büyüme kanalı. Kullanıcılar ilginç bilgileri arkadaşlarıyla paylaşmak ister.

---

### 🟡 Koleksiyonlar (Tamamlandı ✅)
Bookmark'ları klasörlere ayır: "Film notları", "Tarih", "Yemek tarifleri". Şu an tek bir bookmark listesi var.

**Teknik:** Mevcut `BookmarkStore`'a `collectionName: String` field'ı ekle.

---

### 🟢 Quiz Modu
Görülen postlardan mini quiz oluştur: "Bu bilgi doğru mu yanlış mı?" veya "Hangi filmde bu sahne var?"

**Teknik:** Gemini'ye önceki postları context olarak ver → quiz formatında çıktı iste. Gamification elementi.

---

### 🟢 Widget (iOS Home Screen)
"Günün bilgisi" widget'ı — her gün bir yeni fun fact, home screen'den bakılabilir.

**Teknik:** WidgetKit + App Group ile shared data. Backend'den günlük 1 post çekip cache'le.

---

### 🟢 Apple Watch Companion
Kısa post'ları bilek üzerinden oku. Complication'da günlük fact sayısı.

---

### 🔵 AR Deneyimi
Post'taki bir yer/obje hakkında bilgi varken kamerayı aç → AR overlay ile ek bilgi göster. (Çok niş ama "wow" faktörü yüksek.)

---

## 5. Teknik & Altyapı Özellikleri

### 🔴 Offline Modu (Tamamlandı ✅)
Daha önce üretilen postları Firestore veya local cache'den göster. İnternet yokken bile feed'e bakılabilir.

**Teknik:** Core Data veya SwiftData ile local persistence. Mevcut `Post` modeli zaten `Codable`'a yakın.

---

### 🟡 Çoklu Dil Desteği Genişletmesi
Şu an EN + TR. Japonca, İspanyolca, Almanca, Korece ekle — global pazar.

**Teknik:** Backend'de `language` field'ı zaten var, yeni dil instruction'ları eklemek basit. UI lokalizasyonu (`L10n.swift`) genişletilmeli.

---

### 🟡 Analytics Dashboard (Kendin İçin)
Firebase Analytics + custom events ile:
- Günde kaç post üretiliyor?
- Hangi interest'ler en popüler?
- Ortalama session süresi?
- Free → Pro conversion funnel

---

### 🟢 AI Model A/B Testing
Farklı prompt template'lerini veya Gemini model versiyonlarını A/B test et. Hangi format daha çok beğeni alıyor?

---

## Önerilen Öncelik Sıralaması

### v1.1 (Lansman sonrası ilk güncelleme)
1. 🔴 Deep Dive modu
2. 🔴 Post kalite oylaması (👍/👎)
3. 🔴 Reaction sistemi
4. 🔴 Offline modu
5. 🟡 iOS Share Sheet

### v1.2
6. 🟡 Günlük Digest + Push Notification
7. 🟡 Koleksiyonlar
8. 🟡 "Beni Şaşırt" modu
9. 🟡 Konu bazlı filtreleme

### v2.0
10. 🟡 Yorum sistemi
11. 🟡 Interest-based topluluklar
12. 🟢 Quiz modu
13. 🟢 Mood-based feed
14. 🟢 iOS Widget

### Uzun Vade
15. 🔵 Kullanıcı memory/persona
16. 🔵 Multimodal postlar
17. 🟢 Apple Watch
18. 🟢 Çoklu dil genişletmesi
