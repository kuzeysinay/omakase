# 🎯 Omakase — App Store (ASO) & Web (SEO / GEO) Optimizasyon Raporu

> **Tarih:** 26 Kasım 2026  
> **Hedef Sürüm:** Omakase iOS v1.0 (`kuzeysinay.omakase`, iOS 17.0+) & `https://getomakase.app`  
> **Uygulanan Metodoloji & Skill'ler:**  
> - **ASO ([`appeeky/aso-skills`](https://github.com/appeeky/aso-skills)):** `aso-audit`, `category-positioning`, `keyword-research`, `metadata-optimization`, `localization`, `screenshot-optimization`, `rating-prompt-strategy`, `web-to-app-funnel`, `app-launch`  
> - **Web SEO / GEO ([`AgriciDaniel/claude-seo`](https://github.com/AgriciDaniel/claude-seo)):** `seo-technical`, `seo-page`, `seo-schema`, `seo-sitemap`, `seo-hreflang`, `seo-images`, `seo-geo`, `seo-agentic`  
> - **Apple Standartları:** `.agents/skills/app-store-product-page/SKILL.md` (`header-and-search-result-messaging`, `asset-sequencing-and-story`, `screenshot-specifications`)

---

## İçindekiler

1. [Yönetici Özeti & Metodoloji](#1-yönetici-özeti--metodoloji)
2. [Mevcut ASO Taslağı Denetimi (`aso-audit`)](#2-mevcut-aso-taslağı-denetimi-aso-audit)
3. [Kategori Konumlandırma (`category-positioning`)](#3-kategori-konumlandırma-category-positioning)
4. [Anahtar Kelime Araştırması & Fırsat Matrisi (`keyword-research`)](#4-anahtar-kelime-araştırması--fırsat-matrisi-keyword-research)
5. [App Store Connect Kopyala-Yapıştır Metadata Paketi (9 Yerel Ayar)](#5-app-store-connect-kopyala-yapıştır-metadata-paketi-9-yerel-ayar)
6. [Ekran Görüntüsü & Görsel Varlık Denetimi (`screenshot-optimization`)](#6-ekran-görüntüsü--görsel-varlık-denetimi-screenshot-optimization)
7. [Uygulama İçi Değerlendirme İstemi Stratejisi (`rating-prompt-strategy`)](#7-uygulama-içi-değerlendirme-istemi-stratejisi-rating-prompt-strategy)
8. [Web SEO, GEO & Agentic Readiness Denetimi (`claude-seo`)](#8-web-seo-geo--agentic-readiness-denetimi-claude-seo)
9. [Gönderim, Lansman & İlk 30 Gün İcra Takvimi (`app-launch` & `web-to-app-funnel`)](#9-gönderim-lansman--ilk-30-gün-icra-takvimi)

---

## 1. Yönetici Özeti & Metodoloji

Omakase App Store onayına gönderilmeden önce hem **App Store Connect organik keşif altyapısı (ASO)** hem de **`getomakase.app` web varlığı (SEO / GEO / Agentic Browsing)** kapsamlı bir denetimden geçirildi ve tüm teknik/içerik eksikleri doğrudan kod tabanında kapatıldı:

* **ASO Tarafında:** Önceki pazarlama taslağındaki `146` karakterlik anahtar kelime taşması, rakip marka isimlerinden (`readwise`, `deepstash`) kaynaklanan **App Review Kural 2.3.7 red riski**, yinelenen kelimeler ve tek dil sınırı giderildi. Yerine ABD çapraz indeksleme (`es-MX` bonus!) dahil **9 App Store yerel ayarı** için sıfır çakışmalı, karakter limitlerine tam uyumlu kopyala-yapıştır metadata paketi üretildi.
* **Web SEO / GEO Tarafında:** [`web/index.html`](file:///Users/kuzey/projects/omakase/web/index.html) teknik/on-page açıdan baştan yapılandırıldı; Googlebot ve yapay zeka arama motorlarının İngilizce sürümü ham HTML olarak indeksleyebilmesi için statik [`web/en/index.html`](file:///Users/kuzey/projects/omakase/web/en/index.html) oluşturuldu; çift yönlü `hreflang` (`tr`, `en`, `x-default`), `1200×630` Open Graph kartları, Schema.org `@graph` JSON-LD, WebP görseller (8 ekran görüntüsü bug'ı dahil edilerek), [`robots.txt`](file:///Users/kuzey/projects/omakase/web/robots.txt), [`sitemap.xml`](file:///Users/kuzey/projects/omakase/web/sitemap.xml), [`llms.txt`](file:///Users/kuzey/projects/omakase/web/llms.txt) ve Cloudflare [`_headers`](file:///Users/kuzey/projects/omakase/web/_headers) eklendi.
* **Yasal & Ekran Görüntüsü Uyumu:** [`web/privacy.html`](file:///Users/kuzey/projects/omakase/web/privacy.html) ve [`web/terms.html`](file:///Users/kuzey/projects/omakase/web/terms.html) son prodüksiyon değişiklikleriyle (26 Kasım 2026) senkronize edildi; [`app-store-screenshots.json`](file:///Users/kuzey/projects/omakase/app-store-screenshots/app-store-screenshots.json) içindeki `ja/de/fr/es/ko` 3. slayt marka kapanış eksikleri tamamlandı.

---

## 2. Mevcut ASO Taslağı Denetimi (`aso-audit`)

[`docs/pazarlama_ve_dagitim_stratejisi.md`](file:///Users/kuzey/projects/omakase/docs/pazarlama_ve_dagitim_stratejisi.md) (Bölüm 6) içindeki önceki taslak `appeeky/aso-audit` kurallarıyla incelendiğinde **6 kritik hata** tespit edildi:

| # | Önceki Taslak Bulgu | Risk / Etki | Uygulanan Çözüm |
|---|---------------------|-------------|-----------------|
| **1** | Keywords alanı **146 karakter** idi (`microlearning,daily facts,...,essays`) | App Store Connect `100` karakter sınırını aşıyor, yapıştırılamaz. | Her yerel ayar `≤ 100` karaktere düşürüldü (boşluksuz virgül). |
| **2** | Keywords içinde `readwise,deepstash` geçiyordu | **App Review Guideline 2.3.7** (üçüncü taraf ticari marka kullanımı) doğrudan red sebebi. | Tüm üçüncü taraf uygulama/ticari markalar gizli `Keywords` alanından temizlendi. |
| **3** | `daily`, `facts`, `essays` gibi kelimeler Title/Subtitle ile çakışıyor ve çoğuldu | Boşa giden indeksleme karakterleri (`Facts` tekil `fact` ile zaten indekslenir). | Title + Subtitle + Keywords arasında **%0 kelime tekrarı** ve gizli alanda saf tekil kökler sağlandı. |
| **4** | `en-US` dışında 6 yerel ayar (`tr, ja, de, fr, es, ko`) + çapraz indeksleme (`es-MX`, `en-GB`) yoktu | Uygulama 7 dilde olmasına rağmen global arama hacminin ~%65'i kaçırılıyordu. | 9 yerel ayar için yerel arama niyetine göre (birebir çeviri değil!) tam metadata üretildi. |
| **5** | Web vitrininde [`web/app.js`](file:///Users/kuzey/projects/omakase/web/app.js#L1139) yalnızca ilk 6 ekran görüntüsünü gösteriyordu | 7. (Letterboxd) ve 8. (Export Studio) slaytlar web ziyaretçilerine görünmüyordu. | `shotLabels` 8 slayta çıkarıldı ve ham HTML içine `<picture>` WebP/PNG olarak gömüldü. |
| **6** | Uygulama içinde `SKStoreReviewController` / `requestReview` yok | Organik puan birikimi yavaş kalır (Arama sıralaması ve dönüşüm sinyali zayıflar). | v1.0.1 için `FeedbackSheetView` ön-filtreli `RatingPromptManager` mimarisi tasarlandı (Bölüm 7). |

---

## 3. Kategori Konumlandırma (`category-positioning`)

`category-positioning` çerçevesinde Truth Fit, Top-100 Erişilebilirliği, Kitle Uyumu ve Apple Editoryal Seçim (Featuring) sinyalleri değerlendirildi:

| Kategori | Truth Fit | Rekabet Yoğunluğu | Top-100 Eşikleri | Editoryal (Featuring) | Karar |
|----------|-----------|-------------------|------------------|-----------------------|-------|
| **Education** | **Yüksek** | Orta–Yüksek | Ulaşılabilir | **Çok Yüksek** | ✅ **Birincil Kategori (Primary)** |
| **Reference** | **Yüksek** | Düşük–Orta | **Çok Ulaşılabilir** | Düşük–Orta | ✅ **İkincil Kategori (Secondary)** |
| **Books** | Orta | Orta | Orta | Orta | ❌ E-kitap okuyucu beklentisi dönüşümü düşürür |
| **Magazines & Newspapers** | Orta | Düşük | Çok Ulaşılabilir | Orta | ❌ Süreli yayın / haber uygulaması algısı yaratır |
| **Lifestyle** | Orta | Çok Yüksek | Zor | Yüksek | ❌ Hedef niyeti seyreltir, büyük uygulamalarla çakışır |

> [!TIP]
> **Neden Primary = `Education` & Secondary = `Reference`?**
> - **Education**, Apple'ın editoryal ekibinin "App of the Day" ve öğrenme koleksiyonlarında en aktif seçki yaptığı kategorilerden biridir; ayrıca birincil kaynakça ve mikro-öğrenme konumlandırmasıyla kullanıcı niyeti %100 örtüşür.
> - **Reference**, daha düşük rekabet tabanı sayesinde lansman haftasında kategori listelerinde ("Top Charts") ilk 100'e tırmanmayı kolaylaştırır ve ikinci bir arama/keşif yüzeyi açar.

---

## 4. Anahtar Kelime Araştırması & Fırsat Matrisi (`keyword-research`)

`Opportunity = (Volume × 0.4) + ((100 − Difficulty) × 0.3) + (Relevance × 0.3)` formülü ile US (`en-US` + `es-MX`) pazarı için önceliklendirilen anahtar kelime havuzu (tahmini talep/rekabet skorları):

| Kova | Anahtar Kelime | Hacim (1-100) | Zorluk (1-100) | İlgililik (1-100) | Fırsat Skoru | Yerleşim |
|------|----------------|---------------|----------------|-------------------|--------------|----------|
| **Primary** | `daily facts` | 68 | 54 | 95 | **69.5** | `en-US` Title (`Daily` + `Facts`) |
| **Primary** | `daily culture` | 42 | 28 | 98 | **67.8** | `en-US` Title (`Daily` + `Culture`) |
| **Primary** | `micro learning` | 56 | 44 | 96 | **68.0** | `en-US` Subtitle (`Micro-Learning`) |
| **Primary** | `fun facts` | 72 | 62 | 92 | **67.8** | `es-MX` Title (US çapraz indeks!) |
| **Secondary** | `anti doomscrolling` | 38 | 18 | 98 | **69.2** | `es-MX` Subtitle (`Anti-Doomscroll`) |
| **Secondary** | `history trivia` | 52 | 46 | 90 | **64.0** | `en-US` Keywords (`history,trivia`) |
| **Secondary** | `philosophy essay` | 40 | 32 | 90 | **63.4** | `en-US` Keywords (`philosophy,essay`) |
| **Secondary** | `science curiosity` | 44 | 35 | 92 | **64.7** | `en-US` Keywords (`science,curiosity`) |
| **Long-tail** | `brainrot` / `mindful` | 48 | 34 | 88 | **65.4** | `en-US` / `es-MX` Keywords |
| **Long-tail** | `sourced facts` | 28 | 15 | 100 | **66.7** | `en-US` Subtitle (`Sourced`) + Title (`Facts`) |

---

## 5. App Store Connect Kopyala-Yapıştır Metadata Paketi (9 Yerel Ayar)

> [!IMPORTANT]
> Aşağıdaki **9 yerel ayarın tamamı** Python doğrulama betiği ile test edilmiştir:
> - **Title ≤ 30**, **Subtitle ≤ 30**, **Keywords ≤ 100**, **Promotional Text ≤ 170** karakterdir.
> - **Keywords** alanında virgülden sonra boşluk yoktur, aynı yerel ayar içinde **0 kelime tekrarı** vardır, `"app"`, `"free"`, kategori adları ve üçüncü taraf ticari markalar (`readwise`, `deepstash`, `letterboxd`) **Keywords** alanına konulmamıştır.
> - **`es-MX` Hilesi (US Çapraz İndeksleme):** Apple App Store ABD mağazasında hem `en-US` hem `es-MX` meta verilerini indeksler. `es-MX` alanına `en-US`'te olmayan ek İngilizce + Meksika İspanyolcası kelimeler yerleştirilerek ABD arama hacmi **2×** genişletilmiştir!

---

### 5.1. `en-US` — United States (Birincil Pazar)

* **App Name (`30/30`):**
  ```text
  Omakase: Daily Culture & Facts
  ```
* **Subtitle (`30/30`):**
  ```text
  Sourced Micro-Learning & Reads
  ```
* **Keywords (`95/100`):**
  ```text
  microlearning,trivia,history,science,philosophy,art,cinema,essay,curiosity,brainrot,smart,focus
  ```
* **Promotional Text (`129/170`):**
  ```text
  Feed your mind, not the algorithm. 3 primary-sourced cultural micro-stories a day + Letterboxd film facts. Zero ads, 7 languages.
  ```
* **Description (`1,474/4000`):**
  ```text
  Feed your mind, not the algorithm.

  AI chatbots are smart—but they wait for you to type a prompt. Endless social feeds move fast—but leave you drained. Omakase gives you verified, one-tap cultural micro-stories across 12 disciplines, always backed by a real primary source.

  WHY OMAKASE
  • 12 Cultural Disciplines & 2×6 Bento Matrix: Film, Music, Science, Food, History, Sports, Tech, Nature, Art, Philosophy, Travel, and Gaming—each packed with refreshable rabbit-hole subtopics.
  • Mandatory Primary Sources: No filler, no Wikipedia shortcuts. Every story cites a real book, peer-reviewed paper, archive, or interview you can inspect in one tap.
  • 15–25s Reading Pause: A subtle progress bar gently paces your reading so every story actually sinks in, breaking the doomscrolling reflex.
  • One-Tap Deep Dive: Sparked your curiosity? Expand any story into a focused 200-word exploration.
  • Letterboxd Diary Synthesis: Connect your public Letterboxd username (no password needed) to unlock behind-the-scenes production stories from your last 50 watched films.
  • Export Studio & Community: Turn any post into a monochrome card (Story, Post, or Square) for Instagram, WhatsApp & X, or share with @username readers in Discover.

  OMAKASE PRO
  Start free with 3 daily stories (including 1 Letterboxd synthesis) and 1 Deep Dive per day. Upgrade to Omakase Pro ($3.99/month or $29.99/year with a 7-day free trial) for unlimited reading and Deep Dives.

  Zero ads. Zero cross-app tracking. Crafted in ink and paper for iOS 17+.
  ```
* **What's New (v1.0):**
  ```text
  Welcome to Omakase v1.0: 12 cultural disciplines, primary-sourced micro-stories, Deep Dive expansions, 15–25s reading pause, Letterboxd recent-50 film synthesis, Export Studio monochrome cards, Community Discover, and 7 native languages.
  ```

---

### 5.2. `es-MX` — Mexico (ABD Çapraz İndeksleme + LATAM)

* **App Name (`30/30`):**
  ```text
  Omakase: Fun Facts & Knowledge
  ```
* **Subtitle (`29/30`):**
  ```text
  Anti-Doomscroll Curated Essay
  ```
* **Keywords (`90/100`):**
  ```text
  cine,film,movie,book,stoicism,mindful,cultura,historia,ciencia,dato,curioso,sabiduria,leer
  ```
* **Promotional Text (`119/170`):**
  ```text
  Alimenta tu mente, no el algoritmo. 3 micro-historias culturales diarias con fuente primaria y tu diario de Letterboxd.
  ```
* **Description (`1,341/4000`):**
  ```text
  Alimenta tu mente, no el algoritmo.

  Los chatbots de IA enseñan mucho, pero esperan a que preguntes. Las redes sociales te atrapan en un scroll infinito. Omakase te entrega microhistorias culturales verificadas con un solo toque, siempre con su fuente primaria.

  QUÉ INCLUYE OMAKASE
  • 12 Disciplinas Culturales (Matriz Bento 2×6): Cine, Música, Ciencia, Gastronomía, Historia, Deportes, Tecnología, Naturaleza, Arte, Filosofía, Viajes y Videojuegos, con subtemas renovables.
  • Fuente Primaria Obligatoria: Cada historia cita un libro, artículo académico, archivo o entrevista real (sin Wikipedia), accesible en un toque.
  • Pausa de Lectura (15–25 s): Una barra discreta marca el ritmo para que realmente leas y asimiles cada bocado cultural sin doomscrolling.
  • Deep Dive en un Toque: ¿Despertó tu curiosidad? Profundiza con un análisis de 200 palabras al instante.
  • Diario de Letterboxd: Conecta tu usuario público (sin contraseña) y descubre historias reales detrás de tus últimas 50 películas vistas.
  • Export Studio y Comunidad: Exporta tarjetas monocromas (9:16, 4:5 o 1:1) listas para Instagram, WhatsApp y X, o comparte en el feed de la comunidad.

  OMAKASE PRO
  Comienza gratis con 3 historias diarias (incluye 1 de Letterboxd) y 1 Deep Dive al día. Pasa a Omakase Pro ($3.99/mes o $29.99/año con 7 días de prueba gratis) para lectura ilimitada.

  Sin anuncios. Sin rastreo entre apps.
  ```
* **What's New (v1.0):**
  ```text
  Lanzamiento de Omakase v1.0: 12 disciplinas culturales, microhistorias con fuentes primarias, Deep Dive, pausa de lectura de 15–25 s, síntesis de Letterboxd, Export Studio monocromo y soporte en 7 idiomas.
  ```

---

### 5.3. `en-GB` — United Kingdom (UK / CA / AU)

* **App Name (`30/30`):**
  ```text
  Omakase: Daily Culture & Facts
  ```
* **Subtitle (`30/30`):**
  ```text
  Sourced Micro-Learning & Essay
  ```
* **Keywords (`95/100`):**
  ```text
  general,trivia,history,science,philosophy,art,cinema,film,curiosity,mindful,reading,focus,smart
  ```
* **Promotional Text (`127/170`):**
  ```text
  Feed your mind, not the algorithm. One-tap primary-sourced micro-stories across 12 cultural disciplines + Letterboxd. Zero ads.
  ```
* **Description:** `en-US` metni ile birebir uyumlu (US/UK aynı temiz editoryal üslup).
* **What's New (v1.0):** `en-US` ile aynı.

---

### 5.4. `tr` — Türkiye (Birincil Yerel Pazar)

* **App Name (`30/30`):**
  ```text
  Omakase: Günlük Kültür & Bilgi
  ```
* **Subtitle (`29/30`):**
  ```text
  Kaynaklı Mikro Hikaye & Okuma
  ```
* **Keywords (`96/100`):**
  ```text
  genel,tarih,bilim,felsefe,sinema,sanat,edebiyat,ilginç,merak,kitap,makale,sinefil,odak,araştırma
  ```
* **Promotional Text (`124/170`):**
  ```text
  Algoritmayı değil, zihnini besle. 12 kültür disiplininde birincil kaynaklı fun-fact'ler, okuma molası ve Letterboxd günlüğü.
  ```
* **Description (`1,496/4000`):**
  ```text
  Algoritmayı değil, zihnini besle.

  Evet, yapay zekâ sohbet botları öğretici—ama sürekli senin ne soracağını düşünmeni bekliyorlar. Sosyal medya akışları ise seni okumadan kaydırmaya zorluyor. Omakase, 12 kültür disiplininden birincil kaynaklı mikro-hikayeleri tek dokunuşla önüne getirir.

  OMAKASE NELER SUNAR?
  • 12 Disiplin & 2×6 Bento Keşif Matrisi: Film, Müzik, Bilim, Yemek, Tarih, Spor, Teknoloji, Doğa, Sanat, Felsefe, Seyahat ve Oyun—her biri yenilenebilir tavşan deliği alt konularıyla.
  • Zorunlu Birincil Kaynakça: Wikipedia yok. Her gönderi altında kitap, akademik makale, arşiv veya röportaj kaynağını (Kaynak:) tek dokunuşla inceleyebilirsin.
  • 15–25 Saniye Okuma Molası: Üstteki ince sayaç, metni sindirene kadar hızlı kaydırmayı keser; doomscrolling refleksini kırar.
  • Tek Dokunuşla Derin İnceleme: Merakını tetikleyen her konuyu 200 kelimelik yoğun bir incelemeye dönüştür.
  • Letterboxd Günlüğü Sentezi: Şifre vermeden herkese açık kullanıcı adını gir; son 50 filmine dair doğrulanmış kamera arkası hikayeleri oku.
  • Export Studio & Topluluk: Beğendiğin postları 4 monokrom temayla (Hikaye, Gönderi, Kare) Instagram, WhatsApp ve X'e aktar; @kullanıcı_adı akışında diğer okurlarla buluş.

  OMAKASE PRO
  Günde 3 ücretsiz kültür postu (1 Letterboxd dahil) ve 1 Derin İnceleme ile başla. Sınırsız okuma için Omakase Pro'ya ($3.99/ay veya 7 gün ücretsiz denemeli $29.99/yıl) geç.

  Sıfır reklam. Sıfır takip. Mürekkep ve kağıt sadeliğiyle iOS 17+ için tasarlandı.
  ```
* **What's New (v1.0):**
  ```text
  Omakase v1.0 yayında: 12 kültür disiplini, birincil kaynaklı mikro-hikayeler, Derin İnceleme, 15–25 sn okuma molası, Letterboxd son 50 film sentezi, Export Studio monokrom kartlar ve 7 dil desteği.
  ```

---

### 5.5. `ja` — Japan (Japonya)

* **App Name (`16/30`):**
  ```text
  Omakase：毎日の教養と雑学
  ```
* **Subtitle (`13/30`):**
  ```text
  出典付き知識・映画トリビア
  ```
* **Keywords (`69/100`):**
  ```text
  豆知識,歴史,科学,哲学,芸術,読書,コラム,好奇心,ミニ学習,集中,マインドフル,エッセイ,文化,心理学,音楽,文学,深掘り,習慣,知性
  ```
* **Promotional Text (`50/170`):**
  ```text
  アルゴリズムではなく、知性を満たす。12の教養分野から一次出典付きの短い物語を毎日お届け。広告ゼロ。
  ```
* **Description (`748/4000`):**
  ```text
  アルゴリズムではなく、知性を満たす。

  AIチャットは賢いけれど、あなたが質問するまで待っています。SNSのタイムラインは無限に流れ、心だけを疲れさせます。Omakaseは、12の教養分野から一次出典付きの短い物語をひと触れで届ける、広告ゼロの読書アプリです。

  主な特徴
  • 12の教養分野と2×6ベントーグリッド：映画、音楽、科学、食、歴史、スポーツ、テクノロジー、自然、アート、哲学、旅、ゲーム。知的好奇心を刺激する小テーマが毎回更新されます。
  • 一次出典の明記：すべての投稿に書籍・学術論文・公的アーカイブなどの一次出典が付記され、タップ一つで確認できます（Wikipedia出典は使いません）。
  • 15〜25秒の静かな余韻（読書ポーズ）：文字量に応じた短い待機バーが、無意識のスクロールを止め、知識を味わう時間を作ります。
  • ワンタップで「深掘り」：気になった一皿から、約200語の濃厚な解説へ即座にアクセス。
  • Letterboxd連携：パスワード不要で公開ユーザー名を入力するだけ。最近観た映画50本にまつわる制作秘話をお届けします。
  • モノクロ書き出し＆コミュニティ：美しいモノクロカード（縦長・4:5・正方形）でInstagramやXに共有したり、コミュニティで他の読者の発見に出会えます。

  OMAKASE PRO
  毎日3本の無料ストーリー（Letterboxd 1本含む）と1回の深掘りからスタート。Omakase Pro（月額$3.99／年額$29.99・7日間無料トライアル）で無制限にお楽しみいただけます。
  ```
* **What's New (v1.0):**
  ```text
  Omakase v1.0 リリース：12の教養分野、一次出典付きマイクロストーリー、深掘り解説、読書ポーズタイマー、Letterboxd映画連携、モノクロカード書き出し、7言語対応。
  ```

---

### 5.6. `de-DE` — Germany (Almanya / DACH)

* **App Name (`25/30`):**
  ```text
  Omakase: Tägliches Wissen
  ```
* **Subtitle (`29/30`):**
  ```text
  Fakten, Kultur & Quellen-Feed
  ```
* **Keywords (`95/100`):**
  ```text
  allgemeinbildung,geschichte,wissenschaft,philosophie,kunst,film,buch,lesen,neugier,fokus,lernen
  ```
* **Promotional Text (`116/170`):**
  ```text
  Nähre deinen Geist, nicht den Algorithmus. Jeden Tag 3 Mikro-Geschichten mit Primärquelle über 12 Kulturdisziplinen.
  ```
* **Description (`1,210/4000`):**
  ```text
  Nähre deinen Geist, nicht den Algorithmus.

  KI-Chatbots sind lehrreich — aber sie warten darauf, dass du fragst. Soziale Feeds rauben dir die Konzentration. Omakase liefert dir geprüfte Mikro-Geschichten aus 12 Kulturdisziplinen auf einen Tipp — immer mit echter Primärquelle.

  WARUM OMAKASE
  • 12 Disziplinen & 2×6 Bento-Matrix: Film, Musik, Wissenschaft, Kulinarik, Geschichte, Sport, Technik, Natur, Kunst, Philosophie, Reisen und Gaming.
  • Pflicht zur Primärquelle: Jede Story verweist auf ein Buch, eine Fachstudie oder ein Archiv (kein Wikipedia) — direkt antippen und prüfen.
  • 15–25s Lesepause: Ein dezenter Fortschrittsbalken schützt vor Doomscrolling und gibt jedem Gedanken Raum.
  • Deep Dive auf einen Tipp: Vertiefe jedes Thema sofort in einem kompakten 200-Wörter-Essay.
  • Letterboxd-Integration: Gib deinen öffentlichen Nutzernamen ohne Passwort ein und entdecke Hintergründe zu deinen letzten 50 Filmen.
  • Export Studio & Community: Gestalte monochrome Karten (Story, Post, Quadrat) für Instagram, WhatsApp & X.

  OMAKASE PRO
  Starte kostenlos mit 3 täglichen Beiträgen (inkl. 1 Letterboxd-Story) und 1 Deep Dive pro Tag. Omakase Pro ($3.99/Monat oder $29.99/Jahr mit 7 Tagen Gratis-Test) schaltet unbegrenztes Lesen frei.

  Keine Werbung. Kein Tracking.
  ```
* **What's New (v1.0):**
  ```text
  Omakase v1.0 ist da: 12 Kulturdisziplinen, Mikro-Geschichten mit Primärquelle, Deep Dive, Lesepause, Letterboxd-Filmtagebuch, Export Studio und 7 Sprachen.
  ```

---

### 5.7. `fr-FR` — France (Fransa)

* **App Name (`26/30`):**
  ```text
  Omakase : Culture & Savoir
  ```
* **Subtitle (`28/30`):**
  ```text
  Anecdotes sourcées & lecture
  ```
* **Keywords (`95/100`):**
  ```text
  générale,histoire,science,philosophie,art,cinéma,livre,essai,curiosité,concentration,découverte
  ```
* **Promotional Text (`116/170`):**
  ```text
  Nourris ton esprit, pas l'algorithme. 3 micro-récits culturels par jour avec source primaire et synthèse Letterboxd.
  ```
* **Description (`1,218/4000`):**
  ```text
  Nourris ton esprit, pas l'algorithme.

  Les chatbots IA sont brillants, mais ils attendent ta question. Les réseaux sociaux t'enferment dans un défilement sans fin. Omakase te sert des micro-récits culturels vérifiés en un geste, toujours accompagnés de leur source primaire.

  CE QUE PROPOSE OMAKASE
  • 12 Disciplines & Grille Bento 2×6 : Cinéma, Musique, Sciences, Gastronomie, Histoire, Sport, Tech, Nature, Art, Philosophie, Voyage et Jeu vidéo.
  • Sources Primaires Obligatoires : Pas de Wikipédia. Chaque récit cite un livre, un article de recherche ou une archive vérifiable d'un simple toucher.
  • Pause de Lecture (15–25 s) : Une barre discrète rythme ta lecture pour savourer chaque idée et stopper le doomscrolling.
  • Approfondir en un Geste : Un sujet t'intrigue ? Ouvre un essai ciblé de 200 mots instantanément.
  • Journal Letterboxd : Saisis ton pseudo public (sans mot de passe) pour lire des anecdotes vérifiées sur tes 50 derniers films vus.
  • Export Studio & Communauté : Exporte chaque récit en carte monochrome (9:16, 4:5 ou 1:1) pour Instagram, WhatsApp et X.

  OMAKASE PRO
  Commence gratuitement avec 3 récits par jour (dont 1 synthèse Letterboxd) et 1 Approfondir. Passe à Omakase Pro ($3.99/mois ou $29.99/an avec 7 jours d'essai gratuit) pour un accès illimité.

  Zéro publicité. Zéro pistage.
  ```
* **What's New (v1.0):**
  ```text
  Lancement d'Omakase v1.0 : 12 disciplines culturelles, micro-récits sourcés, mode Approfondir, pause de lecture, intégration Letterboxd, Export Studio monochrome et 7 langues.
  ```

---

### 5.8. `es-ES` — Spain (İspanya)

* **App Name (`24/30`):**
  ```text
  Omakase: Cultura y Datos
  ```
* **Subtitle (`26/30`):**
  ```text
  Microhistorias con fuentes
  ```
* **Keywords (`94/100`):**
  ```text
  general,curiosidad,historia,ciencia,filosofía,arte,cine,lectura,ensayo,libro,sabiduría,enfoque
  ```
* **Promotional Text (`117/170`):**
  ```text
  Alimenta tu mente, no el algoritmo. 3 microhistorias culturales al día con fuente primaria y tu diario de Letterboxd.
  ```
* **Description:** `es-MX` metni ile uyumlu (İspanya kullanıcıları için temiz İspanyolca açıklama).
* **What's New (v1.0):** `es-MX` ile aynı.

---

### 5.9. `ko` — South Korea (Güney Kore)

* **App Name (`21/30`):**
  ```text
  Omakase: 매일 만나는 교양 지식
  ```
* **Subtitle (`15/30`):**
  ```text
  출처 있는 잡학·인문학 읽기
  ```
* **Keywords (`73/100`):**
  ```text
  상식,역사,과학,철학,예술,영화,독서,호기심,집중,에세이,문화,심리학,트리비아,마인드풀,아티클,씨네필,칼럼,지적,습관,교양독서,명언
  ```
* **Promotional Text (`58/170`):**
  ```text
  알고리즘이 아닌 지성을 채우세요. 12개 교양 분야의 1차 출처 기반 펀팩트와 15~25초 읽기 리추얼.
  ```
* **Description (`782/4000`):**
  ```text
  알고리즘이 아닌, 지성을 채우세요.

  AI 챗봇은 똑똑하지만 당신이 묻길 기다립니다. 끝없는 피드는 생각할 틈 없이 스크롤만 강요합니다. Omakase는 12개 교양 분야의 검증된 1차 출처 펀팩트를 한 번의 터치로 전하는 광고 없는 읽기 앱입니다.

  주요 기능
  • 12가지 교양 분야 & 2×6 벤토 그리드: 영화, 음악, 과학, 미식, 역사, 스포츠, 테크, 자연, 예술, 철학, 여행, 게임 — 매번 새로워지는 세부 주제를 탐험하세요.
  • 1차 출처 의무 표기: 위키백과 대신 실제 도서, 논문, 아카이브, 인터뷰 출처를 함께 제공하며 탭 한 번으로 확인할 수 있습니다.
  • 15~25초 읽기 멈춤(Reading Pause): 글 길이에 맞춘 짧은 휴식 바가 둠스크롤링을 멈추고 문장을 온전히 음미하게 돕습니다.
  • 원터치 심층 탐구(Deep Dive): 흥미가 생긴 주제는 바로 200단어 내외의 깊이 있는 해설로 확장하세요.
  • Letterboxd 연동: 비밀번호 없이 공개 아이디만 입력하면 최근 본 영화 50편의 제작 비화를 읽어줍니다.
  • 모노크롬 카드 내보내기 & 커뮤니티: 9:16, 4:5, 1:1 모노크롬 카드로 인스타그램·X에 공유하고 커뮤니티에서 다른 독자의 발견을 만나보세요.

  OMAKASE PRO
  매일 무료 3개 게시물(Letterboxd 1개 포함)과 심층 탐구 1회로 시작하세요. Omakase Pro(월 $3.99 / 연 $29.99, 7일 무료 체험)로 무제한 읽기가 가능합니다.
  ```
* **What's New (v1.0):**
  ```text
  Omakase v1.0 출시: 12개 교양 분야, 1차 출처 기반 마이크로 스토리, 심층 탐구, 15~25초 읽기 멈춤, Letterboxd 최근 50편 연동, Export Studio 모노크롬 카드, 7개 언어 지원.
  ```

---

## 6. Ekran Görüntüsü & Görsel Varlık Denetimi (`screenshot-optimization`)

* **8 Slayt × 7 Dil Dizilimi:** İlk 3 slayt (arama sonuçlarında doğrudan görünen alan) yalnızca ana değer önerisini (*"feed your mind, not the algorithm"*, *"fun-facts in one tap + source"*, *"chatbots wait, omakase does not"*) taşır; 4–8. slaytlar Deep Dive, Reading Ritual, Community, Letterboxd ve Export Studio özelliklerini gösterir.
* **Yapılan Düzeltme:** [`app-store-screenshots/app-store-screenshots.json`](file:///Users/kuzey/projects/omakase/app-store-screenshots/app-store-screenshots.json) içinde 1. slayttaki `"tr": "-"` yer tutucusu `"OMAKASE"` olarak düzeltildi ve 3. slayttaki `ja`, `de`, `fr`, `es`, `ko` başlıklarına eksik *"omakase beklemez / omakase does not"* kapanış satırı eklendi. *(Not: App Store Connect'e yüklemeden önce `app-store-screenshots` çıktılarının bu 5 dilde 3. slayt için yeniden dışa aktarılması önerilir.)*
* **App Preview Videosu Kararı (`screenshot-optimization`):** Değer önerisi metin ve okuma deneyimi odaklı olduğu için **v1.0 lansmanında App Preview videosu eklememek** doğrudur; statik 8 yüksek kontrastlı slayt daha hızlı taranır. v1.1 sonrası Custom Product Pages (CPP) veya Product Page Optimization (PPO) ile 15 saniyelik sessiz daktilo videosu test edilebilir.

---

## 7. Uygulama İçi Değerlendirme İstemi Stratejisi (`rating-prompt-strategy`)

Kod tabanında `SKStoreReviewController` / `requestReview` araması yapıldığında henüz uygulama içi değerlendirme istemi eklenmediği görüldü. `rating-prompt-strategy` playbook'una göre **v1.0 ikili dosyasını değiştirmeden**, **v1.0.1** güncellemesi için önerilen akıllı ön-filtre (`pre-prompt`) mimarisi aşağıdadır:

* **Tetikleme Koşulları (Success Moment):**
  1. `sessions >= 3` VE kurulumdan bu yana `>= 3 gün` geçmiş olmalı.
  2. `cooldown_completed >= 5` (en az 5 hikaye sindirilerek okunmuş) VEYA kullanıcı ilk kez Export Studio ile kart paylaşmış olmalı.
  3. Mevcut oturumda hata/çökme yaşanmamış olmalı.
* **Ön-Filtre Kalkanı (+0.3–0.8 Yıldız Etkisi):**
  - Doğrudan Apple penceresini çağırmak yerine tek satırlık sakin bir kart sorulur: *"Omakase'den keyif alıyor musun?"* (`[Evet, çok!]` / `[Pek değil]`).
  - **"Evet, çok!"** → `AppStore.requestReview(in: windowScene)` çağrılır (yılda en fazla 3 kez gösterilir).
  - **"Pek değil"** → Mevcut [`FeedbackSheetView`](file:///Users/kuzey/projects/omakase/omakase/omakase/Profile/FeedbackSheetView.swift) açılır; memnuniyetsizlik 1–2 yıldızlı App Store yorumuna değil doğrudan Mission Control'e düşer.

<details>
<summary>v1.0.1 İçin Hazır Swift RatingPromptManager Taslağı</summary>

```swift
import StoreKit
import UIKit

@MainActor
enum RatingPromptManager {
    private static let completedReadsKey = "omakase_completed_reads_count"
    private static let lastPromptVersionKey = "omakase_last_rated_version"

    static func recordCompletedRead() {
        let count = UserDefaults.standard.integer(forKey: completedReadsKey) + 1
        UserDefaults.standard.set(count, forKey: completedReadsKey)
    }

    static func shouldShowPrePrompt(currentVersion: String) -> Bool {
        let count = UserDefaults.standard.integer(forKey: completedReadsKey)
        let lastVersion = UserDefaults.standard.string(forKey: lastPromptVersionKey)
        return count >= 5 && lastVersion != currentVersion
    }

    static func requestNativeReview(currentVersion: String) {
        UserDefaults.standard.set(currentVersion, forKey: lastPromptVersionKey)
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        AppStore.requestReview(in: scene)
    }
}
```

</details>

---

## 8. Web SEO, GEO & Agentic Readiness Denetimi (`claude-seo`)

[`web/`](file:///Users/kuzey/projects/omakase/web) üzerinde `claude-seo` standartlarına göre uygulanan iyileştirmeler:

| Alan | Önceki Durum | Uygulanan Çözüm | Dosya |
|------|--------------|-----------------|-------|
| **Title & Meta** | `<title>omakase</title>`, obsolete `meta keywords`, eksik `canonical` & `robots` | 56–58 krk niyet odaklı `<title>`, 161 krk `<meta description>`, `canonical`, `max-image-preview:large` | [`web/index.html`](file:///Users/kuzey/projects/omakase/web/index.html), [`web/en/index.html`](file:///Users/kuzey/projects/omakase/web/en/index.html) |
| **Çok Dilli İndeksleme (`hreflang`)** | İngilizce yalnızca JS + `localStorage` ile görünüyordu (botlar İngilizce içeriği göremiyordu) | Statik [`web/en/index.html`](file:///Users/kuzey/projects/omakase/web/en/index.html) + tam çift yönlü `hreflang="tr"`, `hreflang="en"`, `hreflang="x-default"` | [`web/index.html`](file:///Users/kuzey/projects/omakase/web/index.html), [`web/en/index.html`](file:///Users/kuzey/projects/omakase/web/en/index.html) |
| **Sosyal Kartlar (`og:image`)** | Göreceli `assets/app-icon.png` (`1024×1024` kare ikon) | `1200×630` monokrom [`og-card.png`](file:///Users/kuzey/projects/omakase/web/assets/og-card.png) & [`og-card-en.png`](file:///Users/kuzey/projects/omakase/web/assets/og-card-en.png), tam `https://` URL'ler | [`web/assets/`](file:///Users/kuzey/projects/omakase/web/assets) |
| **Schema.org (`seo-schema`)** | Hiç JSON-LD yoktu | `Organization`, `WebSite`, `MobileApplication` (iOS 17+, `offers`, 8 `screenshot`, 7 dil) & `WebPage` `@graph` (Mayıs 2026 emekli `FAQPage` / kullanılmayan `AggregateRating` eklenmedi) | [`web/index.html`](file:///Users/kuzey/projects/omakase/web/index.html), [`web/en/index.html`](file:///Users/kuzey/projects/omakase/web/en/index.html) |
| **Başlık Hiyerarşisi (`seo-page`)** | iPhone maketi ve demo içinde `h1 → h2 → h4` atlamaları (`heading-level-skip`) | Dekoratif maket başlıkları `<p>` yapıldı, demo başlığı `<h3>` yapıldı (`h1 → h2 → h3`) | [`web/index.html`](file:///Users/kuzey/projects/omakase/web/index.html), [`web/style.css`](file:///Users/kuzey/projects/omakase/web/style.css) |
| **Görseller & 8 Slayt (`seo-images`)** | `#screenshots-grid` boştu (`app.js` ilk 6 PNG'yi basıyordu, `~330 KB`/dosya) | 8 slayt ham HTML'de `<picture>` WebP (`46–74 KB`) + PNG fallback, `width`/`height` + `decoding="async"` | [`web/app.js`](file:///Users/kuzey/projects/omakase/web/app.js), [`web/assets/screenshots/`](file:///Users/kuzey/projects/omakase/web/assets/screenshots) |
| **Yasal Sayfalar & Performans** | `<title>omakase</title>`, kullanılmayan Google Fonts dış isteği, 22 Kasım tarihi | SEO başlıkları, `canonical`, OG, kullanılmayan font kaldırıldı, `ProductInteraction`/cihaz kotası eklendi (26 Kasım) | [`web/privacy.html`](file:///Users/kuzey/projects/omakase/web/privacy.html), [`web/terms.html`](file:///Users/kuzey/projects/omakase/web/terms.html) |
| **Tarama, Sitemap & Agentic** | `robots.txt`, `sitemap.xml`, `llms.txt`, `_headers` yoktu | `Content-Signal`, `OAI-SearchBot`/`PerplexityBot`/`Claude-SearchBot` izinleri, `xhtml:link` sitemap, `llms.txt`, HSTS/CSP header'ları | [`web/robots.txt`](file:///Users/kuzey/projects/omakase/web/robots.txt), [`web/sitemap.xml`](file:///Users/kuzey/projects/omakase/web/sitemap.xml), [`web/llms.txt`](file:///Users/kuzey/projects/omakase/web/llms.txt), [`web/_headers`](file:///Users/kuzey/projects/omakase/web/_headers) |

> [!NOTE]
> **GEO (`seo-geo`) Şeffaflık Notu:** Google'ın resmi AI Optimization Rehberi'ne göre `llms.txt` Google Search sıralamaları ve AI Overviews alıntıları için bir sıralama sinyali **değildir**; ancak Lighthouse **Agentic Browsing** puanına ve harici AI tarayıcı ajanlarına yapılandırılmış özet sunar. Yapay zeka arama motorlarında (ChatGPT, Perplexity, AI Overviews) gerçek alıntı gücü için asıl belirleyici olan **Reddit (`r/nosurf`, `r/digitalminimalism`, `r/Letterboxd`), Hacker News (`Show HN`), YouTube ve bağımsız basın bahsetmeleridir**.

---

## 9. Gönderim, Lansman & İlk 30 Gün İcra Takvimi

### A. App Store Gönderimi Öncesi & Yayın Günü
- [ ] **1. Web Sitesini Cloudflare'e Yayınlayın (`wrangler`):**
  ```bash
  npx wrangler deploy
  ```
- [ ] **2. App Store Connect Bilgilerini Girin:** Bölüm 5'teki **9 yerel ayarın** Title, Subtitle, Keywords, Promotional Text, Description ve What's New alanlarını birebir yapıştırın; Primary: **Education**, Secondary: **Reference** seçin.
- [ ] **3. Ekran Görüntüleri:** 3. slayt (`ja/de/fr/es/ko`) güncellemelerini `app-store-screenshots` üzerinden dışa aktarıp 8×7 görselleri yükleyin.
- [ ] **4. Onay Sonrası Smart App Banner (`web-to-app-funnel`):** App Store Connect'ten uygulamanın sayısal `Apple ID`'si çıktığında [`web/index.html`](file:///Users/kuzey/projects/omakase/web/index.html#L11) ve [`web/en/index.html`](file:///Users/kuzey/projects/omakase/web/en/index.html#L11) içindeki `<meta name="apple-itunes-app" content="app-id=...">` yorum satırını açın, hero ve CTA butonlarına gerçek `https://apps.apple.com/app/id...` bağlantısını verip `wrangler deploy` tekrarlayın.

### B. Yayın Sonrası İlk 7–30 Gün (SEO + ASO Büyüme)
- [ ] **5. Google Search Console & Bing Webmaster Tools:** `https://getomakase.app/sitemap.xml` dosyasını gönderin; Rich Results Test ile JSON-LD `MobileApplication` şemasını doğrulayın.
- [ ] **6. Apple Editoryal Başvurusu (`app-store-featured`):** Yayın öncesi/günü `appstore.com/promote` üzerinden *"Anti-doomscrolling cultural micro-stories with mandatory primary sources in 7 languages"* açısıyla editörlere başvurun.
- [ ] **7. Haftalık Anahtar Kelime & ASA Kontrolü:** Apple Search Ads (`$100` başlangıç kredisi) ile `daily facts`, `micro learning`, `history trivia`, `anti doomscrolling` kelimelerindeki gerçek TTR/CR dönüşümünü ölçün; 30. günde düşük performanslı Keywords token'larını değiştirin.
