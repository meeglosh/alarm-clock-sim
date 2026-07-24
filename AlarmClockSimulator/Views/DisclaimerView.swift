import SwiftUI

/// The "Real Life Comes First" wellness screen: shown once at first launch
/// and available any time from Settings.
struct DisclaimerView: View {
    var showsBackToMenu: Bool
    var onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HeroImage(name: "heroDisclaimer", height: 230)

                VStack(spacing: 10) {
                    HeadlineGradientText(text: "REAL LIFE", size: 40)
                    HeadlineGradientText(
                        text: "COMES FIRST",
                        size: 40,
                        colors: [Color(white: 0.98), Color(white: 0.62)]
                    )
                    AccentPill(text: "THIS IS ONLY A GAME")
                }

                VStack(alignment: .leading, spacing: 0) {
                    disclaimerRow("💙", "Alarm Clock Simulator is meant to be a playful joke game. Your mental health, sleep, relationships, school, work, and wellbeing always come first.")
                    Divider().overlay(Palette.panelBorder)
                    disclaimerRow("☕️", "If the game stops being fun, take a break.")
                    Divider().overlay(Palette.panelBorder)
                    disclaimerRow("❄️", "Use streak freezes when you need peace.")
                    Divider().overlay(Palette.panelBorder)
                    disclaimerRow("🌙", "Never sacrifice real rest or peace of mind for a streak.")
                }
                .gamePanel()

                Button("I UNDERSTAND  ♥") { onDismiss() }
                    .buttonStyle(ChunkyButtonStyle(style: .gold))

                if showsBackToMenu {
                    Button("BACK TO MENU") { onDismiss() }
                        .buttonStyle(ChunkyButtonStyle(style: .purple, height: 48))
                }

                Text("Play responsibly. Rest wins in real life. 🐑")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(20)
            .contentColumn()
        }
        .background(Palette.background)
        .preferredColorScheme(.dark)
    }

    private func disclaimerRow(_ emoji: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji).font(.system(size: 24))
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
    }
}
