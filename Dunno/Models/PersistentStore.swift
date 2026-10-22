import Foundation
import SwiftData

/// Opens the task store without crashing when it can't be read. A failure is
/// kept in `result` so the app can offer Retry (for temporary problems such
/// as a full disk) or Reset (for an unreadable store).
@MainActor
@Observable
final class PersistentStore {
    private(set) var result: Result<ModelContainer, any Error>
    private let schema: Schema
    private let configuration: ModelConfiguration

    init(url: URL? = nil) {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = url.map { ModelConfiguration(schema: schema, url: $0) }
            ?? ModelConfiguration(schema: schema)
        self.schema = schema
        self.configuration = configuration
        result = Self.open(schema, configuration)
    }

    func retry() {
        result = Self.open(schema, configuration)
    }

    /// Moves the store files aside, never deleting them, and opens an empty store.
    func reset() {
        do {
            try Self.moveAside(configuration.url)
            retry()
        } catch {
            result = .failure(error)
        }
    }

    private static func open(_ schema: Schema, _ configuration: ModelConfiguration) -> Result<ModelContainer, any Error> {
        Result {
            try ModelContainer(for: schema, migrationPlan: DunnoMigrationPlan.self, configurations: configuration)
        }
    }

    private static func moveAside(_ url: URL) throws {
        let backup = url.path + ".corrupt-\(Int(Date().timeIntervalSince1970))"
        for suffix in ["", "-wal", "-shm"] where FileManager.default.fileExists(atPath: url.path + suffix) {
            try FileManager.default.moveItem(atPath: url.path + suffix, toPath: backup + suffix)
        }
    }
}
