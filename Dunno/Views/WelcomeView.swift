import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            BouncingMascot(size: 230)

            // Only the app name is bold; the rest of the line stays regular.
            Text("Don't know where to start?\n\(Text("Dunno").fontWeight(.heavy)) knows!")
                .font(.system(size: 30, weight: .regular, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.top, 40)
                .padding(.horizontal, 24)

            Spacer()

            Button("Get started") {
                withAnimation {
                    appState.completeTutorial()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.dunnoBase.ignoresSafeArea())
    }
}

