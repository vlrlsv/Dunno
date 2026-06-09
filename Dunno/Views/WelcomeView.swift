import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "dice.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to Dunno")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Add up to 8 tasks to your list, then let the app pick one for you at random. Once a task is picked, you must complete it or cancel it before doing anything else!")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    appState.completeTutorial()
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}
