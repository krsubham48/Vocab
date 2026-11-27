import SwiftUI

struct CalendarView: View {
    let model: AppModel
    /// nil means the current month, so the view moves on when a new month starts.
    @State private var pinned: YearMonth?
    @State private var selected: String?
    @Environment(\.verticalSizeClass) private var verticalSize

    var body: some View {
        let current = model.currentMonth
        let shown = pinned.map { min($0, current) } ?? current
        let byDate = model.learntByDate
        ScreenScroll {
            VStack(spacing: 0) {
                header(shown: shown, current: current)
                    .padding(.bottom, 14)
                grid(shown: shown, byDate: byDate)
                if let selected, selected.hasPrefix(CalendarMath.isoPrefix(shown)) {
                    detail(selected, words: byDate[selected] ?? [])
                        .padding(.top, 16)
                }
            }
            // date cells are square, so a narrower calendar is also a shorter one
            .frame(maxWidth: verticalSize == .compact ? 340 : 480)
        }
    }

    private func header(shown: YearMonth, current: YearMonth) -> some View {
        HStack(spacing: 8) {
            arrow("chevron.left", "Previous month", id: "calendar.previous") {
                move(to: CalendarMath.shift(shown, by: -1), current: current)
            }
            Text(verbatim: CalendarMath.title(shown))
                .font(Theme.font(20, bold: true))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("calendar.title")
            arrow("chevron.right", "Next month", id: "calendar.next") {
                move(to: CalendarMath.shift(shown, by: 1), current: current)
            }
            // nothing can have been learnt in a future month
            .disabled(shown >= current)
            .opacity(shown >= current ? 0.35 : 1)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func arrow(_ symbol: String, _ label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.accentStrong)
                .frame(width: 44, height: 44)
                .background(.white, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
                .shadow(color: Theme.accent.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }

    private func move(to target: YearMonth, current: YearMonth) {
        pinned = target < current ? target : nil
        selected = nil
    }

    private func grid(shown: YearMonth, byDate: [String: [Word]]) -> some View {
        let firstWeekday = Calendar.current.firstWeekday
        let cells = CalendarMath.cells(for: shown, firstWeekday: firstWeekday)
        let weeks = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
        // a plain Grid: at most 42 cells, and lazy layouts are what hung Revisit
        return Grid(horizontalSpacing: 3, verticalSpacing: 4) {
            GridRow {
                ForEach(Array(CalendarMath.weekdayLetters(firstWeekday: firstWeekday).enumerated()), id: \.offset) { letter in
                    Text(verbatim: letter.element)
                        .font(Theme.font(11, bold: true))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 6)
                        .accessibilityHidden(true)
                }
            }
            ForEach(Array(weeks.enumerated()), id: \.offset) { week in
                GridRow {
                    ForEach(Array(week.element.enumerated()), id: \.offset) { cell in
                        if let day = cell.element {
                            dayButton(day, in: shown, byDate: byDate)
                        } else {
                            Color.clear.aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        // new identities for a new month, so no cell is reused with the old date
        .id(shown)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.shadow.opacity(0.18), radius: 8, y: 4)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1) // seven columns must still fit
    }

    private func dayButton(_ day: Int, in month: YearMonth, byDate: [String: [Word]]) -> some View {
        let iso = CalendarMath.isoDate(year: month.year, month: month.month, day: day)
        let count = byDate[iso]?.count ?? 0
        let shape = RoundedRectangle(cornerRadius: Theme.innerRadius)
        return Button { selected = iso } label: {
            VStack(spacing: 2) {
                Text(verbatim: "\(day)")
                    .font(Theme.font(15, bold: count > 0))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Circle()
                    .fill(Theme.gradient)
                    .frame(width: 5, height: 5)
                    .opacity(count > 0 ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(count > 0 ? Theme.highlightFill : .clear, in: shape)
            .overlay { if selected == iso { shape.strokeBorder(Theme.accentStrong, lineWidth: 2) } }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day) \(CalendarMath.monthNames[month.month - 1])" + (count > 0 ? ", \(count) learnt" : ""))
        .accessibilityIdentifier("day.\(iso)")
        .accessibilityAddTraits(selected == iso ? .isSelected : [])
    }

    @ViewBuilder
    private func detail(_ iso: String, words: [Word]) -> some View {
        if words.isEmpty {
            EmptyCard("No words learnt on this day.")
        } else {
            let shape = RoundedRectangle(cornerRadius: Theme.controlRadius)
            VStack(spacing: 6) {
                Text(verbatim: "Learnt on \(CalendarMath.longDate(iso))".uppercased())
                    .font(Theme.font(11, bold: true))
                    .kerning(0.9)
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                ForEach(words) { word in
                    WordAndDeck(word: word, nameIdentifier: "calendar.word.\(word.id)")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(minHeight: 48)
                    .background(Theme.meaningFill, in: shape)
                    .overlay { shape.strokeBorder(Theme.meaningBorder) }
                }
            }
            .card()
        }
    }
}
