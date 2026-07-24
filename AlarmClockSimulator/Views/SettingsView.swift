import SwiftUI

struct SettingsView: View {
    @Environment(StoreManager.self) private var store
    @Environment(GameCenterManager.self) private var gameCenter
    @Environment(AlarmNotificationScheduler.self) private var notifications
    @Environment(\.dismiss) private var dismiss
    var onShowDisclaimer: () -> Void
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HeadlineGradientText(text: "SETTINGS", size: 38)
                }

                VStack(spacing: 0) {
                    settingsRow(
                        "🔔",
                        "Alarm Notifications",
                        notifications.isAuthorized ? "On" : "Off"
                    ) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Divider().overlay(Palette.panelBorder)
                    settingsRow(
                        "🏆",
                        "Game Center",
                        gameCenter.isAuthenticated ? "Signed in" : "Signed out"
                    ) {}
                    Divider().overlay(Palette.panelBorder)
                    settingsRow("💳", "Restore Purchases", "") {
                        Task {
                            do {
                                try await store.restorePurchases()
                                message = "Purchases restored."
                            } catch {
                                message = error.localizedDescription
                            }
                        }
                    }
                    Divider().overlay(Palette.panelBorder)
                    settingsRow("💙", "Real Life Comes First", "") {
                        onShowDisclaimer()
                    }
                }
                .gamePanel()

                Text("Alarm Clock Simulator")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                Text("No snooze. No win. 🐑")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(16)
            .contentColumn()
        }
        .background(Palette.background)
        .preferredColorScheme(.dark)
        .overlay(alignment: .topLeading) {
            SheetBackButton()
        }
        .alert("Settings", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private func settingsRow(_ emoji: String, _ title: String, _ detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji).font(.system(size: 22))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}
