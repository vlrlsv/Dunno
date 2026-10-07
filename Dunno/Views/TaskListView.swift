import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted }, sort: \TaskItem.sortOrder) private var tasks: [TaskItem]

    @State private var newTaskTitle: String = ""
    @State private var saveErrorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(tasks) { task in
                        TaskRow(task: task, onCommit: { title in saveTitle(title, for: task) })
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
                    Button(action: pickRandomTask) {
                        Text(tasks.count == 1 ? "Start Task" : "Pick a Random Task")
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
            .alert(
                "Couldn't Save Task",
                isPresented: Binding(
                    get: { saveErrorMessage != nil },
                    set: { if !$0 { saveErrorMessage = nil } }
                ),
                presenting: saveErrorMessage
            ) { _ in
                Button("OK", role: .cancel) { saveErrorMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }
    
    private func pickRandomTask() {
        // With a single task there's nothing to randomize — go straight to it.
        if tasks.count == 1, let only = tasks.first {
            appState.setActiveTask(only)
        } else {
            appState.isRandomizing = true
        }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, tasks.count < 8 else { return }
        let nextOrder = (tasks.map(\.sortOrder).max() ?? -1) + 1
        let newTask = TaskItem(title: title, sortOrder: nextOrder)
        do {
            // Save explicitly rather than trusting autosave, so a rejected write
            // surfaces here instead of being silently swallowed by the store.
            try TaskStore.insert(newTask, into: modelContext)
            newTaskTitle = ""
        } catch {
            // Keep the typed title for retry and report the failed write.
            saveErrorMessage = error.localizedDescription
            print("Failed to save new task: \(error)")
        }
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        var reordered = tasks
        reordered.move(fromOffsets: source, toOffset: destination)
        do {
            try TaskStore.reorder(reordered, in: modelContext)
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        do {
            try TaskStore.delete(offsets.map { tasks[$0] }, from: modelContext)
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func saveTitle(_ title: String, for task: TaskItem) {
        do {
            if title.isEmpty {
                try TaskStore.delete([task], from: modelContext)
            } else if title != task.title {
                try TaskStore.updateTitle(task, to: title, in: modelContext)
            }
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

/// Keep edits in a draft until committed so autosave cannot persist partial input.
private struct TaskRow: View {
    let task: TaskItem
    let onCommit: (String) -> Void
    @State private var draftTitle: String

    init(task: TaskItem, onCommit: @escaping (String) -> Void) {
        self.task = task
        self.onCommit = onCommit
        _draftTitle = State(initialValue: task.title)
    }

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Task", text: $draftTitle)
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit { isFocused = false }
            .onChange(of: isFocused) { _, focused in
                guard !focused else { return }
                draftTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                onCommit(draftTitle)
            }
    }
}
