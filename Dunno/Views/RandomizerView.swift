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
            Color.dunnoBase.ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 2) {
                    ThoughtBubble(text: hasLanded ? "This one!" : "Hmm… let me think…")
                        .contentTransition(.opacity)
                        .animation(.snappy, value: hasLanded)
                    RandomizerMascot(hasLanded: hasLanded)
                }

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
            // Accent fill behind the center slot, revealed once the wheel lands.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.dunnoAccent)
                .frame(height: rowHeight - 8)
                .opacity(hasLanded ? 1 : 0)
                .animation(.snappy, value: hasLanded)

            // The scrolling strip of task rows.
            ReelStrip(offset: offset, count: reel.count, rowHeight: rowHeight, windowHeight: windowHeight) { index in
                rowView(reel[index], isWinner: hasLanded && index == winnerIndex)
            }

            // Fixed selection frame over the center slot.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.dunnoAccent, lineWidth: 3)
                .frame(height: rowHeight - 8)
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
            .font(.dunnoDisplay(28))
            .foregroundStyle(isWinner ? Color.dunnoOnAccent : Color.primary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .scaleEffect(isWinner ? 1.06 : 1.0)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                appState.setActiveTask(winnerTask)
                appState.isRandomizing = false
            }
        }
    }
}

/// The reel of rows. It's `Animatable` on its offset, so every animation frame
/// knows exactly where each row is and can shrink and dim the rows further from
/// the centre slot — no lag between the spin and the highlight.
private struct ReelStrip<Row: View>: View, Animatable {
    var offset: CGFloat
    let count: Int
    let rowHeight: CGFloat
    let windowHeight: CGFloat
    @ViewBuilder let row: (Int) -> Row

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                // Row centre within the window, given the strip is centred and offset.
                let rowCenter = windowHeight / 2 + offset - CGFloat(count) * rowHeight / 2 + (CGFloat(index) + 0.5) * rowHeight
                let distance = min(abs(rowCenter - windowHeight / 2) / rowHeight, 2.5)
                row(index)
                    .frame(height: rowHeight)
                    .scaleEffect(1 - distance * 0.13)
                    .opacity(1 - distance * 0.3)
            }
        }
        .offset(y: offset)
    }
}

/// The randomizer's mascot: quick, excited hops with sound waves from its horn
/// while the wheel spins, then one big happy jump when it lands.
private struct RandomizerMascot: View {
    let hasLanded: Bool
    private let size: CGFloat = 96

    var body: some View {
        MascotView(size: size)
            .phaseAnimator([false, true]) { mascot, up in
                let hopping = up && !hasLanded
                return mascot
                    .scaleEffect(x: hopping ? 0.95 : 1.04, y: hopping ? 1.06 : 0.95, anchor: .bottom)
                    .offset(y: hopping ? -12 : 0)
            } animation: { _ in
                .easeInOut(duration: 0.17)
            }
            .keyframeAnimator(initialValue: CGFloat(0), trigger: hasLanded) { mascot, lift in
                mascot.offset(y: lift)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-36, duration: 0.24)
                    SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                }
            }
            .overlay {
                if !hasLanded {
                    HornSoundWaves(size: size)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: hasLanded)
    }
}
