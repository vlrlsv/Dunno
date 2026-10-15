import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted }, sort: \TaskItem.sortOrder) private var tasks: [TaskItem]

    @State private var newTaskTitle: String = ""
    @State private var saveErrorMessage: String?

    private let maxTasks = 8

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if tasks.isEmpty {
                        emptyState
                    }

                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        TaskRow(task: task, number: index + 1, onCommit: { title in saveTitle(title, for: task) })
                    }
                    .onDelete(perform: deleteTasks)
                    .onMove(perform: moveTasks)

                    if tasks.count < maxTasks {
                        addTaskRow
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        SlotsIndicator(filled: tasks.count, total: maxTasks)
                            .padding(.bottom, 8)

                        // Once there are tasks, the mascot moves up between the slots
                        // bar and the list and comments on the work ahead.
                        if !tasks.isEmpty {
                            HStack(alignment: .center, spacing: 2) {
                                Spacer(minLength: 0)
                                ThoughtBubble(text: "I see you have some work to do!", trail: .trailing)
                                BouncingMascot(size: 58)
                            }
                            .transition(.scale(scale: 0.3, anchor: .trailing).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.6), value: tasks.isEmpty)
                }
                .listRowBackground(Color.dunnoSurface)
                .listRowSeparatorTint(Color.dunnoBase)
            }
            .scrollContentBackground(.hidden)
            .background(Color.dunnoBase.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if !tasks.isEmpty {
                    Button(action: pickRandomTask) {
                        Text(tasks.count == 1 ? "Start task" : "Pick for me")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Your tasks")
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

    private var emptyState: some View {
        VStack(spacing: 4) {
            ThoughtBubble(text: "Give me something to pick!")
            BouncingMascot(size: 120)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var addTaskRow: some View {
        HStack(spacing: 12) {
            TextField("Add a task", text: $newTaskTitle)
                .submitLabel(.done)
                .onSubmit {
                    addTask()
                }
            Button(action: addTask) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.dunnoOnAccent)
                    .frame(width: 30, height: 30)
                    .background(Color.dunnoAccent, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty ? 0.3 : 1)
            .accessibilityLabel("Add task")
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
        guard !title.isEmpty, tasks.count < maxTasks else { return }
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

/// Eight pips showing how many of the task slots are in use.
private struct SlotsIndicator: View {
    let filled: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < filled ? Color.dunnoAccent : Color.dunnoSurface)
                    .frame(height: 6)
            }
            Text("\(filled)/\(total)")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.leading, 6)
        }
        .animation(.snappy, value: filled)
        .textCase(nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(filled) of \(total) tasks")
    }
}

/// Keep edits in a draft until committed so autosave cannot persist partial input.
private struct TaskRow: View {
    let task: TaskItem
    let number: Int
    let onCommit: (String) -> Void
    @State private var draftTitle: String

    init(task: TaskItem, number: Int, onCommit: @escaping (String) -> Void) {
        self.task = task
        self.number = number
        self.onCommit = onCommit
        _draftTitle = State(initialValue: task.title)
    }

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color.dunnoBase, in: Circle())
                .accessibilityHidden(true)

            TextField("Task", text: $draftTitle)
                .font(.body.weight(.medium))
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { isFocused = false }
                .onChange(of: isFocused) { _, focused in
                    guard !focused else { return }
                    draftTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    onCommit(draftTitle)
                }
        }
        .padding(.vertical, 4)
    }
}
