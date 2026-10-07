import Foundation
import SwiftData
import Testing
@testable import Dunno

@MainActor
struct DunnoTests {
    private enum SaveFailure: Error { case rejected }

    @Test func failedAdditionPreservesOtherPendingChanges() throws {
        let container = try ModelContainer(
            for: TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let edited = TaskItem(title: "Original", sortOrder: 0)
        let moved = TaskItem(title: "Moved", sortOrder: 1)
        let deleted = TaskItem(title: "Deleted", sortOrder: 2)
        for task in [edited, moved, deleted] { context.insert(task) }
        try context.save()

        edited.title = "Edited"
        edited.isCompleted = true
        edited.sortOrder = 1
        moved.sortOrder = 0
        context.delete(deleted)
        let added = TaskItem(title: "Rejected", sortOrder: 2)

        do {
            try TaskStore.insert(added, into: context) { savingContext in
                #expect(savingContext === context)
                #expect(savingContext.insertedModelsArray.contains { ($0 as? TaskItem)?.id == added.id })
                throw SaveFailure.rejected
            }
            Issue.record("Expected the failed save to propagate")
        } catch SaveFailure.rejected {
            // The view can report the original error and retain the input.
        }

        // Saving the surviving changes must not resurrect the failed addition
        // or undo the user's earlier edits, move, completion, or deletion.
        try context.save()
        let reader = ModelContext(container)
        let saved = try reader.fetch(FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\TaskItem.sortOrder)]))
        #expect(saved.map(\.id) == [moved.id, edited.id])
        #expect(saved.last?.title == "Edited")
        #expect(saved.last?.isCompleted == true)
        #expect(saved.last?.sortOrder == 1)
    }

    @Test func successfulAdditionSavesTheNewTask() throws {
        let container = try ModelContainer(
            for: TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let task = TaskItem(title: "New task", sortOrder: 4)
        try TaskStore.insert(task, into: ModelContext(container))
        let saved = try ModelContext(container).fetch(FetchDescriptor<TaskItem>())
        #expect(saved.map(\.id) == [task.id])
        #expect(saved.first?.title == "New task")
        #expect(saved.first?.sortOrder == 4)
    }

    private func withDefaults(_ test: (UserDefaults) throws -> Void) rethrows {
        let name = "DunnoTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try test(defaults)
    }

    @Test func freshStateRequiresOnboarding() {
        withDefaults { defaults in
            let state = AppState(defaults: defaults)
            #expect(!state.hasSeenTutorial)
            #expect(state.activeTaskId == nil)
            #expect(!state.isRandomizing)
        }
    }

    @Test func onboardingSurvivesNewStateInstance() {
        withDefaults { defaults in
            AppState(defaults: defaults).completeTutorial()
            #expect(AppState(defaults: defaults).hasSeenTutorial)
        }
    }

    @Test func activeTaskSurvivesNewStateInstanceAndCanBeCleared() {
        withDefaults { defaults in
            let task = TaskItem(title: "Read")
            let state = AppState(defaults: defaults)
            state.setActiveTask(task)
            let restored = AppState(defaults: defaults)
            #expect(restored.activeTaskId == task.id)
            restored.clearActiveTask()
            #expect(AppState(defaults: defaults).activeTaskId == nil)
            #expect(defaults.object(forKey: "activeTaskId") == nil)
        }
    }

    @Test func malformedActiveIDIsIgnored() {
        withDefaults { defaults in
            defaults.set("invalid UUID", forKey: "activeTaskId")
            #expect(AppState(defaults: defaults).activeTaskId == nil)
        }
    }

    @Test func randomizingIsTransient() {
        withDefaults { defaults in
            let state = AppState(defaults: defaults)
            state.isRandomizing = true
            #expect(!AppState(defaults: defaults).isRandomizing)
        }
    }

    @Test func newTasksHaveIndependentIdentityAndStartIncomplete() {
        let before = Date()
        let first = TaskItem(title: "Read", sortOrder: 3)
        let second = TaskItem(title: "Read")
        #expect(first.id != second.id)
        #expect(first.title == "Read")
        #expect(!first.isCompleted)
        #expect(first.sortOrder == 3)
        #expect(second.sortOrder == 0)
        #expect(first.creationDate >= before && first.creationDate <= Date())
    }

    @Test func savedTasksCanBeReadEditedCompletedAndDeleted() throws {
        let container = try ModelContainer(
            for: TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let first = TaskItem(title: "First", sortOrder: 1)
        let second = TaskItem(title: "Second", sortOrder: 0)
        context.insert(first)
        context.insert(second)
        try context.save()

        let reader = ModelContext(container)
        let saved = try reader.fetch(FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\TaskItem.sortOrder)]))
        #expect(saved.map(\.id) == [second.id, first.id])
        let edited = try #require(saved.first)
        edited.title = "Edited"
        edited.isCompleted = true
        try reader.save()

        let verifier = ModelContext(container)
        let incomplete = try verifier.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { !$0.isCompleted }))
        #expect(incomplete.map(\.id) == [first.id])
        let completed = try verifier.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.isCompleted }))
        #expect(completed.first?.title == "Edited")
        verifier.delete(try #require(completed.first))
        try verifier.save()
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<TaskItem>()) == 1)
    }
}
