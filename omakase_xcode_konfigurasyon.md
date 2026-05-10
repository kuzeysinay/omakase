# 🔧 Omakase — Xcode & App Store Konfigürasyon Raporu

> Proje dosyaları (`project.pbxproj`, `Info.plist`, `Assets`) üzerinden bulunan **reject riski taşıyan** veya düzeltilmesi gereken konfigürasyon sorunları.

---

## 🔴 Acil Düzeltilmesi Gerekenler

### 1. Info.plist — Development Ayarları Production'da Kalmamalı

Mevcut [Info.plist](file:///Users/kuzey/projects/omakase/omakase/omakase/Info.plist) içeriği App Store build'inde reject sebebi olabilir:

```diff
  <key>NSAppTransportSecurity</key>
  <dict>
-   <key>NSAllowsLocalNetworking</key>
-   <true/>
-   <key>NSExceptionDomains</key>
-   <dict>
-     <key>127.0.0.1</key>
-     <dict>
-       <key>NSExceptionAllowsInsecureHTTPLoads</key>
-       <true/>
-     </dict>
-     <key>localhost</key>
-     <dict>
-       <key>NSExceptionAllowsInsecureHTTPLoads</key>
-       <true/>
-       <key>NSIncludesSubdomains</key>
-       <true/>
-     </dict>
-   </dict>
  </dict>

- <key>OMAKASE_API_URL</key>
- <string>http://127.0.0.1:8000</string>
+ <key>OMAKASE_API_URL</key>
+ <string>https://omakase-backend-XXXXX.run.app</string>
```

**Sorunlar:**
- `NSAllowsLocalNetworking` + `NSExceptionAllowsInsecureHTTPLoads` → Apple reviewer'ı "neden HTTP kullanıyorsunuz?" diye sorar
- `http://127.0.0.1:8000` → Production build'de **hiçbir şey çalışmaz**, kullanıcı boş ekran görür
- `NSLocalNetworkUsageDescription` → "talks to your development server" yazıyor — production'da anlamsız

**Çözüm:**
Production build'de ATS exception'larını tamamen kaldır. Backend'in HTTPS olduğundan emin ol (Cloud Run default HTTPS sağlar). Xcode'da **Release** ve **Debug** için ayrı Info.plist veya build configuration kullanabilirsin.

> [!TIP]
> **En temiz yöntem:** Xcode'da bir `.xcconfig` dosyası ile Debug/Release ayrımı yap:
> ```
> // Debug.xcconfig
> OMAKASE_API_URL = http://127.0.0.1:8000
> 
> // Release.xcconfig  
> OMAKASE_API_URL = https:/$()/omakase-backend.run.app
> ```
> Info.plist'te: `$(OMAKASE_API_URL)` olarak referans ver.

---

### 2. App Icon Eksik

[AppIcon.appiconset/Contents.json](file:///Users/kuzey/projects/omakase/omakase/omakase/Assets.xcassets/AppIcon.appiconset/Contents.json) dosyasında **3 slot tanımlı ama hiçbirinde görsel dosya yok** (filename property eksik). App Store'a yüklemek için:

- **1024×1024 PNG** (standart, light mode)
- **1024×1024 PNG** (dark mode varyantı)  
- **1024×1024 PNG** (tinted varyantı)

En azından ilk slot (standart) dolu olmalı. Dark ve tinted opsiyonel ama iOS 26'da icon'lar otomatik dark mode desteği gösterir — boş bırakırsan yanlış render olabilir.

> [!IMPORTANT]
> App icon olmadan Xcode archive/upload **başarısız olur**. Bu adımı atlamak mümkün değil.

---

### 3. NSLocalNetworkUsageDescription — Güncellenmeli

Mevcut değer (pbxproj satır 292):
```
"Omakase talks to your development server on this Wi‑Fi network (your Mac) to load the feed."
```

Production'da local network kullanmıyorsan bu key'i tamamen kaldır. Eğer kalırsa Apple reviewer "bu uygulama local network'e neden erişiyor?" diye sorar ve **reject** eder.

---

### 4. Launch Screen — Otomatik Üretim

`INFOPLIST_KEY_UILaunchScreen_Generation = YES` → Xcode otomatik beyaz ekran üretir. Bu çalışır ama profesyonel görünmez.

**Öneri:** Basit bir `LaunchScreen.storyboard` veya SwiftUI launch screen ile marka tutarlılığı sağla (logo + background renk).

---

## 🟡 Önemli Konfigürasyonlar

### 5. Versiyon Numaralandırma Stratejisi

Mevcut ayarlar:
- `MARKETING_VERSION = 1.0` → App Store'da gösterilir
- `CURRENT_PROJECT_VERSION = 1` → Build numarası

**App Store kuralı:** Her yükleme için `CURRENT_PROJECT_VERSION` artmalı. Aynı marketing version ile birden fazla build yükleyebilirsin ama build numarası her seferinde farklı olmalı.

**Önerilen strateji:**
```
v1.0 (1)  → İlk submit
v1.0 (2)  → Reject sonrası düzeltme
v1.0.1 (3) → Bug fix güncellemesi
v1.1 (4)  → Feature güncellemesi
```

> [!TIP]
> Build numarasını otomatik artırmak için Xcode Build Phase script'i:
> ```bash
> # Run Script → Build Phases
> BUILD_NUM=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}")
> BUILD_NUM=$(($BUILD_NUM + 1))
> /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUM" "${INFOPLIST_FILE}"
> ```

---

### 6. Deployment Target: iOS 26.4

Bu çok yeni bir hedef. Kullanıcı tabanını daraltabilir.

| Hedef | Kapsam (tahmini) |
|-------|-----------------|
| iOS 26.4 | ~%30-40 iPhone kullanıcısı |
| iOS 26.0 | ~%50-60 |
| iOS 18.0 | ~%85-90 |

**Durum:** Uygulamada `@Observable`, `#Preview`, modern SwiftUI kullanılıyor. iOS 26.0'a düşürmek mümkün olabilir ama daha geriye gitmek büyük refactor gerektirir. İlk sürüm için iOS 26.0 makul.

---

### 7. Targeted Device Family: iPhone + iPad (1,2)

`TARGETED_DEVICE_FAMILY = "1,2"` → Uygulama hem iPhone hem iPad'i desteklediğini söylüyor.

**Sorun:** iPad layout'u test edilmiş mi? `FeedView` ve `MainTabView` iPad'de düzgün çalışıyor mu? App Store reviewer'ı iPad'de de test eder — bozuk bir iPad deneyimi reject sebebi.

**Seçenekler:**
1. iPad desteğini test et ve düzelt (split view, multitasking)
2. Sadece iPhone hedefle: `TARGETED_DEVICE_FAMILY = 1` → Daha güvenli, daha az iş

---

### 8. Hesap Silme Özelliği (Zorunlu)

Apple, Ocak 2022'den beri hesap oluşturma özelliği olan tüm uygulamalardan **hesap silme** özelliği zorunlu kılıyor.

Senin uygulamanda Google Sign-In + Firestore profili var → şunlar gerekli:

1. **Settings'te "Hesabımı Sil" butonu**
2. Firebase Auth'tan kullanıcıyı sil: `Auth.auth().currentUser?.delete()`
3. Firestore'daki kullanıcı verilerini sil: `users/{uid}`, subcollection'lar, `shared_posts`
4. Local verileri temizle: `@AppStorage` key'lerini sıfırla

Bu eksikse **kesin reject**.

---

### 9. Debug Kodları Temizliği

[FeedViewModel.swift](file:///Users/kuzey/projects/omakase/omakase/omakase/Feed/FeedViewModel.swift) içinde `AgentDebugLog` enum'u ve tüm `#region agent log` blokları var. Bu kodlar:
- Localhost:7607'ye HTTP POST atıyor
- `sessionId`, `hypothesisId` gibi debug verisi gönderiyor
- Production'da gereksiz network trafiği ve potansiyel crash

**Silinmesi gereken dosyalar/bloklar:**
- `FeedViewModel.swift` → `AgentDebugLog` enum (satır 397-436) ve tüm `.log()` çağrıları
- `SSEClient.swift` → `AgentDebugLog.log()` çağrısı (satır 83-92)

---

## 🟢 App Store Connect Konfigürasyonu

### 10. App Store Connect'te Yapılacaklar Checklist

| Adım | Detay |
|------|-------|
| **App oluştur** | Bundle ID: `kuzeysinay.omakase` ile kayıt |
| **Kategori** | Primary: `Entertainment` veya `Education` — Secondary: `Social Networking` |
| **Yaş derecelendirmesi** | 12+ (User-generated content, infrequent mature themes) |
| **Fiyat** | Free (IAP ile monetize) |
| **Availability** | Başlangıçta sadece Türkiye + ABD, sonra genişlet |
| **Screenshots** | 6.7" (iPhone 16 Pro Max) + 6.1" (iPhone 16) — zorunlu. iPad opsiyonel |
| **Preview video** | Opsiyonel ama SSE streaming efekti video ile çok iyi gösterilir |
| **App description** | EN + TR lokalizasyonu |
| **Keywords** | Max 100 karakter, virgülle ayrılmış |
| **Support URL** | Bir GitHub Pages veya basit site |
| **Privacy Policy URL** | **Zorunlu** — bir public URL'de host et |
| **Review Notes** | "Uygulamayı test etmek için Google hesabıyla giriş yapın. Test hesabı: ..." |

---

### 11. In-App Purchase Konfigürasyonu

App Store Connect'te subscription oluşturmadan **önce**:

1. **Agreements & Banking** → "Paid Applications" sözleşmesini kabul et ve banka bilgilerini gir
2. **Subscription Group** oluştur → "Omakase Pro"
3. **Ürünleri tanımla:**
   - `com.kuzeysinay.omakase.pro.monthly` — Auto-Renewable, $3.99
   - `com.kuzeysinay.omakase.pro.yearly` — Auto-Renewable, $29.99
4. Her ürün için **lokalize açıklama** yaz (EN + TR)
5. **Subscription screenshot** — paywall ekranının screenshot'ı

> [!WARNING]
> Banking bilgileri tamamlanmadan IAP review'a **gönderilemez**. Bu adım onay süreci 1-3 gün sürebilir.

---

### 12. Xcode Konfigürasyon Değişiklikleri — Özet

Production build için yapılması gereken Xcode değişiklikleri:

```
┌─────────────────────────────────────┬──────────────────────┐
│ Ayar                                │ Değişiklik           │
├─────────────────────────────────────┼──────────────────────┤
│ Info.plist ATS exceptions           │ Kaldır               │
│ Info.plist OMAKASE_API_URL          │ HTTPS production URL │
│ NSLocalNetworkUsageDescription      │ Kaldır               │
│ App Icon (1024×1024)                │ Ekle                 │
│ LaunchScreen                        │ Tasarla              │
│ IPHONEOS_DEPLOYMENT_TARGET          │ 26.0'a düşür (opt.)  │
│ TARGETED_DEVICE_FAMILY              │ Test et veya 1 yap   │
│ Signing & Capabilities              │ Distribution cert    │
│ StoreKit capability                 │ Ekle                 │
│ AgentDebugLog + #region kodları     │ Sil                  │
│ CURRENT_PROJECT_VERSION             │ Her build'de artır   │
│ Hesap silme özelliği                │ Implement et         │
└─────────────────────────────────────┴──────────────────────┘
```
