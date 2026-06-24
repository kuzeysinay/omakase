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
        case .english: "Sign in with Google"
        case .turkish: "Google ile giriş yap"
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
        case .english: "Timeline"
        case .turkish: "Zaman Akışı"
        }
    }

    // MARK: - Timeline

    var loadingTimeline: String {
        switch lang {
        case .english: "Loading timeline…"
        case .turkish: "Zaman akışı yükleniyor…"
        }
    }

    var timelineEmptyHeadline: String {
        switch lang {
        case .english: "Your timeline is empty"
        case .turkish: "Zaman akışın boş"
        }
    }

    var timelineEmptyDetail: String {
        switch lang {
        case .english: "Follow people to see the posts they share from their AI feeds."
        case .turkish: "Yapay zeka akışlarından paylaştıkları gönderileri görmek için insanları takip et."
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
        case .english: "Share to timeline"
        case .turkish: "Zaman akışına paylaş"
        }
    }

    var unsharePost: String {
        switch lang {
        case .english: "Remove from timeline"
        case .turkish: "Zaman akışından kaldır"
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
        case .english: "Post shared to Social Feed"
        case .turkish: "Gönderi akışta paylaşıldı"
        }
    }

    var toastPostUnshared: String {
        switch lang {
        case .english: "Post unshared"
        case .turkish: "Paylaşım kaldırıldı"
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
}
