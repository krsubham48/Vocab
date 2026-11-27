import Foundation

/// Saves progress as one JSON file on the device.
struct StateStore {
    let url: URL

    static var standard: StateStore {
        StateStore(url: URL.applicationSupportDirectory.appending(path: "vocab-state.json"))
    }

    func load() -> AppState {
        guard let data = try? Data(contentsOf: url) else { return AppState() }
        if let state = try? JSONDecoder().decode(AppState.self, from: data) { return state }
        // keep what could not be read, so it is not lost when the next save replaces it
        let copy = url.appendingPathExtension("unreadable")
        try? FileManager.default.removeItem(at: copy)
        try? FileManager.default.copyItem(at: url, to: copy)
        return AppState()
    }

    func save(_ state: AppState) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(state).write(to: url, options: .atomic)
    }

    /// The store the app starts with.
    static func forLaunch(environment: [String: String] = ProcessInfo.processInfo.environment) -> StateStore {
        #if DEBUG
        // UI tests use a separate file so they never touch real progress.
        // "reset" starts empty, "keep" reuses it, and JSON seeds it.
        if let mode = environment["VOCAB_TEST_STORE"] {
            let store = StateStore(url: URL.temporaryDirectory.appending(path: "vocab-ui-test.json"))
            if mode != "keep" { try? FileManager.default.removeItem(at: store.url) }
            if mode.hasPrefix("{") { try? Data(mode.utf8).write(to: store.url) }
            return store
        }
        #endif
        return .standard
    }
}
