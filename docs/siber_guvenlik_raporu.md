# 🛡️ Omakase — Kapsamlı Siber Güvenlik Durumu ve Tehdit Analizi Raporu

> **Denetim & Sertleştirme Tarihi:** 26 Kasım 2026  
> **Son Bağımsız Yeniden Denetim:** 26 Kasım 2026 — Cloudflare [`security-audit-skill`](https://github.com/cloudflare/security-audit-skill) (Run 1; keşif → kapsam güdümlü avlanma → doğrulama → `findings.json` → bağımsız doğrulama)  
> **Kapsam:** Tüm Omakase ekosistemi — iOS İstemcisi (`omakase/`), FastAPI & Cloud Run Backend (`backend/`), Mission Control Admin Paneli (`admin-web/`, Firebase Hosting), Tanıtım Web Sitesi (`web/`, Cloudflare `wrangler.json`), Cloud Firestore Kuralları (`firestore.rules`), API Anahtarları, RevenueCat / Bildirim Altyapısı ve Sır (Secret) Yönetimi.  
> **Dayanak:** Kod tabanı statik güvenlik denetimi, git geçmişi taraması, [OWASP Mobile Top 10 / MASVS](https://mas.owasp.org/), [OWASP API Security Top 10](https://owasp.org/API-Security/), [`knowledge.networking.authenticated-requests`](file:///Users/kuzey/projects/omakase/.agents/knowledge/networking/authenticated-requests.md) ve Apple [`knowledge.app-store-review-guidelines.data-security`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/data-security.md).

---

## İçindekiler

1. [Yönetici Özeti & Güvenlik Karnesi](#1-yönetici-özeti--güvenlik-karnesi)
2. [Güven Sınırları (Trust Boundaries) & Mimari Harita](#2-güven-sınırları-trust-boundaries--mimari-harita)
3. [Bölüm 1: API Anahtarları, Sırlar (Secrets) ve Kimlik Bilgisi Yönetimi](#3-bölüm-1-api-anahtarları-sırlar-secrets-ve-kimlik-bilgisi-yönetimi)
4. [Bölüm 2: Backend & Google Cloud Run Güvenlik Analizi (`backend/`)](#4-bölüm-2-backend--google-cloud-run-güvenlik-analizi-backend)
5. [Bölüm 3: Cloud Firestore & Sosyal Grafik Güvenlik Analizi (`firestore.rules`)](#5-bölüm-3-cloud-firestore--sosyal-grafik-güvenlik-analizi-firestorerules)
6. [Bölüm 4: iOS İstemci, Mission Control (`admin-web/`) & Web (`web/`) Güvenlik Analizi](#6-bölüm-4-ios-i̇stemci-mission-control-admin-web--web-web-güvenlik-analizi)
7. [Bölüm 5: Siber Güvenlik Eylem Planı & Kalan Bulut Konsolu Adımları](#7-bölüm-5-siber-güvenlik-eylem-planı--kalan-bulut-konsolu-adımları)
8. [Bölüm 6: Güncel Denetim (26 Kasım 2026 — Faz 1–4, Admin & Cihaz Kota Koruması)](#8-bölüm-6-güncel-denetim-26-kasım-2026--faz-14-admin--cihaz-kota-koruması)
9. [Bölüm 7: Bağımsız Yeniden Denetim (26 Kasım 2026 — `security-audit-skill` Run 1)](#9-bölüm-7-bağımsız-yeniden-denetim-26-kasım-2026--security-audit-skill-run-1)

---

## 1. Yönetici Özeti & Güvenlik Karnesi

Önceki denetimde tespit edilen **tüm kritik ve yüksek öncelikli kod seviyesi zafiyetler (`S-01`, `S-02`, `S-04`–`S-15`) uygulamanın çalışırlığı bozulmadan kapatılmıştır:**

- **Backend API, LLM & Admin Koruması (`S-01`, `S-02`, `S-12`, `S-14`):** Tüm kullanıcı uç noktalarına kriptografik **Firebase ID Token (`Authorization: Bearer <token>`) doğrulaması** ve **sliding-window hız sınırlaması** eklenmiştir. Tüm `/admin/*` uç noktaları ayrıca `verify_admin_user` (`ADMIN_UIDS` / doğrulanmış `ADMIN_EMAILS`, 401/403) ile korunur. iOS tarafında [`APITokenProvider`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L16-L133) aktörü single-flight `401` yenileme ve `X-Omakase-Device-Id` eklemesi yapar.
- **Cihaz-Bazlı Kota Suistimali Koruması (`S-13`):** Ücretsiz günlük 3 post / 1 Letterboxd / 1 Derin İnceleme sınırının Apple, Google ve E-posta hesapları arasında geçiş yapılarak veya hesap silip yeniden açılarak aşılmasını önlemek için Keychain tabanlı anonim kurulum kimliği (`quotaDeviceID`) + sunucu tarafı SHA-256 `device_usage/{hash}_{yyyymmdd}` birleştirmesi devreye alınmıştır.
- **PII, Atomik Kullanıcı Adı & Sosyal Grafik (`S-04`, `S-06`, `S-11`, `S-15`):** `users/{uid}` belgelerinden `email` ve üçüncü taraf `photoURL` alanları temizlenmiştir (`FieldValue.delete()`); `usernames/{handle}` koleksiyonu ile atomik benzersizlik ve `firestore.rules` içinde **14 günlük kullanıcı adı değiştirme beklemesi** (`isValidUsernameUpdate`) zorunlu kılınmıştır.
- **Mission Control İzolasyonu, SSRF, XXE & Prompt Injection (`S-05`, `S-07`, `S-08`, `S-09`, `S-14`):** `admin-web/` paneli `web/`'den tamamen ayrılarak Firebase Hosting üzerinde `noindex, nofollow`, COOP, HSTS ve sıkı CSP ile izole edilmiştir; `web/` (`getomakase.app`) ise Cloudflare (`wrangler.json`) üzerinden sunulur.

> **26 Kasım 2026 Bağımsız Yeniden Denetim Notu:** Cloudflare `security-audit-skill` ile yapılan ikinci tur denetimde, önceki `S-01`–`S-15` kapanışlarının büyük ölçüde korunduğu doğrulandı; ancak **9 yeni doğrulanmış bulgu (`S-16`–`S-24`)** ve konsol doğrulaması gereken `S-03` tespit edildi. Yeni bulguların hiçbiri önceki kritik kapanışları geri almıyor; en yüksek öncelikliler `S-16` (kota kaçağı) ve `S-17` (sahte sosyal bildirim) olarak sınıflandırıldı.

### Risk Matrisi (Güncel Durum Tablosu)

| # | Önem | Durum | Alan | Bulgu / Zafiyet Başlığı | Uygulanan Çözüm & İlgili Konum |
|---|------|-------|------|-------------------------|--------------------------------|
| **S-01** | 🚨 **KRİTİK (P0)** | ✅ **ÇÖZÜLDÜ** | Backend API / LLM | Kimlik doğrulamasız Gemini uç noktaları (**Denial of Wallet**) | `verify_firebase_user` + `APITokenProvider` Bearer token & 401 retry ([`backend/app/security.py`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L89-L140), [`SSEClient.swift#L16-L133`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L16-L133)) |
| **S-02** | 🔴 **YÜKSEK (P0)** | ✅ **ÇÖZÜLDÜ** | Backend API / DoS | Rate Limiting yokluğu ve sınırsız `DeepDiveRequest` / `letterboxd_films` girdileri | `_check_rate_limit` (sliding window) + Pydantic boyut/tip sınırları ([`backend/app/security.py#L64-L87`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L64-L87), [`backend/app/schemas.py`](file:///Users/kuzey/projects/omakase/backend/app/schemas.py)) |
| **S-03** | 🔴 **YÜKSEK (P1)** | ⚠️ **GCP KONSOL** | Secrets / GCP | `GoogleService-Info.plist` içindeki Firebase `API_KEY`'in (`AIzaSyBr65...`) GCP kısıtlama riski | GCP Console → Credentials üzerinden Bundle ID (`kuzeysinay.omakase`) + API kısıtlaması yapılmalı ([Bölüm 3.2](#32-firebase-api_key-googleservice-infoplist-ve-gcp-proje-kısıtlama-riski--s-03--bulut-konsolu-i̇şlemi)) |
| **S-04** | 🔴 **YÜKSEK (P1)** | ✅ **ÇÖZÜLDÜ** | Firestore / PII | `users/{userId}` belgelerinde `email` alanının tüm giriş yapmış kullanıcılara açık okunması | `users/{uid}` yazımlarından `email` ve `photoURL` silindi (`FieldValue.delete()`); e-posta `AuthService`'ten okunuyor ([`FirestoreService.swift#L89-L93`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift#L89-L93)) |
| **S-05** | 🟠 **YÜKSEK (P1)** | ✅ **ÇÖZÜLDÜ** | Backend / SSRF | `/letterboxd/films` doğrulanmamış `username` path traversal & XML riski | `^[a-zA-Z0-9_-]{1,40}$` regex, `https://letterboxd.com/` redirect kontrolü, 2 MB limit ve `<!DOCTYPE`/`<!ENTITY` reddi ([`letterboxd_service.py`](file:///Users/kuzey/projects/omakase/backend/app/services/letterboxd_service.py)) |
| **S-06** | 🟠 **ORTA-YÜKSEK (P1)** | ✅ **ÇÖZÜLDÜ** | Firestore Rules | `following` / `followers` "Forced Follow" ve `shared_posts` sayaç/rapor manipülasyonu | `following`/`followers`/`reactions` `create, update` sahibe kısıtlandı; `commentCount` ±1 ve `reportedBy` ekleme kuralları eklendi ([`firestore.rules#L409-L537`](file:///Users/kuzey/projects/omakase/firestore.rules#L409-L537)) |
| **S-07** | 🟡 **ORTA (P2)** | ✅ **ÇÖZÜLDÜ** | Backend / Hardening | Ham hata sızıntısı, `/health` ifşası, `CORS *` ve `Dockerfile` root | Genel hata mesajları ([`errors.py`](file:///Users/kuzey/projects/omakase/backend/app/errors.py)), sade `/health` ([`main.py#L102-L105`](file:///Users/kuzey/projects/omakase/backend/main.py#L102-L105)), `ALLOWED_CORS_ORIGINS` ([`config.py#L89-L96`](file:///Users/kuzey/projects/omakase/backend/app/config.py#L89-L96)) ve `USER appuser` ([`Dockerfile#L12-L13`](file:///Users/kuzey/projects/omakase/backend/Dockerfile#L12-L13)) |
| **S-08** | 🟡 **ORTA (P2)** | ✅ **ÇÖZÜLDÜ** | Backend / AI | Doğrudan metin birleştirmeye dayalı Prompt Injection yüzeyi | `_sanitize_single_line` + `<user_context>` XML izolasyonu ve sistem prompt savunma kuralları ([`backend/app/prompts.py`](file:///Users/kuzey/projects/omakase/backend/app/prompts.py)) |
| **S-09** | 🟡 **ORTA (P2)** | ✅ **ÇÖZÜLDÜ** | Web & Auth | Hosting güvenlik başlıkları (CSP/HSTS) ve 6 karakter parola sınırı | `firebase.json` CSP/HSTS/COOP/X-Frame-Options eklendi; yeni kayıtlarda minimum parola 8 karaktere çıkarıldı ([`firebase.json`](file:///Users/kuzey/projects/omakase/firebase.json), [`AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift)) |
| **S-10** | ✅ **GÜVENLİ** | ✅ **KORUNDU** | iOS / Depolama | `GEMINI_API_KEY` gizliliği, Apple SHA-256 Nonce + Keychain ve ATS uyumluluğu | İstemci tarafı API sır sızıntısı yok; `Release` derlemelerinde `http://127.0.0.1` fallback'i `#if DEBUG` ile izole ([`SSEClient.swift#L25-L37`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L25-L37)) |
| **S-11** | 🟠 **ORTA-YÜKSEK (P1)** | ✅ **ÇÖZÜLDÜ** | Firestore Rules | Eksik `hasOnly` anahtar kilidi, kendini takip, engelli takip ve `reportedBy` silme riski | [`firestore.rules`](file:///Users/kuzey/projects/omakase/firestore.rules) tüm validator'lara `hasOnly` + timestamp tip kilidi eklendi, kendini takip & engelli takip engellendi, yazarın `reportedBy` değiştirmesi kilitlendi |
| **S-12** | 🟡 **ORTA (P2)** | ✅ **ÇÖZÜLDÜ** | Backend / Billing & Push | `/billing/status`, `/billing/sync` rate-limit eksikliği + `actor_name` spoofing | [`billing.py`](file:///Users/kuzey/projects/omakase/backend/app/routers/billing.py) rate limit (`30/dk`, `10/dk`) + [`notification_service.py`](file:///Users/kuzey/projects/omakase/backend/app/services/notification_service.py) `_resolve_actor_display_name` eklendi |
| **S-13** | 🟠 **YÜKSEK (P1)** | ✅ **ÇÖZÜLDÜ** | Kota / Anti-Abuse | Ücretsiz kullanıcıların hesap değiştirerek/silerek günlük 3 post sınırını atlaması | Keychain `quotaDeviceID` (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) + `X-Omakase-Device-Id` + sunucu SHA-256 `device_usage` ([`SSEClient.swift#L42-L79`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L42-L79), [`access_service.py#L182-L299`](file:///Users/kuzey/projects/omakase/backend/app/services/access_service.py#L182-L299)) |
| **S-14** | 🔴 **YÜKSEK (P1)** | ✅ **ÇÖZÜLDÜ** | Admin & Hosting | Mission Control uç noktalarının korunması ve admin panelinin halka açık siteden ayrılması | `verify_admin_user` (`ADMIN_UIDS` / verified `ADMIN_EMAILS`) + `/admin/*` rate limits ([`security.py#L150-L235`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L150-L235), [`admin.py`](file:///Users/kuzey/projects/omakase/backend/app/routers/admin.py)); `admin-web/` `firebase.json` üzerinde `noindex, nofollow` + CSP ile izole |
| **S-15** | 🟡 **ORTA (P2)** | ✅ **ÇÖZÜLDÜ** | Firestore / Kimlik | `@username` yarış durumu (race condition) ve sınırsız kimlik değiştirme | Atomik `usernames/{handle}` koleksiyonu + `isValidUsernameUpdate()` ile 14 günlük sunucu zamanlı bekleme ([`firestore.rules#L187-L213`](file:///Users/kuzey/projects/omakase/firestore.rules#L187-L213), [`firestore.rules#L454-L463`](file:///Users/kuzey/projects/omakase/firestore.rules#L454-L463)) |

### 1.1. Bağımsız Yeniden Denetim Özeti (S-16–S-24)

| # | Önem | Durum | Alan | Bulgu | Birincil Kanıt |
|---|------|-------|------|-------|----------------|
| **S-16** | 🟠 **ORTA** | ⚠️ **AÇIK** | Backend / Kota | SSE bağlantısı kesildiğinde günlük kota düşülmüyor; Gemini maliyeti kotasız üretilebiliyor | [`gemini_service.py#L334`](file:///Users/kuzey/projects/omakase/backend/app/services/gemini_service.py#L334), [`feed.py#L61`](file:///Users/kuzey/projects/omakase/backend/app/routers/feed.py#L61) |
| **S-17** | 🟠 **ORTA** | ⚠️ **AÇIK** | Backend / Bildirim | Sosyal bildirimler gerçek yorum/reaksiyon kaydına bağlı değil; sahte push ve içerik enjeksiyonu | [`notification_service.py#L416`](file:///Users/kuzey/projects/omakase/backend/app/services/notification_service.py#L416), [`#L603`](file:///Users/kuzey/projects/omakase/backend/app/services/notification_service.py#L603) |
| **S-18** | 🟡 **DÜŞÜK** | ⚠️ **AÇIK** | Firestore / Bütünlük | Herhangi bir kullanıcı gönderi sayaçlarını (`reactionCounts`, `totalReactions`) keyfi değiştirebiliyor | [`firestore.rules#L479-L502`](file:///Users/kuzey/projects/omakase/firestore.rules#L479-L502) |
| **S-19** | 🟡 **DÜŞÜK** | ⚠️ **AÇIK** | Firestore / PII | `users/{uid}` kuralları `email` alanını kabul ediyor ve tüm oturum açmış kullanıcılara okutuyor | [`firestore.rules#L177`](file:///Users/kuzey/projects/omakase/firestore.rules#L177), [`#L377`](file:///Users/kuzey/projects/omakase/firestore.rules#L377) |
| **S-20** | 🟡 **DÜŞÜK** | ⚠️ **AÇIK** | Backend / DoS | Hız sınırlayıcı süreç içi ve sınırsız büyüyor; çoklu Cloud Run örneklerinde aşılabilir | [`security.py#L27`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L27), [`#L64-L87`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L64-L87) |
| **S-21** | 🟡 **DÜŞÜK** | ⚠️ **AÇIK** | Yapılandırma / Yetki | Yönetici UID'si ve 50 tabak kota istisnası kaynak kodda varsayılan olarak gömülü | [`config.py#L43-L47`](file:///Users/kuzey/projects/omakase/backend/app/config.py#L43-L47), [`#L85-L87`](file:///Users/kuzey/projects/omakase/backend/app/config.py#L85-L87) |
| **S-22** | 🟡 **DÜŞÜK** | ⚠️ **AÇIK** | Admin / CSP | Mission Control CSP'si `script-src 'unsafe-inline'` ve üretimde localhost `connect-src` içeriyor | [`firebase.json#L52`](file:///Users/kuzey/projects/omakase/firebase.json#L52) |
| **S-23** | 🟡 **DÜŞÜK** | ⚠️ **AÇIK** | Firestore / Moderasyon | `reportedBy` listesi kısmen değiştirilebiliyor; moderasyon kanıtı silinebilir/forjenebilir | [`firestore.rules#L498-L502`](file:///Users/kuzey/projects/omakase/firestore.rules#L498-L502) |
| **S-24** | 🟡 **DÜŞÜK** | ⚠️ **AÇIK** | Kota / Anti-abuse | Cihaz kotası istemci başlığına bağlı; başlık atlanarak/döndürülerek S-13 koruması devre dışı bırakılabilir | [`access_service.py#L183`](file:///Users/kuzey/projects/omakase/backend/app/services/access_service.py#L183), [`#L296-L298`](file:///Users/kuzey/projects/omakase/backend/app/services/access_service.py#L296-L298) |
| **S-03** | 🔴 **YÜKSEK (koşullu)** | ⚠️ **GCP KONSOL** | Secrets / GCP | Firebase iOS API anahtarının GCP kısıtlamaları depodan doğrulanamıyor; canlı konsol kontrolü gerekli | [`GoogleService-Info.plist#L10`](file:///Users/kuzey/projects/omakase/omakase/omakase/GoogleService-Info.plist#L10) |

---

## 2. Güven Sınırları (Trust Boundaries) & Mimari Harita

```mermaid
flowchart LR
    Attacker["🌐 Dış Saldırgan / Bot<br/>(Auth Token YOK)"] -->|🚫 HTTP 401 / 403 / 429 Red| CloudRun["☁️ Google Cloud Run<br/>FastAPI (backend/main.py + 7 Router)<br/>✅ Firebase JWT + Admin Allowlist + Rate Limit"]
    iOS["📱 Omakase iOS<br/>(APITokenProvider + Keychain Device Hash)"] -->|HTTPS POST<br/>Bearer JWT + X-Omakase-Device-Id| CloudRun
    Admin["🛡️ Mission Control (admin-web/)<br/>Firebase Hosting (noindex, CSP, HSTS)"] -->|Bearer JWT ADMIN_UIDS| CloudRun
    CloudRun -->|os.getenv GEMINI_API_KEY| Gemini["✨ Google Gemini API<br/>(Korumalı Kota)"]
    CloudRun -->|Admin SDK| Firestore["🔥 Cloud Firestore<br/>(device_usage, metrics_daily,<br/>entitlements, usage — İstemciye Kapalı)"]
    iOS -->|Firebase SDK + JWT| Firestore
    Browser["🖥️ Tanıtım Sitesi (getomakase.app)"] -->|Cloudflare wrangler.json| WebFiles["📄 web/ Statik Dosyalar"]
```

---

## 3. Bölüm 1: API Anahtarları, Sırlar (Secrets) ve Kimlik Bilgisi Yönetimi

### 3.1. Sunucu Sırları (`GEMINI_API_KEY`, RevenueCat & Cron/Webhook) — ✅ Tam Korumalı
* [`backend/app/config.py#L21-L41`](file:///Users/kuzey/projects/omakase/backend/app/config.py#L21-L41) üzerinden tüm hassas anahtarlar (`GEMINI_API_KEY`, `REVENUECAT_SECRET_API_KEY`, `REVENUECAT_V2_SECRET_API_KEY`, `REVENUECAT_WEBHOOK_SECRET`, `NOTIFICATION_CRON_SECRET`, `ADMIN_ALERT_WEBHOOK_URL`) yalnızca ortam değişkenlerinden okunur; iOS istemcisine (`omakase/`) hiçbir sunucu gizli anahtarı gömülmemiştir ([`knowledge.app-store-review-guidelines.data-security`](file:///Users/kuzey/projects/omakase/.agents/knowledge/app-store-review-guidelines/data-security.md) **Rule 3** uyumlu).
* `.env` dosyaları kök [`.gitignore`](file:///Users/kuzey/projects/omakase/.gitignore) ve `backend/.dockerignore` ile dışlanmıştır.
* `REVENUECAT_WEBHOOK_SECRET` ve `NOTIFICATION_CRON_SECRET` doğrulamaları sabit zamanlı `hmac.compare_digest` ile yapılır.

### 3.2. Firebase `API_KEY` (`GoogleService-Info.plist`) ve GCP Proje Kısıtlama Riski (⚠️ S-03 — Bulut Konsolu İşlemi)
* **İlgili Dosya:** [`omakase/omakase/GoogleService-Info.plist`](file:///Users/kuzey/projects/omakase/omakase/omakase/GoogleService-Info.plist)
* **Teknik Değerlendirme:** Firebase iOS `API_KEY` (`AIzaSyBr65...`) herkese açık istemci yapılandırmasıdır; ancak aynı GCP projesinde (`gen-lang-client-0120875563`) Generative Language API etkin olduğu için GCP Console üzerinden kısıtlama eklenmelidir:
  1. **Google Cloud Console → APIs & Services → Credentials** altından `AIzaSyBr65...` anahtarını açın.
  2. **Application restrictions:** `iOS apps` → yalnızca `kuzeysinay.omakase`.
  3. **API restrictions:** `Restrict key` seçip yalnızca `Identity Toolkit API`, `Token Service API`, `Firebase Installations API` ve `Cloud Firestore API` izinlerini bırakın; **`Generative Language API` kesinlikle kapalı** olmalıdır.

### 3.3. İstemci Tarafı Kimlik & Cihaz Özeti Saklama (✅ S-10 & S-13)
* [`AuthService.swift`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift) içinde Sign in with Apple kullanıcı kimliği (`com.omakase.auth.appleIDUser`) iOS **Keychain**'de (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) saklanır; kriptografik nonce `SecRandomCopyBytes` + `CryptoKit.SHA256` ile üretilir.
* [`SSEClient.swift#L42-L72`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L42-L72) içindeki `APITokenProvider.quotaDeviceID`, Keychain'de (`kuzeysinay.omakase.device` / `quota_device_id`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) yalnızca anonim kota suistimali önlemi için saklanır; iCloud'a yedeklenmez/senkronlanmaz ve reklam amaçlı takip kimliği içermez.

---

## 4. Bölüm 2: Backend & Google Cloud Run Güvenlik Analizi (`backend/`)

### 4.1. [✅ ÇÖZÜLDÜ — S-01 & S-14] Firebase ID Token & Admin Allowlist Doğrulaması
* **Kullanıcı Uç Noktaları ([`backend/app/security.py#L89-L140`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L89-L140)):** `verify_firebase_user` gelen `Bearer` token'ı `google.oauth2.id_token.verify_firebase_token` ile doğrular (token hash'i kısa ömürlü bellek içi önbellekte tutulur). İstemci tarafında [`APITokenProvider`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L16-L133) single-flight `401` token yenileme uygular.
* **Admin Uç Noktaları ([`backend/app/security.py#L150-L235`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L150-L235)):** `verify_admin_user` bağımlılığı `uid in ADMIN_UIDS` veya `email_verified and email in ADMIN_EMAILS` kontrolü yapar; yetkisiz oturumları `403 Forbidden`, eksik/geçersiz token'ları `401 Unauthorized` ile reddeder.

### 4.2. [✅ ÇÖZÜLDÜ — S-02 & S-12] Rate Limiting ve Sıkı Pydantic Girdi Sınırları
* **Sliding-Window Hız Sınırı ([`security.py#L64-L87`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L64-L87)):** `/feed/stream` (`20/dk`), `/feed/deep-dive` (`20/dk`), `/feed/reward-share` (`10/dk`), `/interests/suggest` (`30/dk`), `/interests/expand-category` (`30/dk`), `/letterboxd/films` (`10/dk`), `/billing/status` (`30/dk`), `/billing/sync` (`10/dk`), `/telemetry/events` (`60/dk`), `/feedback` (`5/dk`), `/admin/overview` (`30/dk`), `/admin/export` (`20/dk`), `/admin/*` okuma/yazma (`60/dk`).
* **Pydantic Sınırları ([`backend/app/schemas.py`](file:///Users/kuzey/projects/omakase/backend/app/schemas.py)):** `FeedRequest`, `DeepDiveRequest`, `SuggestRequest`, `ExpandCategoryRequest`, `LetterboxdFilmsRequest`, `TelemetryBatchRequest` ve `FeedbackSubmitRequest` üzerinde alan uzunluğu, maksimum öğe sayısı ve `_BLOCKLIST_RE` kontrolleri zorunludur.

### 4.3. [✅ ÇÖZÜLDÜ — S-05] `/letterboxd/films` SSRF & XML Sertleştirmesi
* [`backend/app/services/letterboxd_service.py`](file:///Users/kuzey/projects/omakase/backend/app/services/letterboxd_service.py): `^[a-zA-Z0-9_-]{1,40}$` whitelist regex, yalnızca `https://letterboxd.com/` redirect kabulü, 2 MB yanıt üst sınırı (`_MAX_RSS_BYTES`) ve `ET.fromstring` öncesi `<!DOCTYPE` / `<!ENTITY` reddi uygulanır.

### 4.4. [✅ ÇÖZÜLDÜ — S-08] Prompt Injection İzolasyonu
* [`backend/app/prompts.py`](file:///Users/kuzey/projects/omakase/backend/app/prompts.py): Kullanıcı girdileri `_sanitize_single_line` ile temizlenip `<user_context>...</user_context>` etiketleri içinde izole edilir; tüm sistem promptlarında veri olarak işlenmesi zorunlu kılınır.

### 4.5. [✅ ÇÖZÜLDÜ — S-07] Hata Mesajı Temizliği, `/health`, CORS ve Non-Root `Dockerfile`
* `OmakaseAPIError` ([`errors.py`](file:///Users/kuzey/projects/omakase/backend/app/errors.py)) istemciye ham istisna detaylarını sızdırmaz; `/health` ([`main.py#L102-L105`](file:///Users/kuzey/projects/omakase/backend/main.py#L102-L105)) yalnızca `{"status": "ok"}` döner.
* `CORSMiddleware` ([`config.py#L89-L96`](file:///Users/kuzey/projects/omakase/backend/app/config.py#L89-L96)) yalnızca resmi Omakase domainleri (`https://getomakase.app`, `https://www.getomakase.app`, `https://gen-lang-client-0120875563.web.app`, `.firebaseapp.com` ve localhost dev portları) ile sınırlıdır ve `X-Omakase-Device-Id`, `X-Omakase-Timezone` başlıklarına izin verir.
* [`backend/Dockerfile#L12-L13`](file:///Users/kuzey/projects/omakase/backend/Dockerfile#L12-L13) `appuser` (`UID 10001`) olarak çalışır.

---

## 5. Bölüm 3: Cloud Firestore & Sosyal Grafik Güvenlik Analizi (`firestore.rules`)

### 5.1. [✅ ÇÖZÜLDÜ — S-04 & S-15] `users/{userId}` PII Temizliği ve `usernames/{handle}` Atomik Kilidi
* [`FirestoreService.swift#L89-L93`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift#L89-L93) içinde `ensureUserProfile` artık `users/{uid}` belgelerine `email` veya `photoURL` yazmamakta ve mevcut belgelerdeki eski alanları `"email": FieldValue.delete()`, `"photoURL": FieldValue.delete()` ile temizlemektedir.
* [`firestore.rules#L187-L213`](file:///Users/kuzey/projects/omakase/firestore.rules#L187-L213) ve [`#L454-L463`](file:///Users/kuzey/projects/omakase/firestore.rules#L454-L463): `usernames/{handle}` (`^[a-z0-9_.]{3,20}$`) koleksiyonu `!exists(...)` ve `uid == request.auth.uid` kontrolüyle aynı kullanıcı adının iki hesaba verilmesini engeller; `isValidUsernameUpdate()` ise `usernameUpdatedAt` üzerinden sunucu saatiyle (`request.time`) **14 günlük değişim beklemesini** zorunlu kılar.

### 5.2. [✅ ÇÖZÜLDÜ — S-06 & S-11] Sosyal Grafik, Sayaçlar ve Sunucu Koleksiyonları
* `following`, `followers`, `blocked_users`, `shared_posts`, `reactions`, `comments` ve `moderation_reports` belgelerinin tamamında `hasOnly` alan beyaz listeleri, `timestamp` tip doğrulaması, kendini takip etme engeli, çift yönlü engel kontrolü ve yazarın `reportedBy` listesini silememesi uygulanmıştır.
* `entitlements/{userId}` ve `usage/{docId}` istemci yazımına kapalıdır (`allow create, update, delete: if false`).
* `device_usage`, `metrics_daily`, `daily_active`, `user_feedback`, `notification_queue`, `notification_cooldowns` koleksiyonları varsayılan red (`allow read, write: if false`) ile tüm istemci erişimine kapalıdır.
* *Takip Notu (Minör Uyum):* [`firestore.rules#L330`](file:///Users/kuzey/projects/omakase/firestore.rules#L330) ve [`#L368`](file:///Users/kuzey/projects/omakase/firestore.rules#L368) içinde `devices` ve `notification_prefs` belgelerindeki `language` alanı şu an `['en', 'tr']` olarak kısıtlıdır; diğer 5 dil (`ja, de, fr, es, ko`) kullanıcılarının FCM tercih yazabilmesi için canlı deploy öncesi 7 dile genişletilmelidir.

---

## 6. Bölüm 4: iOS İstemci, Mission Control (`admin-web/`) & Web (`web/`) Güvenlik Analizi

### 6.1. [✅ ÇÖZÜLDÜ — S-10] iOS İstemci Ağı, Derleme ve Hesap Silme Güvenliği
* [`SSEClient.swift#L25-L37`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L25-L37) içinde `http://127.0.0.1:8000` yalnızca `#if DEBUG` derlemelerinde aktiftir; `Release` derlemeleri yalnızca HTTPS Cloud Run adresini kullanır.
* [`AuthService.swift#L446-L483`](file:///Users/kuzey/projects/omakase/omakase/omakase/Auth/AuthService.swift#L446-L483) içinde hesap silme (`deleteAccount`) Apple token iptalini, tüm Firestore verilerinin silinmesini, Firebase Auth silinmesini ve yerel `PostCacheService` + `BookmarkStore` + `UserDefaults` temizliğini eksiksiz uygular.

### 6.2. [✅ ÇÖZÜLDÜ — S-09 & S-14] Mission Control (`admin-web/`) ve Tanıtım Web (`web/`) Ayrımı
* **Mission Control (`admin-web/`):** 25 Kasım'da `web/` dizininden çıkarılarak yalnızca Firebase Hosting üzerinden sunulacak şekilde izole edilmiştir ([`firebase.json`](file:///Users/kuzey/projects/omakase/firebase.json)). `X-Robots-Tag: noindex, nofollow`, `Strict-Transport-Security`, `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Cross-Origin-Opener-Policy: same-origin-allow-popups`, `Referrer-Policy` ve `Permissions-Policy` başlıkları tanımlıdır.
* **Tanıtım Sitesi (`web/` — `getomakase.app`):** [`wrangler.json`](file:///Users/kuzey/projects/omakase/wrangler.json) ile Cloudflare statik barındırmada sunulur; hiçbir admin kodu, özel API anahtarı veya yönetim arayüzü içermez. *(Öneri: Cloudflare yanıt başlıklarına da HSTS / `X-Content-Type-Options: nosniff` / CSP kuralları eklenmesi savunma derinliğini artırır.)*

---

## 7. Bölüm 5: Siber Güvenlik Eylem Planı & Kalan Bulut Konsolu Adımları

### Kod Tabanında Tamamlananlar
- [x] **S-01, S-02, S-04 – S-12:** Firebase JWT, Sliding-Window Rate Limiting, Pydantic sınırları, PII temizliği, `firestore.rules` sertleştirmesi (`5/5`), Letterboxd SSRF/XXE, Prompt Injection `<user_context>`, non-root `Dockerfile`, 8 karakter parola, billing/notification sertleştirmeleri.
- [x] **S-13 (Cihaz Bazlı Kota Koruması):** Keychain `quotaDeviceID` + `X-Omakase-Device-Id` + SHA-256 `device_usage` ([`access_service.py`](file:///Users/kuzey/projects/omakase/backend/app/services/access_service.py)).
- [x] **S-14 (Mission Control Güvenliği):** `verify_admin_user`, `/admin/*` rate limits, `admin-web/` ayrı Firebase Hosting izolasyonu ve güvenlik başlıkları.
- [x] **S-15 (`@username` Atomikliği & Bekleme Süresi):** `usernames/{handle}` + 14 gün sunucu zamanlı bekleme kuralı.

### Bağımsız Yeniden Denetim Aksiyonları (S-16–S-24)
- [ ] **S-16 (Orta):** Kota tüketimini akış sonundan çıkarıp üretim başında atomik rezervasyona çevir; bağlantı kesintisinde rezervasyonu koru ([`gemini_service.py#L334`](file:///Users/kuzey/projects/omakase/backend/app/services/gemini_service.py#L334)).
- [ ] **S-17 (Orta):** `/notifications/events` olaylarını gerçek `comments`/`reactions` belgesine bağla veya bildirimi Firestore tetikleyicisine taşı; `comment_preview` yerine saklanan `text` alanını kullan.
- [ ] **S-18 (Düşük):** `shared_posts` sayaç güncellemelerini Admin SDK/Cloud Function'a taşı; geçiş döneminde ±1 delta ve reaksiyon belgesi varlığı ile sınırla.
- [ ] **S-19 (Düşük):** `isValidUserProfile` içinden `email` alanını çıkar ve yazımı reddet; mevcut belgelerdeki alanı migrasyonla sil.
- [ ] **S-20 (Düşük):** Dağıtık hız sınırlama (Cloud Armor/API Gateway/Redis) veya en azından TTL temizliği ekle; üretimde `OMAKASE_REQUIRE_AUTH=true` zorunluluğunu koru.
- [ ] **S-21 (Düşük):** `ADMIN_UIDS` varsayılanını kaldır (fail-closed) ve kota istisnasını denetlenebilir yapılandırmaya taşı.
- [ ] **S-22 (Düşük):** Admin CSP'sinden `'unsafe-inline'` ve localhost `connect-src` kökenlerini çıkar.
- [ ] **S-23 (Düşük):** `reportedBy` güncellemesini `eski liste ∪ {request.auth.uid}` kesin küme kontrolüne bağla.
- [ ] **S-24 (Düşük):** App Check (App Attest/DeviceCheck) ile cihaz bütünlüğünü doğrula; ücretsiz katmanda eksik `X-Omakase-Device-Id` başlığını reddet.
- [ ] **S-03 (Konsol):** GCP Credentials altında iOS API anahtarını bundle ID + gerekli API'lerle sınırla; Generative Language API erişimini kaldır.

### Canlı Ortam (Cloud Console & CLI) Dağıtım Adımları
- [ ] **1. Güncel Backend'i Cloud Run'a Dağıtın** (`ADMIN_UIDS`, `REVENUECAT_V2_SECRET_API_KEY`, opsiyonel `ADMIN_ALERT_WEBHOOK_URL` dahil):
  ```bash
  cd backend && gcloud run deploy omakase-backend --source . --region us-central1 --project gen-lang-client-0120875563
  ```
- [ ] **2. Güncel Firestore Kurallarını (`language` 7 dil güncellemesi sonrası) ve Mission Control Hosting'i Dağıtın:**
  ```bash
  firebase deploy --only firestore:rules,hosting --project gen-lang-client-0120875563
  ```
- [ ] **3. Tanıtım Sitesini (`web/`) Cloudflare'e Dağıtın** ve Cloudflare Transform Rules üzerinden `nosniff` / HSTS başlıklarını doğrulayın.
- [ ] **4. Google Cloud Console'da `AIzaSyBr65...` Anahtarını Kısıtlayın (`S-03`)** ve Firebase Console'da **App Check (App Attest)** + **Email Enumeration Protection**'ı etkinleştirin.

---

## 8. Bölüm 6: Güncel Denetim (26 Kasım 2026 — Faz 1–4, Admin & Cihaz Kota Koruması)

### 8.1. Yeni Sistemlerin Güvenlik Doğrulaması
* **Cihaz-Bazlı Kota Koruması (`S-13`):** İstemcinin gönderdiği `X-Omakase-Device-Id` en az 8, en fazla 128 karakter doğrulanır ve sunucuda sabit tuzlu (`omakase-device-quota:`) SHA-256 hash'ine dönüştürülerek 32 karakterlik özet olarak `device_usage/{hash}_{yyyymmdd}` belgesinde saklanır. Ham cihaz ID'si veritabanında tutulmaz; `device_usage` istemci okumasına/yazmasına tamamen kapalıdır ve `test_device_quota_prevents_free_account_switching_abuse` birim testiyle doğrulanmıştır.
* **Mission Control & Telemetri (`S-14`):** `POST /telemetry/events` (`60/dk`) ve `POST /feedback` (`5/dk`) yalnızca doğrulanmış Firebase kullanıcısı kabul eder ve `metrics_daily`, `daily_active`, `user_feedback` koleksiyonlarına yalnızca Admin SDK yazar. Tüm `/admin/*` uç noktaları `verify_admin_user` ile korunur; `test_admin_and_telemetry.py` tarafından red-team erişim testlerinden geçirilmiştir.
* **Monetizasyon & Bildirimler:** RevenueCat v1/v2 anahtarları ve `NOTIFICATION_CRON_SECRET` yalnızca sunucu ortamındadır; `entitlements/{uid}` ve `usage/{uid}_{yyyymmdd}` istemci yazımına kapalıdır.

### 8.2. `firestore.rules` Güvenlik Durumu Özeti
`S-11` ve `S-15` sonrası `firestore.rules`:
- Tüm kullanıcı yazılabilir koleksiyonlarda sıkı `hasOnly` anahtar beyaz listeleri, tip/uzunluk sınırları, sunucu zamanı tabanlı 14 gün `@username` beklemesi, kendini/engelliyi takip yasağı ve `reportedBy` değişmezliği uygulanmaktadır.
- İdari ve sunucu koleksiyonları (`entitlements`, `usage`, `device_usage`, `metrics_daily`, `daily_active`, `user_feedback`, `notification_queue`, `notification_cooldowns`) istemci yazımına (ve `usage`/`entitlements` dışındakiler istemci okumasına da) tamamen kapalıdır.
- *Açık Küçük İş:* `devices` (`#L330`) ve `notification_prefs` (`#L368`) içindeki `language in ['en', 'tr']` listesi deploy öncesi 7 dile genişletilmelidir.

---

## 9. Bölüm 7: Bağımsız Yeniden Denetim (26 Kasım 2026 — `security-audit-skill` Run 1)

### 9.1. Metodoloji ve Kapsam

Bu tur, [Cloudflare `security-audit-skill`](https://github.com/cloudflare/security-audit-skill) metodolojisiyle yürütülmüştür:

1. **Keşif (Reconnaissance):** Depo yapısı, güven sınırları, kimlik doğrulama akışı, kota/faturalama, Firestore kuralları, iOS istemcisi, admin paneli ve hosting yapılandırması haritalandı.
2. **Kapsam güdümlü avlanma (Coverage-led hunting):** Her alt sistem için saldırı sınıfları (yetkilendirme, kota/DoS, veri bütünlüğü, PII, XSS, SSRF, sır sızıntısı, prompt injection) eşlendi.
3. **Aday doğrulama:** Kaynak izi (entrypoint → propagation → sink), mevcut testler ve kural semantiği ile doğrulandı.
4. **Yapılandırılmış bulgular:** `findings.json` (13 bulgu: 9 doğrulanmış, 1 doğrulama bekleyen, 3 reddedilmiş) ve `coverage-ledger.json` (14 kapsam birimi) üretildi; skill'in `validate-findings.cjs` ve `validate-coverage-ledger.cjs` doğrulayıcılarıyla **PASS** alındı.
5. **Bağımsız doğrulama ve raporlama:** Bulgular hedeften bağımsız, kanıt ve yeniden üretim adımlarıyla raporlandı.

**Sınır:** Bu tur statik/kaynak güdümlü bir denetimdir; canlı ortamda exploit çalıştırılmamıştır. GCP/Firebase konsol durumu (S-03), RevenueCat paneli, APNs sertifikaları ve üçüncü taraf CVE taraması kapsam dışıdır.

### 9.2. Yeni Bulgular — Ayrıntılı Analiz

#### S-16 — Bağlantı kesintisinde kota düşülmüyor (Orta)

- **Kök neden:** Kota tüketimi `on_complete` callback'ine bağlı; akış sırasında bağlantı kesilirse `gemini_service._stream_post` "skipping quota deduction" loguyla erken dönüyor ([`gemini_service.py#L334`](file:///Users/kuzey/projects/omakase/backend/app/services/gemini_service.py#L334), [`#L402`](file:///Users/kuzey/projects/omakase/backend/app/services/gemini_service.py#L402)). Gemini çağrısı ve token üretimi ise çoktan başlamış oluyor.
- **Saldırı:** Doğrulanmış kullanıcı `/feed/stream` çağırır, ilk `event: token` çerçevesini okur ve bağlantıyı kapatır. Sunucu maliyeti üretir, `usage/{uid}_{day}` sayacı artmaz. Döngü, günlük 3 post sınırının çok üzerinde tekrarlanabilir.
- **Etki:** Ücretsiz katman ekonomisi ve Gemini faturası; kota adaletsizliği. Doğrudan veri sızıntısı yok.
- **Çözüm:** Kotayı üretim başında atomik rezerve et; bağlantı kesintisinde rezervasyonu koru. Yalnızca hiç token üretilmediyse ve ürün politikası gerektiriyorsa iade et. `on_complete`'i tek muhasebe yolu olmaktan çıkar.
- **İlgili test:** `backend/tests/test_billing_and_quota.py::test_disconnected_stream_does_not_deduct_quota` mevcut davranışı sabitliyor; güvenlik açısından bu testin iş kuralı ile birlikte yeniden değerlendirilmesi gerekir.

#### S-17 — Doğrulanmamış sosyal bildirim olayları (Orta)

- **Kök neden:** `POST /notifications/events` yalnızca `shared_posts/{post_id}` belgesinin varlığını kontrol ediyor; aktörün gerçekten yorum/reaksiyon bıraktığını doğrulamıyor ([`notification_service.py#L416-L444`](file:///Users/kuzey/projects/omakase/backend/app/services/notification_service.py#L416-L444)). `comment_preview` istemciden geldiği gibi push gövdesine giriyor ([`#L603`](file:///Users/kuzey/projects/omakase/backend/app/services/notification_service.py#L603), [`#L652`](file:///Users/kuzey/projects/omakase/backend/app/services/notification_service.py#L652)); reaksiyon sayacı da doğrulama olmadan artıyor ([`#L681`](file:///Users/kuzey/projects/omakase/backend/app/services/notification_service.py#L681)).
- **Saldırı:** Herhangi bir oturum açmış kullanıcı, herkese açık gönderi kimliklerinden birini seçip `event_type=comment`, `post_id=<hedef>`, `comment_preview=<saldırgan metni>` gönderir. Yazarın tercihleri açıksa push iletilir. Yorum başına 30 dakikalık soğuma, farklı gönderilerle aşılabilir.
- **Etki:** Kimlik avı, taciz, yanıltıcı bildirim ve bildirim güvenilirliğinin kaybı. `actor_name` sunucuda profilden çözüldüğü için aktör kimliği spoofing'i engellenmiş; ancak olayın kendisi ve metni doğrulanmıyor.
- **Çözüm:** Bildirimi Firestore `comments`/`reactions` yazımına bağlı sunucu tetikleyicisine taşı. En azından `comments/{commentId}` belgesinin `authorId == actor_uid` olduğunu ve önizlemenin saklanan `text` alanından türetildiğini doğrula; reaksiyonlarda `reactions/{uid}` belgesini kontrol et.

#### S-18 — Gönderi sayaçlarının keyfi değiştirilmesi (Düşük)

- **Kök neden:** [`firestore.rules#L479-L502`](file:///Users/kuzey/projects/omakase/firestore.rules#L479-L502) ikinci güncelleme dalı, yazar olmayan kullanıcılara `reactionCounts`, `totalReactions`, `commentCount`, `reportedBy` alanlarını açıyor. `commentCount` ±1 ile sınırlı; `totalReactions` yalnızca `>= 0`; `reactionCounts` için hiçbir değer kontrolü yok.
- **Saldırı:** Herhangi bir doğrulanmış kullanıcı, `authorId`/`text`/`title` değişmeden `totalReactions` ve `reactionCounts` alanlarını keyfi değerlere çeker.
- **Etki:** Sosyal kanıt metrikleri şişirilebilir/sıfırlanabilir; tekrarlı yazmalar maliyet üretir.
- **Çözüm:** Sayaçları Admin SDK/Cloud Function'a taşı; geçiş döneminde ±1 delta ve ilgili `reactions/{uid}` belgesinin varlığı ile sınırla.

#### S-19 — Profil `email` alanı için kural katmanı açığı (Düşük)

- **Kök neden:** [`firestore.rules#L154`](file:///Users/kuzey/projects/omakase/firestore.rules#L154) ve [`#L177`](file:///Users/kuzey/projects/omakase/firestore.rules#L177) `email` alanını kabul ediyor; [`#L377`](file:///Users/kuzey/projects/omakase/firestore.rules#L377) profili tüm doğrulanmış kullanıcılara okutuyor. İstemci `FieldValue.delete()` ile siliyor ([`FirestoreService.swift#L68`](file:///Users/kuzey/projects/omakase/omakase/omakase/Services/FirestoreService.swift#L68)), ancak bu yalnızca iyi niyetli istemci davranışı.
- **Saldırı:** Değiştirilmiş/eski istemci veya doğrudan SDK yazımı ile `users/{uid}` belgesine `email` yazılır; herhangi bir oturum açmış hesap bu alanı okur.
- **Etki:** E-posta adresi tüm hesaplara açık hale gelebilir; kimlik avı ve hesap eşleştirme riski.
- **Çözüm:** `email` alanını `isValidUserProfile` beyaz listesinden çıkar ve yazımı reddet; mevcut belgelerdeki alanı migrasyonla sil. Profil okumasını yalnızca sosyal alanlarla sınırlamak için ayrı `public_profiles` koleksiyonu değerlendirilebilir.

#### S-20 — Süreç içi, sınırsız hız sınırlayıcı (Düşük)

- **Kök neden:** [`security.py#L27`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L27) `_RATE_BUCKETS` süreç içi `defaultdict(deque)`; [`#L73`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L73) anahtar başına deque oluşturuluyor ve TTL/temizleme yok. [`#L139`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L139) auth kapalıysa anahtar `ip:<host>`.
- **Etki:** Cloud Run çoklu örneklerinde etkin sınır `max_calls × örnek`; auth yanlış yapılandırılırsa bellek büyümesi. Kota hâlâ ana koruma olduğu için etki sınırlı.
- **Çözüm:** Cloud Armor/API Gateway/Redis tabanlı dağıtık sayaç; en azından periyodik TTL temizliği ve üretimde `OMAKASE_REQUIRE_AUTH=true` zorunluluğu.

#### S-21 — Gömülü yönetici UID'si ve kota istisnası (Düşük)

- **Kök neden:** [`config.py#L45`](file:///Users/kuzey/projects/omakase/backend/app/config.py#L45) varsayılan `ADMIN_UIDS` sabit UID; [`#L85-L87`](file:///Users/kuzey/projects/omakase/backend/app/config.py#L85-L87) aynı UID için 50 tabak/gün istisnası; [`backend/.env.example#L15`](file:///Users/kuzey/projects/omakase/backend/.env.example#L15) aynı kimliği yayımlıyor.
- **Etki:** Ortam değişkeni yoksa/yanlışsa ayrıcalıklı erişim beklenmedik biçimde devam eder; ayrıcalıklı hesap kimliği herkese açık olur.
- **Çözüm:** Varsayılanı kaldır (fail-closed); istisnayı denetlenebilir bir yapılandırmaya taşı.

#### S-22 — Gevşek admin CSP'si (Düşük)

- **Kök neden:** [`firebase.json#L52`](file:///Users/kuzey/projects/omakase/firebase.json#L52) `script-src 'self' 'unsafe-inline' ...` ve `connect-src ... http://127.0.0.1:8000 http://localhost:8000`.
- **Etki:** HTML enjeksiyonu bulunursa satır içi script çalışabilir; admin tarayıcısındaki yerel servis token'ı alabilir. Mevcut çıktılar `escapeHtml` ([`admin.js#L392`](file:///Users/kuzey/projects/omakase/admin-web/admin.js#L392)) ile kaçırıldığı için tek başına sömürülemez.
- **Çözüm:** Satır içi script'i kaldır, nonce/hash tabanlı CSP kullan, üretimde localhost kökenlerini çıkar.

#### S-23 — `reportedBy` kanıtının kısmen değiştirilebilmesi (Düşük)

- **Kök neden:** [`firestore.rules#L498-L502`](file:///Users/kuzey/projects/omakase/firestore.rules#L498-L502) ve [`#L529`](file:///Users/kuzey/projects/omakase/firestore.rules#L529) yalnızca kendi UID'nin listede olmasını ve boyutun küçülmemesini istiyor; eski girdilerin korunmasını zorunlu kılmıyor.
- **Etki:** Saldırgan eski muhabirleri listeden çıkarıp yerine istediği kimlikleri koyabilir; moderasyon kanıtı zayıflar.
- **Çözüm:** `reportedBy == eskiListe ∪ {request.auth.uid}` biçiminde kesin küme kontrolü.

#### S-24 — Cihaz kotasının istemci başlığına bağımlılığı (Düşük)

- **Kök neden:** [`access_service.py#L183`](file:///Users/kuzey/projects/omakase/backend/app/services/access_service.py#L183) boş/geçersiz başlıkta `None`; [`#L296-L298`](file:///Users/kuzey/projects/omakase/backend/app/services/access_service.py#L296-L298) yalnızca `device_hash` varsa cihaz kullanımını birleştiriyor. [`SSEClient.swift#L78`](file:///Users/kuzey/projects/omakase/omakase/omakase/Networking/SSEClient.swift#L78) başlığı istemci üretiyor.
- **Etki:** Başlık atlanır veya döndürülürse S-13'ün çoklu hesap koruması devre dışı kalır; hesap başına kota yine geçerli.
- **Çözüm:** App Check (App Attest/DeviceCheck) ile cihaz/uygulama bütünlüğü; ücretsiz katmanda eksik başlığı reddet.

### 9.3. Doğrulama Gerektiren Bulgu (S-03)

- **Durum:** Depodan doğrulanamıyor; GCP Console erişimi gerekiyor.
- **Kanıt:** [`GoogleService-Info.plist#L10`](file:///Users/kuzey/projects/omakase/omakase/omakase/GoogleService-Info.plist#L10) herkese açık Firebase istemci anahtarı. Sunucu Gemini anahtarı ayrı ortam değişkeninden okunuyor ([`config.py#L21`](file:///Users/kuzey/projects/omakase/backend/app/config.py#L21)).
- **Doğrulama planı:** GCP Console → APIs & Services → Credentials altında anahtarın Application restrictions = iOS (`kuzeysinay.omakase`) ve API restrictions = Identity Toolkit, Token Service, Firebase Installations, Cloud Firestore olduğunu; **Generative Language API'nin kapalı** olduğunu doğrula.

### 9.4. Reddedilen Adaylar

| Aday | Sonuç | Gerekçe |
|------|-------|---------|
| `admin-web` geri bildirim/moderasyon render'ında DOM XSS | ❌ Reddedildi | Tüm dinamik alanlar `escapeHtml` ([`admin.js#L392`](file:///Users/kuzey/projects/omakase/admin-web/admin.js#L392)) ile kaçırılıyor; CSP ek katman. |
| `/letterboxd/films` SSRF | ❌ Reddedildi | `^[a-zA-Z0-9_-]{1,40}$` whitelist ([`security.py#L61`](file:///Users/kuzey/projects/omakase/backend/app/security.py#L61)), `https://letterboxd.com/` redirect kontrolü ([`letterboxd_service.py#L67`](file:///Users/kuzey/projects/omakase/backend/app/services/letterboxd_service.py#L67)) ve 2 MB sınırı. |
| Depoda sunucu sırrı/özel anahtar | ❌ Reddedildi | Yalnızca herkese açık Firebase istemci anahtarı; `.env`/`.venv` izlenmiyor ([`.gitignore#L16-L19`](file:///Users/kuzey/projects/omakase/.gitignore#L16-L19)). |
| Prompt injection ile sistem talimatı ezme | ✅ Azaltıldı | `_sanitize_single_line`, `<user_context>` izolasyonu ve Gemini safety settings mevcut; kanıtlanmış bir kaçış yok. |

### 9.5. Artefaktlar ve Doğrulama

- `~/security-audit-skill/omakase/run-1/findings.json` — 13 bulgu; `node validate-findings.cjs` → **PASS**.
- `~/security-audit-skill/omakase/run-1/coverage-ledger.json` — 14 kapsam birimi; `node validate-coverage-ledger.cjs` → **PASS**.
- `~/security-audit-skill/omakase/run-1/REPORT.md` — hedeften bağımsız denetim raporu.

### 9.6. Öncelik Sırası

1. **S-16 ve S-17** — operasyonel/ekonomik etkisi en yüksek; lansman öncesi kapatılmalı.
2. **S-03** — GCP Console işlemi; anahtar kısıtlaması ve Generative Language API erişiminin kaldırılması.
3. **S-18, S-19, S-23** — Firestore kural sertleştirmesi; tek bir `firebase deploy --only firestore:rules` ile birlikte yapılabilir.
4. **S-20, S-21, S-22, S-24** — savunma derinliği ve yapılandırma sertleştirmesi; sonraki sprintte ele alınabilir.
