#if DEBUG
import SwiftUI
import SwiftData

/// Sample data for Xcode previews: in-memory tasks and an isolated AppState,
/// so previews never touch the real store or UserDefaults.
@MainActor
enum PreviewData {
    nonisolated static let sampleTitles = ["Разобрать почту", "Убраться на столе", "Пробежка"]

    static func container(_ titles: [String] = sampleTitles) -> ModelContainer {
        let container = try! ModelContainer(
            for: TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        for (index, title) in titles.enumerated() {
            container.mainContext.insert(TaskItem(title: title, sortOrder: index))
        }
        return container
    }

    static func tasks(in container: ModelContainer) -> [TaskItem] {
        (try? container.mainContext.fetch(FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
    }

    static func appState() -> AppState {
        let state = AppState(defaults: UserDefaults(suiteName: "DunnoPreview.\(UUID().uuidString)")!)
        state.completeTutorial()
        return state
    }
}

#Preview("1 · Welcome") {
    WelcomeView()
        .environment(PreviewData.appState())
}

#Preview("2 · Tasks") {
    MainTabView()
        .environment(PreviewData.appState())
        .modelContainer(PreviewData.container())
}

#Preview("2 · Tasks — empty") {
    MainTabView()
        .environment(PreviewData.appState())
        .modelContainer(PreviewData.container([]))
}

#Preview("3 · Randomizer") {
    let container = PreviewData.container()
    return RandomizerView(tasks: PreviewData.tasks(in: container))
        .environment(PreviewData.appState())
        .modelContainer(container)
}

#Preview("4 · Active task") {
    let container = PreviewData.container()
    let state = PreviewData.appState()
    let task = PreviewData.tasks(in: container)[0]
    state.setActiveTask(task)
    return ActiveTaskView(task: task)
        .environment(state)
        .modelContainer(container)
}

#Preview("5 · Settings") {
    SettingsView()
}
#endif
