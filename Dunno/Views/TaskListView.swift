import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted }, sort: \TaskItem.sortOrder) private var tasks: [TaskItem]

    @State private var newTaskTitle: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(tasks) { task in
                        TaskRow(task: task, onDelete: { delete(task) })
                    }
                    .onDelete(perform: deleteTasks)
                    .onMove(perform: moveTasks)

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
            .toolbar {
                if !tasks.isEmpty {
                    EditButton()
                }
            }
        }
    }
    
    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, tasks.count < 8 else { return }
        let nextOrder = (tasks.map(\.sortOrder).max() ?? -1) + 1
        let newTask = TaskItem(title: title, sortOrder: nextOrder)
        modelContext.insert(newTask)
        newTaskTitle = ""
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        var reordered = tasks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, task) in reordered.enumerated() {
            task.sortOrder = index
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tasks[index])
        }
    }

    private func delete(_ task: TaskItem) {
        modelContext.delete(task)
    }
}

/// An inline-editable task row. Edits to `title` persist automatically because
/// `TaskItem` is a SwiftData `@Model`. Clearing the title and committing removes
/// the task.
private struct TaskRow: View {
    @Bindable var task: TaskItem
    let onDelete: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Task", text: $task.title)
            .focused($isFocused)
            .submitLabel(.done)
            .onChange(of: isFocused) { _, focused in
                guard !focused else { return }
                task.title = task.title.trimmingCharacters(in: .whitespaces)
                if task.title.isEmpty {
                    onDelete()
                }
            }
    }
}
