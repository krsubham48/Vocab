import SwiftUI

enum Screen: Hashable {
    case home, practice, learn, revise, revisit, calendar, about

    /// The bottom bar entry lit for this screen. The start page has no bar.
    var tab: AppTab? {
        switch self {
        case .home: nil
        case .learn: .learn
        case .practice, .revise: .revise // the Revise/Revisit chooser sits under Revise
        case .revisit: .revisit
        case .calendar: .calendar
        case .about: .about
        }
    }
}

enum AppTab: CaseIterable, Hashable {
    case learn, revise, revisit, calendar, about

    var screen: Screen {
        switch self {
        case .learn: .learn
        case .revise: .revise
        case .revisit: .revisit
        case .calendar: .calendar
        case .about: .about
        }
    }

    var title: String {
        switch self {
        case .learn: "Learn"
        case .revise: "Revise"
        case .revisit: "Revisit"
        case .calendar: "Calendar"
        case .about: "About"
        }
    }

    var icon: String {
        switch self {
        case .learn: "📖"
        case .revise: "🗂️"
        case .revisit: "📔"
        case .calendar: "📅"
        case .about: "📋"
        }
    }
}

struct RootView: View {
    @Bindable var model: AppModel
    @State private var screen = Screen.home
    @State private var visited: [Screen] = [.home]
    @State private var isSearching = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            // visited pages stay alive, so each keeps its place when you come back
            ZStack {
                ForEach(visited, id: \.self) { page in
                    content(for: page)
                        .opacity(page == screen ? 1 : 0)
                        .allowsHitTesting(page == screen)
                        .accessibilityHidden(page != screen)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped() // nothing scrolls behind the status bar

            if let tab = screen.tab, !isSearching {
                BottomBar(selected: tab) { show($0.screen) }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .tint(Theme.accentStrong)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refreshClock() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            model.refreshClock()
        }
        .alert("Couldn’t save your progress", isPresented: $model.saveFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your latest change may be lost when you close the app.")
        }
    }

    private func show(_ next: Screen) {
        model.refreshClock()
        if !visited.contains(next) { visited.append(next) }
        screen = next
    }

    @ViewBuilder
    private func content(for page: Screen) -> some View {
        switch page {
        case .home: HomeView(go: show)
        case .practice: PracticeView(go: show)
        case .learn: LearnView(model: model)
        case .revise: ReviseView(model: model)
        case .revisit: RevisitView(model: model, isSearching: $isSearching)
        case .calendar: CalendarView(model: model)
        case .about: AboutView { show(.home) }
        }
    }
}

struct BottomBar: View {
    let selected: AppTab
    let select: (AppTab) -> Void
    @Environment(\.verticalSizeClass) private var verticalSize

    var body: some View {
        let compact = verticalSize == .compact // a phone held sideways
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button { select(tab) } label: {
                    let layout = compact ? AnyLayout(HStackLayout(spacing: 6)) : AnyLayout(VStackLayout(spacing: 4))
                    layout {
                        Text(tab.icon)
                            .font(.system(size: compact ? 16 : 20))
                            .frame(width: compact ? 28 : 32, height: compact ? 28 : 32)
                            .background {
                                if tab == selected {
                                    RoundedRectangle(cornerRadius: Theme.innerRadius).fill(Theme.gradient)
                                }
                            }
                        Text(tab.title)
                            .font(Theme.font(11, bold: true))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(tab == selected ? Theme.accentStrong : Theme.muted)
                .accessibilityIdentifier("tab.\(tab)")
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(tab == selected ? .isSelected : [])
            }
        }
        .frame(maxWidth: Theme.contentWidth)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .padding(.top, compact ? 4 : 8)
        // phones without a home indicator need their own breathing room
        .padding(.bottom, 6)
        .background {
            Rectangle()
                .fill(Theme.barFill)
                .shadow(color: Theme.accent.opacity(0.15), radius: 6, y: -2)
                // to the screen edges, including past the notch when sideways
                .ignoresSafeArea(edges: [.bottom, .horizontal])
        }
        // like the system tab bar, labels stop growing early so five fit
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}
