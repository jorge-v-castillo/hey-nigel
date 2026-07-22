import XCTest

/// Walks the entire conversational onboarding flow, into the Dashboard, and
/// through the voice-driven "Begin Round" setup — attaching a named
/// screenshot at each screen. CI has no microphone signal, so every step is
/// driven through the manual fallback controls `GuidedVoicePromptView`
/// always shows alongside the mic button (not a failure-triggered path —
/// the same one a real user gets on a mishear).
final class OnboardingWalkthroughUITests: XCTestCase {
    private let promptTimeout: TimeInterval = 12

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingDashboardAndRoundSetupWalkthrough() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestReset"]
        app.launch()

        // Welcome
        attach(app.screenshot(), name: "01-Welcome")
        app.buttons["Get Started"].tap()

        // Intro slides
        XCTAssertTrue(app.staticTexts["Hello, I'm Nigel"].waitForExistence(timeout: 5))
        attach(app.screenshot(), name: "02-IntroOne")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["Let's get you set up"].waitForExistence(timeout: 5))
        attach(app.screenshot(), name: "03-IntroTwo")
        app.buttons["Let's Begin"].tap()

        // Permissions
        XCTAssertTrue(app.staticTexts["Nigel needs a few permissions"].waitForExistence(timeout: 5))
        attach(app.screenshot(), name: "04-Permissions")
        app.buttons["Continue"].tap()

        // Name
        answerGuidedPrompt(app, text: "Jorge Castillo", screenshotName: "05-Name")

        // Nickname
        answerGuidedPrompt(app, text: "Ace", screenshotName: "06-Nickname")

        // 9-club loop
        let yardages = ["230", "215", "195", "180", "165", "150", "135", "120", "105"]
        for (index, yardage) in yardages.enumerated() {
            answerGuidedPrompt(app, text: yardage, screenshotName: index == 0 ? "07-ClubLoop-Driver" : nil)
        }

        // Ready
        XCTAssertTrue(app.staticTexts["You're all set"].waitForExistence(timeout: promptTimeout))
        attach(app.screenshot(), name: "08-Ready")
        app.buttons["Continue"].tap()

        // Dashboard
        let beginRound = app.buttons["Begin Round"]
        XCTAssertTrue(beginRound.waitForExistence(timeout: 5))
        attach(app.screenshot(), name: "09-Dashboard")
        beginRound.tap()

        // Round setup: no GPS in CI, so this waits out the location timeout
        // (~5s) before falling back to asking the course by name — generous
        // timeout here to cover that plus speech synthesis time.
        answerGuidedPrompt(app, text: "Sunridge", screenshotName: "10-RoundSetup-Course", timeout: 20)

        // Holes
        answerGuidedPrompt(app, text: "18", screenshotName: "11-RoundSetup-Holes")

        // Front/back nine — a direct choice tap, no review step.
        let frontButton = app.buttons["Front"]
        XCTAssertTrue(frontButton.waitForExistence(timeout: promptTimeout))
        attach(app.screenshot(), name: "12-RoundSetup-Nine")
        frontButton.tap()

        // Tees — also a direct choice tap.
        let whiteTeeButton = app.buttons["White"]
        XCTAssertTrue(whiteTeeButton.waitForExistence(timeout: promptTimeout))
        attach(app.screenshot(), name: "13-RoundSetup-Tees")
        whiteTeeButton.tap()

        // Active round
        XCTAssertTrue(app.staticTexts["Hole 1"].waitForExistence(timeout: promptTimeout))
        Thread.sleep(forTimeInterval: 1.5)
        attach(app.screenshot(), name: "14-ActiveRound")
    }

    /// Waits for the manual-fallback text field to appear, types the given
    /// text, submits, then confirms the review step — the standard path for
    /// every free-text/number question in the flow.
    private func answerGuidedPrompt(_ app: XCUIApplication, text: String, screenshotName: String?, timeout: TimeInterval? = nil) {
        let field = app.textFields["guidedPromptTextField"]
        XCTAssertTrue(field.waitForExistence(timeout: timeout ?? promptTimeout))
        if let screenshotName {
            attach(app.screenshot(), name: screenshotName)
        }
        field.tap()
        field.typeText(text)
        app.buttons["Submit"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()
    }

    private func attach(_ screenshot: XCUIScreenshot, name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
