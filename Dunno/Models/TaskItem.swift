import Foundation
import SwiftData

/// The current model version. The app and tests use this alias, so a new
/// schema version only needs to repoint it.
typealias TaskItem = SchemaV1.TaskItem

/// The original model. It must stay field-for-field identical so stores
/// created before versioning are recognized as V1.
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
