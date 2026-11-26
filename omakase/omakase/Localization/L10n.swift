//
//  L10n.swift
//  omakase
//
//  UI strings keyed by ``AppLanguage`` via per-language `.lproj/Localizable.strings`
//  bundles (keeps onboarding, feed, and notifications in sync with API `language`).
//

import Foundation

struct L10n {
    let lang: AppLanguage

    private static let bundles: [AppLanguage: Bundle] = {
        var map: [AppLanguage: Bundle] = [:]
        for language in AppLanguage.allCases {
            if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                map[language] = bundle
            }
        }
        return map
    }()

    private func tr(_ key: String, fallback: String) -> String {
        if let bundle = Self.bundles[lang] {
            let value = bundle.localizedString(forKey: key, value: "__MISSING__", table: nil)
            if value != "__MISSING__" {
                return value
            }
        }
        if let enBundle = Self.bundles[.english] {
            let value = enBundle.localizedString(forKey: key, value: "__MISSING__", table: nil)
            if value != "__MISSING__" {
                return value
            }
        }
        return fallback
    }

    private func tr(_ key: String, fallback: String, _ replacements: (String, String)...) -> String {
        var result = tr(key, fallback: fallback)
        for (placeholder, replacement) in replacements {
            result = result.replacingOccurrences(of: "{\(placeholder)}", with: replacement)
        }
        return result
    }

    // MARK: - Shared chrome

    var appTitle: String { "omakase" }
    var languageMenuAccessibility: String { tr("languageMenuAccessibility", fallback: "Language") }
    var backA11y: String { tr("backA11y", fallback: "Back") }
    var closeLabel: String { tr("closeLabel", fallback: "Close") }
    var clearTextA11y: String { tr("clearTextA11y", fallback: "Clear text") }
    var passwordVisibilityA11y: String { tr("passwordVisibilityA11y", fallback: "Password visibility") }
    var loadingLabel: String { tr("loadingLabel", fallback: "Loading…") }
    var loadingMoreLabel: String { tr("loadingMoreLabel", fallback: "Loading more…") }

    // MARK: - Onboarding

    var onboardingTagline: String {
        tr("onboardingTagline", fallback: "Tell us what you love. Your feed is generated fresh, just for you.")
    }
    var onboardingNeedInterest: String { tr("onboardingNeedInterest", fallback: "Add at least one interest") }
    var onboardingStartFeed: String { tr("onboardingStartFeed", fallback: "Start my feed") }

    // MARK: - Feed

    var shareSheetA11y: String { tr("shareSheetA11y", fallback: "Share post") }
    var deepDiveA11y: String { tr("deepDiveA11y", fallback: "Deep dive") }
    var noPostsYet: String { tr("noPostsYet", fallback: "No posts yet") }
    var offlineBanner: String { tr("offlineBanner", fallback: "You're offline. Showing cached posts.") }
    var internetRequired: String { tr("internetRequired", fallback: "Internet required") }
    var clearFeed: String { tr("clearFeed", fallback: "Clear feed") }
    var clearSearch: String { tr("clearSearch", fallback: "Clear search") }
    var feedMoreActionsA11y: String { tr("feedMoreActionsA11y", fallback: "More actions") }
    var errorSomethingWrong: String { tr("errorSomethingWrong", fallback: "Something went wrong") }
    var ok: String { tr("ok", fallback: "OK") }

    func editTastesA11y(_ tasteSummary: String) -> String {
        tr("editTastesA11y", fallback: "Edit tastes, {summary}", ("summary", tasteSummary))
    }

    func tastesNoneA11y() -> String { tr("tastesNoneA11y", fallback: "none selected") }

    func tastesCountA11y(_ count: Int) -> String {
        tr("tastesCountA11y", fallback: "{count} selected", ("count", "\(count)"))
    }

    var addTastes: String { tr("addTastes", fallback: "Add tastes") }

    func tastesShortLabel(count: Int, singleName: String) -> String {
        if count == 0 { return addTastes }
        if count == 1 {
            return singleName.count > 16 ? String(singleName.prefix(14)) + "…" : singleName
        }
        return tr("tastesShortLabelCount", fallback: "{count} tastes", ("count", "\(count)"))
    }

    func savedPostsA11y(count: Int) -> String {
        if count > 0 {
            return tr("savedPostsA11yCount", fallback: "Saved posts, {count}", ("count", "\(count)"))
        }
        return tr("savedPostsA11yEmpty", fallback: "Saved posts")
    }

    var emptyFeedHeadline: String { tr("emptyFeedHeadline", fallback: "Your feed is warming up…") }
    var emptyFeedDetail: String { tr("emptyFeedDetail", fallback: "Tap the button below to taste the first post.") }
    var generating: String { tr("generating", fallback: "Generating…") }

    /// Rotates while a post streams in; paired with ``FeedViewModel/loadingQuipIndex``.
    var cookingQuips: [String] {
        let fallback = [
            "Simmering…",
            "Chef absolutely knows which knife.",
            "Reducing your interests into a sauce…",
            "Tasting the draft so you don't have to.",
            "Quietly sharpening the punchlines…",
            "Plating commas and confidence…",
            "One more swirl of personality…",
            "Almost too hot to subtitle.",
        ]
        let raw = tr("cookingQuips", fallback: fallback.joined(separator: "\n"))
        let lines = raw.components(separatedBy: "\n").filter { !$0.isEmpty }
        return lines.isEmpty ? fallback : lines
    }

    var serveNextPost: String { tr("serveNextPost", fallback: "Serve next post") }

    func readingCooldownTitle(seconds: Int) -> String {
        tr("readingCooldownTitle", fallback: "Reading cooldown: {seconds}s", ("seconds", "\(seconds)"))
    }

    var readingCooldownDetail: String {
        tr("readingCooldownDetail", fallback: "Take your time with this post. Next dish unlocks shortly.")
    }
    var removeBookmarkA11y: String { tr("removeBookmarkA11y", fallback: "Remove bookmark") }
    var bookmarkPostA11y: String { tr("bookmarkPostA11y", fallback: "Bookmark post") }
    var liveBadge: String { tr("liveBadge", fallback: "LIVE") }
    var composingTitle: String { tr("composingTitle", fallback: "Composing…") }
    var untitledBite: String { tr("untitledBite", fallback: "Untitled bite") }
    var streamEndedNoText: String {
        tr("streamEndedNoText", fallback: "Could not generate the post right now. Please check your internet connection and try again.")
    }

    func couldNotConnect(apiBase: String) -> String {
        _ = apiBase
        return tr("couldNotConnect", fallback: "Could not connect to omakase servers. Please check your internet connection and try again.")
    }

    var writingDeepDive: String { tr("writingDeepDive", fallback: "Writing deep dive…") }
    var scrollDownForNewPost: String { tr("scrollDownForNewPost", fallback: "Scroll down for a new post") }
    var actionReRead: String { tr("actionReRead", fallback: "Re-read") }
    var deepDiveTitle: String { tr("deepDiveTitle", fallback: "Deep Dive") }
    var deepDiveShortLabel: String { tr("deepDiveShortLabel", fallback: "Deep Dive") }
    var readDeepDiveA11y: String { tr("readDeepDiveA11y", fallback: "Read deep dive") }
    var hideKeyboard: String { tr("hideKeyboard", fallback: "Hide keyboard") }

    // MARK: - Interests editor

    var addTastePlaceholder: String { tr("addTastePlaceholder", fallback: "Add a taste…") }
    var ideasToTry: String { tr("ideasToTry", fallback: "Ideas to try") }
    var thinking: String { tr("thinking", fallback: "Thinking…") }
    var refreshIdeasA11y: String { tr("refreshIdeasA11y", fallback: "Refresh ideas") }
    var couldNotLoadIdeas: String { tr("couldNotLoadIdeas", fallback: "Could not load ideas.") }

    // MARK: - Adjust tastes sheet

    var adjustTastesBlurb: String {
        tr("adjustTastesBlurb", fallback: "Tune what omakase cooks for you. Add, remove, or steal ideas below — your feed updates right away.")
    }
    var yourTastes: String { tr("yourTastes", fallback: "Your tastes") }
    var cancel: String { tr("cancel", fallback: "Cancel") }
    var save: String { tr("save", fallback: "Save") }

    // MARK: - Bookmarks

    var noBookmarks: String { tr("noBookmarks", fallback: "No bookmarks") }
    var bookmarksHint: String {
        tr("bookmarksHint", fallback: "Save a finished post from your feed to read it again here.")
    }
    var savedPostFallbackTitle: String { tr("savedPostFallbackTitle", fallback: "Saved post") }
    var savedPostsLabel: String { tr("savedPostsLabel", fallback: "Saved Posts") }
    var bookmarkAllCategory: String { tr("bookmarkAllCategory", fallback: "All") }
    var moveToCategory: String { tr("moveToCategory", fallback: "Move to Category…") }
    var remove: String { tr("remove", fallback: "Remove") }
    var savedTitle: String { tr("savedTitle", fallback: "Saved") }
    var done: String { tr("done", fallback: "Done") }
    var removeAllSaved: String { tr("removeAllSaved", fallback: "Remove all saved") }
    var selectEdit: String { tr("selectEdit", fallback: "Select") }

    func deleteSelectedCount(_ count: Int) -> String {
        tr("deleteSelectedCount", fallback: "Delete {count} selected", ("count", "\(count)"))
    }

    // MARK: - Delete confirmations

    var confirmDeleteTitle: String { tr("confirmDeleteTitle", fallback: "Delete bookmark?") }
    var confirmDeleteMessage: String {
        tr("confirmDeleteMessage", fallback: "This saved post will be removed permanently.")
    }

    func confirmDeleteSelectedTitle(_ count: Int) -> String {
        tr("confirmDeleteSelectedTitle", fallback: "Delete {count} bookmarks?", ("count", "\(count)"))
    }

    func confirmDeleteSelectedMessage(_ count: Int) -> String {
        tr("confirmDeleteSelectedMessage", fallback: "The {count} selected posts will be removed permanently.", ("count", "\(count)"))
    }

    var confirmDeleteAllTitle: String { tr("confirmDeleteAllTitle", fallback: "Delete all bookmarks?") }
    var confirmDeleteAllMessage: String {
        tr("confirmDeleteAllMessage", fallback: "All saved posts will be removed permanently.")
    }
    var confirmDeletePostTitle: String { tr("confirmDeletePostTitle", fallback: "Delete post?") }
    var confirmDeletePostMessage: String {
        tr("confirmDeletePostMessage", fallback: "This post will be removed from your feed.")
    }

    // MARK: - Auth

    var authTagline: String {
        tr("authTagline", fallback: "Noise-free culture feed. Read and share short, sourced posts on topics you love.")
    }
    var signInWithGoogle: String { tr("signInWithGoogle", fallback: "Continue with Google") }
    var signInWithApple: String { tr("signInWithApple", fallback: "Continue with Apple") }
    var authSignUpTab: String { tr("authSignUpTab", fallback: "Sign Up") }
    var authSignInTab: String { tr("authSignInTab", fallback: "Sign In") }
    var authNameLabel: String { tr("authNameLabel", fallback: "Full Name") }
    var authNamePlaceholder: String { tr("authNamePlaceholder", fallback: "Your name") }
    var authEmailLabel: String { tr("authEmailLabel", fallback: "Email") }
    var authEmailPlaceholder: String { tr("authEmailPlaceholder", fallback: "name@example.com") }
    var authPasswordLabel: String { tr("authPasswordLabel", fallback: "Password") }
    var authPasswordPlaceholder: String { tr("authPasswordPlaceholder", fallback: "At least 6 characters") }
    var authConfirmPasswordLabel: String { tr("authConfirmPasswordLabel", fallback: "Confirm Password") }
    var authConfirmPasswordPlaceholder: String { tr("authConfirmPasswordPlaceholder", fallback: "Re-enter your password") }
    var authSignUpWithEmailButton: String { tr("authSignUpWithEmailButton", fallback: "Sign up with Email") }
    var authSignInWithEmailButton: String { tr("authSignInWithEmailButton", fallback: "Sign in with Email") }
    var authOrDivider: String { tr("authOrDivider", fallback: "or") }
    var authOrWithEmail: String { tr("authOrWithEmail", fallback: "or with email") }
    var authForgotPassword: String { tr("authForgotPassword", fallback: "Forgot password?") }
    var authResetPasswordSent: String {
        tr("authResetPasswordSent", fallback: "Password reset link sent to your email.")
    }
    var authSwitchToSignInPrompt: String {
        tr("authSwitchToSignInPrompt", fallback: "Already have an account? Sign in")
    }
    var authSwitchToSignUpPrompt: String {
        tr("authSwitchToSignUpPrompt", fallback: "Don't have an account? Sign up with email")
    }
    var authErrorNameRequired: String { tr("authErrorNameRequired", fallback: "Please enter your name.") }
    var authErrorInvalidEmail: String {
        tr("authErrorInvalidEmail", fallback: "Please enter a valid email address.")
    }
    var authErrorWeakPassword: String {
        tr("authErrorWeakPassword", fallback: "Password must be at least 8 characters.")
    }
    var authErrorPasswordMismatch: String { tr("authErrorPasswordMismatch", fallback: "Passwords do not match.") }
    var authErrorEmailInUse: String {
        tr("authErrorEmailInUse", fallback: "This email address is already registered.")
    }
    var authErrorInvalidCredential: String { tr("authErrorInvalidCredential", fallback: "Incorrect email or password.") }
    var authErrorEnterEmailForReset: String {
        tr("authErrorEnterEmailForReset", fallback: "Enter your email address above first to reset your password.")
    }
    var authCreateAccountButton: String { tr("authCreateAccountButton", fallback: "Create account with Email") }
    var authContinueButton: String { tr("authContinueButton", fallback: "Continue") }
    var authCompleteSignUpButton: String { tr("authCompleteSignUpButton", fallback: "Create Account") }
    var authStep1Title: String { tr("authStep1Title", fallback: "Create your account") }
    var authStep1Subtitle: String {
        tr("authStep1Subtitle", fallback: "Start with your email and a secure password.")
    }
    var authStep2Title: String { tr("authStep2Title", fallback: "What should we call you?") }
    var authStep2Subtitle: String {
        tr("authStep2Subtitle", fallback: "This is your display name shown on your profile and shared bites.")
    }
    var authDisplayNamePlaceholder: String {
        tr("authDisplayNamePlaceholder", fallback: "Display Name (e.g. Kuzey Sınay)")
    }
    var authStep3Title: String { tr("authStep3Title", fallback: "Pick your @username") }
    var authStep3Subtitle: String {
        tr("authStep3Subtitle", fallback: "Your unique handle makes it easy for others to find and follow you.")
    }
    var authUsernamePlaceholder: String { tr("authUsernamePlaceholder", fallback: "username") }
    var authSuggestedUsernames: String { tr("authSuggestedUsernames", fallback: "Suggestions") }
    var authUsernameAvailable: String { tr("authUsernameAvailable", fallback: "Available") }
    var authUsernameTaken: String { tr("authUsernameTaken", fallback: "This username is already taken.") }
    var authUsernameTooShort: String {
        tr("authUsernameTooShort", fallback: "Username must be at least 3 characters.")
    }
    var authWelcomeBackTitle: String { tr("authWelcomeBackTitle", fallback: "Welcome back") }
    var authWelcomeBackSubtitle: String {
        tr("authWelcomeBackSubtitle", fallback: "Sign in with your email and password.")
    }
    var authPasswordHintValid: String { tr("authPasswordHintValid", fallback: "8+ characters") }
    var authPasswordHintRequirement: String { tr("authPasswordHintRequirement", fallback: "Minimum 8 characters") }
    var authProfilePreviewLabel: String { tr("authProfilePreviewLabel", fallback: "PROFILE PREVIEW") }
    var signOut: String { tr("signOut", fallback: "Sign out") }

    // MARK: - Tabs

    var tabMyFeed: String { tr("tabMyFeed", fallback: "My Feed") }
    var tabTimeline: String { tr("tabTimeline", fallback: "Community") }
    var tabProfile: String { tr("tabProfile", fallback: "Profile") }

    // MARK: - Timeline / Community & Comments

    var loadingTimeline: String { tr("loadingTimeline", fallback: "Loading community…") }
    var timelineEmptyHeadline: String { tr("timelineEmptyHeadline", fallback: "No community posts yet") }
    var timelineEmptyDetail: String {
        tr("timelineEmptyDetail", fallback: "Follow people to see the posts they share from their AI feeds.")
    }
    var communitySearchPlaceholder: String {
        tr("communitySearchPlaceholder", fallback: "Search people or posts…")
    }
    var searchPeopleSection: String { tr("searchPeopleSection", fallback: "People") }
    var noSearchResults: String { tr("noSearchResults", fallback: "No results found") }
    var discoverBannerTitle: String { tr("discoverBannerTitle", fallback: "Discover") }
    var discoverBannerDetail: String {
        tr("discoverBannerDetail", fallback: "You're not following anyone yet. Here's what people are sharing.")
    }
    var deletePost: String { tr("deletePost", fallback: "Delete Post") }
    var likeA11y: String { tr("likeA11y", fallback: "Like") }
    var commentsA11y: String { tr("commentsA11y", fallback: "Comments") }

    func commentsCountTitle(_ count: Int) -> String {
        tr("commentsCountTitle", fallback: "{count} Comments", ("count", "\(count)"))
    }

    var noCommentsYet: String { tr("noCommentsYet", fallback: "No comments yet") }
    var addCommentPlaceholder: String { tr("addCommentPlaceholder", fallback: "Add a comment…") }
    var sendCommentA11y: String { tr("sendCommentA11y", fallback: "Send comment") }

    // MARK: - Follow system

    var findPeople: String { tr("findPeople", fallback: "Find people") }
    var follow: String { tr("follow", fallback: "Follow") }
    var following: String { tr("following", fallback: "Following") }
    var followers: String { tr("followers", fallback: "Followers") }
    var followingLabel: String { tr("followingLabel", fallback: "Following") }
    var searchUsersPlaceholder: String { tr("searchUsersPlaceholder", fallback: "Search by name…") }
    var searchUsersHint: String { tr("searchUsersHint", fallback: "Search for people to follow") }
    var noUsersFound: String { tr("noUsersFound", fallback: "No users found") }

    // MARK: - Profile

    var myProfile: String { tr("myProfile", fallback: "My Profile") }
    var profilePreferences: String { tr("profilePreferences", fallback: "Preferences") }
    var profilePosts: String { tr("profilePosts", fallback: "Posts") }
    var profileAccount: String { tr("profileAccount", fallback: "Account") }

    // MARK: - Share & Reels Actions

    var sharePost: String { tr("sharePost", fallback: "Share to community") }
    var unsharePost: String { tr("unsharePost", fallback: "Remove from community") }
    var actionDive: String { tr("actionDive", fallback: "Dive") }
    var actionShare: String { tr("actionShare", fallback: "Share") }
    var actionShared: String { tr("actionShared", fallback: "Shared") }
    var actionExport: String { tr("actionExport", fallback: "Export") }
    var actionSave: String { tr("actionSave", fallback: "Save") }
    var actionSaved: String { tr("actionSaved", fallback: "Saved") }
    var toastBookmarked: String { tr("toastBookmarked", fallback: "Post bookmarked") }
    var toastBookmarkRemoved: String { tr("toastBookmarkRemoved", fallback: "Bookmark removed") }
    var toastPostShared: String { tr("toastPostShared", fallback: "Post shared to Community") }
    var toastPostUnshared: String { tr("toastPostUnshared", fallback: "Post unshared") }
    var toastInappropriateInterest: String {
        tr("toastInappropriateInterest", fallback: "Inappropriate interest cannot be added")
    }

    // MARK: - Interest Discovery & Bento Box

    var orTypeYourOwn: String { tr("orTypeYourOwn", fallback: "Or type your own…") }
    var exploreCategoriesTitle: String { tr("exploreCategoriesTitle", fallback: "Explore") }
    var tapToExplore: String { tr("tapToExplore", fallback: "Tap to explore") }
    var bentoAllCategories: String { tr("bentoAllCategories", fallback: "All Topics") }
    var bentoAiSynthesizing: String { tr("bentoAiSynthesizing", fallback: "AI is synthesizing…") }
    var bentoShuffle: String { tr("bentoShuffle", fallback: "Spin") }
    var bentoAdded: String { tr("bentoAdded", fallback: "Added") }
    var bentoDeepDive: String { tr("bentoDeepDive", fallback: "Deep dive") }
    var bentoTapToSelect: String { tr("bentoTapToSelect", fallback: "Tap to pick") }
    var bentoCollapse: String { tr("bentoCollapse", fallback: "Collapse") }
    var bentoExpand: String { tr("bentoExpand", fallback: "Explore") }
    var collectionsTitle: String { tr("collectionsTitle", fallback: "Collections") }
    var bentoReturnToLastPost: String {
        tr("bentoReturnToLastPost", fallback: "Swipe up or tap to return to last post")
    }
    var bentoCategoriesTitle: String { tr("bentoCategoriesTitle", fallback: "Categories") }
    var bentoCategoriesSubtitle: String {
        tr("bentoCategoriesSubtitle", fallback: "Select a category and tap a subtopic to craft a new post")
    }
    var bentoRefreshing: String { tr("bentoRefreshing", fallback: "Refreshing…") }
    var bentoRefresh: String { tr("bentoRefresh", fallback: "Refresh") }

    func bentoCooldownHint(seconds: Int) -> String {
        tr("bentoCooldownHint", fallback: "Once reading cooldown ({seconds}s) ends, tap any subtopic to generate a post.", ("seconds", "\(seconds)"))
    }

    var bentoSubtopicHint: String {
        tr("bentoSubtopicHint", fallback: "Tap any subtopic below to generate a dedicated post")
    }
    var bentoCooking: String { tr("bentoCooking", fallback: "Cooking…") }

    func shortSeconds(_ seconds: Int) -> String {
        tr("shortSeconds", fallback: "{seconds}s", ("seconds", "\(seconds)"))
    }

    func bentoScrollCategoriesHint(count: Int) -> String {
        tr("bentoScrollCategoriesHint", fallback: "Scroll down to browse all {count} categories", ("count", "\(count)"))
    }

    var bentoScrollSubtopicsHint: String {
        tr("bentoScrollSubtopicsHint", fallback: "Scroll down for more subtopics")
    }
    var bentoManualPlaceholder: String {
        tr("bentoManualPlaceholder", fallback: "Type a custom topic or add taste…")
    }
    var bentoCreateButton: String { tr("bentoCreateButton", fallback: "Create") }

    // MARK: - Appearance

    var appearanceLabel: String { tr("appearanceLabel", fallback: "Appearance") }

    func appearanceName(_ mode: AppAppearance) -> String {
        switch mode {
        case .system: tr("appearanceSystem", fallback: "System")
        case .light: tr("appearanceLight", fallback: "Light")
        case .dark: tr("appearanceDark", fallback: "Dark")
        }
    }

    // MARK: - Letterboxd

    var letterboxdMode: String { tr("letterboxdMode", fallback: "Letterboxd Mode") }
    var updateLetterboxdButton: String {
        tr("updateLetterboxdButton", fallback: "Update Letterboxd Username")
    }
    var letterboxdUsernamePromptTitle: String {
        tr("letterboxdUsernamePromptTitle", fallback: "Letterboxd Username")
    }
    var letterboxdUsernamePromptMessage: String {
        tr("letterboxdUsernamePromptMessage", fallback: "Enter your Letterboxd username to personalize posts with your recently watched films.")
    }
    var letterboxdUsernamePlaceholder: String { tr("letterboxdUsernamePlaceholder", fallback: "username") }
    var letterboxdActive: String { tr("letterboxdActive", fallback: "Letterboxd active") }
    var letterboxdFetchError: String { tr("letterboxdFetchError", fallback: "Could not load Letterboxd data.") }
    var letterboxdRecentFilms: String { tr("letterboxdRecentFilms", fallback: "Recent Diary") }
    var letterboxdConnectDiary: String { tr("letterboxdConnectDiary", fallback: "Connect Diary") }
    var letterboxdChangeUsername: String { tr("letterboxdChangeUsername", fallback: "Change Username") }
    var letterboxdConnectAction: String { tr("letterboxdConnectAction", fallback: "Connect Letterboxd") }
    var disconnectAction: String { tr("disconnectAction", fallback: "Disconnect") }

    // MARK: - Account Deletion, UGC Moderation & Legal

    var deleteAccount: String { tr("deleteAccount", fallback: "Delete account") }
    var confirmDeleteAccountTitle: String {
        tr("confirmDeleteAccountTitle", fallback: "Delete Account Permanently?")
    }
    var confirmDeleteAccountMessage: String {
        tr("confirmDeleteAccountMessage", fallback: "Your profile, shared posts, comments, and account data will be permanently deleted. This action cannot be undone.")
    }
    var deleteAccountConfirmButton: String {
        tr("deleteAccountConfirmButton", fallback: "Delete Permanently")
    }
    var accountDeleteRequiresReauth: String {
        tr("accountDeleteRequiresReauth", fallback: "For your security, please sign out and sign in again to complete account deletion.")
    }
    var moderationErrorInappropriateText: String {
        tr("moderationErrorInappropriateText", fallback: "This text contains inappropriate language and cannot be used.")
    }
    var reportPost: String { tr("reportPost", fallback: "Report Post") }
    var reportUser: String { tr("reportUser", fallback: "Report User") }
    var reportComment: String { tr("reportComment", fallback: "Report Comment") }
    var reportSubmittedToast: String {
        tr("reportSubmittedToast", fallback: "Report received. Our team will review it within 24 hours.")
    }
    var blockUser: String { tr("blockUser", fallback: "Block User") }
    var unblockUser: String { tr("unblockUser", fallback: "Unblock User") }
    var confirmBlockUserTitle: String { tr("confirmBlockUserTitle", fallback: "Block User?") }
    var confirmBlockUserMessage: String {
        tr("confirmBlockUserMessage", fallback: "They will no longer be able to reach you, and their posts and comments will be removed from your feed immediately.")
    }
    var userBlockedToast: String { tr("userBlockedToast", fallback: "User blocked") }
    var profileSupportAndLegal: String { tr("profileSupportAndLegal", fallback: "Support & Legal") }
    var contactSupport: String { tr("contactSupport", fallback: "Contact Support") }
    var privacyPolicy: String { tr("privacyPolicy", fallback: "Privacy Policy") }
    var termsOfUse: String { tr("termsOfUse", fallback: "Terms of Use (EULA)") }
    var blockedUsersTitle: String { tr("blockedUsersTitle", fallback: "Blocked Users") }
    var noBlockedUsers: String { tr("noBlockedUsers", fallback: "No blocked users") }

    // MARK: - Error Handling & Status

    var tryAgain: String { tr("tryAgain", fallback: "Try Again") }
    var signInAgain: String { tr("signInAgain", fallback: "Sign In") }
    var editUsername: String { tr("editUsername", fallback: "Edit Username") }
    var dismissLabel: String { tr("dismissLabel", fallback: "Dismiss") }
    var errorOfflineMessage: String {
        tr("errorOfflineMessage", fallback: "You're offline. You can still read saved posts.")
    }
    var errorTimeoutTitle: String { tr("errorTimeoutTitle", fallback: "Request Timed Out") }
    var errorTimeoutMessage: String {
        tr("errorTimeoutMessage", fallback: "The kitchen took too long to respond. Please try again.")
    }
    var errorServerUnreachableTitle: String { tr("errorServerUnreachableTitle", fallback: "Couldn't Connect") }
    var errorServerUnreachableMessage: String {
        tr("errorServerUnreachableMessage", fallback: "Could not reach omakase servers. Check your internet connection and try again.")
    }
    var errorUnauthorizedTitle: String { tr("errorUnauthorizedTitle", fallback: "Session Expired") }
    var errorUnauthorizedMessage: String {
        tr("errorUnauthorizedMessage", fallback: "Please sign in again to continue.")
    }

    func errorRateLimitedMessage(seconds: Int?) -> String {
        if let seconds, seconds > 0 {
            return tr("errorRateLimitedSeconds", fallback: "Let's slow down a little. Try again in {seconds} seconds.", ("seconds", "\(seconds)"))
        }
        return tr("errorRateLimitedMoment", fallback: "Let's slow down a little. Try again in a moment.")
    }

    var errorQuotaExceededTitle: String { tr("errorQuotaExceededTitle", fallback: "Today's Menu Is Complete") }
    var errorQuotaExceededMessage: String {
        tr("errorQuotaExceededMessage", fallback: "You've reached today's reading limit. New posts will be ready tomorrow.")
    }
    var errorContentBlockedMessage: String {
        tr("errorContentBlockedMessage", fallback: "We can't prepare a post on this topic. Try another one.")
    }
    var errorGenerationFailedTitle: String { tr("errorGenerationFailedTitle", fallback: "Couldn't Prepare Post") }
    var errorGenerationFailedMessage: String {
        tr("errorGenerationFailedMessage", fallback: "The chef couldn't finish this one. It didn't count toward your limit.")
    }
    var errorServiceUnavailableTitle: String {
        tr("errorServiceUnavailableTitle", fallback: "Kitchen on a Short Break")
    }
    var errorServiceUnavailableMessage: String {
        tr("errorServiceUnavailableMessage", fallback: "The kitchen is taking a short break. Try again in a few minutes.")
    }
    var errorLetterboxdMissingUsername: String {
        tr("errorLetterboxdMissingUsername", fallback: "Enter your Letterboxd username to load recent films.")
    }
    var errorLetterboxdNotFoundMessage: String {
        tr("errorLetterboxdNotFoundMessage", fallback: "No public films found for this Letterboxd username.")
    }
    var errorLetterboxdPrivateMessage: String {
        tr("errorLetterboxdPrivateMessage", fallback: "This Letterboxd diary is private. Update your privacy settings or username.")
    }
    var errorBillingSyncFailedMessage: String {
        tr("errorBillingSyncFailedMessage", fallback: "Couldn't verify your subscription yet. Try Restore Purchases.")
    }
    var authErrorNetwork: String {
        tr("authErrorNetwork", fallback: "You appear to be offline. Check your connection and try again.")
    }
    var authErrorTooManyRequests: String {
        tr("authErrorTooManyRequests", fallback: "Too many attempts. Wait a moment and try again.")
    }
    var authErrorUserDisabled: String {
        tr("authErrorUserDisabled", fallback: "This account is currently unavailable. Please contact support.")
    }
    var authErrorProviderFailed: String {
        tr("authErrorProviderFailed", fallback: "Sign-in couldn't be completed. Please try again.")
    }
    var authErrorSignOutFailed: String {
        tr("authErrorSignOutFailed", fallback: "Could not sign out right now. Please try again.")
    }
    var errorShareFailed: String { tr("errorShareFailed", fallback: "Couldn't share this post. Please try again.") }
    var errorUnshareFailed: String {
        tr("errorUnshareFailed", fallback: "Couldn't remove from community. Please try again.")
    }
    var errorCommentSendFailed: String {
        tr("errorCommentSendFailed", fallback: "Your comment wasn't sent. Your text is saved so you can try again.")
    }
    var errorCommentLoadFailed: String { tr("errorCommentLoadFailed", fallback: "Couldn't load comments right now.") }
    var errorCommentDeleteFailed: String {
        tr("errorCommentDeleteFailed", fallback: "Couldn't delete the comment. Please try again.")
    }
    var errorReportFailed: String { tr("errorReportFailed", fallback: "Your report wasn't sent. Please try again.") }
    var errorBlockFailed: String { tr("errorBlockFailed", fallback: "Couldn't block this user. Please try again.") }
    var errorUnblockFailed: String { tr("errorUnblockFailed", fallback: "Couldn't unblock this user. Please try again.") }
    var errorFollowFailed: String { tr("errorFollowFailed", fallback: "Couldn't follow right now. Try again.") }
    var errorUnfollowFailed: String { tr("errorUnfollowFailed", fallback: "Couldn't unfollow right now. Try again.") }
    var errorReactionFailed: String { tr("errorReactionFailed", fallback: "Couldn't update reaction. Please try again.") }
    var errorTimelineLoadFailed: String { tr("errorTimelineLoadFailed", fallback: "Couldn't load the community feed.") }
    var errorUserSearchFailed: String {
        tr("errorUserSearchFailed", fallback: "Couldn't search users right now. Please try again.")
    }
    var errorProfileLoadFailed: String { tr("errorProfileLoadFailed", fallback: "Couldn't load this profile right now.") }
    var errorPostDeleteFailed: String {
        tr("errorPostDeleteFailed", fallback: "Couldn't delete this post. Please try again.")
    }
    var errorUnknownMessage: String {
        tr("errorUnknownMessage", fallback: "An unexpected situation occurred. Please try again.")
    }

    // MARK: - Monetization, Omakase Pro & Daily Limit

    var proTitle: String { "omakase Pro" }
    var proHeadline: String { tr("proHeadline", fallback: "Unlimited posts, zero noise.") }
    var proSubtitle: String {
        tr("proSubtitle", fallback: "3 free posts a day is just a taste. Unlock unlimited posts, primary-source Deep Dives, and full Letterboxd synthesis.")
    }
    var proFeatureUnlimitedPlates: String {
        tr("proFeatureUnlimitedPlates", fallback: "Unlimited daily posts & Letterboxd behind-the-scenes")
    }
    var proEyebrowPlateLimit: String { tr("proEyebrowPlateLimit", fallback: "DAILY 3/3 POSTS REACHED") }
    var proEyebrowDeepDiveLimit: String { tr("proEyebrowDeepDiveLimit", fallback: "DEEP DIVE LIMIT") }
    var proEyebrowLetterboxdLimit: String { tr("proEyebrowLetterboxdLimit", fallback: "DAILY LETTERBOXD LIMIT") }
    var proHeadlinePlateLimit: String { tr("proHeadlinePlateLimit", fallback: "Keep your reading flow.") }
    var proHeadlineDeepDiveLimit: String { tr("proHeadlineDeepDiveLimit", fallback: "Go deeper on every post.") }
    var proHeadlineLetterboxdLimit: String {
        tr("proHeadlineLetterboxdLimit", fallback: "Unlock unlimited Letterboxd posts.")
    }
    var proCompareFreeHeader: String { tr("proCompareFreeHeader", fallback: "Free") }
    var proCompareProHeader: String { tr("proCompareProHeader", fallback: "Pro") }
    var proComparePostsLabel: String { tr("proComparePostsLabel", fallback: "Daily posts") }
    var proComparePostsFree: String { tr("proComparePostsFree", fallback: "3 / day") }
    var proCompareDeepDiveLabel: String { tr("proCompareDeepDiveLabel", fallback: "Deep Dive & sources") }
    var proCompareDeepDiveFree: String { tr("proCompareDeepDiveFree", fallback: "1 / day") }
    var proCompareLetterboxdLabel: String { tr("proCompareLetterboxdLabel", fallback: "Letterboxd posts") }
    var proCompareLetterboxdFree: String { tr("proCompareLetterboxdFree", fallback: "1 / day") }
    var proCompareSubtopicsLabel: String { tr("proCompareSubtopicsLabel", fallback: "Subtopics & Letterboxd") }
    var proCompareSubtopicsFree: String { tr("proCompareSubtopicsFree", fallback: "Limited") }
    var proCompareUnlimited: String { tr("proCompareUnlimited", fallback: "Unlimited") }
    var proCompareFull: String { tr("proCompareFull", fallback: "Full") }
    func proSavePercentBadge(_ percent: Int) -> String {
        tr("proSavePercentBadge", fallback: "SAVE {percent}%", ("percent", "\(percent)"))
    }
    func proFreeTrialDaysLabel(_ days: Int) -> String {
        tr("proFreeTrialDaysLabel", fallback: "{days} days free", ("days", "\(days)"))
    }
    func proPerMonthEquivalent(_ price: String) -> String {
        tr("proPerMonthEquivalent", fallback: "{price}/mo", ("price", price))
    }
    var proBilledMonthly: String { tr("proBilledMonthly", fallback: "Billed monthly · Cancel anytime") }
    var proTrialReassurance: String { tr("proTrialReassurance", fallback: "No charge today · Cancel anytime") }
    var proMonthlyReassurance: String { tr("proMonthlyReassurance", fallback: "Instant access · Cancel anytime") }
    func proYearlyDisclosure(_ price: String) -> String {
        tr("proYearlyDisclosure", fallback: "7 days free, then {price}/year. Auto-renews unless canceled at least 24 hours before the period ends.", ("price", price))
    }
    func proMonthlyDisclosure(_ price: String) -> String {
        tr("proMonthlyDisclosure", fallback: "Charged {price}/month at confirmation. Auto-renews unless canceled at least 24 hours before the period ends.", ("price", price))
    }
    var actionReport: String { tr("actionReport", fallback: "Report") }
    var actionReported: String { tr("actionReported", fallback: "Reported") }
    var reportAIPostTitle: String { tr("reportAIPostTitle", fallback: "Report Content") }
    var reportAIPostMessage: String { tr("reportAIPostMessage", fallback: "What's wrong with this AI-generated post?") }
    var reportReasonInaccurate: String { tr("reportReasonInaccurate", fallback: "Inaccurate info or source") }
    var reportReasonInappropriate: String { tr("reportReasonInappropriate", fallback: "Inappropriate or offensive content") }
    var reportReasonOther: String { tr("reportReasonOther", fallback: "Other") }
    var introSkip: String { tr("introSkip", fallback: "Skip") }
    var introNext: String { tr("introNext", fallback: "Continue") }
    var introPickInterestsCTA: String { tr("introPickInterestsCTA", fallback: "Choose Your Topics") }
    var introSlide1Eyebrow: String { tr("introSlide1Eyebrow", fallback: "NOISE-FREE FEED") }
    var introSlide1Title: String { tr("introSlide1Title", fallback: "Stop scrolling, actually read.") }
    var introSlide1Body: String { tr("introSlide1Body", fallback: "Sharp 60-word posts across film, history, science, and architecture—each backed by a real primary source.") }
    var introSlide1SampleTag: String { tr("introSlide1SampleTag", fallback: "HISTORY · 60 WORDS") }
    var introSlide1SampleText: String { tr("introSlide1SampleText", fallback: "When jazz was banned in 1950s Leningrad, underground bootleggers etched Miles Davis records directly onto discarded hospital X-ray films.") }
    var introSlide1SampleSource: String { tr("introSlide1SampleSource", fallback: "Source: Stephen Coates, X-Ray Audio (2015)") }
    var introSlide2Eyebrow: String { tr("introSlide2Eyebrow", fallback: "DEEP DIVE") }
    var introSlide2Title: String { tr("introSlide2Title", fallback: "Mindful pace, deeper stories.") }
    var introSlide2Body: String { tr("introSlide2Body", fallback: "A brief reading pause sits between every post. Tap once whenever curiosity strikes to open a 200-word Deep Dive.") }
    var introSlide2Metric1: String { tr("introSlide2Metric1", fallback: "15–25s mindful reading pause") }
    var introSlide2Metric2: String { tr("introSlide2Metric2", fallback: "One-tap 200-word Deep Dive") }
    var introSlide3Eyebrow: String { tr("introSlide3Eyebrow", fallback: "COMMUNITY & LETTERBOXD") }
    var introSlide3Title: String { tr("introSlide3Title", fallback: "Share, save, connect your diary.") }
    var introSlide3Body: String { tr("introSlide3Body", fallback: "Share favorite posts to the community, save offline, or link your Letterboxd diary for behind-the-scenes stories on films you watch.") }
    var introSlide3Pill1: String { tr("introSlide3Pill1", fallback: "Community Feed") }
    var introSlide3Pill2: String { tr("introSlide3Pill2", fallback: "Offline Bookmarks") }
    var introSlide3Pill3: String { tr("introSlide3Pill3", fallback: "Letterboxd") }
    var settingsTitle: String { tr("settingsTitle", fallback: "Settings") }
    var editProfileTitle: String { tr("editProfileTitle", fallback: "Edit Profile") }
    var profileSetupTitle: String { tr("profileSetupTitle", fallback: "Set Up Your Profile") }
    var profileSetupSubtitle: String { tr("profileSetupSubtitle", fallback: "Choose your display name and a unique username. No need to use your last name.") }
    var profileDisplayNameLabel: String { tr("profileDisplayNameLabel", fallback: "Display Name") }
    var profileDisplayNameHint: String { tr("profileDisplayNameHint", fallback: "You can change this anytime. Its initials appear on your avatar.") }
    var profileUsernameLabel: String { tr("profileUsernameLabel", fallback: "Username") }
    var profileUsernameCooldownNote: String { tr("profileUsernameCooldownNote", fallback: "You can change your username once every 14 days.") }
    func profileUsernameLockedDays(_ days: Int) -> String {
        tr("profileUsernameLockedDays", fallback: "You can change your username again in {days} days.", ("days", "\(days)"))
    }
    var profileSavedToast: String { tr("profileSavedToast", fallback: "Profile updated.") }
    var profileSetupContinue: String { tr("profileSetupContinue", fallback: "Continue") }
    var authUsernameInvalid: String { tr("authUsernameInvalid", fallback: "Username must be at least 3 characters (a-z, 0-9, _ or .).") }
    var proFeatureUnlimitedDeepDive: String {
        tr("proFeatureUnlimitedDeepDive", fallback: "Unlimited Deep Dives with verified primary sources")
    }
    var proFeatureUnlimitedSubtopics: String {
        tr("proFeatureUnlimitedSubtopics", fallback: "Unlimited subtopic refreshes")
    }
    var proFeatureProBadge: String {
        tr("proFeatureProBadge", fallback: "Pro badge on your Community profile")
    }
    var proBestValueBadge: String { tr("proBestValueBadge", fallback: "Best Value") }
    var proFreeTrialBadge: String { tr("proFreeTrialBadge", fallback: "7-day free trial · Save 37%") }
    var proPlanYearly: String { tr("proPlanYearly", fallback: "Yearly") }
    var proPlanMonthly: String { tr("proPlanMonthly", fallback: "Monthly") }
    var proPerYearSuffix: String { tr("proPerYearSuffix", fallback: "/ year") }
    var proPerMonthSuffix: String { tr("proPerMonthSuffix", fallback: "/ month") }
    var proStartTrialCTA: String { tr("proStartTrialCTA", fallback: "Start 7-Day Free Trial") }
    var proSubscribeCTA: String { tr("proSubscribeCTA", fallback: "Continue with omakase Pro") }
    var proRestorePurchases: String { tr("proRestorePurchases", fallback: "Restore Purchases") }
    var proRestoreSuccess: String {
        tr("proRestoreSuccess", fallback: "Your omakase Pro subscription is restored.")
    }
    var proRestoreEmpty: String {
        tr("proRestoreEmpty", fallback: "No active subscription was found to restore.")
    }
    var proPurchaseSuccess: String { tr("proPurchaseSuccess", fallback: "Welcome to omakase Pro.") }
    var proPaymentPending: String {
        tr("proPaymentPending", fallback: "Your purchase is pending approval and will activate once confirmed.")
    }
    var proSubscriptionDisclosure: String {
        tr("proSubscriptionDisclosure", fallback: "Payment is charged to your Apple ID account at confirmation (or after the 7-day trial ends). Subscription renews automatically unless canceled at least 24 hours before the end of the current period.")
    }
    var proManageSubscription: String { tr("proManageSubscription", fallback: "Manage Subscription") }
    var proActiveStatus: String { tr("proActiveStatus", fallback: "Active") }
    var proTrialStatus: String { tr("proTrialStatus", fallback: "Free Trial") }
    var proBillingIssueStatus: String {
        tr("proBillingIssueStatus", fallback: "Billing issue — update payment method")
    }

    func proRenewsOn(_ dateText: String) -> String {
        tr("proRenewsOn", fallback: "Renews on {date}", ("date", dateText))
    }

    func proExpiresOn(_ dateText: String) -> String {
        tr("proExpiresOn", fallback: "Expires on {date}", ("date", dateText))
    }

    var proProductsUnavailable: String {
        tr("proProductsUnavailable", fallback: "Subscription options are loading from the App Store. Try again shortly.")
    }
    var proShareForDeepDiveCTA: String {
        tr("proShareForDeepDiveCTA", fallback: "Tip: Share any post today to unlock +1 bonus Deep Dive for free.")
    }
    var limitCardTitle: String { tr("limitCardTitle", fallback: "Today's Menu Is Complete") }
    var limitCardSubtitle: String {
        tr("limitCardSubtitle", fallback: "You've read all 3 free posts for today. Unlock omakase Pro for unlimited reading or wait for tomorrow's menu.")
    }

    func limitCardNextMenuIn(_ countdown: String) -> String {
        tr("limitCardNextMenuIn", fallback: "Next menu in {countdown}", ("countdown", countdown))
    }

    var limitCardUpgradeCTA: String { tr("limitCardUpgradeCTA", fallback: "Continue with omakase Pro") }
    var limitCardRemindCTA: String { tr("limitCardRemindCTA", fallback: "Remind Me Tomorrow") }
    var limitCardRemindPendingToast: String {
        tr("limitCardRemindPendingToast", fallback: "Daily menu reminders are coming in the next step.")
    }
    var limitCardBackToPlates: String { tr("limitCardBackToPlates", fallback: "Re-read today's posts") }
    var toastShareBonusGranted: String {
        tr("toastShareBonusGranted", fallback: "+1 bonus Deep Dive unlocked for today!")
    }
    var profileMembershipSection: String { tr("profileMembershipSection", fallback: "Membership") }
    var profileUpgradeToPro: String { tr("profileUpgradeToPro", fallback: "Upgrade to omakase Pro") }

    func profileDailyQuotaSummary(
        platesRemaining: Int,
        platesLimit: Int,
        deepDivesRemaining: Int,
        deepDivesLimit: Int
    ) -> String {
        tr(
            "profileDailyQuotaSummary",
            fallback: "Today: {platesRemaining}/{platesLimit} posts · {deepDivesRemaining}/{deepDivesLimit} deep dives left",
            ("platesRemaining", "\(platesRemaining)"),
            ("platesLimit", "\(platesLimit)"),
            ("deepDivesRemaining", "\(deepDivesRemaining)"),
            ("deepDivesLimit", "\(deepDivesLimit)")
        )
    }

    // MARK: - Notifications

    var notificationsSectionTitle: String { tr("notificationsSectionTitle", fallback: "Notifications") }
    var notificationsDailyMenuToggle: String {
        tr("notificationsDailyMenuToggle", fallback: "Daily Menu Reminder")
    }
    var notificationsReminderTime: String { tr("notificationsReminderTime", fallback: "Reminder Time") }
    var notificationsCommentsToggle: String {
        tr("notificationsCommentsToggle", fallback: "Comment Notifications")
    }
    var notificationsDigestToggle: String {
        tr("notificationsDigestToggle", fallback: "Daily Follower & Reaction Digest")
    }
    var notificationsDeniedBanner: String {
        tr("notificationsDeniedBanner", fallback: "Notifications are off — Open Settings")
    }
    var notificationsProvisionalHint: String {
        tr("notificationsProvisionalHint", fallback: "Notifications are currently delivered quietly to Notification Center.")
    }
    var notificationsQuietHoursFooter: String {
        tr(
            "notificationsQuietHoursFooter",
            fallback: "Unseen story headlines arrive 3× daily (morning, 15:30 break & 21:00 prime time). Social updates pause between 22:00 and 08:00."
        )
    }
    var notificationsDeniedAlertTitle: String {
        tr("notificationsDeniedAlertTitle", fallback: "Notifications Disabled")
    }
    var notificationsDeniedAlertMessage: String {
        tr("notificationsDeniedAlertMessage", fallback: "Allow notifications in iOS Settings so omakase can let you know when tomorrow's menu is ready.")
    }
    var openSettingsCTA: String { tr("openSettingsCTA", fallback: "Open Settings") }

    func limitCardRemindScheduledToast(timeText: String) -> String {
        tr("limitCardRemindScheduledToast", fallback: "Reminder set for {time}.", ("time", timeText))
    }

    var notificationsNotGrantedToast: String {
        tr("notificationsNotGrantedToast", fallback: "Notifications weren't enabled. You can turn them on anytime in Profile.")
    }
    var commentNotificationPromptTitle: String {
        tr("commentNotificationPromptTitle", fallback: "Get notified about new comments on your posts")
    }
    var turnOnCTA: String { tr("turnOnCTA", fallback: "Turn On") }
    var dailyMenuNotificationTitle: String { tr("dailyMenuNotificationTitle", fallback: "Today's Menu") }

    func dailyMenuNotificationBody(interests: [String]) -> String {
        if interests.count >= 2 {
            return tr(
                "dailyMenuBodyTwo",
                fallback: "{first} and {second} are on the menu today.",
                ("first", interests[0]),
                ("second", interests[1])
            )
        } else if let first = interests.first, !first.isEmpty {
            return tr("dailyMenuBodyOne", fallback: "{first} is featured on today's menu.", ("first", first))
        } else {
            return tr("dailyMenuBodyEmpty", fallback: "Fresh posts curated for your taste are ready today.")
        }
    }

    var hiddenPreviewDailyMenu: String { tr("hiddenPreviewDailyMenu", fallback: "Today's Menu") }
    var hiddenPreviewComment: String { tr("hiddenPreviewComment", fallback: "New comment") }
    var hiddenPreviewDigest: String { tr("hiddenPreviewDigest", fallback: "Community summary") }

    // MARK: - Immersive Daily Notification Archetypes

    var dailyMenuDefaultTopic: String { tr("dailyMenuDefaultTopic", fallback: "Culture") }
    var dailyMenuDefaultSecondTopic: String { tr("dailyMenuDefaultSecondTopic", fallback: "Philosophy") }

    func dailyMenuDeepDiveTitle(title: String) -> String {
        tr("dailyMenuDeepDiveTitle", fallback: "“{title}”", ("title", title))
    }

    func dailyMenuDeepDiveBody(platesCount: Int?) -> String {
        guard let count = platesCount, count > 0 else {
            return tr(
                "dailyMenuDeepDiveBodyNoCount",
                fallback: "The deeper story behind this post is still on the counter. Fresh chef curation and Deep Dive await."
            )
        }
        if count == 1 {
            return tr(
                "dailyMenuDeepDiveBodyOne",
                fallback: "The deeper story behind this post is still on the counter. Today's 1 fresh post and Deep Dive await."
            )
        }
        return tr(
            "dailyMenuDeepDiveBody",
            fallback: "The deeper story behind this post is still on the counter. Today's {count} fresh posts and Deep Dive await.",
            ("count", "\(count)")
        )
    }

    var dailyMenuThreadTitle: String {
        tr("dailyMenuThreadTitle", fallback: "A New Thread on the Chef's Counter")
    }

    func dailyMenuThreadBody(title: String, topic: String) -> String {
        tr(
            "dailyMenuThreadBody",
            fallback: "After “{title}”, today's menu uncovers an unexpected story on {topic}.",
            ("title", title),
            ("topic", topic)
        )
    }

    func dailyMenuPairingTitle(first: String, second: String) -> String {
        tr(
            "dailyMenuPairingTitle",
            fallback: "Today's Tasting Pairing: {first} × {second}",
            ("first", first),
            ("second", second)
        )
    }

    func dailyMenuPairingWithPostBody(title: String, second: String, platesCount: Int?) -> String {
        guard let count = platesCount, count > 0 else {
            return tr(
                "dailyMenuPairingWithPostBodyNoCount",
                fallback: "From “{title}” into the world of {second}: a fresh chef curation is ready to serve.",
                ("title", title),
                ("second", second)
            )
        }
        if count == 1 {
            return tr(
                "dailyMenuPairingWithPostBodyOne",
                fallback: "From “{title}” into the world of {second}: 1 fresh post is ready to serve.",
                ("title", title),
                ("second", second)
            )
        }
        return tr(
            "dailyMenuPairingWithPostBody",
            fallback: "From “{title}” into the world of {second}: {count} fresh posts are ready to serve.",
            ("title", title),
            ("second", second),
            ("count", "\(count)")
        )
    }

    var dailyMenuPairingEditorialBody: String {
        tr(
            "dailyMenuPairingEditorialBody",
            fallback: "Two distinct disciplines meet in a sharp 60-word micro-story today."
        )
    }

    func dailyMenuEchoTitle(topic: String) -> String {
        tr("dailyMenuEchoTitle", fallback: "A 60-Word Pause: {topic}", ("topic", topic))
    }

    func dailyMenuEchoBody(title: String, topic: String) -> String {
        tr(
            "dailyMenuEchoBody",
            fallback: "If “{title}” sparked your curiosity, don't miss the chef's {topic} curation today.",
            ("title", title),
            ("topic", topic)
        )
    }

    func dailyMenuRitualTitle(platesCount: Int?) -> String {
        guard let count = platesCount, count > 0 else {
            return tr("dailyMenuRitualTitleNoCount", fallback: "Algorithm-Free Chef's Pick Is Ready")
        }
        if count == 1 {
            return tr("dailyMenuRitualTitleOne", fallback: "1 Algorithm-Free Post Is Ready")
        }
        return tr("dailyMenuRitualTitle", fallback: "{count} Algorithm-Free Posts Are Ready", ("count", "\(count)"))
    }

    func dailyMenuRitualWithPostBody(title: String, topic: String) -> String {
        tr(
            "dailyMenuRitualWithPostBody",
            fallback: "Last on your counter: “{title}”. Today opens a fresh post around {topic}.",
            ("title", title),
            ("topic", topic)
        )
    }

    func dailyMenuRitualEditorialBody(topic: String, platesCount: Int?) -> String {
        guard let count = platesCount, count > 0 else {
            return tr(
                "dailyMenuRitualEditorialBodyNoCount",
                fallback: "Step away from the algorithmic noise. Today's counter serves a fresh curation on {topic}.",
                ("topic", topic)
            )
        }
        if count == 1 {
            return tr(
                "dailyMenuRitualEditorialBodyOne",
                fallback: "Step away from the algorithmic noise. Today's counter serves 1 fresh post on {topic}.",
                ("topic", topic)
            )
        }
        return tr(
            "dailyMenuRitualEditorialBody",
            fallback: "Step away from the algorithmic noise. Today's counter serves {count} fresh posts on {topic}.",
            ("topic", topic),
            ("count", "\(count)")
        )
    }

    // MARK: - Unseen Post Teaser Notification Variants (Tap-to-Generate)

    func dailyUnseenSpotlightTitle(category: String, title: String) -> String {
        tr(
            "dailyUnseenSpotlightTitle",
            fallback: "{category} · “{title}”",
            ("category", category),
            ("title", title)
        )
    }

    var dailyUnseenSpotlightBody: String {
        tr(
            "dailyUnseenSpotlightBody",
            fallback: "You haven't opened this story yet. Tap and the chef will write it for you in 60 words."
        )
    }

    var dailyUnseenCounterTitle: String {
        tr("dailyUnseenCounterTitle", fallback: "A Fresh Headline on the Chef's Counter")
    }

    func dailyUnseenCounterBody(title: String, category: String) -> String {
        tr(
            "dailyUnseenCounterBody",
            fallback: "“{title}” ({category}) is on the counter today. Tap to have this post written live.",
            ("title", title),
            ("category", category)
        )
    }

    func dailyUnseenBackstageTitle(title: String) -> String {
        tr("dailyUnseenBackstageTitle", fallback: "“{title}”", ("title", title))
    }

    func dailyUnseenBackstageBody(category: String) -> String {
        tr(
            "dailyUnseenBackstageBody",
            fallback: "An unseen backstage story from {category}. Tap to generate it fresh off the counter.",
            ("category", category)
        )
    }

    func dailyUnseenDiscoveryTitle(category: String) -> String {
        tr("dailyUnseenDiscoveryTitle", fallback: "A 60-Word Discovery: {category}", ("category", category))
    }

    func dailyUnseenDiscoveryBody(title: String) -> String {
        tr(
            "dailyUnseenDiscoveryBody",
            fallback: "Today's unopened post: “{title}”. The chef starts writing the moment you tap.",
            ("title", title)
        )
    }

    func dailyUnseenRitualTitle(category: String) -> String {
        tr("dailyUnseenRitualTitle", fallback: "Algorithm-Free Pick · {category}", ("category", category))
    }

    func dailyUnseenRitualBody(title: String) -> String {
        tr(
            "dailyUnseenRitualBody",
            fallback: "“{title}” — let the chef serve this unseen story right now. Tap to open.",
            ("title", title)
        )
    }

    // MARK: - Daily Plate Quota Stress Pill & Social Discover Mode

    func feedQuotaPlatesRemaining(remaining: Int, limit: Int) -> String {
        if remaining <= 0 {
            return tr("feedQuotaEmpty", fallback: "Limit · 0/{limit}", ("limit", "\(limit)"))
        } else if remaining == 1 {
            return tr("feedQuotaLastOne", fallback: "Last 1 · 1/{limit}", ("limit", "\(limit)"))
        } else {
            return tr("feedQuotaRemaining", fallback: "{remaining}/{limit} Left", ("remaining", "\(remaining)"), ("limit", "\(limit)"))
        }
    }

    func feedQuotaAccessibilityLabel(remaining: Int, limit: Int) -> String {
        tr(
            "feedQuotaAccessibilityLabel",
            fallback: "Daily free plates remaining: {remaining} of {limit}. Tap to upgrade to omakase Pro.",
            ("remaining", "\(remaining)"),
            ("limit", "\(limit)")
        )
    }

    var timelineModeDiscover: String { tr("timelineModeDiscover", fallback: "Discover") }
    var timelineModeFollowing: String { tr("timelineModeFollowing", fallback: "Following") }
    var discoverFeedSubheader: String {
        tr("discoverFeedSubheader", fallback: "Fresh plates shared by readers across the community.")
    }
    var followingEmptyHeadline: String {
        tr("followingEmptyHeadline", fallback: "No posts from people you follow yet")
    }
    var followingEmptyDetail: String {
        tr("followingEmptyDetail", fallback: "Switch to Discover to see random readers and follow tastes you like.")
    }
    var exploreDiscoverCTA: String { tr("exploreDiscoverCTA", fallback: "Explore Discover Feed") }
    var postSourceLabel: String { tr("postSourceLabel", fallback: "Source") }
    var searchSourceInBrowser: String { tr("searchSourceInBrowser", fallback: "Search in Browser") }

    // MARK: - In-App Feedback

    var feedbackRowLabel: String { tr("feedbackRowLabel", fallback: "Send Feedback") }
    var feedbackTitle: String { tr("feedbackTitle", fallback: "Send Feedback") }
    var feedbackSubtitle: String {
        tr("feedbackSubtitle", fallback: "Share a bug, idea, or content note directly with the maker.")
    }
    var feedbackCategoryLabel: String { tr("feedbackCategoryLabel", fallback: "Category") }
    var feedbackCategoryBug: String { tr("feedbackCategoryBug", fallback: "Bug") }
    var feedbackCategoryIdea: String { tr("feedbackCategoryIdea", fallback: "Idea") }
    var feedbackCategoryContent: String { tr("feedbackCategoryContent", fallback: "Content") }
    var feedbackCategoryOther: String { tr("feedbackCategoryOther", fallback: "Other") }
    var feedbackRatingLabel: String { tr("feedbackRatingLabel", fallback: "Experience (optional)") }
    var feedbackMessageLabel: String { tr("feedbackMessageLabel", fallback: "Your note") }
    var feedbackMessagePlaceholder: String {
        tr("feedbackMessagePlaceholder", fallback: "What feels great, what broke, or what would you love next?")
    }
    var feedbackMetaFootnote: String {
        tr("feedbackMetaFootnote", fallback: "App version, iOS version, and language are included automatically to help debug.")
    }
    var feedbackSubmitButton: String { tr("feedbackSubmitButton", fallback: "Send") }
    var feedbackSending: String { tr("feedbackSending", fallback: "Sending…") }
    var feedbackSentToast: String { tr("feedbackSentToast", fallback: "Thanks! Your feedback reached the chef.") }

    // MARK: - Export Studio

    var exportStudioTitle: String { tr("exportStudioTitle", fallback: "Export Post") }
    var exportRatioStory: String { tr("exportRatioStory", fallback: "Story") }
    var exportRatioPost: String { tr("exportRatioPost", fallback: "Post") }
    var exportRatioSquare: String { tr("exportRatioSquare", fallback: "Square") }
    var exportThemePaper: String { tr("exportThemePaper", fallback: "Paper") }
    var exportThemeInk: String { tr("exportThemeInk", fallback: "Ink") }
    var exportThemeEditorial: String { tr("exportThemeEditorial", fallback: "Editorial") }
    var exportThemeMidnight: String { tr("exportThemeMidnight", fallback: "Midnight") }
    var exportToggleSource: String { tr("exportToggleSource", fallback: "Source") }
    var exportToggleTags: String { tr("exportToggleTags", fallback: "Tags") }
    var exportToggleMotif: String { tr("exportToggleMotif", fallback: "Motif") }
    var exportActionInstagram: String { tr("exportActionInstagram", fallback: "Instagram") }
    var exportActionWhatsApp: String { tr("exportActionWhatsApp", fallback: "WhatsApp") }
    var exportActionX: String { tr("exportActionX", fallback: "X") }
    var exportActionSave: String { tr("exportActionSave", fallback: "Save") }
    var exportActionCopy: String { tr("exportActionCopy", fallback: "Copy") }
    var exportActionMore: String { tr("exportActionMore", fallback: "More") }
    var exportCopyLink: String { tr("exportCopyLink", fallback: "Copy") }
    var exportCopied: String { tr("exportCopied", fallback: "Copied") }
    var exportToastLinkCopied: String { tr("exportToastLinkCopied", fallback: "Link copied: getomakase.app") }
    var exportToastImageCopied: String { tr("exportToastImageCopied", fallback: "Card image copied") }
    var exportToastSavedToPhotos: String { tr("exportToastSavedToPhotos", fallback: "Saved to Photos") }
    var exportToastPhotoPermissionDenied: String {
        tr("exportToastPhotoPermissionDenied", fallback: "Allow Photos access in Settings to save")
    }
    var exportToastImageCopiedForApp: String {
        tr("exportToastImageCopiedForApp", fallback: "Card copied — paste it in your post!")
    }

    // MARK: - Chef's Pick (Frictionless Feed)

    var chefPickTitle: String { tr("chefPickTitle", fallback: "Leave it to the Chef") }
    var chefPickPullHint: String {
        tr("chefPickPullHint", fallback: "Keep scrolling down for a surprise post")
    }
    var chefPickReleaseHint: String {
        tr("chefPickReleaseHint", fallback: "Serving a surprise post…")
    }
    func chefPickCategoryHint(_ category: String) -> String {
        tr("chefPickCategoryHint", fallback: "Surprise me in {category}", ("category", category))
    }
    var chefPickButtonCTA: String { tr("chefPickButtonCTA", fallback: "Surprise") }

    // MARK: - Guest Tasting & Monthly Stats

    func guestTasteBadge(index: Int, total: Int) -> String {
        tr(
            "guestTasteBadge",
            fallback: "TODAY'S TASTE · {index}/{total}",
            ("index", "\(index)"),
            ("total", "\(total)")
        )
    }
    var guestTasteSignIn: String { tr("guestTasteSignIn", fallback: "Sign In") }
    var guestTasteNextCTA: String { tr("guestTasteNextCTA", fallback: "Next Taste") }
    var guestTasteStartCTA: String { tr("guestTasteStartCTA", fallback: "Continue to Your Daily Menu") }
    var guestTasteSkipToAuth: String { tr("guestTasteSkipToAuth", fallback: "Create Account or Sign In") }
    var guestTasteDeepDiveOpen: String { tr("guestTasteDeepDiveOpen", fallback: "Deep Dive") }
    var guestTasteDeepDiveHide: String { tr("guestTasteDeepDiveHide", fallback: "Hide Deep Dive") }
    var profileReadsThisMonth: String { tr("profileReadsThisMonth", fallback: "This Month") }
    var guestLimitTitle: String { tr("guestLimitTitle", fallback: "Your Tasting Menu Is Complete") }
    var guestLimitSubtitle: String {
        tr(
            "guestLimitSubtitle",
            fallback: "Create a free account to unlock 3 daily personalized posts across 12 cultural disciplines, Deep Dives, and Letterboxd."
        )
    }
    var guestLimitSignUpCTA: String { tr("guestLimitSignUpCTA", fallback: "Create Free Account") }
    var guestLimitBackToPosts: String { tr("guestLimitBackToPosts", fallback: "Re-read tasting posts") }
    var guestNextPlateReadyTitle: String { tr("guestNextPlateReadyTitle", fallback: "Ready for Your Second Plate") }
    var guestNextPlateButton: String { tr("guestNextPlateButton", fallback: "Serve Next Post") }
    func guestCooldownWaiting(seconds: Int) -> String {
        tr("guestCooldownWaiting", fallback: "Take a moment to digest · {seconds}s", ("seconds", "\(seconds)"))
    }
    var guestShareSignInToast: String {
        tr("guestShareSignInToast", fallback: "Sign in to share posts with the community.")
    }

    // MARK: - Pro Welcome (Post-Buy Celebration)

    var proWelcomeTitle: String { tr("proWelcomeTitle", fallback: "Welcome to the Chef's Table") }
    func proWelcomeSubtitleTrial(_ days: Int) -> String {
        tr(
            "proWelcomeSubtitleTrial",
            fallback: "Your {days}-day free trial is active. Every limit is lifted—read as deeply as curiosity takes you.",
            ("days", "\(days)")
        )
    }
    var proWelcomeSubtitlePaid: String {
        tr("proWelcomeSubtitlePaid", fallback: "Your omakase Pro membership is active. Every limit is lifted—read as deeply as curiosity takes you.")
    }
    var proWelcomeUnlockedHeader: String { tr("proWelcomeUnlockedHeader", fallback: "NOW UNLOCKED") }
    var proWelcomeStartCTA: String { tr("proWelcomeStartCTA", fallback: "Start Unlimited Reading") }
    var proWelcomeManageNote: String {
        tr("proWelcomeManageNote", fallback: "You can manage your plan anytime in Profile → Settings.")
    }
    var proWelcomeBadgeActive: String { tr("proWelcomeBadgeActive", fallback: "Active") }

    // MARK: - Intro Welcome Slide

    var introWelcomeTitle: String { tr("introWelcomeTitle", fallback: "Welcome to omakase.") }
    var introWelcomeSubtitle: String {
        tr("introWelcomeSubtitle", fallback: "A quiet, source-backed daily feed curated for your curiosity.")
    }

    // MARK: - Account Confirmation & Deletion Friction

    var confirmSignOutTitle: String { tr("confirmSignOutTitle", fallback: "Sign Out?") }
    var confirmSignOutMessage: String {
        tr("confirmSignOutMessage", fallback: "You can sign back in anytime. Your profile and shared posts stay safe.")
    }
    var deleteAccountSheetTitle: String {
        tr("deleteAccountSheetTitle", fallback: "Delete Your Account?")
    }
    var deleteAccountSheetSubtitle: String {
        tr("deleteAccountSheetSubtitle", fallback: "This action is permanent and cannot be undone.")
    }
    var deleteAccountImpactProfile: String {
        tr("deleteAccountImpactProfile", fallback: "Your profile, @username, and follower connections")
    }
    var deleteAccountImpactPosts: String {
        tr("deleteAccountImpactPosts", fallback: "All shared community posts, comments, and likes")
    }
    var deleteAccountImpactBookmarks: String {
        tr("deleteAccountImpactBookmarks", fallback: "Your saved bookmarks and reading preferences")
    }
    var deleteAccountImpactSubscription: String {
        tr("deleteAccountImpactSubscription", fallback: "Active App Store subscriptions must be canceled separately in iOS Settings.")
    }
    var deleteAccountConfirmKeyword: String {
        tr("deleteAccountConfirmKeyword", fallback: "DELETE")
    }
    func deleteAccountTypePrompt(_ keyword: String) -> String {
        tr("deleteAccountTypePrompt", fallback: "Type \"{keyword}\" below to confirm", ("keyword", keyword))
    }
    var deleteAccountKeepButton: String {
        tr("deleteAccountKeepButton", fallback: "Keep My Account")
    }
    var noFollowersYet: String {
        tr("noFollowersYet", fallback: "No followers yet.")
    }
    var notFollowingAnyoneYet: String {
        tr("notFollowingAnyoneYet", fallback: "Not following anyone yet.")
    }
}
