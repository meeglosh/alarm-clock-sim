import SwiftUI

private struct HUDBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Idle-phase home screen over the full title artwork: HUD, PLAY,
/// leaderboard/settings, daily challenge, tab bar.
struct MainMenuView: View {
    @Environment(GameViewModel.self) private var game
    var onSheet: (GameSheet) -> Void
    var onPlay: () -> Void

    /// Measured bottom edge of the HUD pills in screen coordinates; the
    /// background art is pushed down so the baked title clears it.
    @State private var hudBottom: CGFloat = 0

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                HUDBar(onRankTap: { onSheet(.leaderboard) })
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: HUDBottomPreferenceKey.self,
                                value: proxy.frame(in: .global).maxY
                            )
                        }
                    )
                Spacer()
                Button {
                    onPlay()
                } label: {
                    HStack(spacing: 10) {
                        Text("PLAY")
                        Image(systemName: "play.circle.fill")
                    }
                }
                .buttonStyle(ChunkyButtonStyle(style: .gold, height: 62))

                HStack(spacing: 12) {
                    Button {
                        onSheet(.leaderboard)
                    } label: {
                        Label("LEADERBOARD", systemImage: "trophy.fill")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                    }
                    .buttonStyle(ChunkyButtonStyle(style: .blue, height: 48))

                    Button {
                        onSheet(.settings)
                    } label: {
                        Label("SETTINGS", systemImage: "gearshape.fill")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                    }
                    .buttonStyle(ChunkyButtonStyle(style: .purple, height: 48))
                }

                DailyChallengeBar()
                GameTabBar { tab in
                    switch tab {
                    case .shop: onSheet(.shop)
                    case .missions: onSheet(.missions)
                    case .collection: onSheet(.collection)
                    case .stats: onSheet(.stats)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentColumn()
        }
        .onPreferenceChange(HUDBottomPreferenceKey.self) { hudBottom = $0 }
        .background {
            ZStack {
                Palette.background
                // Top-anchored fill: when tall screens (iPad) crop the art,
                // sacrifice the table edge, never the title. The art is then
                // pushed down until the baked title (with its lightning-bolt
                // accents, starting at ~7.5% of the art's height) clears the
                // measured HUD bottom; the revealed top strip is dark and
                // blends into the backdrop.
                GeometryReader { geo in
                    let scale = max(geo.size.width / 852, geo.size.height / 1847)
                    let titleTop = 0.075 * 1847 * scale
                    Image("bgMain")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .clipped()
                        .offset(y: max(0, hudBottom + 14 - titleTop))
                }
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.58),
                        .init(color: Palette.background.opacity(0.95), location: 0.80),
                        .init(color: Palette.background, location: 0.97),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }
}
