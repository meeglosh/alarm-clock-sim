import SwiftUI

/// Shown once, before the system permission dialog ever appears, the first
/// time a player hits PLAY. This game is close to unplayable with
/// notifications off — the alarm has no way to reach a locked or
/// backgrounded phone otherwise — so the ask needs to be understood, not
/// just tapped through. A bare system dialog with no context is exactly
/// what gets reflexively declined.
struct NotificationPrimerView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            VStack(spacing: 18) {
                Text("🔔")
                    .font(.system(size: 64))
                    .shadow(color: Palette.lcdOrange.opacity(0.7), radius: 16)

                HeadlineGradientText(text: "TURN ON", size: 36)
                HeadlineGradientText(
                    text: "NOTIFICATIONS",
                    size: 36,
                    colors: [Color(white: 0.98), Color(white: 0.62)]
                )
                AccentPill(text: "REQUIRED TO PLAY", color: Palette.danger)
            }

            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 0) {
                primerRow(
                    "🔒",
                    "This game is nearly impossible to play without them.",
                    emphasis: true
                )
                Divider().overlay(Palette.panelBorder)
                primerRow(
                    "⏰",
                    "The alarm rings every 10 minutes, even while your phone is locked or the app is closed."
                )
                Divider().overlay(Palette.panelBorder)
                primerRow(
                    "👆",
                    "Notifications are the only way the alarm can reach you to snooze in time and keep your streak alive."
                )
                Divider().overlay(Palette.panelBorder)
                primerRow(
                    "🚫",
                    "Without them, alarms silently expire in the background and your streak ends before you ever see them."
                )
            }
            .gamePanel()

            Spacer(minLength: 24)

            VStack(spacing: 12) {
                Button {
                    onContinue()
                } label: {
                    HStack(spacing: 10) {
                        Text("ENABLE NOTIFICATIONS")
                        Image(systemName: "bell.badge.fill")
                    }
                }
                .buttonStyle(ChunkyButtonStyle(style: .gold, height: 58))

                Button {
                    onContinue()
                } label: {
                    Text("Play without them anyway")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .underline()
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func primerRow(_ emoji: String, _ text: String, emphasis: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji).font(.system(size: 22))
            Text(text)
                .font(.system(size: 14, weight: emphasis ? .bold : .medium))
                .foregroundStyle(emphasis ? Palette.danger : .white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
    }
}

#Preview {
    NotificationPrimerView(onContinue: {})
}
