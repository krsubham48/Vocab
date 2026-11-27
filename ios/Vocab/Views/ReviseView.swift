import SwiftUI

/// Self-check flashcards over every learnt word. Neither answer changes progress.
struct ReviseView: View {
    let model: AppModel
    @State private var index = 0
    @State private var revealed = false

    var body: some View {
        let pool = model.learnt
        ScrollViewReader { scroller in
            ScreenScroll {
                if pool.isEmpty {
                    EmptyCard("Learn and mark some words first!")
                } else {
                    let word = pool[min(index, pool.count - 1)]
                    if revealed {
                        flashcard(word).id("top")
                        answers(count: pool.count)
                    } else {
                        Button { revealed = true } label: { flashcard(word) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("revise.card")
                            .accessibilityHint("Shows the meaning")
                            .id("top")
                    }
                }
            }
            .onChange(of: index) { _, _ in scroller.scrollTo("top", anchor: .top) }
        }
        // a changed set of learnt words starts the pile again
        .onChange(of: pool.map(\.id)) { _, _ in
            index = 0
            revealed = false
        }
    }

    private func flashcard(_ word: Word) -> some View {
        VStack(spacing: 0) {
            DeckTag(deck: word.deck).padding(.bottom, 10)
            WordTitle(word: word.word)
            if revealed {
                WordDetails(word: word)
            } else {
                Text("Tap to reveal the meaning")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 156)
        .card(vertical: 32)
    }

    private func answers(count: Int) -> some View {
        ButtonPair {
            Button("Got it") { advance(count) }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("revise.gotIt")
            Button("Still learning") { advance(count) }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("revise.stillLearning")
        }
    }

    private func advance(_ count: Int) {
        index = (min(index, count - 1) + 1) % count
        revealed = false
    }
}
