import SwiftUI

/// Pages published with the web app. The App Store requires both links in the app.
private enum Links {
    static let privacy = URL(string: "https://krsubham48.github.io/Vocab/privacy.html")!
    static let support = URL(string: "https://krsubham48.github.io/Vocab/support.html")!
}

/// The pronunciation dictionary's licence, which must be shipped with the app.
enum Acknowledgements {
    /// The bundled notice, with its hard-wrapped lines joined into paragraphs.
    static let text: String = {
        guard let url = Bundle.main.url(forResource: "Acknowledgements", withExtension: "txt"),
              let file = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return file.components(separatedBy: "\n\n")
            .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
            .joined(separator: "\n\n")
    }()
}

struct AboutView: View {
    let back: () -> Void
    @State private var showingLicence = false

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
                header("📮 Privacy and help")
                link("Privacy policy", to: Links.privacy, id: "about.privacy")
                link("Help and contact", to: Links.support, id: "about.support")
                Button { showingLicence.toggle() } label: { linkLabel("Acknowledgements") }
                    .accessibilityIdentifier("about.credits")
                    .accessibilityHint(showingLicence ? "Hides the licence" : "Shows the licence")
                if showingLicence {
                    Text(verbatim: Acknowledgements.text)
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("about.licence")
                }
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

    private func header(_ title: String) -> some View {
        Text(title)
            .font(Theme.font(18, bold: true))
            .foregroundStyle(Theme.accentStrong)
            .padding(.top, 14)
            .accessibilityAddTraits(.isHeader)
    }

    /// Opens in the browser; the app itself makes no network requests.
    private func link(_ title: String, to destination: URL, id: String) -> some View {
        Link(destination: destination) { linkLabel(title) }
            .accessibilityIdentifier(id)
    }

    private func linkLabel(_ title: String) -> some View {
        Text(title)
            .font(Theme.font(16, bold: true))
            .underline()
            .foregroundStyle(Theme.accent)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private func steps(_ title: String, numbered: Bool = true, _ items: [String]) -> some View {
        header(title)
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
