import XCTest

final class AuthFlowUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchOmakase(route: "auth")
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testWelcomeScreenDisplaysAllAuthOptions() throws {
        XCTAssertTrue(app.buttons[UIID.authAppleButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.authGoogleButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.authCreateAccountButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.authSignInButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.languagePicker].waitForExistence(timeout: 5))
    }

    func testEmailSignUpMultiStepValidationAndBackNavigation() throws {
        app.buttons[UIID.authCreateAccountButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.authStep1Title].waitForExistence(timeout: 5))

        // Invalid email triggers error banner
        app.buttons[UIID.authStep1ContinueButton].waitAndTap(in: app)
        XCTAssertTrue(app.staticTexts[UIID.authErrorBanner].waitForExistence(timeout: 5))

        // Enter valid email, short password -> triggers weak password error
        let emailField = app.textFields[UIID.authStep1EmailField]
        emailField.waitAndTap()
        emailField.typeText("test@omakase.app")

        let securePasswordField = app.secureTextFields[UIID.authStep1PasswordField]
        securePasswordField.waitAndTap()
        securePasswordField.typeText("1234567")

        app.buttons[UIID.authStep1ContinueButton].waitAndTap(in: app)
        XCTAssertTrue(app.staticTexts[UIID.authErrorBanner].waitForExistence(timeout: 5))

        // Toggle password visibility and enter 8+ characters
        app.buttons[UIID.authStep1PasswordVisibilityButton].waitAndTap()
        let visiblePasswordField = app.textFields[UIID.authStep1PasswordVisibleField]
        XCTAssertTrue(visiblePasswordField.waitForExistence(timeout: 5))
        visiblePasswordField.tap()
        visiblePasswordField.typeText("omakase123")

        app.buttons[UIID.authStep1ContinueButton].waitAndTap(in: app)

        // Step 2: Display Name
        XCTAssertTrue(app.staticTexts[UIID.authStep2Title].waitForExistence(timeout: 5))
        app.buttons[UIID.authStep2ContinueButton].waitAndTap(in: app)
        XCTAssertTrue(app.staticTexts[UIID.authErrorBanner].waitForExistence(timeout: 5))

        let displayNameField = app.textFields[UIID.authStep2DisplayNameField]
        displayNameField.waitAndTap()
        displayNameField.typeText("Kuzey")
        app.buttons[UIID.authStep2ContinueButton].waitAndTap(in: app)

        // Step 3: Username & Preview Card
        XCTAssertTrue(app.staticTexts[UIID.authStep3Title].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements[UIID.authStep3PreviewCard].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields[UIID.authStep3UsernameField].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.authStep3CompleteButton].waitForExistence(timeout: 5))

        // Back navigation: Step 3 -> Step 2 -> Step 1 -> Welcome
        app.buttons[UIID.authBackButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.authStep2Title].waitForExistence(timeout: 5))

        app.buttons[UIID.authBackButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.authStep1Title].waitForExistence(timeout: 5))

        app.buttons[UIID.authBackButton].waitAndTap()
        XCTAssertTrue(app.buttons[UIID.authCreateAccountButton].waitForExistence(timeout: 5))
    }

    func testSignInValidationAndForgotPasswordFlow() throws {
        app.buttons[UIID.authSignInButton].waitAndTap()
        XCTAssertTrue(app.staticTexts[UIID.authSignInTitle].waitForExistence(timeout: 5))

        XCTAssertTrue(app.textFields[UIID.authSignInEmailField].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields[UIID.authSignInPasswordField].waitForExistence(timeout: 5))

        app.buttons[UIID.authSignInSubmitButton].waitAndTap(in: app)
        XCTAssertTrue(app.staticTexts[UIID.authErrorBanner].waitForExistence(timeout: 5))

        app.buttons[UIID.authSignInForgotPasswordButton].waitAndTap(in: app)
        XCTAssertTrue(app.staticTexts[UIID.authErrorBanner].waitForExistence(timeout: 5))

        app.buttons[UIID.authBackButton].waitAndTap()
        XCTAssertTrue(app.buttons[UIID.authCreateAccountButton].waitForExistence(timeout: 5))
    }

    func testLanguageSwitchKeepsAuthFlowAccessible() throws {
        let picker = app.buttons[UIID.languagePicker]
        picker.waitAndTap()

        let turkishOption = app.buttons["language.option.tr"]
        XCTAssertTrue(turkishOption.waitForExistence(timeout: 5))
        turkishOption.tap()

        XCTAssertTrue(app.buttons[UIID.authCreateAccountButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[UIID.authSignInButton].waitForExistence(timeout: 5))
    }
}
