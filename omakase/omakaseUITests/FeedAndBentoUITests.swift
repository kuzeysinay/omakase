import XCTest

final class FeedAndBentoUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testBentoCategoryDrillDownAndLetterboxdTile() throws {
        app.launchOmakase(route: "bento")

        XCTAssertTrue(app.staticTexts[UIID.bentoRootTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.bentoChefPickBar].waitForExistence(timeout: 5))

        let historyTile = app.buttons[UIID.bentoHistoryCategory]
        XCTAssertTrue(historyTile.waitForExistence(timeout: 5))
        historyTile.tap()

        XCTAssertTrue(app.buttons[UIID.bentoSubtopicsBackButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.bentoSubtopicsRefreshButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.bentoSubtopic0].waitForExistence(timeout: 5))

        app.buttons[UIID.bentoSubtopicsBackButton].tap()
        XCTAssertTrue(app.staticTexts[UIID.bentoRootTitle].waitForExistence(timeout: 5))

        let filmTile = app.buttons[UIID.bentoFilmCategory]
        XCTAssertTrue(filmTile.waitForExistence(timeout: 5))
        filmTile.tap()

        XCTAssertTrue(app.buttons[UIID.bentoLetterboxdTile].waitForExistence(timeout: 5))
    }

    func testFeedCardBookmarkSourcePopoverAndDeepDive() throws {
        app.launchOmakase(route: "feed")

        XCTAssertTrue(app.staticTexts[UIID.feedHeaderTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.feedQuotaPill].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[UIID.feedPostTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[UIID.feedPostBody].waitForExistence(timeout: 5))

        // Bookmark toggle shows toast
        app.buttons[UIID.feedActionBookmark].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.toast].waitForExistence(timeout: 5))
        app.buttons[UIID.feedActionBookmark].tap()

        // Primary Source popover
        app.buttons[UIID.postSourceButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.postSourceCitation].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.postSourceSearchButton].waitForExistence(timeout: 5))

        // Dismiss popover
        let dismissRegion = app.otherElements["PopoverDismissRegion"]
        if dismissRegion.exists {
            dismissRegion.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
        }

        // Deep Dive sheet opens and closes
        app.buttons[UIID.feedActionDeepDive].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.deepDiveBody].waitForExistence(timeout: 5))
        app.buttons[UIID.deepDiveCloseButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.feedPostTitle].waitForExistence(timeout: 5))
    }

    func testExportStudioCustomizationAndCopyLink() throws {
        app.launchOmakase(route: "feed")

        app.buttons[UIID.feedActionExport].waitAndTap()
        XCTAssertTrue(app.buttons[UIID.exportCloseButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.exportCopyLinkButton].waitForExistence(timeout: 5))

        for ratioID in ["export.ratio.story", "export.ratio.square", "export.ratio.post"] {
            app.buttons[ratioID].waitAndTap()
        }

        for toggleID in ["export.toggle.source", "export.toggle.tags", "export.toggle.motif"] {
            app.buttons[toggleID].waitAndTap()
        }

        for themeID in ["export.theme.ink", "export.theme.editorial", "export.theme.midnight", "export.theme.paper"] {
            app.buttons[themeID].waitAndTap()
        }

        app.buttons[UIID.exportCopyLinkButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.exportToast].waitForExistence(timeout: 5))

        app.buttons[UIID.exportCloseButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.feedPostTitle].waitForExistence(timeout: 5))
    }
}
