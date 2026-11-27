import SwiftUI

struct AboutView: View {
    let back: () -> Void

    var body: some View {
        ScreenScroll {
            PageTitle("About Vocab").accessibilityIdentifier("about.title")
            VStack(alignment: .leading, spacing: 8) {
                line("Vocab helps you learn English words that turn up in newspapers, magazines, TV and conversation.")

                steps("📖 Learn a new word", [
                    "Choose the **Everyday** or **Advanced** deck at the top.",
                    "Tap **New Word**.",
                    "Read the pronunciation, meaning and example sentence.",
                    "Once you know it, tap **Mark as Learnt**. If you don’t, it can come up again later.",
                ])
                steps("🗂️ Revise with flashcards", [
                    "Read the word and try to recall its meaning.",
                    "Tap the card to check.",
                    "Tap **Got it** or **Still learning** to see the next card. Neither changes your learnt words.",
                ])
                steps("📔 Revisit your words", [
                    "Scroll the list, or search by word or meaning.",
                    "Tap a word to open its card, and tap it again to close it.",
                    "To un-learn a word, open it, tap **Remove** and confirm.",
                ])
                steps("📅 Calendar", [
                    "A dot marks each day when you learnt something.",
                    "Tap a date to see that day’s words.",
                    "Use the arrows beside the month name to see earlier months.",
                ])
                steps("📱 Good to know", numbered: false, [
                    "Revise, Revisit and Calendar show only words you’ve marked as learnt.",
                    "Vocab works offline. There’s no account, and nothing is sent anywhere.",
                    "Your progress is stored on this device. **Deleting the app erases it**, unless you restore a device backup.",
                ])
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()

            Button("Back to start page", action: back)
                .buttonStyle(SecondaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 18)
                .accessibilityIdentifier("about.back")
        }
    }

    private func line(_ text: String) -> some View {
        Text(LocalizedStringKey(text))
            .font(Theme.font(16))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func steps(_ title: String, numbered: Bool = true, _ items: [String]) -> some View {
        Text(title)
            .font(Theme.font(18, bold: true))
            .foregroundStyle(Theme.accentStrong)
            .padding(.top, 14)
            .accessibilityAddTraits(.isHeader)
        ForEach(Array(items.enumerated()), id: \.offset) { item in
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: numbered ? "\(item.offset + 1)." : "•")
                    .font(Theme.font(16))
                    .frame(minWidth: 18, alignment: .trailing)
                line(item.element)
            }
        }
    }
}
