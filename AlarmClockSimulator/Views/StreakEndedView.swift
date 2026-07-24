import SwiftUI

/// Game-over screen: wrecked-clock artwork with smoke still rising, final
/// streak, previous best, global rank, and the sheep's condolences.
struct StreakEndedView: View {
    @Environment(GameViewModel.self) private var game
    @Environment(GameCenterManager.self) private var gameCenter
    let reason: GameOverReason
    var onTryAgain: () -> Void
    var onSheet: (GameSheet) -> Void
    var onBackToMenu: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 8) {
                    HeadlineGradientText(text: reason == .smashed ? "SMASH!" : "OVERSLEPT!", size: 52)
                    Text("STREAK ENDED")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.92, green: 0.16, blue: 0.14))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 6)
                        .gamePanel(cornerRadius: 12)
                    Text(reason == .smashed ? "💀 THE ALARM WON'T WIN TODAY 💀" : "💀 THE ALARM WON THIS TIME 💀")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.85))
                }

                heroWithSmoke

                VStack(spacing: 2) {
                    Text("FINAL STREAK")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.7))
                    HStack(spacing: 12) {
                        Text("🔥").font(.system(size: 40))
                        Text("\(game.streak)")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Text("SNOOZES")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .gamePanel()

                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("PREVIOUS BEST")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Color(red: 0.35, green: 0.66, blue: 0.97))
                        HStack(spacing: 6) {
                            Text("🏆").font(.system(size: 22))
                            Text("\(game.bestStreak)")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("SNOOZES")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Rectangle().fill(Palette.panelBorder).frame(width: 1, height: 44)
                    VStack(spacing: 4) {
                        Text("GLOBAL RANK")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Palette.fireOrange)
                        Text(gameCenter.globalRank.map { "#\($0.formatted())" } ?? "—")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .gamePanel()

                HStack(spacing: 12) {
                    Text("🐑").font(.system(size: 34))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BETTER LUCK TOMORROW!")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.2))
                        Text("Even legends hit snooze sometimes.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                }
                .padding(12)
                .gamePanel()

                Button {
                    onTryAgain()
                } label: {
                    HStack(spacing: 10) {
                        Text("TRY AGAIN")
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(ChunkyButtonStyle(style: .gold, height: 58))

                Button {
                    onSheet(.leaderboard)
                } label: {
                    Label("VIEW LEADERBOARD", systemImage: "trophy.fill")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                }
                .buttonStyle(ChunkyButtonStyle(style: .blue, height: 46))

                Button {
                    onBackToMenu()
                } label: {
                    Label("BACK TO MENU", systemImage: "house.fill")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                }
                .buttonStyle(ChunkyButtonStyle(style: .purple, height: 46))
            }
            .padding(16)
            .contentColumn()
        }
        .background(Palette.background)
        .overlay(alignment: .topLeading) {
            MusicToggleButton()
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
    }

    private var heroWithSmoke: some View {
        HeroImage(name: "heroWrecked", height: 200)
            .overlay(
                // Smoke keeps rising from the wreckage (clock sits left of
                // center in the crop).
                GeometryReader { proxy in
                    SmashParticlesView(
                        point: CGPoint(x: proxy.size.width * 0.42, y: proxy.size.height * 0.42),
                        burst: false
                    )
                    .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            )
    }
}
