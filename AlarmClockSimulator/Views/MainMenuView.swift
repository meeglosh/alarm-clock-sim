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
                // The hero band of the art (title top through the clock's
                // base, 7.2%-63.5% of its height) must fit between the
                // measured HUD bottom and PLAY top. When the band is too
                // short for a full-width fill, the art scales down and
                // letterboxes with soft-faded edges; otherwise it fills the
                // screen width as usual.
                GeometryReader { geo in
                    let titleTopFrac: CGFloat = 0.072
                    let clockBottomFrac: CGFloat = 0.635
                    let widthScale = max(geo.size.width / 852, geo.size.height / 1847)
                    let bandTop = hudBottom + 8
                    let bandBottom = playTop - 8
                    let bandHeight = bandBottom - bandTop
                    let hasMeasurements = hudBottom > 0 && playTop > 0 && bandHeight > 100
                    let fitScale = hasMeasurements
                        ? bandHeight / ((clockBottomFrac - titleTopFrac) * 1847)
                        : widthScale
                    let scale = min(widthScale, fitScale)
                    let width = 852 * scale
                    let height = 1847 * scale
                    let yOffset = hasMeasurements
                        ? bandTop - titleTopFrac * height
                        : 0
                    Image("bgMain")
                        .resizable()
                        .frame(width: width, height: height)
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
                        .position(x: geo.size.width / 2, y: yOffset + height / 2)
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
