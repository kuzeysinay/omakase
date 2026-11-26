# 🧪 Omakase — 100 Müşteri Simülasyonu & Teklif Optimizasyonu Raporu (`founder-skill`)

> **Simülasyon Tarihi:** 22 Kasım 2026 · **Ürün Eşitleme Güncellemesi:** 26 Kasım 2026  
> **Metodoloji:** [`founder-consumer`](https://github.com/Jakeschincariol/founder-skill/tree/main/skills/founder-consumer) (`panel.py`, `seed=7`, `n=100` bağımsız alıcı ajanı) ve [`founder-pricing`](https://github.com/Jakeschincariol/founder-skill/tree/main/skills/founder-pricing) (`van_westendorp.py`)  
> **Uyarı (Metodoloji Sınırı):** Bu paneldeki 100 kişi simüle edilmiş alıcı personalarıdır; dil modelleri gerçek tüketicilere göre daha olumlu karar vermeye yatkın olduğundan 2. Turdaki `%72` oranı **teorik üst sınır (upper bound)** olarak okunmalıdır. Asıl kanıt değeri, **birebir aynı 100 persona (`seed=7`) üzerinde 1. Tur (`%1`) → 2. Tur (`%72`)** arasındaki devasa sıçramadır. *(Not: 26 Kasım güncellemesi simülasyon rakamlarını değiştirmemiş; yalnızca simülasyon sonrası eklenen ürün ve kota koruma mekanizmalarını Bölüm 6'da belgelemiştir.)*

---

## 1. İki Tur Karşılaştırması: Ne Değişti, Ne Oldu?

| Kriter | 1. Tur (İlk Teklif) | 2. Tur (Optimize Teklif — Lifetime Yok) | Fark |
|---|---|---|---|
| **Ücretsiz Günlük Tabak / Post** | 5 tabak (`Kalan: X/5`) + `+2` Deep Dive bonusu | **3 post (`Kalan: X/3`) + `+1` Deep Dive bonusu** | Tadımlık eşik, merak tam zirvedeyken duvar |
| **Doğruluk / Güven** | Kaynakça satırı yok | **Her post ve Deep Dive altında birincil kaynakça (`Kaynak:` / `Source:`)**; "Wikipedia" yasak | AI halüsinasyon itirazını kırdı |
| **Paywall Çerçevesi** | \$3.99/ay veya \$29.99/yıl (aylık fiyat ön planda) | **7 gün ücretsiz deneme + yıllık planda ayda ~\$2.49 (%37 avantaj)** (lifetime yok) | Fiyat algısını `IPP` altına çekti |
| **Satın Alma (Pro Dönüşüm)** | **1 Alıcı · 99 Pas (`%1`)** | **72 Alıcı · 28 Pas (`%72`)** | **+71 kişi (+71 puan)** |

---

## 2. Segment, Davranış ve Gelir Kırılımı (1. Tur → 2. Tur)

### 2.1. Müşteri Segmentlerine Göre

| Segment | Kişi | 1. Tur | 2. Tur | Değişim |
|---|---:|---:|---:|---|
| **Akademik & Derin Okur (Yüksek Gelir)** | 15 | %0 | **%100** | **+100 puan** |
| **Beyaz Yaka & Yaratıcı Profesyonel** | 30 | %3 | **%77** | **+74 puan** |
| **Sinefil & Letterboxd Tutkunu** | 25 | %0 | **%68** | **+68 puan** |
| **Üniversite Öğrencisi & Genç Meraklı** | 30 | %0 | **%57** | **+57 puan** |

### 2.2. Satın Alma Davranışına Göre

| Davranış Profili | Kişi | 1. Tur | 2. Tur |
|---|---:|---:|---:|
| **Derin Okur (Wikipedia/Substack)** | 14 | %7 | **%93** |
| **Letterboxd Günlükçüsü** | 15 | %0 | **%87** |
| **Doomscroll Pişmanı** | 18 | %0 | **%83** |
| **Sosyal Paylaşımcı (Story/X)** | 12 | %0 | **%83** |
| **Şüpheci (AI Halüsinasyon Korkusu)** | 10 | %0 | **%60** |
| **Ücretsiz Plan Avcısı** | 16 | %0 | **%50** |
| **Abonelik Yorgunu** | 15 | %0 | **%47** |

### 2.3. Gelir Bandına Göre (2. Tur)

| Yıllık Gelir Bandı | Kişi | 1. Tur | 2. Tur |
|---|---:|---:|---:|
| **\$76,000 ve üzeri** | 34 | %3 | **%91** |
| **\$39,000 – \$76,000** | 33 | %0 | **%67** |
| **\$39,000 altı** | 33 | %0 | **%58** |

---

## 3. 2. Turda Satın Alanların (72 Alıcı) ve Kalanların (28 Pas) Gerçek Sebepleri

### 3.1. Neden Satın Aldılar? (`why_yes`: 72 Kişi)
* **`habit` (47 kişi):** *"Ücretsiz 3 hak sınırı hemen bitiyor, `Kalan: X/3` sayacı kırmızıya dönünce merak yarım kalıyor; 7 günlük ücretsiz denemeyle başlayıp ayda \$2.49'a yıllık kalırım."* (`P001`, `P002`)
* **`need` (16 kişi):** *"Birincil kaynakça (`Kaynak:`) ve Letterboxd entegrasyonu Wikipedia'dan ayrışıyor; 3 hak tam daldığım yerde kapandığı için Pro açarım."* (`P003`, `P032`)
* **`convenience` (4 kişi):** *"Estetik, altı birincil kaynakçalı ve Story'de paylaşılmaya değer kartlar; aylık \$2.49 kahveden ucuz."* (`P039`, `P042`)
* **`trust` (2 kişi)** & **`quality` (2 kişi)** & **`price` (1 kişi):** *"Wikipedia yerine gerçek kitap/makale/röportaj kaynağı göstermesi ve riski sıfırlayan 7 gün deneme."* (`P008`, `P023`, `P012`)

### 3.2. Kalan 28 Kişi Neden Hâlâ Almıyor? (`why_not`: 28 Kişi)
* **`habit` (14 kişi) & `price` (13 kişi) & `need` (1 kişi):**
  1. **Lifetime / Ömür Boyu Seçenek Yokluğu (`Abonelik Yorgunu`):** Spotify, Netflix, iCloud ve ChatGPT üstüne yeni bir tekrarlayan ödeme eklemek istemeyenler (`P006`, `P011`).
  2. **Çok Düşük Öğrenci Bütçesi (`$12k–$15k`):** Yıllık \$29.99 bile dar bütçeli öğrenciler için lüks kalıyor; ücretsiz 3 postta kalmayı veya çıkmayı seçiyor (`P017`, `P025`, `P070`).
  3. **Sadece 3 Hakkın Yarattığı Tepki:** Kıtlık baskısını sevenler (`72` kişi) Pro'ya dönerken, küçük bir azınlık duvarı erken görüp *"kızdım, kapatırım"* tepkisi veriyor (`P017`, `P080`).

> **Kritik Gerçekçi Not:** Bu 3. gruptaki tepki (küçük bir kesimin "3 hak az" demesi) **sağlıklı bir paywall'un normal bedelidir.** 1. Turda herkes bedava 5 hakla mutlu olduğu için %99 kimse para vermemişti; 2. Turda %10-15 erken duvar tepkisine karşılık %72 dönüşüm isteği oluştu.

---

## 4. Van Westendorp Fiyat Duyarlılığı Analizi (`van_westendorp.py`)

| Metrik | 1. Tur (`$3.99/ay`) | 2. Tur (`$2.49/ay`) | Yorum |
|---|---:|---:|---|
| **PMC** *(Çok Ucuz Sınırı)* | \$1.00 | **\$1.01** | Güven sınırı ~\$1.00/ay |
| **OPP** *(En Düşük Direnç)* | \$1.01 | **\$1.01** | — |
| **IPP** *(Denge Fiyatı)* | \$2.97 | **\$2.53** | Yıllık planın aylık karşılığı (**\$2.49/ay**) tam `IPP` noktasında! |
| **PME** *(Çok Pahalı Sınırı)* | \$5.01 | **\$5.49** | Birincil kaynakça eklenince algılanan değer tavanı \$5.01 → **\$5.49**'a yükseldi |
| **Kabul Edilebilir Aralık** | \$1.00 – \$5.01 | **\$1.01 – \$5.49** | Medyanlar: Çok ucuz `\$0.99`, Fırsat `\$1.99`, Pahalı `\$4.99`, Çok pahalı `\$7.99` |

---

## 5. Uygulanan İlk Tur İyileştirmeleri (22 Kasım 2026)

1. **Günlük Ücretsiz Kota (`5` → `3` Post, `+2` → `+1` Paylaşım Bonusu):** [config.py](file:///Users/kuzey/projects/omakase/backend/app/config.py#L74-L82), [AccessManager.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/AccessManager.swift#L64-L87), [test_billing_and_quota.py](file:///Users/kuzey/projects/omakase/backend/tests/test_billing_and_quota.py).
2. **Birincil Kaynakça Zorunluluğu (`Kaynak:` / `Source:`):** [prompts.py](file:///Users/kuzey/projects/omakase/backend/app/prompts.py#L12-L119) ve [PostSourceView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Theme/PostSourceView.swift) ile her post ve Deep Dive sonuna gerçek kitap/makale/arşiv/röportaj kaynağı zorunlu kılındı ("Wikipedia" yasaklandı).
3. **Paywall & Web Konumlandırması (Lifetime Yok):** [OmakasePaywallView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Monetization/OmakasePaywallView.swift), [L10n.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Localization/L10n.swift), [index.html](file:///Users/kuzey/projects/omakase/web/index.html) ve [terms.html](file:///Users/kuzey/projects/omakase/web/terms.html) üzerinde **3 ücretsiz post**, **birincil kaynakça** ve **ayda ~\$2.49 (%37 avantaj) + 7 gün ücretsiz deneme** vurgusu canlıya alındı.

---

## 6. Simülasyon Sonrası Ürün & Monetizasyon Güncellemeleri (24–26 Kasım 2026)

22 Kasım'daki 100 müşteri doğrulamasının ardından, simülasyonda öne çıkan **kıtlık eşiği**, **paylaşım motivasyonu** ve **fiyat/güven sunumunu** gerçek dünyada koruyup ölçebilmek için 5 ek mekanizma geliştirildi:

1. **Cihaz-Bazlı Kota Koruması (`X-Omakase-Device-Id` + `device_usage`):** Ücretsiz `3 post/gün` duvarının Apple, Google ve E-posta hesapları arasında geçiş yapılarak veya hesap silip yeniden açılarak aşılmasını önlemek için Keychain + SHA-256 cihaz bazlı kota birleştirme ([`SSEClient.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L42-L79), [`access_service.py`](file:///Users/kuzey/projects/omakase/backend/app/services/access_service.py#L182-L299)) eklendi.
2. **Letterboxd `1/gün` Ücretsiz Sınırı + `letterboxdLimit` Paywall:** Simülasyonda Sinefil segmentinin (`%68` dönüşüm) en güçlü tetikleyicisi olan Letterboxd sentezi ücretsiz katmanda **günde 1 film postuyla** (`FREE_DAILY_LETTERBOXD_PLATES = 1`, 3 post hakkının içinde) sınırlandı ve 5. bağlamsal paywall kaynağı (`letterboxdLimit`) eklendi.
3. **Tek Ekranlı ASCII Suşi Paywall & "Post" Dili:** [OmakasePaywallView.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Monetization/OmakasePaywallView.swift) iç kaydırmasız tek ekranda buzlu Free/Pro karşılaştırma kartıyla yenilendi ve arayüz kopyası "tabak" yerine "post" terminolojisine sadeleştirildi.
4. **Export Studio (`ExportPostSheet.swift`):** `Sosyal Paylaşımcı (%83)` segmentinin dönüşümünü ve organik paylaşımı büyütmek için 3 oran (`Story`, `Post`, `Kare`) × 4 monokrom temalı dışa aktarım stüdyosu ve doğrudan Instagram Stories / WhatsApp / X paylaşımı eklendi; paylaşım tamamlamada `+1` Derin İnceleme ödülü verilir.
5. **Canlı Hipotez Doğrulaması (`TelemetryService` + Mission Control):** Simülasyondaki tahminler artık gerçek kullanıcı verisiyle ölçülür: [`TelemetryService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/TelemetryService.swift) ve [`admin-web/`](file:///Users/kuzey/projects/omakase/admin-web) üzerinden **kaynak bazlı paywall dönüşümü** (`firstPlateSoft`, `plateLimit`, `deepDiveLimit`, `profile`), **`source_tap_rate_pct`** (kaynak kapsülü tıklama oranı) ve **RevenueCat v2** canlı deneme/abonelik metrikleri takip edilir.
