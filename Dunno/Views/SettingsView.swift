import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Label("Follows your iPhone's light or dark setting", systemImage: "circle.lefthalf.filled")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .listRowBackground(Color.dunnoSurface)

                Section("Sync") {
                    Label("Cloud sync is coming in a future update", systemImage: "icloud")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .listRowBackground(Color.dunnoSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.dunnoBase.ignoresSafeArea())
            .navigationTitle("Settings")
        }
    }
}
