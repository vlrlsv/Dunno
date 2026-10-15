import SwiftUI
import SwiftData

struct ActiveTaskView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var saveErrorMessage: String?
    @State private var isCelebrating = false

    let task: TaskItem

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                CelebratingMascot(isCelebrating: isCelebrating)
                    .zIndex(1)   // confetti flies over the rest of the card

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
            // Ignore taps while the celebration plays, without dimming the buttons.
            .allowsHitTesting(!isCelebrating)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color.dunnoBase.ignoresSafeArea())
        #if DEBUG
        // Design review helper: `-DunnoAutoComplete` presses Done two seconds after appearing.
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-DunnoAutoComplete") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { completeTask() }
            }
        }
        #endif
        .alert("Couldn't Complete Task", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    /// Celebrate first, then save: once the task is completed the app leaves
    /// this screen, so the confetti has to play before that.
    private func completeTask() {
        guard !isCelebrating else { return }
        isCelebrating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            do {
                try TaskStore.complete(task, in: modelContext)
                withAnimation { appState.clearActiveTask() }
            } catch {
                isCelebrating = false
                saveErrorMessage = error.localizedDescription
            }
        }
    }

    private func cancelTask() {
        withAnimation {
            appState.clearActiveTask()
        }
    }
}

/// The active task's mascot. When the task is done it jumps and blows a burst
/// of confetti out of its horn, like a party popper.
private struct CelebratingMascot: View {
    let isCelebrating: Bool
    private let size: CGFloat = 88

    var body: some View {
        MascotView(size: size)
            .keyframeAnimator(initialValue: CGFloat(0), trigger: isCelebrating) { mascot, lift in
                mascot.offset(y: lift)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-30, duration: 0.2)
                    SpringKeyframe(0, duration: 0.55, spring: .bouncy)
                }
            }
            .overlay {
                if isCelebrating {
                    HornConfetti(size: size)
                }
            }
            .sensoryFeedback(.success, trigger: isCelebrating)
    }
}
