import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Sync")) {
                    Text("Cloud sync settings will be available in a future update.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
