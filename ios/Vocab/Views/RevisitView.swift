import SwiftUI

/// Every learnt word as a searchable list; tap a row to open its card.
struct RevisitView: View {
    let model: AppModel
    @Binding var isSearching: Bool
    @State private var query = ""
    @State private var open: Set<String> = []
    @State private var pendingRemoval: Word?
    @FocusState private var focused: Bool

    var body: some View {
        let learnt = model.learnt
        VStack(spacing: 0) {
            if learnt.isEmpty {
                ScreenScroll { EmptyCard("Learn and mark some words first!") }
            } else {
                let results = WordLogic.search(learnt, query: query)
                header(found: results.count, total: learnt.count)
                // A List rather than a lazy stack: SwiftUI's lazy stack could lay out
                // forever when scrolling past an opened card taller than the screen.
                List {
                    ForEach(results) { word in row(word).plainListRow() }
                    if results.isEmpty { EmptyCard("No matching words.").plainListRow() }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 0)
                .contentMargins(.bottom, 24, for: .scrollContent)
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .onChange(of: focused) { _, isFocused in isSearching = isFocused }
        .onChange(of: learnt.isEmpty) { _, isEmpty in
            if isEmpty {
                focused = false
                isSearching = false
                query = ""
            }
        }
        .alert(
            "Remove “\(pendingRemoval?.word ?? "")” from your learnt words?",
            isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }),
            presenting: pendingRemoval
        ) { word in
            Button("Remove", role: .destructive) {
                open.remove(word.id)
                model.remove(word)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func header(found: Int, total: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.controlRadius)
        let searching = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    TextField("Search words or meanings", text: $query)
                        .font(Theme.font(16))
                        .focused($focused)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .accessibilityIdentifier("revisit.search")
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.muted)
                        }
                        .accessibilityLabel("Clear search")
                        .accessibilityIdentifier("revisit.clear")
                    }
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(.white, in: shape)
                .overlay { shape.strokeBorder(focused ? Theme.accentStrong : Theme.buttonBorder, lineWidth: 2) }

                if focused {
                    Button("Done") { focused = false }
                        .font(Theme.font(15, bold: true))
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("revisit.done")
                }
            }
            Text(verbatim: searching ? "\(found) of \(total) words" : "\(total) learnt \(total == 1 ? "word" : "words")")
                .font(Theme.font(13, bold: true))
                .foregroundStyle(Theme.accent)
                .accessibilityIdentifier("revisit.count")
        }
        .frame(maxWidth: Theme.contentWidth)
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2) // leaves room for the list
    }

    private func row(_ word: Word) -> some View {
        let isOpen = open.contains(word.id)
        return VStack(spacing: 0) {
            Button {
                if isOpen { open.remove(word.id) } else { open.insert(word.id) }
            } label: {
                HStack(spacing: 8) {
                    // an opened word reads as its card's title
                    WordAndDeck(word: word, size: isOpen ? 20 : 15)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.muted)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minHeight: 48)
                .contentShape(Rectangle())
            }
            // borderless, so each button in a list row handles only its own tap
            .buttonStyle(.borderless)
            .foregroundStyle(Theme.ink)
            .accessibilityIdentifier("revisit.row.\(word.id)")
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")

            if isOpen {
                VStack(spacing: 6) {
                    WordDetails(word: word, alignment: .leading)
                    Button { pendingRemoval = word } label: {
                        Text("Remove")
                            .font(Theme.font(15, bold: true))
                            .foregroundStyle(Theme.remove)
                            .padding(.horizontal, 20)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                        .accessibilityLabel("Remove \(word.word) from learnt words")
                        .accessibilityIdentifier("revisit.remove.\(word.id)")
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
            }
        }
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
        .shadow(color: Theme.accent.opacity(0.1), radius: 4, y: 2)
    }
}

private extension View {
    /// A bare list row, without separator or background, in the centred column.
    func plainListRow() -> some View {
        frame(maxWidth: Theme.contentWidth)
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
