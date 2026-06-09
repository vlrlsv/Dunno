import Foundation
import SwiftUI
import SwiftData

@Observable
final class AppState {
    var hasSeenTutorial: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenTutorial, forKey: "hasSeenTutorial")
        }
    }
    
    var activeTaskId: UUID? {
        didSet {
            if let activeTaskId {
                UserDefaults.standard.set(activeTaskId.uuidString, forKey: "activeTaskId")
            } else {
                UserDefaults.standard.removeObject(forKey: "activeTaskId")
            }
        }
    }

    // Transient: drives the randomizer full-screen cover, presented at the root.
    var isRandomizing: Bool = false
    
    init() {
        self.hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenTutorial")
        if let uuidString = UserDefaults.standard.string(forKey: "activeTaskId"), let uuid = UUID(uuidString: uuidString) {
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
