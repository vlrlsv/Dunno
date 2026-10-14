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
    /// The light disc behind the (always black) mascot, so it reads in both modes.
    static let dunnoMascotStage = Color("MascotStage")
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

/// The black mascot on its light disc. Uses the "Mascot" image asset when one is
/// added to the catalog; until then it draws a simple placeholder character.
struct MascotView: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle().fill(Color.dunnoMascotStage)

            if UIImage(named: "Mascot") != nil {
                Image("Mascot")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.14)
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
