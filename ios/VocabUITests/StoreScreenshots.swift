import XCTest

/// Takes the App Store screenshots, showing a few weeks of progress.
/// Skipped in normal runs; `scripts/ios_screenshots.py` runs it.
final class StoreScreenshots: XCTestCase {
    private let app = XCUIApplication()

    func testStoreScreenshots() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["STORE_SCREENSHOTS"] == "1",
                          "run scripts/ios_screenshots.py")
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app.launchEnvironment["VOCAB_TEST_STORE"] = progress
        app.launch()
        XCTAssertTrue(app.buttons["home.learn"].waitForExistence(timeout: 20))
        snapshot("1-start")

        app.buttons["home.learn"].tap()
        XCTAssertEqual(app.staticTexts["learn.word"].label, "Ephemeral")
        snapshot("2-learn")

        app.buttons["tab.revise"].tap()
        app.buttons["revise.card"].tap()
        XCTAssertTrue(app.buttons["revise.gotIt"].waitForExistence(timeout: 5))
        snapshot("3-revise")

        app.buttons["tab.revisit"].tap()
        app.buttons["revisit.row.everyday:candid"].tap()
        XCTAssertTrue(app.buttons["revisit.remove.everyday:candid"].waitForExistence(timeout: 5))
        snapshot("4-revisit")

        app.buttons["tab.calendar"].tap()
        app.buttons["day.\(day(0))"].tap()
        XCTAssertTrue(app.staticTexts["calendar.word.advanced:lucid"].waitForExistence(timeout: 5))
        snapshot("5-calendar")
    }

    /// Words learnt over the last few weeks, with a new one on the Learn screen.
    private var progress: String {
        let learnt = [
            ("advanced:lucid", 0), ("everyday:candid", 0), ("everyday:resilient", 1),
            ("advanced:tenacious", 2), ("everyday:ambitious", 4), ("everyday:meticulous", 4),
            ("advanced:serene", 7), ("everyday:pragmatic", 9), ("advanced:ubiquitous", 11),
            ("everyday:eloquent", 15), ("advanced:alacrity", 18),
        ]
        let words = learnt.map { id, ago in "\"\(id)\":{\"status\":\"learnt\",\"learntDate\":\"\(day(ago))\"}" }
            + ["\"advanced:ephemeral\":{\"status\":\"seen\"}"]
        return "{\"words\":{\(words.joined(separator: ","))},"
            + "\"lastShownID\":\"advanced:ephemeral\",\"activeDeck\":\"advanced\"}"
    }

    /// "yyyy-MM-dd" for the day `ago` days before today.
    private func day(_ ago: Int) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(byAdding: .day, value: -ago, to: Date())!
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    private func snapshot(_ name: String) {
        Thread.sleep(forTimeInterval: 1)  // let button fades finish
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
