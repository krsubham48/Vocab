import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// The web app's colours, type and corners, so both look the same.
enum Theme {
    static let ink = Color(hex: 0x3D2463)
    static let accent = Color(hex: 0x7C3FB5)
    static let accentStrong = Color(hex: 0x6B2FB3)
    static let muted = Color(hex: 0x6E5798)
    static let meaningFill = Color(hex: 0xF8F4FD)
    static let meaningBorder = Color(hex: 0xE6DAF5)
    static let buttonBorder = Color(hex: 0xB78CEC)
    static let confirmedFill = Color(hex: 0xE9DCF7)
    static let highlightFill = Color(hex: 0xF3ECFB)
    static let remove = Color(hex: 0x9B3D6E)
    static let shadow = Color(hex: 0x7C5CB5)

    static let background = LinearGradient(
        stops: [.init(color: Color(hex: 0xF3ECFB), location: 0),
                .init(color: Color(hex: 0xE9DCF7), location: 0.5),
                .init(color: Color(hex: 0xE0D0F5), location: 1)],
        startPoint: .top, endPoint: .bottom)
    static let barFill = LinearGradient(colors: [Color(hex: 0xF3ECFB), Color(hex: 0xE9DCF7)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing)
    static let gradient = LinearGradient(colors: [Color(hex: 0xA177F0), accentStrong],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)

    static let cardRadius: CGFloat = 20
    static let controlRadius: CGFloat = 14
    static let innerRadius: CGFloat = 10
    /// Keeps lines readable on iPad.
    static let contentWidth: CGFloat = 600

    /// Helvetica, as on the web, growing with the reader's text size setting.
    static func font(_ size: CGFloat, bold: Bool = false, italic: Bool = false) -> Font {
        let name = bold ? "Helvetica-Bold" : italic ? "Helvetica-Oblique" : "Helvetica"
        let style: Font.TextStyle = switch size {
        case ..<12: .caption2
        case ..<14: .footnote
        case ..<16: .subheadline
        case ..<18: .callout
        case ..<20: .body
        case ..<30: .title3
        case ..<40: .title
        default: .largeTitle
        }
        return .custom(name, size: size, relativeTo: style)
    }
}

extension View {
    /// The white rounded card used for words and messages.
    func card(horizontal: CGFloat = 20, vertical: CGFloat = 24) -> some View {
        modifier(CardStyle(horizontal: horizontal, vertical: vertical))
    }
}

private struct CardStyle: ViewModifier {
    let horizontal: CGFloat
    let vertical: CGFloat
    @Environment(\.dynamicTypeSize) private var typeSize

    func body(content: Content) -> some View {
        content
            // very large text needs the width more than the margin
            .padding(.horizontal, typeSize.isAccessibilitySize ? 12 : horizontal)
            .padding(.vertical, vertical)
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .shadow(color: Theme.shadow.opacity(0.18), radius: 8, y: 4)
    }
}

/// Two buttons side by side, stacked once text is too large to share a row.
struct ButtonPair<Content: View>: View {
    @ViewBuilder var content: Content
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        layout { content }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 18)
    }
}

/// A word and its deck, side by side; stacked at accessibility text sizes.
struct WordAndDeck: View {
    let word: Word
    var size: CGFloat = 15
    var nameIdentifier = ""
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 8))
        layout {
            Text(word.word)
                .font(Theme.font(size, bold: true))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(nameIdentifier)
            DeckTag(deck: word.deck)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var size: CGFloat = 15
    var minHeight: CGFloat = 48

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(size, bold: true))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: .infinity)
            .background(Theme.gradient, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
            .shadow(color: Theme.accentStrong.opacity(0.3), radius: 4, y: 3)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var size: CGFloat = 15
    var minHeight: CGFloat = 48
    /// The "Learnt" look: filled, without a border.
    var confirmed = false

    func makeBody(configuration: Configuration) -> some View {
        Content(configuration: configuration, style: self)
    }

    private struct Content: View {
        let configuration: Configuration
        let style: SecondaryButtonStyle
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: Theme.controlRadius)
            configuration.label
                .font(Theme.font(style.size, bold: true))
                .multilineTextAlignment(.center)
                .foregroundStyle(style.confirmed ? Theme.accentStrong : Theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: style.minHeight, maxHeight: .infinity)
                .background(style.confirmed ? Theme.confirmedFill : .white, in: shape)
                .overlay { if !style.confirmed { shape.strokeBorder(Theme.buttonBorder, lineWidth: 2) } }
                .opacity(!isEnabled && !style.confirmed ? 0.45 : configuration.isPressed ? 0.85 : 1)
        }
    }
}

/// A scrolling page with its content in a centred column.
struct ScreenScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 0) { content }
                .frame(maxWidth: Theme.contentWidth)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
        }
    }
}

struct PageTitle: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(Theme.font(20, bold: true))
            .multilineTextAlignment(.center)
            .padding(.bottom, 18)
            .accessibilityAddTraits(.isHeader)
    }
}

struct EmptyCard: View {
    let message: String
    init(_ message: String) { self.message = message }

    var body: some View {
        Text(message)
            .font(Theme.font(16))
            .foregroundStyle(Theme.accent)
            .multilineTextAlignment(.center)
            .card(vertical: 40)
    }
}

struct DeckTag: View {
    let deck: Deck

    var body: some View {
        Text(deck.title.uppercased())
            .font(Theme.font(11, bold: true))
            .kerning(0.9)
            .foregroundStyle(Theme.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

struct MeaningBlock: View {
    let meaning: Meaning
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.controlRadius)
        VStack(alignment: .leading, spacing: 0) {
            Text(meaning.partOfSpeech.uppercased())
                .font(Theme.font(13, bold: true))
                .kerning(0.5)
                .foregroundStyle(Theme.accent)
                .padding(.bottom, 8)
            Text(meaning.definition)
                .font(Theme.font(18))
                .foregroundStyle(Theme.ink)
                .lineSpacing(4)
                .padding(.bottom, 12)
            Text("“\(meaning.example)”")
                .font(Theme.font(16, italic: true))
                .foregroundStyle(Theme.accentStrong)
                .lineSpacing(4)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, typeSize.isAccessibilitySize ? 10 : 16)
        .padding(.vertical, 18)
        .background(Theme.meaningFill, in: shape)
        .overlay { shape.strokeBorder(Theme.meaningBorder) }
        .accessibilityElement(children: .combine)
    }
}

/// Pronunciation and meanings, as shown under a word on every card.
struct WordDetails: View {
    let word: Word
    var alignment: Alignment = .center

    var body: some View {
        VStack(spacing: 0) {
            if let pronunciation = word.displayPronunciation {
                Text(pronunciation)
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: alignment)
                    .padding(.top, 6)
                    .padding(.bottom, 20)
            } else {
                Color.clear.frame(height: 14)
            }
            VStack(spacing: 12) {
                ForEach(Array(word.meanings.enumerated()), id: \.offset) { item in
                    MeaningBlock(meaning: item.element)
                }
            }
        }
    }
}

/// The word itself. Long words shrink to fit on one line.
struct WordTitle: View {
    let word: String

    var body: some View {
        Text(word)
            .font(Theme.font(30, bold: true))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .accessibilityAddTraits(.isHeader)
    }
}
