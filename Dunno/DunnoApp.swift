import SwiftUI
import SwiftData

@main
struct DunnoApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environment(appState)
        }
        .modelContainer(for: TaskItem.self)
    }
}
