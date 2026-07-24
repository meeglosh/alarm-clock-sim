import SwiftUI

enum GameSheet: String, Identifiable {
    case shop, leaderboard, settings, stats, missions, collection, disclaimer

    var id: String { rawValue }
}

/// Top-level flow: loader tap-through, one-time wellness disclaimer, then
/// the phase-driven game screens with the smash cinematic overlaid on top.
struct RootView: View {
    private enum Flow: Equatable {
        case loader, disclaimer, main
    }

    @Environment(GameViewModel.self) private var game
    @Environment(AlarmNotificationScheduler.self) private var notifications
    @Environment(MusicPlayer.self) private var music
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
            skipLoaderIfRunLive()
            #if DEBUG
            applyLaunchOverrides()
            #endif
            updateMusic()
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                game.reconcile()
                game.startTicking()
                skipLoaderIfRunLive()
                updateMusic()
            } else {
                game.stopTicking()
                music.fadeOut(duration: 0.3)
            }
        }
        .onChange(of: flow) { _, _ in
            updateMusic()
        }
        .onChange(of: game.phase) { oldValue, newValue in
            updateMusic(previousPhase: oldValue)
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
            MissionsView(onPlay: {
                startRun()
                activeSheet = nil
            })
        case .collection:
            CollectionView()
        case .disclaimer:
            DisclaimerView(showsBackToMenu: true) { activeSheet = nil }
        }
    }

    private func startRun() {
        game.startRun()
        Task { await notifications.requestAuthorizationIfNeeded() }
    }

    /// Launching into a live run (most importantly: from tapping an alarm
    /// notification) must land directly on the play screen with the snooze
    /// button, never behind the loader tap-through.
    private func skipLoaderIfRunLive() {
        if flow != .main, game.phase.isRunActive {
            flow = .main
        }
    }

    /// Music plays on the loader, disclaimer, menu, and streak-ended
    /// screens; it bows out while a run is live. The return after a run
    /// ends uses a long swell so it rises as the smash dust settles.
    private func updateMusic(previousPhase: GamePhase? = nil) {
        guard scenePhase != .background else { return }
        let shouldPlay: Bool
        switch flow {
        case .loader, .disclaimer:
            shouldPlay = true
        case .main:
            shouldPlay = game.phase == .idle || game.phase.isGameOver
        }
        if shouldPlay {
            let runJustEnded = game.phase.isGameOver && previousPhase?.isRunActive == true
            music.fadeIn(duration: runJustEnded ? 2.4 : 1.0)
        } else {
            music.fadeOut(duration: 0.9)
        }
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
        } else if args.contains("-uiMissions") {
            activeSheet = .missions
        } else if args.contains("-uiCollection") {
            activeSheet = .collection
        } else if args.contains("-uiSmash") {
            game.startRun()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                smashCinematicActive = true
            }
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
        .environment(MusicPlayer())
}
