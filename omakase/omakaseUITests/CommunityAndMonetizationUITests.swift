import XCTest

final class CommunityAndMonetizationUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testCommunitySearchAndTabSwitching() throws {
        app.launchOmakase(route: "community")

        let searchField = app.textFields[UIID.communitySearchField]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertTrue(app.segmentedControls[UIID.communityFeedModePicker].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements[UIID.communityPostCard0].waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("Kurosawa\n")
        XCTAssertTrue(app.otherElements[UIID.communityPostCard0].waitForExistence(timeout: 5))

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        // Switch to Feed tab (index 0)
        tabBar.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts[UIID.feedPostTitle].waitForExistence(timeout: 5))

        // Switch to Profile tab (index 2)
        tabBar.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.staticTexts[UIID.profileMarker].waitForExistence(timeout: 5))

        // Switch back to Community tab (index 1)
        tabBar.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.segmentedControls[UIID.communityFeedModePicker].waitForExistence(timeout: 5))
    }

    func testDailyLimitOpensPaywallAndSwitchesPlans() throws {
        app.launchOmakase(route: "dailyLimit")

        XCTAssertTrue(app.staticTexts[UIID.dailyLimitTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.dailyLimitRemindButton].waitForExistence(timeout: 5))

        app.buttons[UIID.dailyLimitUpgradeButton].waitAndTap()

        XCTAssertTrue(app.buttons[UIID.paywallCloseButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.paywallPurchaseButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.paywallRestoreButton].waitForExistence(timeout: 5))

        app.buttons[UIID.paywallMonthlyPlan].waitAndTap()
        app.buttons[UIID.paywallYearlyPlan].waitAndTap()

        app.buttons[UIID.paywallCloseButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.dailyLimitTitle].waitForExistence(timeout: 5))
    }
}
