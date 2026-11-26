import XCTest

final class AppLaunchSmokeUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchOmakase(route: nil, skipSplash: true)
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testDefaultAppLaunchRendersRootScreenWithoutCrash() throws {
        let authCreate = app.buttons[UIID.authCreateAccountButton]
        let profileContinue = app.buttons[UIID.profileSetupContinueButton]
        let onboardingPrimary = app.buttons[UIID.onboardingPrimaryButton]
        let feedTitle = app.staticTexts[UIID.feedHeaderTitle]

        let candidates = [authCreate, profileContinue, onboardingPrimary, feedTitle]
        let deadline = Date().addingTimeInterval(8)
        var renderedRoot = false
        while Date() < deadline {
            if candidates.contains(where: { $0.exists }) {
                renderedRoot = true
                break
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        XCTAssertTrue(renderedRoot, "Expected app launch to render Auth, ProfileSetup, Onboarding, or Feed")
        XCTAssertEqual(app.state, .runningForeground)
    }
}
