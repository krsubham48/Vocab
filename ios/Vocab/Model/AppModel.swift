import Foundation
import Observation

/// What the screens read and the actions they take. Every change is saved at once.
@Observable
final class AppModel {
    let words: [Word]
    private(set) var state: AppState
    private(set) var currentMonth: YearMonth
    var saveFailed = false

    @ObservationIgnored private let store: StateStore
    @ObservationIgnored private let now: () -> Date

    init(words: [Word], store: StateStore, now: @escaping () -> Date = Date.init) {
        self.words = words
        self.store = store
        self.now = now
        state = store.load()
        currentMonth = CalendarMath.month(of: now())
    }

    var currentWord: Word? {
        words.first { $0.id == state.lastShownID && $0.deck == state.activeDeck }
    }

    var progress: (learnt: Int, total: Int) {
        WordLogic.progress(of: words, state: state, deck: state.activeDeck)
    }

    /// Every word in the chosen deck has been learnt.
    var isDeckComplete: Bool {
        let (learnt, total) = progress
        return total > 0 && learnt == total
    }

    var learnt: [Word] { WordLogic.learntWords(words, state: state) }

    var learntByDate: [String: [Word]] { WordLogic.learntByDate(words, state: state) }

    func newWord() {
        var generator = SystemRandomNumberGenerator()
        apply(WordLogic.pickNewWord(from: words, state: state, using: &generator).state)
    }

    func markCurrentLearnt() {
        guard let word = currentWord, !state.isLearnt(word) else { return }
        apply(WordLogic.markLearnt(word, in: state, today: CalendarMath.isoDate(now())))
        refreshClock()
    }

    func setDeck(_ deck: Deck) {
        var next = state
        next.activeDeck = deck
        apply(next)
    }

    func remove(_ word: Word) {
        apply(WordLogic.unmarkLearnt(word, in: state))
    }

    /// Call whenever time may have passed: on resume, at midnight, on navigation.
    func refreshClock() {
        let month = CalendarMath.month(of: now())
        if month != currentMonth { currentMonth = month }
    }

    private func apply(_ next: AppState) {
        state = next
        do {
            try store.save(next)
        } catch {
            saveFailed = true
        }
    }
}
