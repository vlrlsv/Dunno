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

    /// The slot indicator above the list, which announces e.g. "3 of 8 tasks".
    private func taskCount(_ count: Int) -> XCUIElement {
        app.descendants(matching: .any)["\(count) of 8 tasks"]
    }

    private func finishOnboarding() {
        let start = app.buttons["Get started"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        XCTAssertTrue(taskCount(0).waitForExistence(timeout: 5))
    }

    private func addTask(_ title: String) {
        let field = app.textFields["Add a task"]
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
        XCTAssertTrue(taskCount(1).waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Get started"].exists)
        XCTAssertEqual(app.textFields["Task"].value as? String, "Read a chapter")
    }

    func testSingleTaskRestoresActiveStateAndSupportsCancelAndComplete() {
        finishOnboarding()
        addTask("Read a chapter")
        app.buttons["Start task"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Read a chapter"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
        app.buttons["Not now"].tap()
        XCTAssertTrue(app.buttons["Start task"].waitForExistence(timeout: 5))
        app.buttons["Start task"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(taskCount(0).waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Start task"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(taskCount(0).waitForExistence(timeout: 5))
    }

    func testTaskLimitAndBlankInput() {
        finishOnboarding()
        let field = app.textFields["Add a task"]
        field.tap()
        field.typeText("   \n")
        XCTAssertTrue(taskCount(0).exists)
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3))
        for index in 1...8 { addTask("Task \(index)") }
        XCTAssertTrue(taskCount(8).waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["Add a task"].exists)
        app.buttons["Pick for me"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 10))
        app.buttons["Done"].tap()
        XCTAssertTrue(taskCount(7).waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Add a task"].exists)
    }

    func testRandomizerChoosesAnExistingTask() {
        finishOnboarding()
        addTask("Read")
        addTask("Walk")
        app.buttons["Pick for me"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Read"].exists || app.staticTexts["Walk"].exists)
        app.buttons["Not now"].tap()
        XCTAssertTrue(taskCount(2).waitForExistence(timeout: 5))
    }

    func testEditingAndDeletingTasks() {
        finishOnboarding()
        addTask("Read")
        let row = app.textFields["Task"]
        row.tap()
        row.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4) + "Walk")
        app.textFields["Add a task"].tap()
        XCTAssertEqual(row.value as? String, "Walk")
        app.terminate()
        app.launch()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertEqual(row.value as? String, "Walk")
        app.buttons["Start task"].tap()
        XCTAssertTrue(app.staticTexts["Walk"].waitForExistence(timeout: 5))
        app.buttons["Not now"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(taskCount(0).waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Start task"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(taskCount(0).waitForExistence(timeout: 5))
    }
}
