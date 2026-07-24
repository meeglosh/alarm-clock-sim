import SwiftUI

/// Custom global leaderboard styled after the mockup, fed by real Game
/// Center entries. Falls back to the native Game Center sheet when data
/// isn't available.
struct LeaderboardView: View {
    @Environment(GameViewModel.self) private var game
    @Environment(GameCenterManager.self) private var gameCenter
    @Environment(\.dismiss) private var dismiss
    @State private var showNativeGameCenter = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 8) {
                    HeadlineGradientText(text: "GLOBAL", size: 36)
                    HeadlineGradientText(
                        text: "LEADERBOARD",
                        size: 36,
                        colors: [Color(white: 0.98), Color(white: 0.62)]
                    )
                    AccentPill(text: "SNOOZE STREAKS")
                }

                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("YOUR STREAK")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Palette.fireOrange)
                        HStack(spacing: 6) {
                            Text("🔥").font(.system(size: 22))
                            Text("\(game.bestStreak)")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("SNOOZES")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Rectangle().fill(Palette.panelBorder).frame(width: 1, height: 46)
                    VStack(spacing: 4) {
                        Text("YOUR GLOBAL RANK")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Palette.gold)
                        HStack(spacing: 6) {
                            Text("🏆").font(.system(size: 22))
                            Text(gameCenter.globalRank.map { "#\($0.formatted())" } ?? "—")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        if let percentile = gameCenter.percentileText {
                            Text(percentile)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .gamePanel()

                if gameCenter.topEntries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .padding(16)
        }
        .background(Palette.background)
        .preferredColorScheme(.dark)
        .overlay(alignment: .topLeading) {
            Button {
                dismiss()
            } label: {
                Label("BACK", systemImage: "arrow.left")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .gamePanel(cornerRadius: 12)
            }
            .padding(12)
        }
        .task {
            await gameCenter.refreshLeaderboard()
        }
        .sheet(isPresented: $showNativeGameCenter) {
            GameCenterView()
                .ignoresSafeArea()
        }
    }

    private var entryList: some View {
        VStack(spacing: 8) {
            HStack {
                Text("RANK")
                Spacer()
                Text("PLAYER")
                Spacer()
                Text("SNOOZE STREAK")
            }
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(.white.opacity(0.5))
            .padding(.horizontal, 14)

            ForEach(gameCenter.topEntries) { entry in
                entryRow(entry)
            }

            if let local = gameCenter.localEntry,
               !gameCenter.topEntries.contains(where: { $0.isLocalPlayer }) {
                Text("• • •")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.35))
                entryRow(local)
            }

            Text("Leaderboards refresh with each game over. 🏆")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 4)
        }
    }

    private func entryRow(_ entry: GameCenterManager.LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            rankBadge(entry.rank)
                .frame(width: 54, alignment: .leading)
            Text(entry.isLocalPlayer ? "You" : entry.displayName)
                .font(.system(size: 15, weight: entry.isLocalPlayer ? .black : .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(entry.score)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.gold)
                Text("SNOOZES")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .gamePanel(cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(entry.isLocalPlayer ? Palette.cyan : .clear, lineWidth: 1.5)
        )
    }

    @ViewBuilder
    private func rankBadge(_ rank: Int) -> some View {
        switch rank {
        case 1: Text("👑 1").font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(Palette.gold)
        case 2: Text("🥈 2").font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(Color(white: 0.8))
        case 3: Text("🥉 3").font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.8, green: 0.5, blue: 0.25))
        default:
            Text("\(rank)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🏆").font(.system(size: 44))
            Text(gameCenter.isAuthenticated
                 ? "No streaks on the board yet.\nSmash your way onto it."
                 : "Sign in to Game Center to join\nthe global snooze race.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
            if gameCenter.isAuthenticated {
                Button("OPEN GAME CENTER") {
                    showNativeGameCenter = true
                }
                .buttonStyle(ChunkyButtonStyle(style: .blue, height: 44))
                .frame(width: 240)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .gamePanel()
    }
}
