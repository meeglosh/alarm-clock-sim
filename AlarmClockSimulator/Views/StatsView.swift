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
        .overlay(alignment: .topLeading) {
            SheetBackButton()
        }
    }
}

