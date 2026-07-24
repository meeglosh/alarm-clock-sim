import SwiftUI

private struct HUDBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PlayTopPreferenceKey: PreferenceKey {
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

    /// Measured bottom edge of the HUD pills and top edge of the PLAY
    /// button, in screen coordinates. The background art is scaled and
    /// positioned so the baked title through the full clock fits between
    /// them.
    @State private var hudBottom: CGFloat = 0
    @State private var playTop: CGFloat = 0

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
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: PlayTopPreferenceKey.self,
                            value: proxy.frame(in: .global).minY
                        )
                    }
                )

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
        .onPreferenceChange(PlayTopPreferenceKey.self) { playTop = $0 }
        .background {
            ZStack {
                Palette.background
                // The art's hero band (title through clock base) fits
                // between the measured HUD bottom and PLAY top, scaling
                // down with faded edges when the band is tight.
                GeometryReader { geo in
                    FittedSceneArt(
                        layout: SceneImageLayout(
                            container: geo.size,
                            bandTop: hudBottom + 8,
                            bandBottom: playTop - 8
                        )
                    )
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
