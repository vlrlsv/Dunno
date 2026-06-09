import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted }, sort: \TaskItem.creationDate) private var tasks: [TaskItem]

    @State private var newTaskTitle: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(tasks) { task in
                        Text(task.title)
                    }
                    .onDelete(perform: deleteTasks)
                    
                    if tasks.count < 8 {
                        HStack {
                            TextField("New task...", text: $newTaskTitle)
                                .onSubmit {
                                    addTask()
                                }
                            Button(action: addTask) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                
                if !tasks.isEmpty {
                    Button(action: {
                        appState.isRandomizing = true
                    }) {
                        Text("Pick a Random Task")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("My Tasks (\(tasks.count)/8)")
        }
    }
    
    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, tasks.count < 8 else { return }
        let newTask = TaskItem(title: title)
        modelContext.insert(newTask)
        newTaskTitle = ""
    }
    
    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tasks[index])
        }
    }
}
