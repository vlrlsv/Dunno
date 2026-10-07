import SwiftData

@MainActor
enum TaskStore {
    static func updateTitle(
        _ task: TaskItem, to title: String, in context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        let previous = task.title
        task.title = title
        do { try save(context) }
        catch {
            task.title = previous
            throw error
        }
    }

    static func complete(
        _ task: TaskItem, in context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        let previous = task.isCompleted
        task.isCompleted = true
        do { try save(context) }
        catch {
            task.isCompleted = previous
            throw error
        }
    }

    static func reorder(
        _ tasks: [TaskItem], in context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        let previous = tasks.map(\.sortOrder)
        for (index, task) in tasks.enumerated() { task.sortOrder = index }
        do { try save(context) }
        catch {
            for (task, order) in zip(tasks, previous) { task.sortOrder = order }
            throw error
        }
    }

    static func delete(
        _ tasks: [TaskItem], from context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        for task in tasks { context.delete(task) }
        do { try save(context) }
        catch {
            for task in tasks { context.insert(task) }
            throw error
        }
    }

    static func insert(
        _ task: TaskItem,
        into context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        context.insert(task)
        do {
            try save(context)
        } catch {
            // Discard only this insert. A context-wide rollback would also
            // discard pending edits, moves, completions, and deletions.
            context.delete(task)
            throw error
        }
    }
}
