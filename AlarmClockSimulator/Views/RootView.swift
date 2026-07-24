import SwiftUI

enum GameSheet: String, Identifiable {
    case shop, leaderboard, settings, stats, missions, collection, disclaimer

    var id: String { rawValue }
}

/// Top-level flow: loader tap-through, one-time wellness disclaimer, then
/// the phase-driven game screens with the smash cinematic overlaid on top.
struct RootView: View {
    private enum Flow {
        case loader, disclaimer, main
    }

    @Environment(GameViewModel.self) private var game
    @Environment(AlarmNotificationScheduler.self) private var notifications
    @Environment(\.scenePhase) private var scenePhase
    @State private var flow: Flow = .loader
    @State private var activeSheet: GameSheet?
    @State private var smashCinematicActive = false

    private static let disclaimerAcceptedKey = "disclaimer.accepted"

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            switch flow {
            case .loader:
                LoaderView {
                    if UserDefaults.standard.bool(forKey: Self.disclaimerAcceptedKey) {
                        flow = .main
                    } else {
                        flow = .disclaimer
                    }
                }
            case .disclaimer:
                DisclaimerView(showsBackToMenu: false) {
                    UserDefaults.standard.set(true, forKey: Self.disclaimerAcceptedKey)
                    flow = .main
                }
            case .main:
                mainContent
            }

            if smashCinematicActive {
                SmashCinematicView(
                    onImpact: { game.smash() },
                    onFinished: { withAnimation(.easeOut(duration: 0.4)) { smashCinematicActive = false } }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .onAppear {
            game.reconcile()
            game.startTicking()
            #if DEBUG
            applyLaunchOverrides()
            #endif
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                game.reconcile()
                game.startTicking()
            } else {
                game.stopTicking()
            }
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(sheet)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }

    @ViewBuilder
    private var mainContent: some View {
        switch game.phase {
        case .idle:
            MainMenuView(
                onSheet: { activeSheet = $0 },
                onPlay: startRun
            )
        case .counting, .ringing:
            PlayView(
                onSheet: { activeSheet = $0 },
                onSmash: { withAnimation(.easeIn(duration: 0.1)) { smashCinematicActive = true } }
            )
        case .gameOver(let reason):
            StreakEndedView(
                reason: reason,
                onTryAgain: startRun,
                onSheet: { activeSheet = $0 },
                onBackToMenu: { game.returnToMenu() }
            )
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: GameSheet) -> some View {
        switch sheet {
        case .shop:
            ShopView()
        case .leaderboard:
            LeaderboardView()
        case .settings:
            SettingsView(onShowDisclaimer: { activeSheet = .disclaimer })
        case .stats:
            StatsView()
        case .missions:
            ComingSoonView(emoji: "🎯", title: "MISSIONS", quip: "Daily dares for serial snoozers.")
        case .collection:
            ComingSoonView(emoji: "⏰", title: "COLLECTION", quip: "A museum of clocks you have silenced.")
        case .disclaimer:
            DisclaimerView(showsBackToMenu: true) { activeSheet = nil }
        }
    }

    private func startRun() {
        game.startRun()
        Task { await notifications.requestAuthorizationIfNeeded() }
    }

    #if DEBUG
    /// Screenshot/dev harness: jump straight to a screen via launch args
    /// (e.g. `simctl launch <device> <bundle> -uiRinging`).
    private func applyLaunchOverrides() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains(where: { $0.hasPrefix("-ui") }) else { return }
        flow = .main
        game.debugResetToIdle()
        if args.contains("-uiDisclaimer") {
            flow = .disclaimer
        } else if args.contains("-uiPlay") {
            game.startRun()
        } else if args.contains("-uiRinging") {
            game.startRun(now: Date().addingTimeInterval(-game.configuration.alarmInterval))
            game.reconcile()
        } else if args.contains("-uiEnded") {
            game.startRun()
            game.smash()
        }
    }
    #endif
}

#Preview {
    RootView()
        .environment(GameViewModel())
        .environment(StoreManager())
        .environment(GameCenterManager())
        .environment(AlarmNotificationScheduler())
}
