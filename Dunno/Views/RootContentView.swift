import SwiftUI
import SwiftData

struct RootContentView: View {
    @Environment(AppState.self) private var appState
    @Query private var tasks: [TaskItem]
    
    var body: some View {
        @Bindable var appState = appState
        Group {
            if !appState.hasSeenTutorial {
                WelcomeView()
            } else if let activeId = appState.activeTaskId, let activeTask = tasks.first(where: { $0.id == activeId }) {
                ActiveTaskView(task: activeTask)
            } else {
                MainTabView()
            }
        }
        // Presented here, above the MainTabView/ActiveTaskView swap, so the cover
        // is never orphaned and dismisses directly onto the picked ActiveTaskView.
        .fullScreenCover(isPresented: $appState.isRandomizing) {
            RandomizerView(tasks: tasks.filter { !$0.isCompleted })
        }
        .onAppear {
            validateActiveTask()
        }
        .onChange(of: tasks) { _, _ in
            validateActiveTask()
        }
    }
    
    private func validateActiveTask() {
        if let activeId = appState.activeTaskId {
            if !tasks.contains(where: { $0.id == activeId }) {
                appState.clearActiveTask()
            }
        }
    }
}
