# Letterboxd Entegrasyonu — Hukuki, Teknik ve Stratejik Risk Analiz Raporu

**Tarih:** 15 Haziran 2026  
**Hazırlayan:** Omakase Geliştirme Ekibi  
**Konu:** Letterboxd verilerinin Omakase uygulamasına entegrasyonunda karşılaşılabilecek hukuki, teknik ve stratejik riskler

---

## 1. Letterboxd Logosu Kullanımı — Ticari Marka Riskleri

### 1.1 Durum Analizi

Letterboxd logosu (hem wordmark hem de ikon) **tescilli bir ticari markadır** ve Letterboxd Limited şirketine aittir. Ticari markaların izinsiz kullanımı birçok yargı bölgesinde hukuki sonuçlar doğurabilir.

### 1.2 Riskler

| Risk | Seviye | Açıklama |
|------|--------|----------|
| **Ticari marka ihlali** | 🔴 Yüksek | Letterboxd logosunun uygulamada, özellikle bir toggle butonunda kullanılması, Letterboxd ile resmi bir ortaklık veya onay ilişkisi izlenimi yaratabilir. Bu durum "passing off" veya "trademark dilution" olarak değerlendirilebilir. |
| **Aldatıcı ticari uygulama** | 🟡 Orta | Kullanıcılar, Letterboxd logosunu gördüklerinde Letterboxd'un bu entegrasyonu onayladığını düşünebilir. Bu, tüketiciyi yanıltma kapsamında değerlendirilebilir. |
| **App Store reddi** | 🟡 Orta | Apple'ın App Store Review Guidelines 5.2.5 maddesi, üçüncü taraf ticari markalarının izinsiz kullanımını yasaklar. Logo kullanımı, uygulama inceleme sürecinde red sebebi olabilir. |
| **Cease & Desist mektubu** | 🟡 Orta | Letterboxd'un hukuk ekibi, logonun izinsiz kullanımını tespit ederse bir ihtarname gönderebilir. Bu durumda logo derhal kaldırılmalıdır. |

### 1.3 Öneriler

1. **Logo kullanmayın.** Bunun yerine:
   - SF Symbol `film.fill` veya `popcorn.fill` ikonu kullanın
   - "Letterboxd" kelimesini düz metin olarak yazın (nominatif/tanımlayıcı kullanım genellikle korunur)
   - Letterboxd'un marka renklerini (yeşil/turuncu gradyan) taklit etmeyin
   
2. **"Powered by Letterboxd" veya "Official Letterboxd Partner" gibi ifadeler kullanmayın.**

3. **Resmi izin almak isterseniz:** Letterboxd'un developer ilişkileri ekibiyle iletişime geçin (hello@letterboxd.com). Ancak küçük/bağımsız projeler için onay alma ihtimali düşüktür.

---

## 2. RSS Feed Scraping — Hukuki ve Teknik Riskler

### 2.1 Hukuki Boyut

| Risk | Seviye | Açıklama |
|------|--------|----------|
| **Terms of Service ihlali** | 🟡 Orta | Letterboxd'un [Terms of Use](https://letterboxd.com/legal/terms-of-use/) belgesi, site içeriğinin otomatik araçlarla toplanmasını kısıtlayan maddeler içerebilir. RSS feed'leri genellikle bu kısıtlamaların dışında tutulsa da, ticari amaçlı toplu erişim sınırda bir alan. |
| **CFAA / Bilgisayar Korsanlığı yasaları** | 🟢 Düşük | RSS feed'leri zaten public olarak sunuluyor ve authentication gerektirmiyor. Kullanıcı kendi verisine kendi username'i ile erişiyor. Bu genellikle "unauthorized access" kapsamına girmez. |
| **GDPR / Kişisel veri** | 🟡 Orta | Kullanıcı kendi Letterboxd verisini sağlıyor (opt-in). Ancak RSS feed'den alınan veriler (izleme geçmişi, puanlar) kişisel veri niteliği taşır. Bu verilerin nasıl saklandığı ve işlendiği KVKK/GDPR kapsamında değerlendirilebilir. |

### 2.2 Teknik Riskler

| Risk | Seviye | Açıklama |
|------|--------|----------|
| **Rate limiting / IP ban** | 🟡 Orta | Letterboxd sunucuları, aynı IP'den gelen çok sayıda istek nedeniyle rate limit uygulayabilir veya IP'yi engelleyebilir. Özellikle backend'in tek bir sunucudan istek attığı durumlarda bu risk artar. |
| **RSS format değişikliği** | 🟡 Orta | Letterboxd, RSS feed formatını herhangi bir anda değiştirebilir. XML namespace'leri, alan isimleri veya yapısı değişebilir ve parser'ınız bozulabilir. |
| **RSS feed'in kaldırılması** | 🟢 Düşük | Letterboxd, RSS desteğini tamamen kaldırabilir. Bu durumda tüm feature çalışmaz hale gelir. Ancak RSS, Letterboxd topluluğu tarafından yaygın kullanıldığından kısa vadede düşük bir olasılık. |
| **Yanlış/geçersiz username** | 🟡 Orta | Kullanıcı yanlış bir username girerse, Letterboxd 404 döner. Bu graceful handle edilmeli. Ayrıca private profiller RSS feed'e erişime izin vermeyebilir. |

### 2.3 Öneriler

1. **Caching uygulayın:** Aynı kullanıcının filmlerini her istek yerine belirli aralıklarla cache'leyin (ör. 30 dakika TTL).
2. **User-Agent header'ı ekleyin:** İsteklerde tanımlayıcı bir User-Agent kullanın (ör. `Omakase/1.0 (https://omakase.app)`).
3. **Hata yönetimi:** 404 (kullanıcı bulunamadı), 429 (rate limit), 403 (erişim engeli) gibi durumları düzgün handle edin.
4. **Kullanıcı onayı:** Feature opt-in olduğu için GDPR açısından makul bir konumdasınız, ancak uygulama içi gizlilik politikasında bu veri kullanımını açıklayın.

---

## 3. Letterboxd API Alternatifi

### 3.1 Resmi API

Letterboxd'un **resmi bir API'si** vardır, ancak erişim **davet/başvuru bazlıdır** (API key gerektirir). Avantajları:
- Yapılandırılmış JSON yanıtları
- Daha güvenilir ve stabil
- ToS ile uyumlu
- Rate limit konusunda şeffaflık

**Dezavantajları:**
- Erişim almak zor olabilir (özellikle küçük projeler için)
- API key yönetimi gerektirir

### 3.2 Öneri

Şu an RSS yaklaşımıyla başlayın (daha hızlı prototype). Uygulama büyürse veya Letterboxd'dan bir ihtarname gelirse, resmi API'ye geçiş planı hazırlayın.

---

## 4. Telif Hakları — Film Verileri

### 4.1 Film Başlıkları ve Meta Verileri

Film başlıkları, yapım yılları ve genel bilgiler genellikle **telif hakkı koruması altında değildir** (factual information). Bunları post üretiminde context olarak kullanmak hukuki açıdan düşük risklidir.

### 4.2 Film Posterleri

Letterboxd RSS feed'inde poster URL'leri (`a.ltrbxd.com` domain'inden) bulunur. Bu posterlerin:
- Doğrudan embed edilmesi veya gösterilmesi **telif hakkı ihlali** oluşturabilir
- Hotlink yapılması Letterboxd'un bant genişliğini tüketir ve ToS ihlali olabilir

**Öneri:** Film posterlerini Omakase'de göstermeyin. Sadece film adı, yıl ve puan bilgilerini kullanın.

### 4.3 Kullanıcı Yorumları

RSS feed'deki kullanıcı yorumları (ör. "iyi ki tek çocuğum") o kullanıcının kendi içeriğidir. Kullanıcı kendi username'ini verdiğinden, kendi yorumlarına erişmektedir — bu genellikle sorun yaratmaz.

---

## 5. App Store Politikaları

| Madde | Risk | Açıklama |
|-------|------|----------|
| **5.2.5 — Third-Party Trademarks** | 🟡 Orta | İzinsiz logo kullanımı red sebebi |
| **5.1.1 — Data Collection** | 🟢 Düşük | Kullanıcı kendi bilgisini opt-in sağlıyor |
| **2.5.1 — API Usage** | 🟢 Düşük | Public RSS feed, undocumented API değil |
| **4.0 — Design** | 🟢 Düşük | Feature iyi tasarlandığında sorun yok |

---

## 6. Rakip Uygulama Analizi

Birçok uygulama Letterboxd RSS feed'ini benzer şekilde kullanır:
- **Sofa** (iOS) — Letterboxd import (RSS bazlı)
- **Sequel** — Letterboxd listelerini import eder
- **Widgetsmith** — Letterboxd widget'ı

Bu uygulamaların App Store'da sorunsuz yayında olması, RSS tabanlı entegrasyonun genel olarak kabul gördüğüne işaret eder. Ancak hiçbiri Letterboxd logosunu doğrudan kullanmaz — genellikle kendi ikon tasarımlarını tercih ederler.

---

## 7. Sonuç ve Öneriler

### ✅ Yapın
- RSS feed'den film verisi parse etme (opt-in, kullanıcının kendi verisi)
- SF Symbol ikonu + "Letterboxd" metin etiketi kullanma
- Caching ve hata yönetimi
- Gizlilik politikasında bu veri kullanımını açıklama

### ⚠️ Dikkatli Olun
- Rate limiting — çok sık istek atmayın
- RSS format değişikliklerine hazır olun
- Verinin sadece post üretimi sırasında geçici olarak kullanılmasını sağlayın

### ❌ Yapmayın
- Letterboxd logosunu kullanma
- Film posterlerini embed etme veya hotlink yapma
- "Powered by Letterboxd" gibi onay izlenimi yaratan ifadeler kullanma
- Kullanıcının Letterboxd verisini kalıcı olarak saklama (cache hariç)

---

## 8. Hukuki Sorumluluk Reddi

Bu rapor genel bilgi amaçlıdır ve hukuki danışmanlık yerine geçmez. Ticari marka, telif hakkı ve veri koruma konularında kesin kararlar vermeden önce ilgili yargı bölgesinde uzman bir avukata danışılması önerilir.
