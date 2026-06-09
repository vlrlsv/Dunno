import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var creationDate: Date
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.creationDate = Date()
    }
}
