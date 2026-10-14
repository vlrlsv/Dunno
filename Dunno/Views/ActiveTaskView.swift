import SwiftUI
import SwiftData

struct ActiveTaskView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var saveErrorMessage: String?

    let task: TaskItem

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                MascotView(size: 88)

                VStack(spacing: 10) {
                    Text("Your task")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(task.title)
                        .font(.dunnoDisplay(36))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .lineLimit(4)
                }

                if let start = appState.activeTaskStartDate {
                    Label {
                        Text(start, style: .timer)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "timer")
                    }
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.dunnoOnAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.dunnoAccent, in: Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
            .background(Color.dunnoSurface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 12) {
                Button(action: completeTask) {
                    Label("Done", systemImage: "checkmark")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Not now", action: cancelTask)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color.dunnoBase.ignoresSafeArea())
        .alert("Couldn't Complete Task", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func completeTask() {
        do {
            try TaskStore.complete(task, in: modelContext)
            withAnimation { appState.clearActiveTask() }
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func cancelTask() {
        withAnimation {
            appState.clearActiveTask()
        }
    }
}
