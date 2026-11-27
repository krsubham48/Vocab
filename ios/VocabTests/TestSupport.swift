import Foundation
@testable import Vocab

func makeWord(_ slug: String, _ deck: Deck = .everyday, name: String? = nil, pronunciation: String = "pro",
              definitions: [String] = ["meaning"], example: String = "An example.") -> Word {
    Word(slug: slug, word: name ?? slug.capitalized, pronunciation: pronunciation, deck: deck,
         meanings: definitions.map { Meaning(partOfSpeech: "noun", definition: $0, example: example) })
}

func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
    CalendarMath.gregorian.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}
