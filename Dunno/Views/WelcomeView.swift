import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            MascotView(size: 176)

            Text("Can't decide?\nDunno will.")
                .font(.dunnoDisplay(40))
                .multilineTextAlignment(.center)
                .padding(.top, 40)

            Text("List up to 8 things you could do. Dunno picks one, and you stick with it until it's done.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.horizontal, 32)

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
