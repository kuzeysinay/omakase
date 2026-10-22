//
//  L10n.swift
//  omakase
//

import Foundation

/// UI strings keyed by ``AppLanguage`` (keeps onboarding + feed in sync with API `language`).
struct L10n {
    let lang: AppLanguage

    // MARK: - Shared chrome

    var appTitle: String { "omakase" }

    var languageMenuAccessibility: String {
        switch lang {
        case .english: "Language"
        case .turkish: "Dil"
        }
    }

    // MARK: - Onboarding

    var onboardingTagline: String {
        switch lang {
        case .english:
            "Tell us what you love. Your feed is generated fresh, just for you."
        case .turkish:
            "Sevdiğin şeyleri söyle. Akışın sana özel, taptaze üretilir."
        }
    }

    var onboardingNeedInterest: String {
        switch lang {
        case .english: "Add at least one interest"
        case .turkish: "En az bir ilgi ekle"
        }
    }

    var onboardingStartFeed: String {
        switch lang {
        case .english: "Start my feed"
        case .turkish: "Akışıma başla"
        }
    }

    // MARK: - Feed

    var shareSheetA11y: String {
        switch lang {
        case .english: "Share post"
        case .turkish: "Gönderiyi paylaş"
        }
    }

    var deepDiveA11y: String {
        switch lang {
        case .english: "Deep dive"
        case .turkish: "Derinlemesine incele"
        }
    }

    var noPostsYet: String {
        switch lang {
        case .english: "No posts yet"
        case .turkish: "Henüz post yok"
        }
    }

    var offlineBanner: String {
        switch lang {
        case .english: "You're offline. Showing cached posts."
        case .turkish: "Çevrimdışısın. Önbellekteki gönderiler gösteriliyor."
        }
    }

    var internetRequired: String {
        switch lang {
        case .english: "Internet required"
        case .turkish: "İnternet gerekli"
        }
    }

    var clearFeed: String {
        switch lang {
        case .english: "Clear feed"
        case .turkish: "Akışı temizle"
        }
    }

    var feedMoreActionsA11y: String {
        switch lang {
        case .english: "More actions"
        case .turkish: "Diğer işlemler"
        }
    }

    var errorSomethingWrong: String {
        switch lang {
        case .english: "Something went wrong"
        case .turkish: "Bir şeyler ters gitti"
        }
    }

    var ok: String {
        switch lang {
        case .english: "OK"
        case .turkish: "Tamam"
        }
    }

    func editTastesA11y(_ tasteSummary: String) -> String {
        switch lang {
        case .english: "Edit tastes, \(tasteSummary)"
        case .turkish: "Tatları düzenle, \(tasteSummary)"
        }
    }

    func tastesNoneA11y() -> String {
        switch lang {
        case .english: "none selected"
        case .turkish: "hiçbiri seçilmedi"
        }
    }

    func tastesCountA11y(_ count: Int) -> String {
        switch lang {
        case .english: "\(count) selected"
        case .turkish: "\(count) seçildi"
        }
    }

    var addTastes: String {
        switch lang {
        case .english: "Add tastes"
        case .turkish: "Tat ekle"
        }
    }

    func tastesShortLabel(count: Int, singleName: String) -> String {
        switch lang {
        case .english:
            if count == 0 { return addTastes }
            if count == 1 {
                return singleName.count > 16 ? String(singleName.prefix(14)) + "…" : singleName
            }
            return "\(count) tastes"
        case .turkish:
            if count == 0 { return addTastes }
            if count == 1 {
                return singleName.count > 16 ? String(singleName.prefix(14)) + "…" : singleName
            }
            return "\(count) tat"
        }
    }

    func savedPostsA11y(count: Int) -> String {
        switch lang {
        case .english:
            count > 0 ? "Saved posts, \(count)" : "Saved posts"
        case .turkish:
            count > 0 ? "Kaydedilen gönderiler, \(count)" : "Kaydedilen gönderiler"
        }
    }

    var emptyFeedHeadline: String {
        switch lang {
        case .english: "Your feed is warming up…"
        case .turkish: "Akışın ısınıyor…"
        }
    }

    var emptyFeedDetail: String {
        switch lang {
        case .english: "Tap the button below to taste the first post."
        case .turkish: "İlk gönderiyi görmek için aşağıdaki düğmeye dokun."
        }
    }

    var generating: String {
        switch lang {
        case .english: "Generating…"
        case .turkish: "Üretiliyor…"
        }
    }

    /// Rotates while a post streams in; paired with ``FeedViewModel/loadingQuipIndex``.
    var cookingQuips: [String] {
        switch lang {
        case .english:
            [
                "Simmering…",
                "Chef absolutely knows which knife.",
                "Reducing your interests into a sauce…",
                "Tasting the draft so you don't have to.",
                "Quietly sharpening the punchlines…",
                "Plating commas and confidence…",
                "One more swirl of personality…",
                "Almost too hot to subtitle.",
            ]
        case .turkish:
            [
                "Kelimeler marine ediliyor…",
                "İlgi alanların harmanlanıyor…",
                "Tat profili çıkarılıyor…",
                "İçerik kısık ateşte demleniyor…",
                "Taze fikirler doğranıyor…",
                "Cümleler özenle diziliyor…",
                "Lezzet dengesi kuruluyor…",
                "Son bir tutam ilham ekleniyor…",
            ]
        }
    }

    var serveNextPost: String {
        switch lang {
        case .english: "Serve next post"
        case .turkish: "Sonraki gönderiyi sun"
        }
    }

    func readingCooldownTitle(seconds: Int) -> String {
        switch lang {
        case .english: "Reading cooldown: \(seconds)s"
        case .turkish: "Okuma süresi: \(seconds) sn"
        }
    }

    var readingCooldownDetail: String {
        switch lang {
        case .english: "Take your time with this post. Next dish unlocks shortly."
        case .turkish: "Gönderiyi sindirmen için bekleniyor. Yeni post az sonra açılacak."
        }
    }

    var removeBookmarkA11y: String {
        switch lang {
        case .english: "Remove bookmark"
        case .turkish: "Yer imini kaldır"
        }
    }

    var bookmarkPostA11y: String {
        switch lang {
        case .english: "Bookmark post"
        case .turkish: "Gönderiyi kaydet"
        }
    }

    var liveBadge: String {
        switch lang {
        case .english: "LIVE"
        case .turkish: "CANLI"
        }
    }

    var composingTitle: String {
        switch lang {
        case .english: "Composing…"
        case .turkish: "Yazılıyor…"
        }
    }

    var untitledBite: String {
        switch lang {
        case .english: "Untitled bite"
        case .turkish: "Başlıksız lokma"
        }
    }

    var streamEndedNoText: String {
        switch lang {
        case .english:
            "The feed stream ended with no post text. Check that the backend is running, "
                + "GEMINI_API_KEY and GEMINI_MODEL are set, and the device can reach the API (on a real "
                + "iPhone, use your Mac’s LAN address instead of 127.0.0.1 in OMAKASE_API_URL)."
        case .turkish:
            "Akış metin olmadan bitti. Sunucunun çalıştığını, GEMINI_API_KEY ve GEMINI_MODEL "
                + "ayarlarını ve cihazın API’ye erişebildiğini doğrula (gerçek iPhone’da 127.0.0.1 "
                + "telefonu gösterir — OMAKASE_API_URL içinde Mac’inin yerel IP’sini kullan, örn. "
                + "http://192.168.1.x:8000)."
        }
    }

    func couldNotConnect(apiBase: String) -> String {
        switch lang {
        case .english:
            "Could not connect to the API at \(apiBase). "
                + "Start the backend from the repo’s `backend` folder: "
                + "`uvicorn main:app --reload --host 0.0.0.0 --port 8000`. "
                + "On a physical iPhone, 127.0.0.1 points at the phone — set OMAKASE_API_URL in Info.plist "
                + "to your Mac’s LAN IP (e.g. http://192.168.1.x:8000)."
        case .turkish:
            "API’ye bağlanılamadı: \(apiBase). "
                + "Repodaki `backend` klasöründen sunucuyu başlat: "
                + "`uvicorn main:app --reload --host 0.0.0.0 --port 8000`. "
                + "Fiziksel iPhone’da 127.0.0.1 telefonun kendisidir — Info.plist’te OMAKASE_API_URL’i "
                + "Mac’inin yerel IP’si yap (örn. http://192.168.1.x:8000)."
        }
    }

    // MARK: - Interests editor

    var addTastePlaceholder: String {
        switch lang {
        case .english: "Add a taste…"
        case .turkish: "Bir tat ekle…"
        }
    }

    var ideasToTry: String {
        switch lang {
        case .english: "Ideas to try"
        case .turkish: "Denebilecek fikirler"
        }
    }

    var thinking: String {
        switch lang {
        case .english: "Thinking…"
        case .turkish: "Düşünüyor…"
        }
    }

    var refreshIdeasA11y: String {
        switch lang {
        case .english: "Refresh ideas"
        case .turkish: "Fikirleri yenile"
        }
    }

    var couldNotLoadIdeas: String {
        switch lang {
        case .english: "Could not load ideas."
        case .turkish: "Fikirler yüklenemedi."
        }
    }

    // MARK: - Adjust tastes sheet

    var adjustTastesBlurb: String {
        switch lang {
        case .english:
            "Tune what Omakase cooks for you. Add, remove, or steal ideas below — your feed updates right away."
        case .turkish:
            "Omakase senin için ne pişireceğini buradan ayarla. Aşağıdan ekle, çıkar veya fikir çal — akışın hemen güncellenir."
        }
    }

    var yourTastes: String {
        switch lang {
        case .english: "Your tastes"
        case .turkish: "Tatların"
        }
    }

    var cancel: String {
        switch lang {
        case .english: "Cancel"
        case .turkish: "İptal"
        }
    }

    var save: String {
        switch lang {
        case .english: "Save"
        case .turkish: "Kaydet"
        }
    }

    // MARK: - Bookmarks

    var noBookmarks: String {
        switch lang {
        case .english: "No bookmarks"
        case .turkish: "Yer imi yok"
        }
    }

    var bookmarksHint: String {
        switch lang {
        case .english: "Save a finished post from your feed to read it again here."
        case .turkish: "Akıştaki tamamlanmış bir gönderiyi kaydederek burada yeniden oku."
        }
    }

    var savedPostFallbackTitle: String {
        switch lang {
        case .english: "Saved post"
        case .turkish: "Kaydedilen gönderi"
        }
    }

    var remove: String {
        switch lang {
        case .english: "Remove"
        case .turkish: "Kaldır"
        }
    }

    var savedTitle: String {
        switch lang {
        case .english: "Saved"
        case .turkish: "Kaydedilenler"
        }
    }

    var done: String {
        switch lang {
        case .english: "Done"
        case .turkish: "Bitti"
        }
    }

    var removeAllSaved: String {
        switch lang {
        case .english: "Remove all saved"
        case .turkish: "Tüm kayıtlıları sil"
        }
    }

    var selectEdit: String {
        switch lang {
        case .english: "Select"
        case .turkish: "Seç"
        }
    }

    func deleteSelectedCount(_ count: Int) -> String {
        switch lang {
        case .english: "Delete \(count) selected"
        case .turkish: "\(count) seçili gönderiyi sil"
        }
    }

    // MARK: - Delete confirmations

    var confirmDeleteTitle: String {
        switch lang {
        case .english: "Delete bookmark?"
        case .turkish: "Yer imi silinsin mi?"
        }
    }

    var confirmDeleteMessage: String {
        switch lang {
        case .english: "This saved post will be removed permanently."
        case .turkish: "Bu kaydedilen gönderi kalıcı olarak silinecek."
        }
    }

    func confirmDeleteSelectedTitle(_ count: Int) -> String {
        switch lang {
        case .english: "Delete \(count) bookmarks?"
        case .turkish: "\(count) yer imi silinsin mi?"
        }
    }

    func confirmDeleteSelectedMessage(_ count: Int) -> String {
        switch lang {
        case .english: "The \(count) selected posts will be removed permanently."
        case .turkish: "Seçilen \(count) gönderi kalıcı olarak silinecek."
        }
    }

    var confirmDeleteAllTitle: String {
        switch lang {
        case .english: "Delete all bookmarks?"
        case .turkish: "Tüm yer imleri silinsin mi?"
        }
    }

    var confirmDeleteAllMessage: String {
        switch lang {
        case .english: "All saved posts will be removed permanently."
        case .turkish: "Tüm kaydedilen gönderiler kalıcı olarak silinecek."
        }
    }

    var confirmDeletePostTitle: String {
        switch lang {
        case .english: "Delete post?"
        case .turkish: "Gönderi silinsin mi?"
        }
    }

    var confirmDeletePostMessage: String {
        switch lang {
        case .english: "This post will be removed from your feed."
        case .turkish: "Bu gönderi akışından kaldırılacak."
        }
    }

    // MARK: - Auth

    var authTagline: String {
        switch lang {
        case .english: "Sign in to discover and share curated bites with people who get it."
        case .turkish: "Keşfetmek ve küratörlüğünü yaptığın lokmaları paylaşmak için giriş yap."
        }
    }

    var signInWithGoogle: String {
        switch lang {
        case .english: "Continue with Google"
        case .turkish: "Google ile devam et"
        }
    }

    var authSignUpTab: String {
        switch lang {
        case .english: "Sign Up"
        case .turkish: "Kayıt Ol"
        }
    }

    var authSignInTab: String {
        switch lang {
        case .english: "Sign In"
        case .turkish: "Giriş Yap"
        }
    }

    var authNameLabel: String {
        switch lang {
        case .english: "Full Name"
        case .turkish: "Ad Soyad"
        }
    }

    var authNamePlaceholder: String {
        switch lang {
        case .english: "Your name"
        case .turkish: "Adın Soyadın"
        }
    }

    var authEmailLabel: String {
        switch lang {
        case .english: "Email"
        case .turkish: "E-posta"
        }
    }

    var authEmailPlaceholder: String {
        switch lang {
        case .english: "name@example.com"
        case .turkish: "ornek@eposta.com"
        }
    }

    var authPasswordLabel: String {
        switch lang {
        case .english: "Password"
        case .turkish: "Şifre"
        }
    }

    var authPasswordPlaceholder: String {
        switch lang {
        case .english: "At least 6 characters"
        case .turkish: "En az 6 karakter"
        }
    }

    var authConfirmPasswordLabel: String {
        switch lang {
        case .english: "Confirm Password"
        case .turkish: "Şifre Tekrar"
        }
    }

    var authConfirmPasswordPlaceholder: String {
        switch lang {
        case .english: "Re-enter your password"
        case .turkish: "Şifreni tekrar gir"
        }
    }

    var authSignUpWithEmailButton: String {
        switch lang {
        case .english: "Sign up with Email"
        case .turkish: "E-posta ile Kayıt Ol"
        }
    }

    var authSignInWithEmailButton: String {
        switch lang {
        case .english: "Sign in with Email"
        case .turkish: "E-posta ile Giriş Yap"
        }
    }

    var authOrDivider: String {
        switch lang {
        case .english: "or"
        case .turkish: "veya"
        }
    }

    var authOrWithEmail: String {
        switch lang {
        case .english: "or with email"
        case .turkish: "veya e-posta ile"
        }
    }

    var authForgotPassword: String {
        switch lang {
        case .english: "Forgot password?"
        case .turkish: "Şifremi unuttum"
        }
    }

    var authResetPasswordSent: String {
        switch lang {
        case .english: "Password reset link sent to your email."
        case .turkish: "Şifre sıfırlama bağlantısı e-posta adresine gönderildi."
        }
    }

    var authSwitchToSignInPrompt: String {
        switch lang {
        case .english: "Already have an account? Sign in"
        case .turkish: "Zaten hesabın var mı? Giriş yap"
        }
    }

    var authSwitchToSignUpPrompt: String {
        switch lang {
        case .english: "Don't have an account? Sign up with email"
        case .turkish: "Hesabın yok mu? E-posta ile kayıt ol"
        }
    }

    var authErrorNameRequired: String {
        switch lang {
        case .english: "Please enter your name."
        case .turkish: "Lütfen adınızı girin."
        }
    }

    var authErrorInvalidEmail: String {
        switch lang {
        case .english: "Please enter a valid email address."
        case .turkish: "Lütfen geçerli bir e-posta adresi girin."
        }
    }

    var authErrorWeakPassword: String {
        switch lang {
        case .english: "Password must be at least 6 characters."
        case .turkish: "Şifre en az 6 karakter olmalıdır."
        }
    }

    var authErrorPasswordMismatch: String {
        switch lang {
        case .english: "Passwords do not match."
        case .turkish: "Şifreler eşleşmiyor."
        }
    }

    var authErrorEmailInUse: String {
        switch lang {
        case .english: "This email address is already registered."
        case .turkish: "Bu e-posta adresiyle zaten bir hesap var."
        }
    }

    var authErrorInvalidCredential: String {
        switch lang {
        case .english: "Incorrect email or password."
        case .turkish: "E-posta veya şifre hatalı."
        }
    }

    var authErrorEnterEmailForReset: String {
        switch lang {
        case .english: "Enter your email address above first to reset your password."
        case .turkish: "Şifre sıfırlamak için önce yukarıya e-posta adresini gir."
        }
    }

    var authCreateAccountButton: String {
        switch lang {
        case .english: "Create account with Email"
        case .turkish: "E-posta ile Hesap Oluştur"
        }
    }

    var authContinueButton: String {
        switch lang {
        case .english: "Continue"
        case .turkish: "Devam Et"
        }
    }

    var authCompleteSignUpButton: String {
        switch lang {
        case .english: "Create Account"
        case .turkish: "Hesabı Oluştur"
        }
    }

    var authStep1Title: String {
        switch lang {
        case .english: "Create your account"
        case .turkish: "Hesabını oluştur"
        }
    }

    var authStep1Subtitle: String {
        switch lang {
        case .english: "Start with your email and a secure password."
        case .turkish: "E-posta adresin ve güvenli bir şifre ile başla."
        }
    }

    var authStep2Title: String {
        switch lang {
        case .english: "What should we call you?"
        case .turkish: "Görünür ismin ne olsun?"
        }
    }

    var authStep2Subtitle: String {
        switch lang {
        case .english: "This is your display name shown on your profile and shared bites."
        case .turkish: "Profilinde ve paylaştığın lokmalarda herkesin göreceği ismin."
        }
    }

    var authDisplayNamePlaceholder: String {
        switch lang {
        case .english: "Display Name (e.g. Kuzey Sınay)"
        case .turkish: "Görünür İsim (örn. Kuzey Sınay)"
        }
    }

    var authStep3Title: String {
        switch lang {
        case .english: "Pick your @username"
        case .turkish: "Bir @kullanıcı adı seç"
        }
    }

    var authStep3Subtitle: String {
        switch lang {
        case .english: "Your unique handle makes it easy for others to find and follow you."
        case .turkish: "Toplulukta seni benzersiz kılacak ve kolayca bulunmanı sağlayacak kullanıcı adın."
        }
    }

    var authUsernamePlaceholder: String {
        switch lang {
        case .english: "username"
        case .turkish: "kullanici_adi"
        }
    }

    var authSuggestedUsernames: String {
        switch lang {
        case .english: "Suggestions"
        case .turkish: "Öneriler"
        }
    }

    var authUsernameAvailable: String {
        switch lang {
        case .english: "Available"
        case .turkish: "Kullanılabilir"
        }
    }

    var authUsernameTaken: String {
        switch lang {
        case .english: "This username is already taken."
        case .turkish: "Bu kullanıcı adı zaten alınmış."
        }
    }

    var authUsernameTooShort: String {
        switch lang {
        case .english: "Username must be at least 3 characters."
        case .turkish: "Kullanıcı adı en az 3 karakter olmalıdır."
        }
    }

    var authWelcomeBackTitle: String {
        switch lang {
        case .english: "Welcome back"
        case .turkish: "Tekrar hoş geldin"
        }
    }

    var authWelcomeBackSubtitle: String {
        switch lang {
        case .english: "Sign in with your email and password."
        case .turkish: "E-posta adresin ve şifrenle giriş yap."
        }
    }

    var authPasswordHintValid: String {
        switch lang {
        case .english: "6+ characters"
        case .turkish: "6+ karakter tamam"
        }
    }

    var authPasswordHintRequirement: String {
        switch lang {
        case .english: "Minimum 6 characters"
        case .turkish: "En az 6 karakter"
        }
    }

    var authProfilePreviewLabel: String {
        switch lang {
        case .english: "PROFILE PREVIEW"
        case .turkish: "PROFİL ÖNİZLEMESİ"
        }
    }

    var signOut: String {
        switch lang {
        case .english: "Sign out"
        case .turkish: "Çıkış yap"
        }
    }

    // MARK: - Tabs

    var tabMyFeed: String {
        switch lang {
        case .english: "My Feed"
        case .turkish: "Akışım"
        }
    }

    var tabTimeline: String {
        switch lang {
        case .english: "Community"
        case .turkish: "Topluluk"
        }
    }

    var tabProfile: String {
        switch lang {
        case .english: "Profile"
        case .turkish: "Profil"
        }
    }

    // MARK: - Timeline / Community

    var loadingTimeline: String {
        switch lang {
        case .english: "Loading community…"
        case .turkish: "Topluluk yükleniyor…"
        }
    }

    var timelineEmptyHeadline: String {
        switch lang {
        case .english: "No community posts yet"
        case .turkish: "Henüz paylaşım yok"
        }
    }

    var timelineEmptyDetail: String {
        switch lang {
        case .english: "Follow people to see the posts they share from their AI feeds."
        case .turkish: "Yapay zeka akışlarından paylaştıkları gönderileri görmek için insanları takip et."
        }
    }

    var communitySearchPlaceholder: String {
        switch lang {
        case .english: "Search people or posts…"
        case .turkish: "Kişi veya gönderi ara…"
        }
    }

    var discoverBannerTitle: String {
        switch lang {
        case .english: "Discover"
        case .turkish: "Keşfet"
        }
    }

    var discoverBannerDetail: String {
        switch lang {
        case .english: "You're not following anyone yet. Here's what people are sharing."
        case .turkish: "Henüz kimseyi takip etmiyorsun. İnsanların paylaştıkları burada."
        }
    }

    // MARK: - Follow system

    var findPeople: String {
        switch lang {
        case .english: "Find people"
        case .turkish: "Kişi bul"
        }
    }

    var follow: String {
        switch lang {
        case .english: "Follow"
        case .turkish: "Takip et"
        }
    }

    var following: String {
        switch lang {
        case .english: "Following"
        case .turkish: "Takip ediliyor"
        }
    }

    var followers: String {
        switch lang {
        case .english: "Followers"
        case .turkish: "Takipçi"
        }
    }

    var followingLabel: String {
        switch lang {
        case .english: "Following"
        case .turkish: "Takip"
        }
    }

    var searchUsersPlaceholder: String {
        switch lang {
        case .english: "Search by name…"
        case .turkish: "İsme göre ara…"
        }
    }

    var searchUsersHint: String {
        switch lang {
        case .english: "Search for people to follow"
        case .turkish: "Takip etmek için kişi ara"
        }
    }

    var noUsersFound: String {
        switch lang {
        case .english: "No users found"
        case .turkish: "Kullanıcı bulunamadı"
        }
    }

    // MARK: - Profile

    var myProfile: String {
        switch lang {
        case .english: "My Profile"
        case .turkish: "Profilim"
        }
    }

    var profilePreferences: String {
        switch lang {
        case .english: "Preferences"
        case .turkish: "Tercihler"
        }
    }

    var profilePosts: String {
        switch lang {
        case .english: "Posts"
        case .turkish: "Gönderiler"
        }
    }

    var profileAccount: String {
        switch lang {
        case .english: "Account"
        case .turkish: "Hesap"
        }
    }

    // MARK: - Share

    var sharePost: String {
        switch lang {
        case .english: "Share to community"
        case .turkish: "Toplulukta paylaş"
        }
    }

    var unsharePost: String {
        switch lang {
        case .english: "Remove from community"
        case .turkish: "Topluluktan kaldır"
        }
    }

    // MARK: - Reels Actions

    var actionDive: String {
        switch lang {
        case .english: "Dive"
        case .turkish: "İncele"
        }
    }

    var actionShare: String {
        switch lang {
        case .english: "Share"
        case .turkish: "Paylaş"
        }
    }

    var actionShared: String {
        switch lang {
        case .english: "Shared"
        case .turkish: "Paylaşıldı"
        }
    }

    var actionExport: String {
        switch lang {
        case .english: "Export"
        case .turkish: "Dışa Aktar"
        }
    }

    var actionSave: String {
        switch lang {
        case .english: "Save"
        case .turkish: "Kaydet"
        }
    }

    var actionSaved: String {
        switch lang {
        case .english: "Saved"
        case .turkish: "Kaydedildi"
        }
    }

    var toastBookmarked: String {
        switch lang {
        case .english: "Post bookmarked"
        case .turkish: "Gönderi kaydedildi"
        }
    }

    var toastBookmarkRemoved: String {
        switch lang {
        case .english: "Bookmark removed"
        case .turkish: "Yer imi kaldırıldı"
        }
    }

    var toastPostShared: String {
        switch lang {
        case .english: "Post shared to Community"
        case .turkish: "Gönderi toplulukta paylaşıldı"
        }
    }

    var toastPostUnshared: String {
        switch lang {
        case .english: "Post unshared"
        case .turkish: "Paylaşım kaldırıldı"
        }
    }

    var toastInappropriateInterest: String {
        switch lang {
        case .english: "Inappropriate interest cannot be added"
        case .turkish: "Uygunsuz ilgi alanı eklenemez"
        }
    }

    // MARK: - Interest Discovery

    var orTypeYourOwn: String {
        switch lang {
        case .english: "Or type your own…"
        case .turkish: "Ya da kendi ilgini yaz…"
        }
    }

    var exploreCategoriesTitle: String {
        switch lang {
        case .english: "Explore"
        case .turkish: "Keşfet"
        }
    }

    var tapToExplore: String {
        switch lang {
        case .english: "Tap to explore"
        case .turkish: "Keşfetmek için dokun"
        }
    }

    // MARK: - Bento Box Interest Discovery

    var bentoAllCategories: String {
        switch lang {
        case .english: "All Topics"
        case .turkish: "Tüm Konular"
        }
    }

    var bentoAiSynthesizing: String {
        switch lang {
        case .english: "AI is synthesizing…"
        case .turkish: "Gemini üretiyor…"
        }
    }

    var bentoShuffle: String {
        switch lang {
        case .english: "Spin"
        case .turkish: "Döndür"
        }
    }

    var bentoAdded: String {
        switch lang {
        case .english: "Added"
        case .turkish: "Eklendi"
        }
    }

    var bentoDeepDive: String {
        switch lang {
        case .english: "Deep dive"
        case .turkish: "Derine in"
        }
    }

    var bentoTapToSelect: String {
        switch lang {
        case .english: "Tap to pick"
        case .turkish: "Seçmek için dokun"
        }
    }

    var bentoCollapse: String {
        switch lang {
        case .english: "Collapse"
        case .turkish: "Daralt"
        }
    }

    var bentoExpand: String {
        switch lang {
        case .english: "Explore"
        case .turkish: "Keşfet"
        }
    }

    var collectionsTitle: String {
        switch lang {
        case .english: "Collections"
        case .turkish: "Yer İşaretleri"
        }
    }

    // MARK: - Appearance

    var appearanceLabel: String {
        switch lang {
        case .english: "Appearance"
        case .turkish: "Görünüm"
        }
    }

    func appearanceName(_ mode: AppAppearance) -> String {
        switch mode {
        case .system:
            switch lang {
            case .english: "System"
            case .turkish: "Sistem"
            }
        case .light:
            switch lang {
            case .english: "Light"
            case .turkish: "Açık"
            }
        case .dark:
            switch lang {
            case .english: "Dark"
            case .turkish: "Koyu"
            }
        }
    }

    // MARK: - Letterboxd

    var letterboxdMode: String {
        switch lang {
        case .english: "Letterboxd Mode"
        case .turkish: "Letterboxd Modu"
        }
    }

    var updateLetterboxdButton: String {
        switch lang {
        case .english: "Update Letterboxd Username"
        case .turkish: "Letterboxd Kullanıcı Adını Güncelle"
        }
    }

    var letterboxdUsernamePromptTitle: String {
        switch lang {
        case .english: "Letterboxd Username"
        case .turkish: "Letterboxd Kullanıcı Adı"
        }
    }

    var letterboxdUsernamePromptMessage: String {
        switch lang {
        case .english:
            "Enter your Letterboxd username to personalize posts with your recently watched films."
        case .turkish:
            "Son izlediğin filmlerle gönderileri kişiselleştirmek için Letterboxd kullanıcı adını gir."
        }
    }

    var letterboxdUsernamePlaceholder: String {
        switch lang {
        case .english: "username"
        case .turkish: "kullanıcı adı"
        }
    }

    var letterboxdActive: String {
        switch lang {
        case .english: "Letterboxd active"
        case .turkish: "Letterboxd aktif"
        }
    }

    var letterboxdFetchError: String {
        switch lang {
        case .english: "Could not load Letterboxd data."
        case .turkish: "Letterboxd verileri yüklenemedi."
        }
    }

    var letterboxdRecentFilms: String {
        switch lang {
        case .english: "Recent Diary"
        case .turkish: "Son İzlediklerin"
        }
    }

    var letterboxdConnectDiary: String {
        switch lang {
        case .english: "Connect Diary"
        case .turkish: "Günlüğü Bağla"
        }
    }
}
