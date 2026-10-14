import Foundation
import SwiftUI
import SwiftData

@Observable
final class AppState {
    private let defaults: UserDefaults
    var hasSeenTutorial: Bool {
        didSet {
            defaults.set(hasSeenTutorial, forKey: "hasSeenTutorial")
        }
    }
    
    var activeTaskId: UUID? {
        didSet {
            if let activeTaskId {
                defaults.set(activeTaskId.uuidString, forKey: "activeTaskId")
            } else {
                defaults.removeObject(forKey: "activeTaskId")
            }
        }
    }

    /// When the current active task was picked; drives the elapsed timer.
    var activeTaskStartDate: Date? {
        didSet {
            defaults.set(activeTaskStartDate, forKey: "activeTaskStartDate")
        }
    }

    // Transient: drives the randomizer full-screen cover, presented at the root.
    var isRandomizing: Bool = false
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasSeenTutorial = defaults.bool(forKey: "hasSeenTutorial")
        if let uuidString = defaults.string(forKey: "activeTaskId"), let uuid = UUID(uuidString: uuidString) {
            self.activeTaskId = uuid
        } else {
            self.activeTaskId = nil
        }
        self.activeTaskStartDate = defaults.object(forKey: "activeTaskStartDate") as? Date
    }
    
    func completeTutorial() {
        hasSeenTutorial = true
    }
    
    func setActiveTask(_ task: TaskItem) {
        activeTaskId = task.id
        activeTaskStartDate = Date()
    }
    
    func clearActiveTask() {
        activeTaskId = nil
        activeTaskStartDate = nil
    }

    func activeTask(in tasks: [TaskItem]) -> TaskItem? {
        guard let activeTaskId else { return nil }
        return tasks.first { $0.id == activeTaskId && !$0.isCompleted }
    }

    func validateActiveTask(in tasks: [TaskItem]) {
        if activeTaskId != nil && activeTask(in: tasks) == nil {
            clearActiveTask()
        }
    }
}
