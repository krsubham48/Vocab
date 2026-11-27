import Foundation

enum WordStatus: String, Codable { case seen, learnt }

struct WordProgress: Codable, Equatable {
    var status: WordStatus
    /// "yyyy-MM-dd" on the device's calendar day.
    var learntDate: String?
}

/// Everything that is saved between launches.
struct AppState: Codable, Equatable {
    var words: [String: WordProgress] = [:]
    var lastShownID: String?
    var activeDeck: Deck = .everyday

    func isLearnt(_ word: Word) -> Bool { words[word.id]?.status == .learnt }
}

/// Selection, progress and search. No storage or UI, so it is unit tested directly.
enum WordLogic {
    static func pickNewWord<G: RandomNumberGenerator>(
        from words: [Word], state: AppState, using generator: inout G
    ) -> (word: Word?, state: AppState) {
        var next = state
        let eligible = words.filter { $0.deck == state.activeDeck && !state.isLearnt($0) }
        guard let chosen = eligible.randomElement(using: &generator) else {
            next.lastShownID = nil
            return (nil, next)
        }
        if next.words[chosen.id] == nil {
            next.words[chosen.id] = WordProgress(status: .seen, learntDate: nil)
        }
        next.lastShownID = chosen.id
        return (chosen, next)
    }

    static func markLearnt(_ word: Word, in state: AppState, today: String) -> AppState {
        var next = state
        next.words[word.id] = WordProgress(status: .learnt, learntDate: today)
        return next
    }

    static func unmarkLearnt(_ word: Word, in state: AppState) -> AppState {
        guard state.isLearnt(word) else { return state }
        var next = state
        next.words[word.id] = WordProgress(status: .seen, learntDate: nil)
        return next
    }

    static func progress(of words: [Word], state: AppState, deck: Deck) -> (learnt: Int, total: Int) {
        let inDeck = words.filter { $0.deck == deck }
        return (inDeck.filter(state.isLearnt).count, inDeck.count)
    }

    static func learntWords(_ words: [Word], state: AppState) -> [Word] {
        words.filter(state.isLearnt)
    }

    static func learntByDate(_ words: [Word], state: AppState) -> [String: [Word]] {
        var grouped: [String: [Word]] = [:]
        for word in words where state.isLearnt(word) {
            if let date = state.words[word.id]?.learntDate {
                grouped[date, default: []].append(word)
            }
        }
        return grouped
    }

    /// Matches names and definitions. Name matches come first, and each group
    /// is alphabetical.
    static func search(_ words: [Word], query: String) -> [Word] {
        let english = Locale(identifier: "en")
        let sorted = words.sorted {
            switch $0.word.compare($1.word, options: .caseInsensitive, range: nil, locale: english) {
            case .orderedAscending: return true
            case .orderedDescending: return false
            case .orderedSame: return $0.id < $1.id
            }
        }
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return sorted }

        func contains(_ text: String) -> Bool { text.range(of: needle, options: .caseInsensitive) != nil }
        let byName = sorted.filter { contains($0.word) }
        let byDefinition = sorted.filter { word in
            !contains(word.word) && word.meanings.contains { contains($0.definition) }
        }
        return byName + byDefinition
    }
}
