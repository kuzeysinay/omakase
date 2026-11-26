import XCTest

final class OnboardingUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchOmakase(route: "onboarding")
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testOnboardingWalkthroughCompletesAfterFourSlides() throws {
        XCTAssertTrue(app.staticTexts[UIID.onboardingSlide0Title].waitForExistence(timeout: 5))

        app.buttons[UIID.onboardingPrimaryButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.onboardingSlide1Title].waitForExistence(timeout: 5))

        app.buttons[UIID.onboardingPrimaryButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.onboardingSlide2Title].waitForExistence(timeout: 5))

        app.buttons[UIID.onboardingPrimaryButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.onboardingSlide3Title].waitForExistence(timeout: 5))

        app.buttons[UIID.onboardingPrimaryButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.onboardingCompleted].waitForExistence(timeout: 5))
    }

    func testOnboardingSkipCompletesImmediately() throws {
        app.buttons[UIID.onboardingSkipButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.onboardingCompleted].waitForExistence(timeout: 5))
    }
}
