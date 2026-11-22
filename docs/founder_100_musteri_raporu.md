# 🧪 Omakase — 100 Müşteri Simülasyonu & Teklif Optimizasyonu Raporu (`founder-skill`)

> **Tarih:** 22 Kasım 2026 · **Metodoloji:** [`founder-consumer`](https://github.com/Jakeschincariol/founder-skill/tree/main/skills/founder-consumer) (`panel.py`, `seed=7`, `n=100` bağımsız alıcı ajanı) ve [`founder-pricing`](https://github.com/Jakeschincariol/founder-skill/tree/main/skills/founder-pricing) (`van_westendorp.py`)  
> **Uyarı (Metodoloji Sınırı):** Bu paneldeki 100 kişi simüle edilmiş alıcı personalarıdır; dil modelleri gerçek tüketicilere göre daha olumlu karar vermeye yatkın olduğundan 2. Turdaki `%72` oranı **teorik üst sınır (upper bound)** olarak okunmalıdır. Asıl kanıt değeri, **birebir aynı 100 persona (`seed=7`) üzerinde 1. Tur (`%1`) → 2. Tur (`%72`)** arasındaki devasa sıçramadır.

---

## 1. İki Tur Karşılaştırması: Ne Değişti, Ne Oldu?

| Kriter | 1. Tur (İlk Teklif) | 2. Tur (Güncel Kod & Teklif — Lifetime Yok) | Fark |
|---|---|---|---|
| **Ücretsiz Günlük Tabak** | 5 tabak (`Kalan: X/5`) + `+2` Deep Dive bonusu | **3 tabak (`Kalan: X/3`) + `+1` Deep Dive bonusu** | Tadımlık eşik, merak tam zirvedeyken duvar |
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
* **`habit` (47 kişi):** *"Ücretsiz 3 tabak sınırı hemen bitiyor, `Kalan: X/3` sayacı kırmızıya dönünce merak yarım kalıyor; 7 günlük ücretsiz denemeyle başlayıp ayda \$2.49'a yıllık kalırım."* (`P001`, `P002`)
* **`need` (16 kişi):** *"Birincil kaynakça (`Kaynak:`) ve Letterboxd entegrasyonu Wikipedia'dan ayrışıyor; 3 tabak tam daldığım yerde kapandığı için Pro açarım."* (`P003`, `P032`)
* **`convenience` (4 kişi):** *"Estetik, altı birincil kaynakçalı ve Story'de paylaşılmaya değer kartlar; aylık \$2.49 kahveden ucuz."* (`P039`, `P042`)
* **`trust` (2 kişi)** & **`quality` (2 kişi)** & **`price` (1 kişi):** *"Wikipedia yerine gerçek kitap/makale/röportaj kaynağı göstermesi ve riski sıfırlayan 7 gün deneme."* (`P008`, `P023`, `P012`)

### 3.2. Kalan 28 Kişi Neden Hâlâ Almıyor? (`why_not`: 28 Kişi)
* **`habit` (14 kişi) & `price` (13 kişi) & `need` (1 kişi):**
  1. **Lifetime / Ömür Boyu Seçenek Yokluğu (`Abonelik Yorgunu`):** Spotify, Netflix, iCloud ve ChatGPT üstüne yeni bir tekrarlayan ödeme eklemek istemeyenler (`P006`, `P011`).
  2. **Çok Düşük Öğrenci Bütçesi (`$12k–$15k`):** Yıllık \$29.99 bile dar bütçeli öğrenciler için lüks kalıyor; ücretsiz 3 tabakta kalmayı veya çıkmayı seçiyor (`P017`, `P025`, `P070`).
  3. **Sadece 3 Tabağın Yarattığı Tepki:** Kıtlık baskısını sevenler (`72` kişi) Pro'ya dönerken, küçük bir azınlık duvarı erken görüp *"kızdım, kapatırım"* tepkisi veriyor (`P017`, `P080`).

> **Kritik Gerçekçi Not:** Bu 3. gruptaki tepki (küçük bir kesimin "3 tabak az" demesi) **sağlıklı bir paywall'un normal bedelidir.** 1. Turda herkes bedava 5 tabakla mutlu olduğu için %99 kimse para vermemişti; 2. Turda %10-15 erken duvar tepkisine karşılık %72 dönüşüm isteği oluştu.

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

## 5. Uygulanan Kod Değişiklikleri (2. Tur İyileştirmeleri)

1. **Günlük Ücretsiz Kota (`5` → `3` Tabak, `+2` → `+1` Paylaşım Bonusu):** [config.py](file:///Users/kuzey/projects/omakase/backend/app/config.py#L48-L55), [AccessManager.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/AccessManager.swift#L67-L69), [test_billing_and_quota.py](file:///Users/kuzey/projects/omakase/backend/tests/test_billing_and_quota.py).
2. **Birincil Kaynakça Zorunluluğu (`Kaynak:` / `Source:`):** [prompts.py](file:///Users/kuzey/projects/omakase/backend/app/prompts.py#L26-L65) ve [gemini_service.py](file:///Users/kuzey/projects/omakase/backend/app/services/gemini_service.py#L263) (`max_output_tokens=360`) ile her post ve Deep Dive sonuna gerçek kitap/makale/arşiv/röportaj kaynağı zorunlu kılındı ("Wikipedia" yasaklandı).
3. **Paywall & Web Konumlandırması (Lifetime Yok):** [L10n.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Localization/L10n.swift#L1750-L1995), [index.html](file:///Users/kuzey/projects/omakase/web/index.html), [app.js](file:///Users/kuzey/projects/omakase/web/app.js) ve [terms.html](file:///Users/kuzey/projects/omakase/web/terms.html) üzerinde **3 ücretsiz tabak**, **birincil kaynakça** ve **ayda ~\$2.49 (%37 avantaj) + 7 gün ücretsiz deneme** vurgusu canlıya alındı.
