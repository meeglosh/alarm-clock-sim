import SwiftUI

struct StatsView: View {
    @Environment(GameViewModel.self) private var game

    private var stats: [(String, String, String)] {
        [
            ("🔥", "Best Streak", "\(game.bestStreak)"),
            ("😴", "Total Snoozes", "\(game.totalSnoozes)"),
            ("🎮", "Runs Started", "\(game.totalRuns)"),
            ("🔨", "Clocks Smashed", "\(game.totalSmashes)"),
            ("💤", "Oversleeps", "\(game.totalOversleeps)"),
            ("❄️", "Freezes Used", "\(game.freezesApplied)"),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HeadlineGradientText(text: "STATS", size: 40)
                    AccentPill(text: "YOUR SNOOZE CAREER")
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(stats, id: \.1) { stat in
                        VStack(spacing: 6) {
                            Text(stat.0).font(.system(size: 30))
                            Text(stat.2)
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text(stat.1.uppercased())
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .gamePanel()
                    }
                }
            }
            .padding(16)
            .contentColumn()
        }
        .background(Palette.background)
        .preferredColorScheme(.dark)
    }
}

struct ComingSoonView: View {
    let emoji: String
    let title: String
    let quip: String

    var body: some View {
        VStack(spacing: 16) {
            Text(emoji).font(.system(size: 64))
            HeadlineGradientText(text: title, size: 36)
            AccentPill(text: "COMING SOON")
            Text(quip)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
        .preferredColorScheme(.dark)
    }
}
