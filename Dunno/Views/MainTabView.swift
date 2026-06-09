import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TaskListView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
