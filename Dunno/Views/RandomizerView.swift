import SwiftUI

struct RandomizerView: View {
    @Environment(\.dismiss) private var dismiss

    let tasks: [TaskItem]
    let onTaskSelected: (TaskItem) -> Void
    
    @State private var displayedTaskIndex = 0
    @State private var isSpinning = true
    
    var body: some View {
        ZStack {
            Color.indigo.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Picking a task...")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(tasks.isEmpty ? "" : tasks[displayedTaskIndex].title)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(height: 200)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .padding()
            }
        }
        .onAppear {
            startSpinning()
        }
    }
    
    private func startSpinning() {
        guard !tasks.isEmpty else {
            dismiss()
            return
        }
        
        let totalSpins = Int.random(in: 20...30)
        var currentSpin = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            withAnimation {
                displayedTaskIndex = (displayedTaskIndex + 1) % tasks.count
            }
            currentSpin += 1
            
            if currentSpin >= totalSpins {
                timer.invalidate()
                isSpinning = false
                
                // Select final task and wait a second before locking it in
                let selectedTask = tasks[displayedTaskIndex]
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onTaskSelected(selectedTask)
                    dismiss()
                }
            }
        }
    }
}
