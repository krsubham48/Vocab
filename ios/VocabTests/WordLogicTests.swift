import XCTest
@testable import Vocab

final class WordLogicTests: XCTestCase {
    private let abundant = makeWord("abundant")
    private let candid = makeWord("candid")
    private let legerdemain = makeWord("legerdemain", .advanced)
    private var words: [Word] { [abundant, candid, legerdemain] }
    private var generator = SystemRandomNumberGenerator()

    private func learnt(_ list: Word..., on date: String = "2026-11-25") -> AppState {
        var state = AppState()
        for word in list { state.words[word.id] = WordProgress(status: .learnt, learntDate: date) }
        return state
    }

    func testPickNewWordSkipsLearntWordsAndOtherDecks() {
        let result = WordLogic.pickNewWord(from: words, state: learnt(abundant), using: &generator)
        XCTAssertEqual(result.word, candid)
        XCTAssertEqual(result.state.lastShownID, candid.id)
        XCTAssertEqual(result.state.words[candid.id], WordProgress(status: .seen, learntDate: nil))
    }

    func testPickNewWordWhenEveryWordIsLearnt() {
        var state = learnt(abundant, candid)
        state.lastShownID = candid.id
        let result = WordLogic.pickNewWord(from: words, state: state, using: &generator)
        XCTAssertNil(result.word)
        XCTAssertNil(result.state.lastShownID)
        XCTAssertEqual(result.state.words, state.words)
    }

    func testDrawingASeenWordAgainKeepsItsStatus() {
        var state = learnt(abundant)
        state.words[candid.id] = WordProgress(status: .seen, learntDate: nil)
        let result = WordLogic.pickNewWord(from: words, state: state, using: &generator)
        XCTAssertEqual(result.word, candid)
        XCTAssertEqual(result.state.words, state.words)
    }

    func testMarkLearntRecordsTheDate() {
        let state = WordLogic.markLearnt(candid, in: AppState(), today: "2026-11-27")
        XCTAssertEqual(state.words[candid.id], WordProgress(status: .learnt, learntDate: "2026-11-27"))
    }

    func testUnmarkLearntReturnsToSeenAndLeavesOthers() {
        let state = WordLogic.unmarkLearnt(abundant, in: learnt(abundant, candid))
        XCTAssertEqual(state.words[abundant.id], WordProgress(status: .seen, learntDate: nil))
        XCTAssertTrue(state.isLearnt(candid))
    }

    func testUnmarkLearntIgnoresAWordThatIsNotLearnt() {
        XCTAssertEqual(WordLogic.unmarkLearnt(abundant, in: AppState()), AppState())
    }

    func testAWordInBothDecksIsTrackedSeparately() {
        let everyday = makeWord("advocate"), advanced = makeWord("advocate", .advanced)
        let state = WordLogic.markLearnt(everyday, in: AppState(), today: "2026-11-27")
        XCTAssertTrue(state.isLearnt(everyday))
        XCTAssertFalse(state.isLearnt(advanced))
        XCTAssertEqual(WordLogic.progress(of: [everyday, advanced], state: state, deck: .advanced).learnt, 0)
    }

    func testProgressCountsOnlyTheChosenDeck() {
        let progress = WordLogic.progress(of: words, state: learnt(abundant, legerdemain), deck: .everyday)
        XCTAssertEqual(progress.learnt, 1)
        XCTAssertEqual(progress.total, 2)
    }

    func testLearntWordsSpanBothDecks() {
        XCTAssertEqual(WordLogic.learntWords(words, state: learnt(abundant, legerdemain)), [abundant, legerdemain])
    }

    func testLearntByDateGroupsWords() {
        var state = learnt(abundant, candid)
        state.words[legerdemain.id] = WordProgress(status: .learnt, learntDate: "2026-11-26")
        let grouped = WordLogic.learntByDate(words, state: state)
        XCTAssertEqual(grouped["2026-11-25"], [abundant, candid])
        XCTAssertEqual(grouped["2026-11-26"], [legerdemain])
    }

    private let searchable = [
        makeWord("timorous", definitions: ["timid, fearful"], example: "Tallulah broke into tears."),
        makeWord("abundant", name: "abundant", definitions: ["more than enough"]),
        makeWord("candid", definitions: ["frank", "unposed"]),
    ]

    private func found(_ query: String) -> [String] { WordLogic.search(searchable, query: query).map(\.word) }

    func testEmptySearchListsEverythingAlphabeticallyIgnoringCase() {
        XCTAssertEqual(found("   "), ["abundant", "Candid", "Timorous"])
    }

    func testSearchMatchesPartOfAWordIgnoringCaseAndSpaces() {
        XCTAssertEqual(found("  IMOR "), ["Timorous"])
    }

    func testSearchMatchesAnyDefinitionButNotExamples() {
        XCTAssertEqual(found("fearful"), ["Timorous"])
        XCTAssertEqual(found("unposed"), ["Candid"])
        XCTAssertEqual(found("tallulah"), [])
    }

    func testSearchListsNameMatchesBeforeDefinitionMatches() {
        let mixed = [makeWord("alpha", definitions: ["beta"]), makeWord("beta", definitions: ["x"])]
        XCTAssertEqual(WordLogic.search(mixed, query: "beta").map(\.slug), ["beta", "alpha"])
    }
}
