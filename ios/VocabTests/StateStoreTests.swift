import XCTest
@testable import Vocab

final class StateStoreTests: XCTestCase {
    private var url: URL!

    override func setUp() {
        url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString)/state.json")
    }

    func testNoFileGivesAnEmptyState() {
        XCTAssertEqual(StateStore(url: url).load(), AppState())
    }

    func testSavedStateLoadsBack() throws {
        var state = AppState()
        state.activeDeck = .advanced
        state.lastShownID = "advanced:abase"
        state.words["advanced:abase"] = WordProgress(status: .learnt, learntDate: "2026-11-27")
        try StateStore(url: url).save(state)
        XCTAssertEqual(StateStore(url: url).load(), state)
    }

    func testAnUnreadableFileGivesAnEmptyStateAndKeepsACopy() throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{not json".utf8).write(to: url)
        XCTAssertEqual(StateStore(url: url).load(), AppState())
        let copy = url.appendingPathExtension("unreadable")
        XCTAssertEqual(try String(contentsOf: copy, encoding: .utf8), "{not json")
    }
}
