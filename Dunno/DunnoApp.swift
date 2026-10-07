import SwiftUI
import SwiftData

@main
struct DunnoApp: App {
    @State private var appState: AppState
    private let container: ModelContainer

    init() {
        // UI tests get isolated stores that survive relaunch within one test.
        #if DEBUG
        if let value = ProcessInfo.processInfo.environment["DUNNO_UI_TEST_ID"],
           let testID = UUID(uuidString: value) {
            let name = "DunnoUITests.\(testID.uuidString)"
            let defaults = UserDefaults(suiteName: name)!
            _appState = State(initialValue: AppState(defaults: defaults))
            container = try! ModelContainer(
                for: TaskItem.self,
                configurations: ModelConfiguration(
                    url: URL.temporaryDirectory.appendingPathComponent("\(name).store")
                )
            )
            return
        }
        #endif
        _appState = State(initialValue: AppState())
        container = try! ModelContainer(for: TaskItem.self)
    }

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environment(appState)
        }
        .modelContainer(container)
    }
}
