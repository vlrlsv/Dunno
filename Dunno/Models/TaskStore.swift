import SwiftData

@MainActor
enum TaskStore {
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
