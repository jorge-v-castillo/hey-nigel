import XCTest

/// Walks the entire onboarding flow plus the start of an active round,
/// attaching a named screenshot at each screen. This isn't a correctness
/// test so much as a way to *see* the app without a working local Xcode —
/// CI runs this against a real Simulator and the screenshots are uploaded
/// as a downloadable artifact.
final class OnboardingWalkthroughUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingAndActiveRoundWalkthrough() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestReset"]
        app.launch()

        attach(app.screenshot(), name: "01-Welcome")

        app.buttons["Get Started"].tap()

        let firstCourse = app.staticTexts["Sunridge Fixture Golf Club"]
        XCTAssertTrue(firstCourse.waitForExistence(timeout: 5))
        attach(app.screenshot(), name: "02-CourseSearch")

        firstCourse.tap()
        let courseContinue = app.buttons["Continue"]
        waitUntilEnabled(courseContinue)
        courseContinue.tap()

        let whiteTee = app.staticTexts["White"]
        XCTAssertTrue(whiteTee.waitForExistence(timeout: 5))
        whiteTee.tap()
        attach(app.screenshot(), name: "03-TeeSelection")
        let teeContinue = app.buttons["Continue"]
        waitUntilEnabled(teeContinue)
        teeContinue.tap()

        XCTAssertTrue(app.staticTexts["How many holes today?"].waitForExistence(timeout: 5))
        attach(app.screenshot(), name: "04-HoleCount")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.textFields["driverYardageField"].waitForExistence(timeout: 5))
        app.textFields["driverYardageField"].tap()
        app.textFields["driverYardageField"].typeText("230")
        app.textFields["sevenIronYardageField"].tap()
        app.textFields["sevenIronYardageField"].typeText("150")
        app.textFields["wedgeYardageField"].tap()
        app.textFields["wedgeYardageField"].typeText("90")
        app.staticTexts["About how far do you hit these?"].tap()
        attach(app.screenshot(), name: "05-ClubYardages")
        let yardageContinue = app.buttons["Continue"]
        waitUntilEnabled(yardageContinue)
        yardageContinue.tap()

        XCTAssertTrue(app.staticTexts["Nigel needs a few permissions"].waitForExistence(timeout: 5))
        attach(app.screenshot(), name: "06-Permissions")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["You're all set"].waitForExistence(timeout: 5))
        attach(app.screenshot(), name: "07-Ready")
        app.buttons["Let's Play"].tap()

        let startRoundButton = app.buttons["Start Round"]
        XCTAssertTrue(startRoundButton.waitForExistence(timeout: 5))
        attach(app.screenshot(), name: "08-ActiveRound-Start")

        startRoundButton.tap()
        XCTAssertTrue(app.staticTexts["Hole 1"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1.5)
        attach(app.screenshot(), name: "09-ActiveRound-WaitingForGPS")
    }

    @MainActor
    private func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = expectation(for: predicate, evaluatedWith: element)
        wait(for: [expectation], timeout: timeout)
    }

    @MainActor
    private func attach(_ screenshot: XCUIScreenshot, name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
