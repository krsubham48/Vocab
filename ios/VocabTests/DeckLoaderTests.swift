import XCTest
@testable import Vocab

final class DeckLoaderTests: XCTestCase {
    func testBundledDecksLoadCompletely() {
        let words = DeckLoader.bundled()
        XCTAssertEqual(words.filter { $0.deck == .everyday }.count, 294)
        XCTAssertEqual(words.filter { $0.deck == .advanced }.count, 1018)
        XCTAssertEqual(Set(words.map(\.id)).count, words.count, "ids must be unique across both decks")
    }

    func testTheAdvancedDeckSharesNoWordWithEverydayAndPronouncesEveryWord() {
        let words = DeckLoader.bundled()
        let everyday = Set(words.filter { $0.deck == .everyday }.map(\.slug))
        let advanced = words.filter { $0.deck == .advanced }
        XCTAssertTrue(everyday.isDisjoint(with: advanced.map(\.slug)))
        XCTAssertEqual(advanced.filter { $0.displayPronunciation == nil }.map(\.word), [])
    }

    func testInvalidEntriesAreDroppedAndTheRestKept() throws {
        let meaning = #""meanings":[{"partOfSpeech":"noun","definition":"d","example":"e"}]"#
        let json = """
        [{"id":"good","word":"Good","pronunciation":"GUD","deck":"everyday",\(meaning)},
         {"id":"nopron","word":"X","deck":"everyday",\(meaning)},
         {"id":"nomeaning","word":"Y","pronunciation":"p","deck":"everyday","meanings":[]},
         {"id":"wrongdeck","word":"Z","pronunciation":"p","deck":"advanced",\(meaning)},
         "not an object"]
        """
        let words = try DeckLoader.decode(Data(json.utf8), deck: .everyday)
        XCTAssertEqual(words.map(\.slug), ["good"])
    }

    /// The pronunciation dictionary's licence must travel with the app.
    func testThePronunciationLicenceIsBundled() {
        for part in ["Copyright (C) 1993-2015 Carnegie Mellon University",
                     "Redistributions in binary form must reproduce",
                     "THIS SOFTWARE IS PROVIDED BY CARNEGIE MELLON UNIVERSITY"] {
            XCTAssertTrue(Acknowledgements.text.contains(part), part)
        }
    }

    func testPlaceholderPronunciationIsHidden() {
        XCTAssertEqual(makeWord("a", pronunciation: "BASH-fuhl").displayPronunciation, "BASH-fuhl")
        XCTAssertNil(makeWord("a", pronunciation: "(pronunciation unavailable)").displayPronunciation)
    }
}
