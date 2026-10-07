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
    }
    
    func completeTutorial() {
        hasSeenTutorial = true
    }
    
    func setActiveTask(_ task: TaskItem) {
        activeTaskId = task.id
    }
    
    func clearActiveTask() {
        activeTaskId = nil
    }
}
