import SwiftUI

/// The start page: no bottom bar.
struct HomeView: View {
    let go: (Screen) -> Void
    @Environment(\.verticalSizeClass) private var verticalSize
    @Environment(\.dynamicTypeSize) private var typeSize

    private var compact: Bool { verticalSize == .compact }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    title
                    tagline
                        .font(Theme.font(16))
                        .foregroundStyle(Theme.accent)
                        .multilineTextAlignment(.center)
                        // wrap onto two lines on narrow phones rather than cut off
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, compact ? 10 : 18)
                        .padding(.bottom, compact ? 16 : 40)
                    mainButtons
                    links
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, compact ? 14 : 28)
                }
                .frame(maxWidth: Theme.contentWidth)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
    }

    /// One line where it fits, otherwise broken after the comma.
    private var tagline: some View {
        ViewThatFits(in: .horizontal) {
            Text("Build your English vocabulary, one word at a time.").lineLimit(1)
            Text("Build your English vocabulary,\none word at a time.")
        }
    }

    private var title: some View {
        Text("Vocab")
            .font(Theme.font(compact ? 40 : 56, bold: true))
            .foregroundStyle(Theme.accentStrong)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.bottom, 6)
            // as wide as the word, so the underline spans all of "Vocab"
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.accentStrong).frame(height: compact ? 4 : 5)
            }
            .accessibilityAddTraits(.isHeader)
    }

    private var mainButtons: some View {
        let layout = compact ? AnyLayout(HStackLayout(spacing: 14)) : AnyLayout(VStackLayout(spacing: 14))
        return layout {
            Button { go(.learn) } label: { iconLabel("📖", "Learn") }
                .buttonStyle(PrimaryButtonStyle(size: 18, minHeight: compact ? 52 : 68))
                .accessibilityIdentifier("home.learn")
            Button { go(.practice) } label: { iconLabel("🗂️", "Revise") }
                .buttonStyle(SecondaryButtonStyle(size: 18, minHeight: compact ? 52 : 68))
                .accessibilityIdentifier("home.revise")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var links: some View {
        // side by side, "About Vocab" would break mid-word at very large text
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 14)) : AnyLayout(HStackLayout(spacing: 14))
        return layout {
            link("📋", "About Vocab", to: .about, id: "home.about")
            link("📅", "Calendar", to: .calendar, id: "home.calendar")
        }
    }

    private func iconLabel(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 10) {
            Text(icon).accessibilityHidden(true)
            Text(title)
        }
    }

    private func link(_ icon: String, _ title: String, to screen: Screen, id: String) -> some View {
        Button { go(screen) } label: {
            HStack(spacing: 8) {
                Text(icon).accessibilityHidden(true)
                Text(title).multilineTextAlignment(.center)
            }
            .font(Theme.font(15, bold: true))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 48, maxHeight: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

/// "Revise" from the start page: flashcards or the full list.
struct PracticeView: View {
    let go: (Screen) -> Void

    var body: some View {
        ScreenScroll {
            PageTitle("How would you like to revise?")
            VStack(spacing: 14) {
                choice("🗂️ Revise", "Test yourself with flashcards.", to: .revise, id: "practice.revise")
                choice("📔 Revisit", "Browse and search every word you’ve learnt.", to: .revisit, id: "practice.revisit")
            }
        }
    }

    private func choice(_ title: String, _ detail: String, to screen: Screen, id: String) -> some View {
        Button { go(screen) } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(Theme.font(20, bold: true))
                Text(detail).font(Theme.font(15)).foregroundStyle(Theme.accent)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}
