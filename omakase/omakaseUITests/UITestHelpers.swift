import XCTest

enum UIID {
    // Common
    static let languagePicker = "common.languagePicker"
    static let toast = "common.toast"

    // Auth
    static let authBackButton = "auth.topBar.backButton"
    static let authAppleButton = "auth.welcome.appleButton"
    static let authGoogleButton = "auth.welcome.googleButton"
    static let authCreateAccountButton = "auth.welcome.createAccountButton"
    static let authSignInButton = "auth.welcome.signInButton"

    static let authStep1Title = "auth.signup.step1.title"
    static let authStep1EmailField = "auth.signup.emailField"
    static let authStep1PasswordField = "auth.signup.passwordField"
    static let authStep1PasswordVisibleField = "auth.signup.passwordVisibleField"
    static let authStep1PasswordVisibilityButton = "auth.signup.passwordVisibilityButton"
    static let authStep1ContinueButton = "auth.signup.step1.continueButton"

    static let authStep2Title = "auth.signup.step2.title"
    static let authStep2DisplayNameField = "auth.signup.displayNameField"
    static let authStep2ClearDisplayNameButton = "auth.signup.clearDisplayNameButton"
    static let authStep2ContinueButton = "auth.signup.step2.continueButton"

    static let authStep3Title = "auth.signup.step3.title"
    static let authStep3PreviewCard = "auth.signup.previewCard"
    static let authStep3UsernameField = "auth.signup.usernameField"
    static let authStep3CompleteButton = "auth.signup.completeButton"

    static let authSignInTitle = "auth.signin.title"
    static let authSignInEmailField = "auth.signin.emailField"
    static let authSignInPasswordField = "auth.signin.passwordField"
    static let authSignInForgotPasswordButton = "auth.signin.forgotPasswordButton"
    static let authSignInSubmitButton = "auth.signin.submitButton"

    static let authErrorBanner = "auth.messageBanner.error"
    static let authInfoBanner = "auth.messageBanner.info"

    // Onboarding / Profile Setup
    static let onboardingSkipButton = "onboarding.skipButton"
    static let onboardingPrimaryButton = "onboarding.primaryButton"
    static let onboardingSlide0Title = "onboarding.slide.0.title"
    static let onboardingSlide1Title = "onboarding.slide.1.title"
    static let onboardingSlide2Title = "onboarding.slide.2.title"
    static let onboardingSlide3Title = "onboarding.slide.3.title"
    static let onboardingCompleted = "uitest.onboarding.completed"
    static let profileSetupContinueButton = "profileSetup.continueButton"

    // Bento
    static let bentoRootTitle = "bento.root.title"
    static let bentoSubtopicsBackButton = "bento.subtopics.backButton"
    static let bentoSubtopicsRefreshButton = "bento.subtopics.refreshButton"
    static let bentoChefPickBar = "bento.chefPickBar"
    static let bentoHistoryCategory = "bento.category.history"
    static let bentoFilmCategory = "bento.category.film"
    static let bentoSubtopic0 = "bento.subtopic.0"
    static let bentoLetterboxdTile = "bento.letterboxdTile"

    // Feed & Post Card
    static let feedHeaderTitle = "feed.header.title"
    static let feedQuotaPill = "feed.header.quotaPill"
    static let feedPostTitle = "feed.post.title"
    static let feedPostBody = "feed.post.body"
    static let feedActionDeepDive = "feed.action.deepDive"
    static let feedActionShare = "feed.action.share"
    static let feedActionExport = "feed.action.export"
    static let feedActionBookmark = "feed.action.bookmark"

    // Source Popover & Deep Dive
    static let postSourceButton = "post.source.button"
    static let postSourceCitation = "post.source.popover.citation"
    static let postSourceSearchButton = "post.source.popover.searchButton"
    static let deepDiveBody = "deepdive.sheet.body"
    static let deepDiveCloseButton = "deepdive.sheet.closeButton"

    // Export Studio
    static let exportCloseButton = "export.sheet.closeButton"
    static let exportToast = "export.toast"
    static let exportCopyLinkButton = "export.linkBar.copyButton"

    // Community & Tabs
    static let communitySearchField = "community.searchField"
    static let communityFeedModePicker = "community.feedModePicker"
    static let communityPostCard0 = "community.postCard.0"
    static let profileMarker = "uitest.profile.marker"

    // Daily Limit & Paywall
    static let dailyLimitTitle = "dailyLimit.title"
    static let dailyLimitUpgradeButton = "dailyLimit.upgradeButton"
    static let dailyLimitRemindButton = "dailyLimit.remindButton"
    static let paywallCloseButton = "paywall.closeButton"
    static let paywallYearlyPlan = "paywall.plan.yearly"
    static let paywallMonthlyPlan = "paywall.plan.monthly"
    static let paywallPurchaseButton = "paywall.purchaseButton"
    static let paywallRestoreButton = "paywall.restoreButton"
}

extension XCUIApplication {
    func launchOmakase(
        route: String? = nil,
        language: String = "en",
        scheme: String = "light",
        skipSplash: Bool = true
    ) {
        var args: [String] = []
        if let route {
            args.append(contentsOf: ["-UITestRoute", route])
        }
        args.append(contentsOf: ["-UITestLang", language])
        args.append(contentsOf: ["-UITestScheme", scheme])
        if skipSplash {
            args.append("-UITestSkipSplash")
        }
        launchArguments = args
        launch()
    }
}

extension XCUIElement {
    func waitAndTap(
        in app: XCUIApplication? = nil,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            waitForExistence(timeout: timeout),
            "Expected element \(self) to exist before tapping",
            file: file,
            line: line
        )
        if !isHittable, let app {
            app.swipeUp()
        }
        tap()
    }
}
