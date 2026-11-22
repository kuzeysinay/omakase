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
        case .turkish: "Derin incele"
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

    var clearSearch: String {
        switch lang {
        case .english: "Clear search"
        case .turkish: "Aramayı temizle"
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
            "Could not generate the post right now. Please check your internet connection and try again."
        case .turkish:
            "Gönderi şu anda üretilemedi. Lütfen internet bağlantını kontrol edip tekrar dene."
        }
    }

    func couldNotConnect(apiBase: String) -> String {
        switch lang {
        case .english:
            "Could not connect to Omakase servers. Please check your internet connection and try again."
        case .turkish:
            "Omakase sunucularına bağlanılamadı. Lütfen internet bağlantını kontrol edip tekrar dene."
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

    var signInWithApple: String {
        switch lang {
        case .english: "Continue with Apple"
        case .turkish: "Apple ile devam et"
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
        case .english: "Password must be at least 8 characters."
        case .turkish: "Şifre en az 8 karakter olmalıdır."
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
        case .english: "8+ characters"
        case .turkish: "8+ karakter tamam"
        }
    }

    var authPasswordHintRequirement: String {
        switch lang {
        case .english: "Minimum 8 characters"
        case .turkish: "En az 8 karakter"
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

    // MARK: - Account Deletion, UGC Moderation & Legal

    var deleteAccount: String {
        switch lang {
        case .english: "Delete account"
        case .turkish: "Hesabı sil"
        }
    }

    var confirmDeleteAccountTitle: String {
        switch lang {
        case .english: "Delete Account Permanently?"
        case .turkish: "Hesap Kalıcı Olarak Silinsin mi?"
        }
    }

    var confirmDeleteAccountMessage: String {
        switch lang {
        case .english:
            "Your profile, shared posts, comments, and account data will be permanently deleted. This action cannot be undone."
        case .turkish:
            "Profilin, toplulukta paylaştığın gönderiler, yorumların ve hesap verilerin kalıcı olarak silinecektir. Bu işlem geri alınamaz."
        }
    }

    var deleteAccountConfirmButton: String {
        switch lang {
        case .english: "Delete Permanently"
        case .turkish: "Kalıcı Olarak Sil"
        }
    }

    var accountDeleteRequiresReauth: String {
        switch lang {
        case .english:
            "For your security, please sign out and sign in again to complete account deletion."
        case .turkish:
            "Güvenliğin için hesabını silmeden önce lütfen çıkış yapıp tekrar giriş yap."
        }
    }

    var moderationErrorInappropriateText: String {
        switch lang {
        case .english: "This text contains inappropriate language and cannot be used."
        case .turkish: "Bu metin uygunsuz ifadeler içerdiği için kullanılamaz."
        }
    }

    var reportPost: String {
        switch lang {
        case .english: "Report Post"
        case .turkish: "Gönderiyi Bildir"
        }
    }

    var reportUser: String {
        switch lang {
        case .english: "Report User"
        case .turkish: "Kullanıcıyı Bildir"
        }
    }

    var reportComment: String {
        switch lang {
        case .english: "Report Comment"
        case .turkish: "Yorumu Bildir"
        }
    }

    var reportSubmittedToast: String {
        switch lang {
        case .english: "Report received. Our team will review it within 24 hours."
        case .turkish: "Bildiriminiz alındı. Ekibimiz 24 saat içinde inceleyecektir."
        }
    }

    var blockUser: String {
        switch lang {
        case .english: "Block User"
        case .turkish: "Kullanıcıyı Engelle"
        }
    }

    var unblockUser: String {
        switch lang {
        case .english: "Unblock User"
        case .turkish: "Engeli Kaldır"
        }
    }

    var confirmBlockUserTitle: String {
        switch lang {
        case .english: "Block User?"
        case .turkish: "Kullanıcı Engellensin mi?"
        }
    }

    var confirmBlockUserMessage: String {
        switch lang {
        case .english:
            "They will no longer be able to reach you, and their posts and comments will be removed from your feed immediately."
        case .turkish:
            "Bu kullanıcı artık seninle etkileşime geçemeyecek ve gönderileri ile yorumları akışından anında kaldırılacak."
        }
    }

    var userBlockedToast: String {
        switch lang {
        case .english: "User blocked"
        case .turkish: "Kullanıcı engellendi"
        }
    }

    var profileSupportAndLegal: String {
        switch lang {
        case .english: "Support & Legal"
        case .turkish: "Destek ve Yasal"
        }
    }

    var contactSupport: String {
        switch lang {
        case .english: "Contact Support"
        case .turkish: "Destek ve İletişim"
        }
    }

    var privacyPolicy: String {
        switch lang {
        case .english: "Privacy Policy"
        case .turkish: "Gizlilik Politikası"
        }
    }

    var termsOfUse: String {
        switch lang {
        case .english: "Terms of Use (EULA)"
        case .turkish: "Kullanım Koşulları (EULA)"
        }
    }

    var blockedUsersTitle: String {
        switch lang {
        case .english: "Blocked Users"
        case .turkish: "Engellenen Kullanıcılar"
        }
    }

    var noBlockedUsers: String {
        switch lang {
        case .english: "No blocked users"
        case .turkish: "Engellenen kullanıcı yok"
        }
    }

    // MARK: - Error Handling & Status

    var tryAgain: String {
        switch lang {
        case .english: "Try Again"
        case .turkish: "Tekrar Dene"
        }
    }

    var signInAgain: String {
        switch lang {
        case .english: "Sign In"
        case .turkish: "Giriş Yap"
        }
    }

    var editUsername: String {
        switch lang {
        case .english: "Edit Username"
        case .turkish: "Kullanıcı Adını Düzenle"
        }
    }

    var dismissLabel: String {
        switch lang {
        case .english: "Dismiss"
        case .turkish: "Kapat"
        }
    }

    var errorOfflineMessage: String {
        switch lang {
        case .english: "You're offline. You can still read saved plates."
        case .turkish: "Çevrimdışısın. Kaydedilen tabakları okuyabilirsin."
        }
    }

    var errorTimeoutTitle: String {
        switch lang {
        case .english: "Request Timed Out"
        case .turkish: "Bağlantı Zaman Aşımına Uğradı"
        }
    }

    var errorTimeoutMessage: String {
        switch lang {
        case .english: "The kitchen took too long to respond. Please try again."
        case .turkish: "Mutfaktan yanıt gelmesi uzun sürdü. Lütfen tekrar dene."
        }
    }

    var errorServerUnreachableTitle: String {
        switch lang {
        case .english: "Couldn't Connect"
        case .turkish: "Bağlantı Kurulamadı"
        }
    }

    var errorServerUnreachableMessage: String {
        switch lang {
        case .english: "Could not reach Omakase servers. Check your internet connection and try again."
        case .turkish: "Omakase sunucularına ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene."
        }
    }

    var errorUnauthorizedTitle: String {
        switch lang {
        case .english: "Session Expired"
        case .turkish: "Oturumun Sona Erdi"
        }
    }

    var errorUnauthorizedMessage: String {
        switch lang {
        case .english: "Please sign in again to continue."
        case .turkish: "Devam etmek için lütfen tekrar giriş yap."
        }
    }

    func errorRateLimitedMessage(seconds: Int?) -> String {
        if let seconds, seconds > 0 {
            switch lang {
            case .english: return "Let's slow down a little. Try again in \(seconds) seconds."
            case .turkish: return "Biraz yavaşlayalım. \(seconds) saniye sonra tekrar dene."
            }
        }
        switch lang {
        case .english: return "Let's slow down a little. Try again in a moment."
        case .turkish: return "Biraz yavaşlayalım. Biraz bekleyip tekrar dene."
        }
    }

    var errorQuotaExceededTitle: String {
        switch lang {
        case .english: "Today's Menu Is Complete"
        case .turkish: "Bugünkü Menü Tamamlandı"
        }
    }

    var errorQuotaExceededMessage: String {
        switch lang {
        case .english: "You've reached today's tasting limit. New plates will be ready tomorrow."
        case .turkish: "Bugünkü tadım hakkını tamamladın. Yeni tabaklar yarın hazır olacak."
        }
    }

    var errorContentBlockedMessage: String {
        switch lang {
        case .english: "We can't prepare a plate on this topic. Try another one."
        case .turkish: "Bu konuda tabak hazırlayamıyoruz. Başka bir konu dene."
        }
    }

    var errorGenerationFailedTitle: String {
        switch lang {
        case .english: "Couldn't Prepare Plate"
        case .turkish: "Tabak Hazırlanamadı"
        }
    }

    var errorGenerationFailedMessage: String {
        switch lang {
        case .english: "The chef couldn't finish this one. It didn't count toward your limit."
        case .turkish: "Şef bu tabağı tamamlayamadı. Hakkından düşülmedi."
        }
    }

    var errorServiceUnavailableTitle: String {
        switch lang {
        case .english: "Kitchen on a Short Break"
        case .turkish: "Mutfak Kısa Bir Mola Verdi"
        }
    }

    var errorServiceUnavailableMessage: String {
        switch lang {
        case .english: "The kitchen is taking a short break. Try again in a few minutes."
        case .turkish: "Mutfak şu an kısa bir mola verdi. Birkaç dakika sonra tekrar dene."
        }
    }

    var errorLetterboxdMissingUsername: String {
        switch lang {
        case .english: "Enter your Letterboxd username to load recent films."
        case .turkish: "Son filmlerini yüklemek için Letterboxd kullanıcı adını gir."
        }
    }

    var errorLetterboxdNotFoundMessage: String {
        switch lang {
        case .english: "No public films found for this Letterboxd username."
        case .turkish: "Bu Letterboxd kullanıcı adında herkese açık film bulunamadı."
        }
    }

    var errorLetterboxdPrivateMessage: String {
        switch lang {
        case .english: "This Letterboxd diary is private. Update your privacy settings or username."
        case .turkish: "Bu Letterboxd günlüğü gizli. Gizlilik ayarlarını veya kullanıcı adını kontrol et."
        }
    }

    var errorBillingSyncFailedMessage: String {
        switch lang {
        case .english: "Couldn't verify your subscription yet. Try Restore Purchases."
        case .turkish: "Aboneliğin henüz doğrulanamadı. Satın Alımları Geri Yükle'yi dene."
        }
    }

    var authErrorNetwork: String {
        switch lang {
        case .english: "You appear to be offline. Check your connection and try again."
        case .turkish: "İnternet bağlantısı yok gibi görünüyor. Bağlantını kontrol edip tekrar dene."
        }
    }

    var authErrorTooManyRequests: String {
        switch lang {
        case .english: "Too many attempts. Wait a moment and try again."
        case .turkish: "Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene."
        }
    }

    var authErrorUserDisabled: String {
        switch lang {
        case .english: "This account is currently unavailable. Please contact support."
        case .turkish: "Bu hesap şu anda kullanılamıyor. Lütfen destek ile iletişime geç."
        }
    }

    var authErrorProviderFailed: String {
        switch lang {
        case .english: "Sign-in couldn't be completed. Please try again."
        case .turkish: "Giriş tamamlanamadı. Lütfen tekrar dene."
        }
    }

    var authErrorSignOutFailed: String {
        switch lang {
        case .english: "Could not sign out right now. Please try again."
        case .turkish: "Şu anda çıkış yapılamadı. Lütfen tekrar dene."
        }
    }

    var errorShareFailed: String {
        switch lang {
        case .english: "Couldn't share this plate. Please try again."
        case .turkish: "Paylaşım tamamlanamadı. Lütfen tekrar dene."
        }
    }

    var errorUnshareFailed: String {
        switch lang {
        case .english: "Couldn't remove from community. Please try again."
        case .turkish: "Paylaşım kaldırılamadı. Lütfen tekrar dene."
        }
    }

    var errorCommentSendFailed: String {
        switch lang {
        case .english: "Your comment wasn't sent. Your text is saved so you can try again."
        case .turkish: "Yorumun gönderilemedi. Metnin duruyor, tekrar deneyebilirsin."
        }
    }

    var errorCommentLoadFailed: String {
        switch lang {
        case .english: "Couldn't load comments right now."
        case .turkish: "Yorumlar şu an yüklenemedi."
        }
    }

    var errorCommentDeleteFailed: String {
        switch lang {
        case .english: "Couldn't delete the comment. Please try again."
        case .turkish: "Yorum silinemedi. Lütfen tekrar dene."
        }
    }

    var errorReportFailed: String {
        switch lang {
        case .english: "Your report wasn't sent. Please try again."
        case .turkish: "Bildirimin gönderilemedi. Lütfen tekrar dene."
        }
    }

    var errorBlockFailed: String {
        switch lang {
        case .english: "Couldn't block this user. Please try again."
        case .turkish: "Kullanıcı engellenemedi. Lütfen tekrar dene."
        }
    }

    var errorUnblockFailed: String {
        switch lang {
        case .english: "Couldn't unblock this user. Please try again."
        case .turkish: "Engel kaldırılamadı. Lütfen tekrar dene."
        }
    }

    var errorFollowFailed: String {
        switch lang {
        case .english: "Couldn't follow right now. Try again."
        case .turkish: "Şu an takip edilemiyor. Tekrar dene."
        }
    }

    var errorUnfollowFailed: String {
        switch lang {
        case .english: "Couldn't unfollow right now. Try again."
        case .turkish: "Takipten çıkılamadı. Tekrar dene."
        }
    }

    var errorReactionFailed: String {
        switch lang {
        case .english: "Couldn't update reaction. Please try again."
        case .turkish: "Tepki güncellenemedi. Lütfen tekrar dene."
        }
    }

    var errorTimelineLoadFailed: String {
        switch lang {
        case .english: "Couldn't load the community feed."
        case .turkish: "Topluluk akışı yüklenemedi."
        }
    }

    var errorUserSearchFailed: String {
        switch lang {
        case .english: "Couldn't search users right now. Please try again."
        case .turkish: "Kullanıcı araması şu an yapılamadı. Lütfen tekrar dene."
        }
    }

    var errorProfileLoadFailed: String {
        switch lang {
        case .english: "Couldn't load this profile right now."
        case .turkish: "Bu profil şu an yüklenemedi."
        }
    }

    var errorPostDeleteFailed: String {
        switch lang {
        case .english: "Couldn't delete this post. Please try again."
        case .turkish: "Gönderi silinemedi. Lütfen tekrar dene."
        }
    }

    var errorUnknownMessage: String {
        switch lang {
        case .english: "An unexpected situation occurred. Please try again."
        case .turkish: "Beklenmeyen bir durum oluştu. Lütfen tekrar dene."
        }
    }

    // MARK: - Monetization, Omakase Pro & Daily Limit

    var proTitle: String { "Omakase Pro" }

    var proHeadline: String {
        switch lang {
        case .english: "Unlimited tasting, zero noise."
        case .turkish: "Sınırsız tadım, sıfır gürültü."
        }
    }

    var proSubtitle: String {
        switch lang {
        case .english: "3 free plates a day is just a taste. Unlock unlimited plates, primary-source Deep Dives, and full Letterboxd synthesis."
        case .turkish: "Günde 3 ücretsiz tabak sadece tadımlık. Sınırsız tabak, birincil kaynakçalı Deep Dive ve tam Letterboxd sentezini aç."
        }
    }

    var proFeatureUnlimitedPlates: String {
        switch lang {
        case .english: "Unlimited daily plates & Letterboxd behind-the-scenes"
        case .turkish: "Her gün sınırsız şef tabağı ve Letterboxd kamera arkası"
        }
    }

    var proFeatureUnlimitedDeepDive: String {
        switch lang {
        case .english: "Unlimited Deep Dives with verified primary sources"
        case .turkish: "Birincil kaynakçalı sınırsız Derin İnceleme"
        }
    }

    var proFeatureUnlimitedSubtopics: String {
        switch lang {
        case .english: "Unlimited subtopic refreshes"
        case .turkish: "Sınırsız alt konu yenileme"
        }
    }

    var proFeatureProBadge: String {
        switch lang {
        case .english: "Pro badge on your Community profile"
        case .turkish: "Topluluk profilinde Pro rozeti"
        }
    }

    var proBestValueBadge: String {
        switch lang {
        case .english: "Best Value"
        case .turkish: "En Avantajlı"
        }
    }

    var proFreeTrialBadge: String {
        switch lang {
        case .english: "7-day free trial · Only ~$2.49/mo (Save 37%)"
        case .turkish: "7 gün ücretsiz · Ayda yalnızca ~$2.49 (%37 avantaj)"
        }
    }

    var proPlanYearly: String {
        switch lang {
        case .english: "Yearly"
        case .turkish: "Yıllık"
        }
    }

    var proPlanMonthly: String {
        switch lang {
        case .english: "Monthly"
        case .turkish: "Aylık"
        }
    }

    var proPerYearSuffix: String {
        switch lang {
        case .english: "/ year"
        case .turkish: "/ yıl"
        }
    }

    var proPerMonthSuffix: String {
        switch lang {
        case .english: "/ month"
        case .turkish: "/ ay"
        }
    }

    var proStartTrialCTA: String {
        switch lang {
        case .english: "Start 7-Day Free Trial"
        case .turkish: "7 Gün Ücretsiz Dene"
        }
    }

    var proSubscribeCTA: String {
        switch lang {
        case .english: "Continue with Omakase Pro"
        case .turkish: "Omakase Pro ile Devam Et"
        }
    }

    var proRestorePurchases: String {
        switch lang {
        case .english: "Restore Purchases"
        case .turkish: "Satın Alımları Geri Yükle"
        }
    }

    var proRestoreSuccess: String {
        switch lang {
        case .english: "Your Omakase Pro subscription is restored."
        case .turkish: "Omakase Pro aboneliğin geri yüklendi."
        }
    }

    var proRestoreEmpty: String {
        switch lang {
        case .english: "No active subscription was found to restore."
        case .turkish: "Geri yüklenecek aktif bir abonelik bulunamadı."
        }
    }

    var proPurchaseSuccess: String {
        switch lang {
        case .english: "Welcome to Omakase Pro."
        case .turkish: "Omakase Pro'ya hoş geldin."
        }
    }

    var proPaymentPending: String {
        switch lang {
        case .english: "Your purchase is pending approval and will activate once confirmed."
        case .turkish: "Satın alma onayı bekleniyor; onaylandığında aboneliğin otomatik açılacak."
        }
    }

    var proSubscriptionDisclosure: String {
        switch lang {
        case .english:
            "Payment is charged to your Apple ID account at confirmation (or after the 7-day trial ends). Subscription renews automatically unless canceled at least 24 hours before the end of the current period."
        case .turkish:
            "Ödeme onay anında (veya 7 günlük deneme bittiğinde) Apple ID hesabından tahsil edilir. Dönem bitiminden en az 24 saat önce iptal edilmedikçe abonelik otomatik yenilenir."
        }
    }

    var proManageSubscription: String {
        switch lang {
        case .english: "Manage Subscription"
        case .turkish: "Aboneliği Yönet"
        }
    }

    var proActiveStatus: String {
        switch lang {
        case .english: "Active"
        case .turkish: "Aktif"
        }
    }

    var proTrialStatus: String {
        switch lang {
        case .english: "Free Trial"
        case .turkish: "Ücretsiz Deneme"
        }
    }

    var proBillingIssueStatus: String {
        switch lang {
        case .english: "Billing issue — update payment method"
        case .turkish: "Ödeme sorunu — ödeme yöntemini güncelle"
        }
    }

    func proRenewsOn(_ dateText: String) -> String {
        switch lang {
        case .english: "Renews on \(dateText)"
        case .turkish: "Yenilenme tarihi: \(dateText)"
        }
    }

    func proExpiresOn(_ dateText: String) -> String {
        switch lang {
        case .english: "Expires on \(dateText)"
        case .turkish: "Bitiş tarihi: \(dateText)"
        }
    }

    var proProductsUnavailable: String {
        switch lang {
        case .english: "Subscription options are loading from the App Store. Try again shortly."
        case .turkish: "Abonelik paketleri App Store'dan yükleniyor. Kısa süre sonra tekrar dene."
        }
    }

    var proShareForDeepDiveCTA: String {
        switch lang {
        case .english: "Tip: Share any plate today to unlock +1 bonus Deep Dive for free."
        case .turkish: "İpucu: Bugün bir tabak paylaşarak ücretsiz +1 ekstra Derin İnceleme kazanabilirsin."
        }
    }

    var limitCardTitle: String {
        switch lang {
        case .english: "Today's Menu Is Complete"
        case .turkish: "Bugünkü Menü Tamamlandı"
        }
    }

    var limitCardSubtitle: String {
        switch lang {
        case .english: "The chef has served all 3 free plates for today. Unlock Omakase Pro for unlimited reading or wait for tomorrow's menu."
        case .turkish: "Şef bugünlük 3 ücretsiz tabağı sundu. Sınırsız okuma için Omakase Pro'ya geç veya yarının menüsünü bekle."
        }
    }

    func limitCardNextMenuIn(_ countdown: String) -> String {
        switch lang {
        case .english: "Next menu in \(countdown)"
        case .turkish: "Yeni menüye \(countdown)"
        }
    }

    var limitCardUpgradeCTA: String {
        switch lang {
        case .english: "Continue with Omakase Pro"
        case .turkish: "Omakase Pro ile Devam Et"
        }
    }

    var limitCardRemindCTA: String {
        switch lang {
        case .english: "Remind Me Tomorrow"
        case .turkish: "Yarın Hatırlat"
        }
    }

    var limitCardRemindPendingToast: String {
        switch lang {
        case .english: "Daily menu reminders are coming in the next step."
        case .turkish: "Günlük menü hatırlatıcısı bir sonraki adımda aktif edilecek."
        }
    }

    var limitCardBackToPlates: String {
        switch lang {
        case .english: "Re-read today's plates"
        case .turkish: "Bugünkü tabaklara dön"
        }
    }

    var toastShareBonusGranted: String {
        switch lang {
        case .english: "+1 bonus Deep Dive unlocked for today!"
        case .turkish: "Bugün için +1 ekstra Derin İnceleme açıldı!"
        }
    }

    var profileMembershipSection: String {
        switch lang {
        case .english: "Membership"
        case .turkish: "Üyelik"
        }
    }

    var profileUpgradeToPro: String {
        switch lang {
        case .english: "Upgrade to Omakase Pro"
        case .turkish: "Omakase Pro'ya Geç"
        }
    }

    func profileDailyQuotaSummary(
        platesRemaining: Int,
        platesLimit: Int,
        deepDivesRemaining: Int,
        deepDivesLimit: Int
    ) -> String {
        switch lang {
        case .english:
            "Today: \(platesRemaining)/\(platesLimit) plates · \(deepDivesRemaining)/\(deepDivesLimit) deep dives left"
        case .turkish:
            "Bugün: \(platesRemaining)/\(platesLimit) tabak · \(deepDivesRemaining)/\(deepDivesLimit) inceleme kaldı"
        }
    }

    // MARK: - Notifications (Phase 3)

    var notificationsSectionTitle: String {
        switch lang {
        case .english: "Notifications"
        case .turkish: "Bildirimler"
        }
    }

    var notificationsDailyMenuToggle: String {
        switch lang {
        case .english: "Daily Menu Reminder"
        case .turkish: "Günlük Menü Hatırlatıcısı"
        }
    }

    var notificationsReminderTime: String {
        switch lang {
        case .english: "Reminder Time"
        case .turkish: "Hatırlatma Saati"
        }
    }

    var notificationsCommentsToggle: String {
        switch lang {
        case .english: "Comment Notifications"
        case .turkish: "Yorum Bildirimleri"
        }
    }

    var notificationsDigestToggle: String {
        switch lang {
        case .english: "Daily Follower & Reaction Digest"
        case .turkish: "Günlük Takipçi & Tepki Özeti"
        }
    }

    var notificationsDeniedBanner: String {
        switch lang {
        case .english: "Notifications are off — Open Settings"
        case .turkish: "Bildirimler kapalı — Ayarlar'da aç"
        }
    }

    var notificationsProvisionalHint: String {
        switch lang {
        case .english: "Notifications are currently delivered quietly to Notification Center."
        case .turkish: "Bildirimler şu anda Bildirim Merkezi'ne sessiz teslim ediliyor."
        }
    }

    var notificationsQuietHoursFooter: String {
        switch lang {
        case .english: "Social updates pause between 22:00 and 08:00. Followers and reactions arrive once daily."
        case .turkish: "Sosyal bildirimler 22:00–08:00 arası duraklatılır. Takipçi ve tepkiler günde tek özet olarak gelir."
        }
    }

    var notificationsDeniedAlertTitle: String {
        switch lang {
        case .english: "Notifications Disabled"
        case .turkish: "Bildirim İzni Kapalı"
        }
    }

    var notificationsDeniedAlertMessage: String {
        switch lang {
        case .english: "Allow notifications in iOS Settings so Omakase can let you know when tomorrow's menu is ready."
        case .turkish: "Yarının menüsü hazır olduğunda haber verebilmemiz için iOS Ayarlar'dan bildirimlere izin ver."
        }
    }

    var openSettingsCTA: String {
        switch lang {
        case .english: "Open Settings"
        case .turkish: "Ayarları Aç"
        }
    }

    func limitCardRemindScheduledToast(timeText: String) -> String {
        switch lang {
        case .english: "Reminder set for \(timeText)."
        case .turkish: "Hatırlatıcı \(timeText) için ayarlandı."
        }
    }

    var notificationsNotGrantedToast: String {
        switch lang {
        case .english: "Notifications weren't enabled. You can turn them on anytime in Profile."
        case .turkish: "Bildirimler açılmadı. İstediğin zaman Profil ekranından açabilirsin."
        }
    }

    var commentNotificationPromptTitle: String {
        switch lang {
        case .english: "Get notified about new comments on your plates"
        case .turkish: "Paylaşımlarına yorum geldiğinde haber al"
        }
    }

    var turnOnCTA: String {
        switch lang {
        case .english: "Turn On"
        case .turkish: "Aç"
        }
    }

    var dailyMenuNotificationTitle: String {
        switch lang {
        case .english: "Today's Menu"
        case .turkish: "Günün Menüsü"
        }
    }

    func dailyMenuNotificationBody(interests: [String]) -> String {
        switch lang {
        case .english:
            if interests.count >= 2 {
                return "\(interests[0]) and \(interests[1]) are on the menu today."
            } else if let first = interests.first, !first.isEmpty {
                return "\(first) is featured on today's menu."
            } else {
                return "Fresh plates curated for your taste are ready today."
            }
        case .turkish:
            if interests.count >= 2 {
                return "Bugün mutfakta \(interests[0]) ve \(interests[1]) var."
            } else if let first = interests.first, !first.isEmpty {
                return "Bugün mutfakta \(first) öne çıkıyor."
            } else {
                return "Şefin bugünkü tabakları hazır."
            }
        }
    }

    var hiddenPreviewDailyMenu: String {
        switch lang {
        case .english: "Today's Menu"
        case .turkish: "Günün Menüsü"
        }
    }

    var hiddenPreviewComment: String {
        switch lang {
        case .english: "New comment"
        case .turkish: "Yeni yorum"
        }
    }

    var hiddenPreviewDigest: String {
        switch lang {
        case .english: "Community summary"
        case .turkish: "Topluluk özeti"
        }
    }

    // MARK: - Daily Plate Quota Stress Pill & Social Discover Mode

    func feedQuotaPlatesRemaining(remaining: Int, limit: Int) -> String {
        switch lang {
        case .english:
            if remaining <= 0 {
                return "Limit · 0/\(limit)"
            } else if remaining == 1 {
                return "Last 1 · 1/\(limit)"
            } else {
                return "\(remaining)/\(limit) Left"
            }
        case .turkish:
            if remaining <= 0 {
                return "Doldu · 0/\(limit)"
            } else if remaining == 1 {
                return "Son 1 Hak · 1/\(limit)"
            } else {
                return "Kalan: \(remaining)/\(limit)"
            }
        }
    }

    func feedQuotaAccessibilityLabel(remaining: Int, limit: Int) -> String {
        switch lang {
        case .english:
            "Daily free plates remaining: \(remaining) of \(limit). Tap to upgrade to Omakase Pro."
        case .turkish:
            "Günlük ücretsiz tabak hakkı: \(limit) üzerinden \(remaining) kaldı. Omakase Pro'ya geçmek için dokun."
        }
    }

    var timelineModeDiscover: String {
        switch lang {
        case .english: "Discover"
        case .turkish: "Keşfet"
        }
    }

    var timelineModeFollowing: String {
        switch lang {
        case .english: "Following"
        case .turkish: "Takip Edilenler"
        }
    }

    var discoverFeedSubheader: String {
        switch lang {
        case .english: "Fresh plates shared by readers across the community."
        case .turkish: "Topluluktaki farklı okurların paylaştığı seçme tabaklar."
        }
    }

    var followingEmptyHeadline: String {
        switch lang {
        case .english: "No posts from people you follow yet"
        case .turkish: "Takip ettiğin kişilerden henüz paylaşım yok"
        }
    }

    var followingEmptyDetail: String {
        switch lang {
        case .english: "Switch to Discover to see random readers and follow tastes you like."
        case .turkish: "Farklı okurları görmek ve zevkine uyanları takip etmek için Keşfet sekmesine geç."
        }
    }

    var exploreDiscoverCTA: String {
        switch lang {
        case .english: "Explore Discover Feed"
        case .turkish: "Keşfet Akışına Geç"
        }
    }
}
