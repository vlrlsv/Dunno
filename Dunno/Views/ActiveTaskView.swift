import SwiftUI

struct ActiveTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let task: TaskItem
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 50) {
                VStack(spacing: 10) {
                    Text("Your Task")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(task.title)
                        .font(.system(size: 40, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 20) {
                    Button(action: completeTask) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark Complete")
                        }
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(16)
                    }
                    
                    Button(action: cancelTask) {
                        Text("Cancel & Pick Another Later")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private func completeTask() {
        withAnimation {
            task.isCompleted = true
            appState.clearActiveTask()
        }
    }
    
    private func cancelTask() {
        withAnimation {
            appState.clearActiveTask()
        }
    }
}
