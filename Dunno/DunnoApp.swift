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
        #if DEBUG
        // Design review helper: `-DunnoSampleTasks N` replaces the open tasks with N samples.
        let arguments = ProcessInfo.processInfo.arguments
        if let flag = arguments.firstIndex(of: "-DunnoSampleTasks"),
           flag + 1 < arguments.count, let count = Int(arguments[flag + 1]) {
            Self.replaceOpenTasks(withSamples: count, in: container.mainContext)
        }
        // `-DunnoOpenScreen randomizer|active` jumps straight to that screen.
        if let flag = arguments.firstIndex(of: "-DunnoOpenScreen"), flag + 1 < arguments.count {
            let open = (try? container.mainContext.fetch(FetchDescriptor<TaskItem>(
                predicate: #Predicate { !$0.isCompleted }, sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
            switch arguments[flag + 1] {
            case "randomizer" where !open.isEmpty:
                appState.clearActiveTask()
                appState.isRandomizing = true
            case "active":
                if let first = open.first { appState.setActiveTask(first) }
            default:
                break
            }
        }
        #endif
    }

    #if DEBUG
    private static func replaceOpenTasks(withSamples count: Int, in context: ModelContext) {
        let samples = ["Разобрать почту", "Убраться на столе", "Пробежка", "Позвонить маме",
                       "Прочитать главу книги", "Полить цветы", "Ответить Ане", "Сходить в магазин"]
        let open = (try? context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { !$0.isCompleted }))) ?? []
        open.forEach(context.delete)
        for (index, title) in samples.prefix(max(0, min(count, 8))).enumerated() {
            context.insert(TaskItem(title: title, sortOrder: index))
        }
        try? context.save()
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environment(appState)
        }
        .modelContainer(container)
    }
}
