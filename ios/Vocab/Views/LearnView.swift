import SwiftUI

struct LearnView: View {
    let model: AppModel

    var body: some View {
        ScrollViewReader { scroller in
            ScreenScroll {
                deckPicker.id("top")

                let progress = model.progress
                Text(verbatim: "\(progress.learnt) / \(progress.total) learnt")
                    .font(Theme.font(13, bold: true))
                    .foregroundStyle(Theme.accent)
                    .padding(.bottom, 14)
                    .accessibilityIdentifier("learn.progress")

                if let word = model.currentWord {
                    wordCard(word)
                } else if model.isDeckComplete {
                    EmptyCard("You’ve learnt every word in this deck!")
                } else {
                    EmptyCard("Press “New Word” to start learning.")
                }

                buttons
            }
            // a new word should be read from its top
            .onChange(of: model.state.lastShownID) { _, _ in scroller.scrollTo("top", anchor: .top) }
        }
    }

    private var deckPicker: some View {
        HStack(spacing: 0) {
            ForEach(Deck.allCases, id: \.self) { deck in
                let active = deck == model.state.activeDeck
                Button { model.setDeck(deck) } label: {
                    Text(deck.title)
                        .font(Theme.font(15, bold: true))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(active ? .white : Theme.muted)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            if active { RoundedRectangle(cornerRadius: Theme.innerRadius).fill(Theme.gradient) }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("learn.deck.\(deck.rawValue)")
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(4)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
        .shadow(color: Theme.accent.opacity(0.1), radius: 4, y: 2)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1) // two names share one row
        .padding(.bottom, 18)
    }

    private func wordCard(_ word: Word) -> some View {
        VStack(spacing: 0) {
            Text("✦ CURRENT WORD")
                .font(Theme.font(11, bold: true))
                .kerning(0.9)
                .foregroundStyle(Theme.accent)
                .padding(.bottom, 18)
            WordTitle(word: word.word).accessibilityIdentifier("learn.word")
            WordDetails(word: word)
        }
        .card()
    }

    private var buttons: some View {
        let learnt = model.currentWord.map(model.state.isLearnt) ?? false
        return ButtonPair {
            Button("New Word") { model.newWord() }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("learn.newWord")
            Button(learnt ? "✓ Learnt" : "Mark as Learnt") { model.markCurrentLearnt() }
                .buttonStyle(SecondaryButtonStyle(confirmed: learnt))
                .disabled(model.currentWord == nil || learnt)
                .accessibilityIdentifier("learn.markLearnt")
        }
    }
}
