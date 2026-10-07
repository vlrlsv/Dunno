import SwiftUI
import SwiftData

struct RootContentView: View {
    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted }) private var tasks: [TaskItem]
    
    var body: some View {
        @Bindable var appState = appState
        Group {
            if !appState.hasSeenTutorial {
                WelcomeView()
            } else if let activeTask = appState.activeTask(in: tasks) {
                ActiveTaskView(task: activeTask)
            } else {
                MainTabView()
            }
        }
        // Presented here, above the MainTabView/ActiveTaskView swap, so the cover
        // is never orphaned and dismisses directly onto the picked ActiveTaskView.
        .fullScreenCover(isPresented: $appState.isRandomizing) {
            RandomizerView(tasks: tasks)
        }
        .onAppear {
            appState.validateActiveTask(in: tasks)
        }
        .onChange(of: tasks.map(\.id)) { _, _ in
            appState.validateActiveTask(in: tasks)
        }
        .onChange(of: appState.activeTaskId) { _, _ in
            appState.validateActiveTask(in: tasks)
        }
    }
}
