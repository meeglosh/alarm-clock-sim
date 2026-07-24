import SwiftUI

struct GameView: View {
    @Environment(GameViewModel.self) private var game
    @Environment(StoreManager.self) private var store
    @Environment(GameCenterManager.self) private var gameCenter
    @Environment(\.scenePhase) private var scenePhase
    @State private var sceneController = BedsideSceneController()
    @State private var showStore = false
    @State private var showLeaderboard = false

    var body: some View {
        ZStack {
            GameSceneView(
                controller: sceneController,
                isHammerEnabled: game.phase.isRunActive,
                onClockTap: { game.snooze() },
                onHammerSmash: { game.smash() }
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                if game.phase != .idle {
                    header
                }
                statusBanner
                Spacer()
                footer
            }
            .padding()

            if game.phase == .idle {
                idleCard
            }
            if case .gameOver(let reason) = game.phase {
                gameOverCard(reason)
            }
        }
        .onAppear {
            game.reconcile()
            game.startTicking()
            if game.phase == .ringing {
                sceneController.setRinging(true)
            }
        }
        .onDisappear {
            game.stopTicking()
        }
        .onChange(of: game.phase) { oldValue, newValue in
            phaseChanged(from: oldValue, to: newValue)
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                game.reconcile()
                game.startTicking()
            } else {
                game.stopTicking()
            }
        }
        .sheet(isPresented: $showStore) {
            NavigationStack {
                StoreView()
            }
        }
        .sheet(isPresented: $showLeaderboard) {
            GameCenterView()
                .ignoresSafeArea()
        }
    }

    // MARK: - Overlay pieces

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("STREAK")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(game.streak)")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("Best \(game.bestStreak)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                freezeBadge
            }
        }
    }

    @ViewBuilder
    private var freezeBadge: some View {
        if store.isUnlimitedFreezeActive {
            badgeLabel("Unlimited")
        } else if let expiry = game.freezeExpiry, expiry > game.displayNow {
            badgeLabel(freezeRemainingText(until: expiry))
        }
    }

    private func badgeLabel(_ text: String) -> some View {
        Label(text, systemImage: "snowflake")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.cyan.opacity(0.2), in: Capsule())
            .foregroundStyle(.cyan)
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch game.phase {
        case .counting:
            VStack(spacing: 2) {
                Text(countdownText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("until the next alarm")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        case .ringing:
            VStack(spacing: 4) {
                Text("WAKE UP!")
                    .font(.title.bold())
                    .foregroundStyle(.red)
                Text("Snooze within \(ringingRemainingText)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
        case .idle, .gameOver:
            EmptyView()
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if game.phase == .ringing {
                Button {
                    game.snooze()
                } label: {
                    Text("SNOOZE")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            HStack(alignment: .bottom) {
                Button {
                    showStore = true
                } label: {
                    Label("Freezes", systemImage: "snowflake")
                }
                .buttonStyle(.bordered)
                .tint(.cyan)
                Spacer()
                if game.phase.isRunActive {
                    Text("Drag the hammer onto the clock to end your run")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 170, alignment: .trailing)
                }
            }
        }
    }

    private var idleCard: some View {
        VStack(spacing: 14) {
            Text("Alarm Clock Simulator")
                .font(.title2.bold())
            Text("Snooze every alarm to grow your streak. Smash the clock only when you're ready to cash out.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if game.bestStreak > 0 {
                Text("Best streak: \(game.bestStreak)")
                    .font(.subheadline.weight(.semibold))
            }
            Button("Start Streak") {
                game.startRun()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            leaderboardButton
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private var leaderboardButton: some View {
        if gameCenter.isAuthenticated {
            Button {
                showLeaderboard = true
            } label: {
                Label("Leaderboard", systemImage: "trophy")
            }
            .buttonStyle(.bordered)
        }
    }

    private func gameOverCard(_ reason: GameOverReason) -> some View {
        VStack(spacing: 12) {
            Text(reason == .smashed ? "Clock smashed." : "You overslept.")
                .font(.title2.bold())
            Text("Final streak")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(game.streak)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
            Text("Best \(game.bestStreak)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Start a New Streak") {
                game.startRun()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            leaderboardButton
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 32)
    }

    // MARK: - Derived text

    private var countdownText: String {
        guard let next = game.nextAlarmDate else { return "--:--" }
        let remaining = max(0, Int(next.timeIntervalSince(game.displayNow).rounded(.up)))
        return String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    private var ringingRemainingText: String {
        guard let since = game.ringingSince else { return "" }
        let elapsed = game.displayNow.timeIntervalSince(since)
        let remaining = max(0, Int((game.configuration.missWindow - elapsed).rounded(.up)))
        return "\(remaining)s"
    }

    private func freezeRemainingText(until expiry: Date) -> String {
        let remaining = max(0, Int(expiry.timeIntervalSince(game.displayNow)))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    // MARK: - Scene sync

    private func phaseChanged(from old: GamePhase, to new: GamePhase) {
        switch new {
        case .ringing:
            sceneController.setRinging(true)
        case .counting:
            sceneController.setRinging(false)
            if old == .ringing {
                sceneController.playSnoozePulse()
            }
            if old == .idle || old.isGameOver {
                sceneController.resetForNewRun()
            }
        case .gameOver(let reason):
            sceneController.setRinging(false)
            if reason == .smashed {
                sceneController.playSmash()
            }
        case .idle:
            sceneController.resetForNewRun()
        }
    }
}

#Preview {
    GameView()
        .environment(GameViewModel())
        .environment(StoreManager())
        .environment(GameCenterManager())
}
