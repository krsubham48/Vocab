import Foundation

enum Deck: String, CaseIterable, Codable {
    case everyday, advanced

    var title: String { self == .everyday ? "Everyday" : "Advanced" }
}

struct Meaning: Codable, Hashable {
    let partOfSpeech: String
    let definition: String
    let example: String
}

struct Word: Identifiable, Hashable {
    /// The id in the word list. Fourteen words appear in both decks, so it is
    /// not unique on its own.
    let slug: String
    let word: String
    let pronunciation: String
    let deck: Deck
    let meanings: [Meaning]

    var id: String { "\(deck.rawValue):\(slug)" }

    /// Some words carry a bracketed "unavailable" placeholder; show nothing for those.
    var displayPronunciation: String? { pronunciation.hasPrefix("(") ? nil : pronunciation }
}

extension Word: Decodable {
    private enum CodingKeys: String, CodingKey {
        case slug = "id", word, pronunciation, deck, meanings
    }
}

private extension Word {
    var isComplete: Bool {
        !slug.isEmpty && !word.isEmpty && !pronunciation.isEmpty && !meanings.isEmpty &&
            meanings.allSatisfy { !$0.partOfSpeech.isEmpty && !$0.definition.isEmpty && !$0.example.isEmpty }
    }
}

enum DeckLoader {
    /// Decodes one deck, dropping any entry that is malformed or incomplete and
    /// keeping the rest.
    static func decode(_ data: Data, deck: Deck) throws -> [Word] {
        struct Lossy: Decodable {
            let word: Word?
            init(from decoder: Decoder) { word = try? Word(from: decoder) }
        }
        return try JSONDecoder().decode([Lossy].self, from: data)
            .compactMap(\.word)
            .filter { $0.deck == deck && $0.isComplete }
    }

    /// Both decks shipped inside the app. A deck that cannot be read is empty
    /// and the other still works.
    static func bundled(in bundle: Bundle = .main) -> [Word] {
        Deck.allCases.flatMap { deck -> [Word] in
            guard let url = bundle.url(forResource: "words-\(deck.rawValue)", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let words = try? decode(data, deck: deck) else { return [] }
            return words
        }
    }
}
