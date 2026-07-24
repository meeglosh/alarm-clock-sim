import SwiftUI

/// Idle-phase home screen over the full title artwork: HUD, PLAY,
/// leaderboard/settings, daily challenge, tab bar.
struct MainMenuView: View {
    @Environment(GameViewModel.self) private var game
    var onSheet: (GameSheet) -> Void
    var onPlay: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                HUDBar(onRankTap: { onSheet(.leaderboard) })
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
        .background {
            ZStack {
                Palette.background
                // Top-anchored fill: when tall screens (iPad) crop the art,
                // sacrifice the table edge, never the title.
                GeometryReader { geo in
                    Image("bgMain")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .clipped()
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
