import SwiftUI

@main
struct VocabApp: App {
    @State private var model = AppModel(words: DeckLoader.bundled(), store: .forLaunch())

    var body: some Scene {
        WindowGroup { RootView(model: model) }
    }
}
