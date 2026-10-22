import Foundation
import SwiftData

/// The current model version. The app and tests use this alias, so a new
/// schema version only needs to repoint it.
typealias TaskItem = SchemaV1.TaskItem

/// The first released model. Until the app first ships it can change in place;
/// after that it must stay frozen, and changes go in a new schema version.
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [TaskItem.self] }

    @Model
    final class TaskItem {
        @Attribute(.unique) var id: UUID
        var title: String
        var isCompleted: Bool
        var creationDate: Date
        var sortOrder: Int
        /// When the task was marked done; nil while it's open.
        var completionDate: Date?
        /// Seconds from the last start to Done (the final session only).
        var completionDuration: TimeInterval?

        init(title: String, sortOrder: Int = 0) {
            self.id = UUID()
            self.title = title
            self.isCompleted = false
            self.creationDate = Date()
            self.sortOrder = sortOrder
        }
    }
}

/// Add each new schema version here, with a stage migrating from the previous one.
enum DunnoMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
