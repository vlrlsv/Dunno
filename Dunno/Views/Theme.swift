import SwiftUI

/// Dunno's palette, built on a 60/30/10 split. Each color is an asset-catalog
/// color set with light and dark variants, so the app follows the system setting.
extension Color {
    /// 60% — screen backgrounds.
    static let dunnoBase = Color("Base")
    /// 30% — cards, rows, fields.
    static let dunnoSurface = Color("Surface")
    /// 10% — primary actions and highlights. Black in light mode; flips to warm
    /// white in dark mode, where black would disappear into the background.
    static let dunnoAccent = Color("AccentColor")
    /// Text and icons drawn on top of `dunnoAccent`.
    static let dunnoOnAccent = Color("OnAccent")
}

extension Font {
    /// Rounded display type for headlines and task titles.
    static func dunnoDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

/// Full-width accent capsule — the one main action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Color.dunnoOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.dunnoAccent, in: Capsule())
            .opacity(isEnabled ? 1 : 0.35)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// Quiet companion to `PrimaryButtonStyle` for the secondary choice.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.dunnoSurface, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// The black mascot, free-standing. Uses the "Mascot" image asset when one is
/// added to the catalog; until then it draws a simple placeholder character.
struct MascotView: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            if UIImage(named: "Mascot") != nil {
                Image("Mascot")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.04)
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
            .fill(Color.black)
            .frame(width: size * 0.5, height: size * 0.46)
            .overlay {
                HStack(spacing: size * 0.1) {
                    eye
                    eye
                }
                .offset(y: -size * 0.03)
            }
            .offset(y: size * 0.04)
    }

    private var eye: some View {
        Capsule()
            .fill(Color.white)
            .frame(width: size * 0.07, height: size * 0.1)
    }
}

/// The mascot's idle loop: a small hop with squash and stretch, and a ground
/// shadow that shrinks while it's in the air. Everything scales with `size`.
struct BouncingMascot: View {
    var size: CGFloat = 230

    private enum Phase: CaseIterable {
        case land, rest, crouch, jump
    }

    var body: some View {
        PhaseAnimator(Phase.allCases) { phase in
            ZStack(alignment: .bottom) {
                // The feet sit ~86% down the artwork, so the shadow is lifted to meet them.
                Ellipse()
                    .fill(Color.primary.opacity(phase == .jump ? 0.07 : 0.14))
                    .frame(width: phase == .jump ? size * 0.38 : size * 0.55, height: size * 0.06)
                    .offset(y: -size * 0.12)

                MascotView(size: size)
                    .scaleEffect(x: phase == .crouch ? 1.06 : (phase == .jump ? 0.96 : 1),
                                 y: phase == .crouch ? 0.92 : (phase == .jump ? 1.05 : 1),
                                 anchor: .bottom)
                    .offset(y: phase == .jump ? -size * 0.11 : 0)
            }
        } animation: { phase in
            switch phase {
            case .land: .easeIn(duration: 0.28)       // fall back down
            case .rest: .linear(duration: 1.1)        // pause between hops
            case .crouch: .easeOut(duration: 0.16)    // squash before jumping
            case .jump: .easeOut(duration: 0.32)      // stretch and rise
            }
        }
    }
}

/// A comic-style thought bubble: a rounded cloud with no tail, plus a trail of
/// shrinking dots leading to the mascot, either below it or to its right.
struct ThoughtBubble: View {
    enum Trail { case bottom, trailing }

    let text: String
    var trail: Trail = .bottom

    var body: some View {
        let bubble = Text(text)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.dunnoOnAccent)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.dunnoAccent, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

        switch trail {
        case .bottom:
            VStack(spacing: 4) {
                bubble
                dot(9).offset(x: 6)
                dot(5).offset(x: 12)
            }
        case .trailing:
            HStack(spacing: 4) {
                bubble
                dot(9).offset(y: 6)
                dot(5).offset(y: 12)
            }
        }
    }

    private func dot(_ size: CGFloat) -> some View {
        Circle()
            .fill(Color.dunnoAccent)
            .frame(width: size, height: size)
    }
}

/// Where the horn's mouth sits inside a `MascotView`, relative to its centre,
/// as a fraction of the view's size. Sound waves and confetti start here.
enum MascotHorn {
    static func mouth(in size: CGFloat) -> CGSize {
        CGSize(width: -0.40 * size, height: -0.01 * size)
    }
}

/// Curved sound waves pulsing out of the mascot's horn, to the left.
struct HornSoundWaves: View {
    var size: CGFloat

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    // Each wave grows outward and fades, staggered by a third of a cycle.
                    let phase = (t * 2.2 + Double(index) / 3).truncatingRemainder(dividingBy: 1)
                    Circle()
                        .trim(from: 0.40, to: 0.60)   // the left-facing arc
                        .stroke(Color.primary.opacity(0.55 * (1 - phase)),
                                style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                        .frame(width: size * (0.18 + 0.42 * phase), height: size * (0.18 + 0.42 * phase))
                }
            }
        }
        .frame(width: size * 0.7, height: size * 0.7)
        .offset(MascotHorn.mouth(in: size))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A one-shot party-popper burst of confetti, fired up and to the left out of
/// the mascot's horn, then falling under gravity and fading out. Each piece is
/// its own small view driven by one animated clock, so it stays cheap to render.
struct HornConfetti: View {
    var size: CGFloat

    fileprivate struct Piece: Identifiable {
        let id = UUID()
        let angle: Double, speed: Double, spin: Double, length: CGFloat
        let isDot: Bool, color: Color
    }

    private static let duration = 1.4

    @State private var time = 0.0
    @State private var pieces: [Piece] = (0..<48).map { _ in
        let colors: [Color] = [.pink, .yellow, .orange, .mint, .cyan, .purple, Color.dunnoAccent]
        return Piece(angle: .pi + 0.85 + Double.random(in: -0.6...0.6),    // up and to the left
                     speed: Double.random(in: 260...560),
                     spin: Double.random(in: -12...12),
                     length: CGFloat.random(in: 6...12),
                     isDot: Bool.random(),
                     color: colors.randomElement()!)
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                Group {
                    if piece.isDot {
                        Circle().frame(width: piece.length / 1.5, height: piece.length / 1.5)
                    } else {
                        RoundedRectangle(cornerRadius: 1.5).frame(width: piece.length, height: 4)
                    }
                }
                .foregroundStyle(piece.color)
                .modifier(ConfettiFlight(time: time, piece: piece, duration: Self.duration))
            }
        }
        .frame(width: 1, height: 1)
        .offset(MascotHorn.mouth(in: size))
        .onAppear {
            withAnimation(.linear(duration: Self.duration)) { time = Self.duration }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Ballistic flight for one confetti piece; `time` is animated, so SwiftUI
/// interpolates it every frame and the piece follows the arc.
private struct ConfettiFlight: ViewModifier, Animatable {
    var time: Double
    let piece: HornConfetti.Piece
    let duration: Double

    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func body(content: Content) -> some View {
        let gravity = 820.0
        let x = cos(piece.angle) * piece.speed * time
        let y = sin(piece.angle) * piece.speed * time + 0.5 * gravity * time * time
        content
            .rotationEffect(.radians(piece.spin * time))
            .offset(x: x, y: y)
            .opacity(max(0, 1 - time / duration))
    }
}
