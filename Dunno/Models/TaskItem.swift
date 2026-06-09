import Foundation
import SwiftData

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
