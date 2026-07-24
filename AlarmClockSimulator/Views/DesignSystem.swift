import SwiftUI

/// Shared visual language matching the img/ mockups: deep navy night
/// palette, chunky top-lit game buttons, translucent dark panels, LCD
/// digits, and glowing accents.
enum Palette {
    static let background = Color(red: 0.043, green: 0.051, blue: 0.09)
    static let panel = Color(red: 0.078, green: 0.086, blue: 0.122)
    static let panelBorder = Color.white.opacity(0.08)
    static let lcdRed = Color(red: 1.0, green: 0.16, blue: 0.10)
    static let lcdOrange = Color(red: 1.0, green: 0.48, blue: 0.0)
    static let fireOrange = Color(red: 1.0, green: 0.62, blue: 0.11)
    static let cyan = Color(red: 0.21, green: 0.82, blue: 0.91)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.36)
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.31)
}

// MARK: - Buttons

enum ChunkyStyle {
    case gold, blue, purple, smash, snooze

    var gradient: [Color] {
        switch self {
        case .gold: [Color(red: 1.0, green: 0.84, blue: 0.36), Color(red: 0.94, green: 0.63, blue: 0.13)]
        case .blue: [Color(red: 0.33, green: 0.69, blue: 0.94), Color(red: 0.09, green: 0.41, blue: 0.72)]
        case .purple: [Color(red: 0.63, green: 0.36, blue: 0.94), Color(red: 0.42, green: 0.17, blue: 0.85)]
        case .smash: [Color(red: 0.16, green: 0.05, blue: 0.06), Color(red: 0.09, green: 0.025, blue: 0.03)]
        case .snooze: [Color(red: 1.0, green: 0.76, blue: 0.29), Color(red: 1.0, green: 0.48, blue: 0.0)]
        }
    }

    var textColor: Color {
        switch self {
        case .gold, .snooze: Color(red: 0.29, green: 0.16, blue: 0.0)
        case .blue, .purple: .white
        case .smash: Palette.danger
        }
    }

    var borderColor: Color {
        switch self {
        case .gold: Color(red: 0.47, green: 0.29, blue: 0.0)
        case .blue: Color(red: 0.04, green: 0.23, blue: 0.43)
        case .purple: Color(red: 0.24, green: 0.08, blue: 0.5)
        case .smash: Palette.danger.opacity(0.55)
        case .snooze: Color(red: 0.55, green: 0.25, blue: 0.0)
        }
    }
}

struct ChunkyButtonStyle: ButtonStyle {
    var style: ChunkyStyle
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: height * 0.4, weight: .heavy, design: .rounded))
            .foregroundStyle(style.textColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: height * 0.32)
                    .fill(LinearGradient(colors: style.gradient, startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: height * 0.32)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: height * 0.32)
                    .stroke(style.borderColor, lineWidth: 2.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 5, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Panels

struct GamePanel: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(Palette.panel.opacity(0.92), in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Palette.panelBorder, lineWidth: 1)
            )
    }
}

extension View {
    func gamePanel(cornerRadius: CGFloat = 18) -> some View {
        modifier(GamePanel(cornerRadius: cornerRadius))
    }
}

// MARK: - Layout

extension View {
    /// Caps content width on large screens (iPad, landscape) while staying
    /// full-width on phones, keeping buttons and panels readable.
    func contentColumn(maxWidth: CGFloat = 560) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

/// A full-width hero band that never expands its container: the image fills
/// via overlay so its natural width can't blow out ScrollView layouts.
struct HeroImage: View {
    let name: String
    var height: CGFloat = 210

    var body: some View {
        Color.clear
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay(
                Image(name)
                    .resizable()
                    .scaledToFill()
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Palette.panelBorder, lineWidth: 1)
            )
    }
}

// MARK: - Text styles

struct HeadlineGradientText: View {
    let text: String
    var size: CGFloat = 40
    var colors: [Color] = [Color(red: 1.0, green: 0.75, blue: 0.25), Color(red: 0.95, green: 0.42, blue: 0.05)]

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            .shadow(color: .black.opacity(0.85), radius: 2, y: 3)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
    }
}

/// Cyan EKG-styled sub-headline pill ("SIMULATOR", "12 HOURS OF PEACE").
struct AccentPill: View {
    let text: String
    var color: Color = Palette.cyan

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .tracking(3)
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.9), radius: 6)
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .gamePanel(cornerRadius: 12)
    }
}

enum LCDFont {
    /// DSEG 7-segment font when bundled, monospaced fallback otherwise.
    static func digits(_ size: CGFloat) -> Font {
        if UIFont(name: "DSEG7Classic-Bold", size: size) != nil {
            return .custom("DSEG7Classic-Bold", size: size)
        }
        return .system(size: size, weight: .bold, design: .monospaced)
    }
}

// MARK: - HUD

struct HUDBar: View {
    @Environment(GameViewModel.self) private var game
    @Environment(GameCenterManager.self) private var gameCenter
    var onRankTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            streakPill
            rankPill
        }
    }

    private var streakPill: some View {
        HStack(spacing: 8) {
            Text("🔥").font(.system(size: 26))
            VStack(alignment: .leading, spacing: 0) {
                Text("STREAK")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Palette.fireOrange)
                Text("\(game.streak)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("SNOOZES")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            challengeDots
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gamePanel(cornerRadius: 16)
    }

    private var challengeDots: some View {
        HStack(spacing: 4) {
            let progress = game.dailyChallengeProgress()
            ForEach(0..<GameViewModel.dailyChallengeTarget, id: \.self) { index in
                Circle()
                    .fill(index < progress ? Palette.fireOrange : Color.white.opacity(0.15))
                    .frame(width: 9, height: 9)
            }
        }
        .padding(.leading, 4)
    }

    private var rankPill: some View {
        Button(action: onRankTap) {
            HStack(spacing: 8) {
                Text("🏆").font(.system(size: 24))
                VStack(alignment: .leading, spacing: 0) {
                    Text("GLOBAL RANK")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Palette.gold)
                    Text(gameCenter.globalRank.map { "#\($0.formatted())" } ?? "—")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(gameCenter.percentileText ?? "PLAY TO RANK")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gamePanel(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Daily challenge bar

struct DailyChallengeBar: View {
    @Environment(GameViewModel.self) private var game

    var body: some View {
        let progress = game.dailyChallengeProgress()
        let target = GameViewModel.dailyChallengeTarget
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text("DAILY").font(.system(size: 11, weight: .heavy)).foregroundStyle(Palette.cyan)
                Text("CHALLENGE").font(.system(size: 11, weight: .heavy)).foregroundStyle(Palette.cyan)
            }
            Text("⏰").font(.system(size: 20))
            Text("Survive \(target) alarms\nwithout smashing!")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(progress) / \(target)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 90, height: 7)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Palette.cyan)
                            .frame(width: 90 * CGFloat(progress) / CGFloat(target))
                    }
            }
            if progress >= target {
                Text("⭐️").font(.system(size: 20))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .gamePanel(cornerRadius: 16)
    }
}

// MARK: - Tab bar

enum GameTab: String, CaseIterable {
    case shop = "SHOP"
    case missions = "MISSIONS"
    case collection = "COLLECTION"
    case stats = "STATS"

    var icon: String {
        switch self {
        case .shop: "storefront.fill"
        case .missions: "target"
        case .collection: "alarm.fill"
        case .stats: "chart.bar.fill"
        }
    }
}

struct GameTabBar: View {
    var onSelect: (GameTab) -> Void

    var body: some View {
        HStack {
            ForEach(GameTab.allCases, id: \.self) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .gamePanel(cornerRadius: 20)
    }
}

// MARK: - Effects

/// Decaying horizontal/vertical jitter used for the smash camera shake.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 14
    var shakes: CGFloat = 7
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let decay = 1 - animatableData
        let x = travel * decay * sin(animatableData * .pi * shakes * 2)
        let y = travel * 0.6 * decay * cos(animatableData * .pi * shakes * 1.7)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: y))
    }
}

/// Maps fractional coordinates of the 852x1847 mockup scene onto the
/// displayed background so overlays stay glued to image features like the
/// clock's LCD across device sizes.
struct SceneImageLayout {
    /// Title top and clock base as fractions of the artwork's height: the
    /// hero band that must stay visible between the game's UI chrome.
    static let titleTopFraction: CGFloat = 0.072
    static let clockBottomFraction: CGFloat = 0.635

    private static let imageSize = CGSize(width: 852, height: 1847)

    let frame: CGRect

    /// Full-bleed centered fill (used by the smash cinematic).
    init(container: CGSize) {
        let size = Self.imageSize
        let scale = max(container.width / size.width, container.height / size.height)
        let width = size.width * scale
        let height = size.height * scale
        frame = CGRect(
            x: (container.width - width) / 2,
            y: (container.height - height) / 2,
            width: width,
            height: height
        )
    }

    /// Fits the artwork so its hero band (title through clock base) lands
    /// between two measured screen edges: full-width fill when the band is
    /// roomy enough, scaled-down and centered when it isn't. Falls back to
    /// a centered fill until measurements arrive.
    init(container: CGSize, bandTop: CGFloat, bandBottom: CGFloat) {
        let size = Self.imageSize
        let widthScale = max(container.width / size.width, container.height / size.height)
        let bandHeight = bandBottom - bandTop
        let scale: CGFloat
        let y: CGFloat
        if bandTop > 0, bandHeight > 100 {
            let heroFraction = Self.clockBottomFraction - Self.titleTopFraction
            scale = min(widthScale, bandHeight / (heroFraction * size.height))
            y = bandTop - Self.titleTopFraction * size.height * scale
        } else {
            scale = widthScale
            y = (container.height - size.height * scale) / 2
        }
        frame = CGRect(
            x: (container.width - size.width * scale) / 2,
            y: y,
            width: size.width * scale,
            height: size.height * scale
        )
    }

    func rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        CGRect(
            x: frame.minX + x * frame.width,
            y: frame.minY + y * frame.height,
            width: width * frame.width,
            height: height * frame.height
        )
    }
}

/// The bedroom artwork rendered at a SceneImageLayout's frame, with soft
/// side fades so letterboxed layouts blend into the backdrop.
struct FittedSceneArt: View {
    let layout: SceneImageLayout

    var body: some View {
        Image("bgMain")
            .resizable()
            .frame(width: layout.frame.width, height: layout.frame.height)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.05),
                        .init(color: .black, location: 0.95),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            // Dissolve everything below the clock so the art's baked
            // footer (e.g. "TAP TO START") never ghosts behind the UI.
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: SceneImageLayout.clockBottomFraction + 0.02),
                        .init(color: .clear, location: SceneImageLayout.clockBottomFraction + 0.1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .position(x: layout.frame.midX, y: layout.frame.midY)
    }
}
