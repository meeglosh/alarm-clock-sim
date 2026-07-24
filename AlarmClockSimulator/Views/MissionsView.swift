import SwiftUI

/// Today's procedurally generated mission with live progress, plus a
/// countdown to the next one at midnight and a mystery card for tomorrow.
struct MissionsView: View {
    @Environment(GameViewModel.self) private var game

    var body: some View {
        TimelineView(.everyMinute) { context in
            let mission = MissionFactory.mission(for: context.date)
            let progress = game.missionProgress(for: mission, now: context.date)
            let complete = progress >= mission.target

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        HeadlineGradientText(text: "MISSIONS", size: 40)
                        AccentPill(text: "A NEW DARE EVERY MIDNIGHT")
                    }

                    VStack(spacing: 12) {
                        Text("TODAY'S MISSION")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Palette.cyan)
                        Text(mission.emoji)
                            .font(.system(size: 52))
                        Text(mission.title)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(mission.objective)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        Text(mission.flavor)
                            .font(.system(size: 12, weight: .medium))
                            .italic()
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)

                        VStack(spacing: 6) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 10)
                                .overlay(alignment: .leading) {
                                    GeometryReader { proxy in
                                        Capsule()
                                            .fill(complete ? Color.green : Palette.cyan)
                                            .frame(width: proxy.size.width * CGFloat(progress) / CGFloat(mission.target))
                                    }
                                }
                            Text("\(progress) / \(mission.target)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 8)

                        if complete {
                            Label("MISSION COMPLETE", systemImage: "star.fill")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(Palette.gold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Palette.gold.opacity(0.15), in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .gamePanel(cornerRadius: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(complete ? Color.green.opacity(0.5) : Palette.cyan.opacity(0.3), lineWidth: 1.5)
                    )

                    Label(countdownText(from: context.date), systemImage: "clock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))

                    HStack(spacing: 12) {
                        Text("❓").font(.system(size: 30))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TOMORROW")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("A new mission arrives at midnight.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(14)
                    .gamePanel()
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

    private func countdownText(from date: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        guard let midnight = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            return "New mission at midnight"
        }
        let remaining = max(0, Int(midnight.timeIntervalSince(date)))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        return hours > 0
            ? "New mission in \(hours)h \(minutes)m"
            : "New mission in \(minutes)m"
    }
}
