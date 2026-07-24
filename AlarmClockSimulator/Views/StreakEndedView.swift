import SwiftUI

/// Game-over screen: wrecked-clock artwork with smoke still rising and a
/// smoldering crackle underneath, final streak, previous best, global rank,
/// and the sheep's condolences. Laid out to fit without scrolling: the hero
/// band flexes to absorb the height difference between devices so every
/// CTA stays above the fold.
struct StreakEndedView: View {
    @Environment(GameViewModel.self) private var game
    @Environment(GameCenterManager.self) private var gameCenter
    @Environment(MusicPlayer.self) private var music
    let reason: GameOverReason
    var onTryAgain: () -> Void
    var onSheet: (GameSheet) -> Void
    var onBackToMenu: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 6) {
                HeadlineGradientText(text: reason == .smashed ? "SMASH!" : "OVERSLEPT!", size: 38)
                Text("STREAK ENDED")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.92, green: 0.16, blue: 0.14))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 5)
                    .gamePanel(cornerRadius: 10)
                Text(reason == .smashed ? "💀 THE ALARM WON'T WIN TODAY 💀" : "💀 THE ALARM WON THIS TIME 💀")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.85))
            }

            heroWithSmoke

            VStack(spacing: 2) {
                Text("FINAL STREAK")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 10) {
                    Text("🔥").font(.system(size: 30))
                    Text("\(game.streak)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text("SNOOZES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .gamePanel()

            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    Text("PREVIOUS BEST")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Color(red: 0.35, green: 0.66, blue: 0.97))
                    HStack(spacing: 6) {
                        Text("🏆").font(.system(size: 18))
                        Text("\(game.bestStreak)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("SNOOZES")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .frame(maxWidth: .infinity)
                Rectangle().fill(Palette.panelBorder).frame(width: 1, height: 36)
                VStack(spacing: 3) {
                    Text("GLOBAL RANK")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Palette.fireOrange)
                    Text(gameCenter.globalRank.map { "#\($0.formatted())" } ?? "—")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 9)
            .gamePanel()

            HStack(spacing: 10) {
                Text("🐑").font(.system(size: 26))
                VStack(alignment: .leading, spacing: 1) {
                    Text("BETTER LUCK TOMORROW!")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.2))
                    Text("Even legends hit snooze sometimes.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .gamePanel()

            Spacer(minLength: 0)

            Button {
                onTryAgain()
            } label: {
                HStack(spacing: 10) {
                    Text("TRY AGAIN")
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(ChunkyButtonStyle(style: .gold, height: 52))

            Button {
                onSheet(.leaderboard)
            } label: {
                Label("VIEW LEADERBOARD", systemImage: "trophy.fill")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .buttonStyle(ChunkyButtonStyle(style: .blue, height: 44))

            Button {
                onBackToMenu()
            } label: {
                Label("BACK TO MENU", systemImage: "house.fill")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .buttonStyle(ChunkyButtonStyle(style: .purple, height: 44))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentColumn()
        .background(Palette.background.ignoresSafeArea())
        .overlay(alignment: .top) {
            HStack {
                MusicToggleButton()
                Spacer()
            }
            .padding(.horizontal, 16)
            .contentColumn()
            .padding(.top, 36)
            .ignoresSafeArea(edges: .top)
        }
        .onAppear {
            music.setSmoldering(true)
        }
        .onDisappear {
            music.setSmoldering(false)
        }
    }

    private var heroWithSmoke: some View {
        HeroImage(name: "heroWrecked", height: nil)
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
