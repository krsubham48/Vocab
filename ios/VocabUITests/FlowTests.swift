import XCTest

/// Drives every user flow and keeps a screenshot of each screen.
final class FlowTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Helpers

    /// `store`: "reset" starts empty, "keep" reuses the last run, JSON seeds it.
    private func launch(_ store: String = "reset", arguments: [String] = []) {
        app.launchEnvironment["VOCAB_TEST_STORE"] = store
        app.launchArguments = arguments
        app.launch()
        XCTAssertTrue(app.buttons["home.learn"].waitForExistence(timeout: 20))
    }

    private func seed(_ entries: [(id: String, date: String)]) -> String {
        let words = entries.map { "\"\($0.id)\":{\"status\":\"learnt\",\"learntDate\":\"\($0.date)\"}" }
        return "{\"words\":{\(words.joined(separator: ","))},\"activeDeck\":\"everyday\"}"
    }

    private var gregorian: Calendar { Calendar(identifier: .gregorian) }

    private func iso(_ date: Date) -> String {
        let parts = gregorian.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    private var today: String { iso(Date()) }

    /// The 15th of the month before this one.
    private var lastMonth: Date {
        var parts = gregorian.dateComponents([.year, .month], from: gregorian.date(byAdding: .month, value: -1, to: Date())!)
        parts.day = 15
        return gregorian.date(from: parts)!
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = gregorian
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private var threeWords: String {
        seed([("everyday:candid", today), ("everyday:ambitious", today), ("everyday:custody", iso(lastMonth))])
    }

    private func text(_ id: String) -> String { app.staticTexts[id].label }

    private func snapshot(_ name: String) {
        // the whole screen: capturing the app window comes out sideways in landscape
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Swipes up until the element can be tapped.
    private func reach(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < 15 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(element.exists && element.isHittable, "could not reach \(element)", file: file, line: line)
    }

    // MARK: - Flows

    func testStartPageHasNoBottomBar() {
        launch()
        XCTAssertTrue(app.buttons["home.revise"].exists)
        XCTAssertTrue(app.buttons["home.about"].exists)
        XCTAssertTrue(app.buttons["home.calendar"].exists)
        XCTAssertFalse(app.buttons["tab.learn"].exists)
        snapshot("home")
    }

    func testLearningAWordIsSavedAcrossLaunches() {
        launch()
        app.buttons["home.learn"].tap()
        XCTAssertTrue(app.buttons["tab.learn"].isSelected)
        XCTAssertEqual(text("learn.progress"), "0 / 294 learnt")
        XCTAssertFalse(app.buttons["learn.markLearnt"].isEnabled)
        snapshot("learn-empty")
        app.buttons["learn.newWord"].tap()
        app.buttons["learn.markLearnt"].tap()
        XCTAssertEqual(text("learn.progress"), "1 / 294 learnt")
        XCTAssertFalse(app.buttons["learn.markLearnt"].isEnabled)
        snapshot("learn")
        app.terminate()
        launch("keep")
        app.buttons["home.learn"].tap()
        XCTAssertEqual(text("learn.progress"), "1 / 294 learnt")
    }

    func testReviseRevealsAndAdvances() {
        launch(threeWords)
        app.buttons["home.revise"].tap()
        XCTAssertTrue(app.buttons["practice.revisit"].exists)
        snapshot("practice")
        app.buttons["practice.revise"].tap()
        XCTAssertTrue(app.buttons["revise.card"].exists)
        XCTAssertFalse(app.buttons["revise.gotIt"].exists)
        snapshot("revise-front")
        app.buttons["revise.card"].tap()
        XCTAssertTrue(app.buttons["revise.gotIt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["revise.stillLearning"].exists)
        snapshot("revise-back")
        reach(app.buttons["revise.gotIt"])
        app.buttons["revise.gotIt"].tap()
        XCTAssertTrue(app.buttons["revise.card"].waitForExistence(timeout: 5))
    }

    func testRevisitSearchExpandAndRemove() {
        launch(threeWords)
        app.buttons["home.revise"].tap()
        app.buttons["practice.revisit"].tap()
        XCTAssertEqual(text("revisit.count"), "3 learnt words")
        snapshot("revisit-list")
        app.buttons["revisit.row.everyday:candid"].tap()
        let remove = app.buttons["revisit.remove.everyday:candid"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5))
        snapshot("revisit-open")

        let search = app.textFields["revisit.search"]
        search.tap()
        search.typeText("cand")
        XCTAssertEqual(text("revisit.count"), "1 of 3 words")
        XCTAssertFalse(app.buttons["tab.learn"].exists, "the bar hides while typing")
        snapshot("revisit-search")
        app.buttons["revisit.done"].tap()

        reach(remove)
        remove.tap()
        app.alerts.buttons["Cancel"].tap()
        XCTAssertEqual(text("revisit.count"), "1 of 3 words")
        remove.tap()
        app.alerts.buttons["Remove"].tap()
        XCTAssertEqual(text("revisit.count"), "0 of 2 words")
    }

    func testCalendarMovesBetweenMonths() {
        launch(threeWords)
        app.buttons["home.calendar"].tap()
        XCTAssertEqual(text("calendar.title"), monthTitle(Date()))
        XCTAssertFalse(app.buttons["calendar.next"].isEnabled)
        app.buttons["day.\(today)"].tap()
        XCTAssertTrue(app.staticTexts["calendar.word.everyday:candid"].waitForExistence(timeout: 5))
        snapshot("calendar")

        app.buttons["calendar.previous"].tap()
        XCTAssertEqual(text("calendar.title"), monthTitle(lastMonth))
        XCTAssertFalse(app.staticTexts["calendar.word.everyday:candid"].exists)
        app.buttons["day.\(iso(lastMonth))"].tap()
        XCTAssertTrue(app.staticTexts["calendar.word.everyday:custody"].waitForExistence(timeout: 5))
        snapshot("calendar-previous")

        app.buttons["calendar.next"].tap()
        XCTAssertEqual(text("calendar.title"), monthTitle(Date()))
        XCTAssertFalse(app.buttons["calendar.next"].isEnabled)
    }

    func testEveryTabOpensAndAboutLeadsBackToStart() {
        launch()
        app.buttons["home.about"].tap()
        XCTAssertTrue(app.staticTexts["about.title"].exists)
        XCTAssertTrue(app.buttons["tab.about"].isSelected)
        snapshot("about")
        app.buttons["tab.revise"].tap()
        XCTAssertTrue(app.staticTexts["Learn and mark some words first!"].exists)
        app.buttons["tab.revisit"].tap()
        XCTAssertTrue(app.staticTexts["Learn and mark some words first!"].exists)
        app.buttons["tab.calendar"].tap()
        XCTAssertTrue(app.staticTexts["calendar.title"].exists)
        app.buttons["tab.learn"].tap()
        XCTAssertTrue(app.buttons["learn.newWord"].exists)
        app.buttons["tab.about"].tap()
        reach(app.buttons["about.back"])
        app.buttons["about.back"].tap()
        XCTAssertTrue(app.buttons["home.learn"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["tab.learn"].exists)
    }

    func testLargestTextSizeKeepsEverythingReachable() {
        let largest = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        launch(threeWords, arguments: largest)
        snapshot("large-home")
        reach(app.buttons["home.calendar"])
        snapshot("large-home-links")
        app.buttons["home.calendar"].tap()
        app.buttons["day.\(today)"].tap()
        snapshot("large-calendar")
        app.buttons["tab.learn"].tap()
        reach(app.buttons["learn.newWord"])
        app.buttons["learn.newWord"].tap()
        snapshot("large-learn")
        reach(app.buttons["learn.markLearnt"])
        snapshot("large-learn-buttons")
        app.buttons["tab.revise"].tap()
        app.buttons["revise.card"].tap()
        snapshot("large-revise")
        reach(app.buttons["revise.gotIt"])
        snapshot("large-revise-buttons")
        app.buttons["tab.revisit"].tap()
        app.buttons["revisit.row.everyday:candid"].tap()
        snapshot("large-revisit")
        reach(app.buttons["revisit.remove.everyday:candid"])
        app.buttons["tab.about"].tap()
        snapshot("large-about")
        reach(app.buttons["about.back"])
    }

    /// The longest word at the largest text size: the screenshots must show it whole.
    func testALongWordAtTheLargestSize() {
        let longWord = "{\"words\":{\"advanced:contemporaneous\":{\"status\":\"learnt\",\"learntDate\":\"\(today)\"}},"
            + "\"lastShownID\":\"advanced:contemporaneous\",\"activeDeck\":\"advanced\"}"
        launch(longWord, arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        reach(app.buttons["home.learn"])
        app.buttons["home.learn"].tap()
        XCTAssertEqual(app.staticTexts["learn.word"].label, "Contemporaneous")
        snapshot("long-word-learn")
        app.buttons["tab.revisit"].tap()
        snapshot("long-word-revisit")
        app.buttons["tab.revise"].tap()
        snapshot("long-word-revise")
        app.buttons["tab.calendar"].tap()
        app.buttons["day.\(today)"].tap()
        app.swipeUp()
        snapshot("long-word-calendar")
    }

    /// Scrolling past an opened card at the largest text size once left the app
    /// stuck laying out the list. It must stay responsive.
    func testScrollingAnOpenCardAtTheLargestTextSize() {
        let words = seed(["ambitious", "candid", "custody", "protest", "advocate"].map { ("everyday:\($0)", today) })
        launch(words, arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        reach(app.buttons["home.revise"])
        app.buttons["home.revise"].tap()
        reach(app.buttons["practice.revisit"])
        app.buttons["practice.revisit"].tap()
        app.buttons["revisit.row.everyday:advocate"].tap()
        for _ in 0..<3 {
            app.swipeUp()
            app.swipeUp()
            app.swipeDown()
            app.swipeDown()
        }
        app.buttons["tab.learn"].tap()
        XCTAssertTrue(app.buttons["learn.newWord"].waitForExistence(timeout: 10))
    }

    func testLandscape() {
        launch(threeWords)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["home.learn"].waitForExistence(timeout: 10))
        snapshot("landscape-home")
        XCTAssertTrue(app.buttons["home.learn"].isHittable)
        XCTAssertTrue(app.buttons["home.revise"].isHittable)
        app.buttons["home.learn"].tap()
        reach(app.buttons["learn.newWord"])
        app.buttons["learn.newWord"].tap()
        snapshot("landscape-learn")
        app.buttons["tab.calendar"].tap()
        snapshot("landscape-calendar")
        app.buttons["tab.revisit"].tap()
        snapshot("landscape-revisit")
        XCUIDevice.shared.orientation = .portrait
    }
}
