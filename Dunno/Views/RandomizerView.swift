import SwiftUI

struct RandomizerView: View {
    @Environment(AppState.self) private var appState

    let tasks: [TaskItem]

    // Wheel geometry. visibleRows is odd so there's a clear center slot.
    private let rowHeight: CGFloat = 84
    private let visibleRows = 5

    @State private var reel: [TaskItem] = []
    @State private var winnerIndex = 0          // index into `reel` we land on
    @State private var offset: CGFloat = 0
    @State private var hasLanded = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo, Color(red: 0.30, green: 0.13, blue: 0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Text(hasLanded ? "Your task" : "Picking a task…")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .contentTransition(.opacity)

                wheel
            }
            .padding(.horizontal, 24)
        }
        .sensoryFeedback(.success, trigger: hasLanded)
        .onAppear(perform: start)
    }

    private var wheel: some View {
        let windowHeight = rowHeight * CGFloat(visibleRows)

        return ZStack {
            // The scrolling strip of task rows.
            VStack(spacing: 0) {
                ForEach(Array(reel.enumerated()), id: \.offset) { index, task in
                    rowView(task, isWinner: hasLanded && index == winnerIndex)
                        .frame(height: rowHeight)
                }
            }
            .offset(y: offset)

            // Fixed selection frame over the center slot.
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white, lineWidth: 3)
                .frame(height: rowHeight - 8)
                .shadow(color: .black.opacity(0.35), radius: 10)
                .allowsHitTesting(false)
        }
        .frame(height: windowHeight)
        .mask(
            // Fade the top and bottom edges so rows dissolve as they spin past.
            // Keep the opaque band tall so all visible rows read clearly.
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .white, location: 0.08),
                    .init(color: .white, location: 0.92),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func rowView(_ task: TaskItem, isWinner: Bool) -> some View {
        Text(task.title)
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .scaleEffect(isWinner ? 1.12 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.55), value: isWinner)
    }

    // Offset that places `reel[index]` in the center slot.
    private func centerOffset(for index: Int) -> CGFloat {
        rowHeight * (CGFloat(reel.count) / 2 - CGFloat(index) - 0.5)
    }

    private func start() {
        guard !tasks.isEmpty else {
            appState.isRandomizing = false
            return
        }

        // Build a long reel by cycling through the tasks many times, then land
        // a few cycles before the end so the center slot is always surrounded
        // by real rows.
        let cycles = 16
        var items: [TaskItem] = []
        for _ in 0..<cycles { items.append(contentsOf: tasks) }

        let winnerPos = Int.random(in: 0..<tasks.count)
        let landingIndex = 13 * tasks.count + winnerPos
        let winnerTask = tasks[winnerPos]

        reel = items
        winnerIndex = landingIndex

        // Start showing the top of the reel, then spin down to the winner.
        offset = centerOffset(for: 2)

        withAnimation(.timingCurve(0.18, 0.0, 0.1, 1.0, duration: 2.8)) {
            offset = centerOffset(for: landingIndex)
        } completion: {
            hasLanded = true
            // Hold on the result briefly, then hand off to ActiveTaskView.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                appState.setActiveTask(winnerTask)
                appState.isRandomizing = false
            }
        }
    }
}
