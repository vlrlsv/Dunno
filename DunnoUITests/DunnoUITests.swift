import XCTest

@MainActor
final class DunnoUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["DUNNO_UI_TEST_ID"] = UUID().uuidString
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    private func finishOnboarding() {
        let start = app.buttons["Get Started"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        XCTAssertTrue(app.navigationBars["My Tasks (0/8)"].waitForExistence(timeout: 5))
    }

    private func addTask(_ title: String) {
        let field = app.textFields["New task..."]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(title + "\n")
        XCTAssertTrue(app.textFields.matching(NSPredicate(format: "value == %@", title)).firstMatch.waitForExistence(timeout: 5))
    }

    func testOnboardingAndTasksSurviveRelaunch() {
        finishOnboarding()
        addTask("Read a chapter")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars["My Tasks (1/8)"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Get Started"].exists)
        XCTAssertEqual(app.textFields["Task"].value as? String, "Read a chapter")
    }

    func testSingleTaskRestoresActiveStateAndSupportsCancelAndComplete() {
        finishOnboarding()
        addTask("Read a chapter")
        app.buttons["Start Task"].tap()
        XCTAssertTrue(app.buttons["Mark Complete"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Read a chapter"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Mark Complete"].waitForExistence(timeout: 5))
        app.buttons["Cancel & Pick Another Later"].tap()
        XCTAssertTrue(app.buttons["Start Task"].waitForExistence(timeout: 5))
        app.buttons["Start Task"].tap()
        app.buttons["Mark Complete"].tap()
        XCTAssertTrue(app.navigationBars["My Tasks (0/8)"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Start Task"].exists)
    }

    func testTaskLimitAndBlankInput() {
        finishOnboarding()
        let field = app.textFields["New task..."]
        field.tap()
        field.typeText("   \n")
        XCTAssertTrue(app.navigationBars["My Tasks (0/8)"].exists)
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3))
        for index in 1...8 { addTask("Task \(index)") }
        XCTAssertTrue(app.navigationBars["My Tasks (8/8)"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["New task..."].exists)
        app.buttons["Pick a Random Task"].tap()
        XCTAssertTrue(app.buttons["Mark Complete"].waitForExistence(timeout: 10))
        app.buttons["Mark Complete"].tap()
        XCTAssertTrue(app.navigationBars["My Tasks (7/8)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["New task..."].exists)
    }

    func testRandomizerChoosesAnExistingTask() {
        finishOnboarding()
        addTask("Read")
        addTask("Walk")
        app.buttons["Pick a Random Task"].tap()
        XCTAssertTrue(app.buttons["Mark Complete"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Read"].exists || app.staticTexts["Walk"].exists)
        app.buttons["Cancel & Pick Another Later"].tap()
        XCTAssertTrue(app.navigationBars["My Tasks (2/8)"].waitForExistence(timeout: 5))
    }

    func testEditingAndDeletingTasks() {
        finishOnboarding()
        addTask("Read")
        let row = app.textFields["Task"]
        row.tap()
        row.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4) + "Walk")
        app.textFields["New task..."].tap()
        XCTAssertEqual(row.value as? String, "Walk")
        app.buttons["Start Task"].tap()
        XCTAssertTrue(app.staticTexts["Walk"].waitForExistence(timeout: 5))
        app.buttons["Cancel & Pick Another Later"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.navigationBars["My Tasks (0/8)"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Start Task"].exists)
    }
}
