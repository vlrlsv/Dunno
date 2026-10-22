import SwiftUI
import SwiftData

@main
struct DunnoApp: App {
    @State private var appState: AppState
    @State private var store: PersistentStore

    init() {
        // UI tests get isolated stores that survive relaunch within one test.
        #if DEBUG
        if let value = ProcessInfo.processInfo.environment["DUNNO_UI_TEST_ID"],
           let testID = UUID(uuidString: value) {
            let name = "DunnoUITests.\(testID.uuidString)"
            let defaults = UserDefaults(suiteName: name)!
            _appState = State(initialValue: AppState(defaults: defaults))
            _store = State(initialValue: PersistentStore(
                url: URL.temporaryDirectory.appendingPathComponent("\(name).store")
            ))
            return
        }
        #endif
        _appState = State(initialValue: AppState())
        _store = State(initialValue: PersistentStore())
    }

    var body: some Scene {
        WindowGroup {
            switch store.result {
            case .success(let container):
                RootContentView()
                    .environment(appState)
                    .modelContainer(container)
            case .failure:
                StoreErrorView(retry: store.retry, reset: store.reset)
            }
        }
    }
}
