import XCTest
@testable import Vocab

final class AppModelTests: XCTestCase {
    private var store: StateStore!
    private var clock = makeDate(2026, 11, 27)
    private let words = [makeWord("candid"), makeWord("advocate", .advanced)]

    override func setUp() {
        store = StateStore(url: URL.temporaryDirectory.appending(path: "\(UUID().uuidString)/state.json"))
    }

    private func makeModel() -> AppModel {
        AppModel(words: words, store: store, now: { [unowned self] in self.clock })
    }

    func testEveryChangeIsSavedAtOnce() {
        let model = makeModel()
        model.newWord()
        XCTAssertEqual(store.load().lastShownID, "everyday:candid")
        model.markCurrentLearnt()
        XCTAssertEqual(store.load().words["everyday:candid"]?.status, .learnt)
        model.setDeck(.advanced)
        XCTAssertEqual(store.load().activeDeck, .advanced)
    }

    func testTheCurrentWordBelongsToTheChosenDeck() {
        let model = makeModel()
        model.newWord()
        XCTAssertEqual(model.currentWord?.slug, "candid")
        model.setDeck(.advanced)
        XCTAssertNil(model.currentWord)
        model.setDeck(.everyday)
        XCTAssertEqual(model.currentWord?.slug, "candid")
    }

    func testTheLearntDateIsTheDayYouTapNotTheDayTheAppOpened() {
        clock = makeDate(2026, 11, 30, 23, 59)
        let model = makeModel()
        model.newWord()
        clock = makeDate(2026, 12, 1, 0, 3)
        model.markCurrentLearnt()
        XCTAssertEqual(model.state.words["everyday:candid"]?.learntDate, "2026-12-01")
        XCTAssertEqual(model.currentMonth, YearMonth(year: 2026, month: 12))
    }

    func testRefreshingTheClockFollowsIntoANewMonth() {
        let model = makeModel()
        XCTAssertEqual(model.currentMonth, YearMonth(year: 2026, month: 11))
        clock = makeDate(2026, 12, 1)
        model.refreshClock()
        XCTAssertEqual(model.currentMonth, YearMonth(year: 2026, month: 12))
    }

    func testRemovingAWordUnmarksItAndSaves() {
        let model = makeModel()
        model.newWord()
        model.markCurrentLearnt()
        model.remove(model.learnt[0])
        XCTAssertTrue(model.learnt.isEmpty)
        XCTAssertEqual(store.load().words["everyday:candid"]?.status, .seen)
    }

    func testADeckIsCompleteOnceEveryWordIsLearntAndNewWordDoesNoHarm() {
        let model = makeModel()
        XCTAssertFalse(model.isDeckComplete)
        model.newWord()
        model.markCurrentLearnt()
        XCTAssertTrue(model.isDeckComplete)
        model.newWord()
        XCTAssertNil(model.currentWord)
        XCTAssertTrue(model.isDeckComplete)
        XCTAssertEqual(model.learnt.map(\.slug), ["candid"])
    }

    func testAFailedSaveIsReported() {
        store = StateStore(url: URL.temporaryDirectory) // a folder cannot be written as a file
        let model = makeModel()
        model.setDeck(.advanced)
        XCTAssertTrue(model.saveFailed)
    }
}
