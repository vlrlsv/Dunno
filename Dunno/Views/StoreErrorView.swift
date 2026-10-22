import SwiftUI

/// Shown instead of the app when the task store can't be opened.
struct StoreErrorView: View {
    let retry: () -> Void
    let reset: () -> Void

    @State private var isConfirmingReset = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                MascotView(size: 88)

                Text("Couldn't open your tasks")
                    .font(.dunnoDisplay(28))
                    .multilineTextAlignment(.center)

                Text("Try again in a moment. If it keeps happening, reset to start with an empty list.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button("Try again", action: retry)
                    .buttonStyle(PrimaryButtonStyle())

                Button("Reset tasks") { isConfirmingReset = true }
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color.dunnoBase.ignoresSafeArea())
        .confirmationDialog("Reset tasks?", isPresented: $isConfirmingReset, titleVisibility: .visible) {
            Button("Reset tasks", role: .destructive, action: reset)
        } message: {
            Text("Your current tasks can't be read and will be replaced with an empty list.")
        }
    }
}
