import SwiftUI
import UserNotifications

@main
struct AlarmClockSimulatorApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: StoreManager
    @State private var game: GameViewModel
    @State private var gameCenter: GameCenterManager
    @State private var notifications: AlarmNotificationScheduler
    @State private var notificationDelegate: NotificationDelegate
    @State private var music = MusicPlayer()

    init() {
        let store = StoreManager()
        let gameCenter = GameCenterManager()
        let notifications = AlarmNotificationScheduler()
        let notificationDelegate = NotificationDelegate()
        let game = GameViewModel(
            isUnlimitedFreezeActive: { [weak store] in store?.isUnlimitedFreezeActive ?? false },
            feedback: AlarmFeedbackPlayer()
        )
        store.onConsumableGranted = { [weak game] productID in
            guard productID == .streakFreeze12h else { return }
            game?.applyConsumableFreeze()
        }
        game.onRunEnded = { streak, _ in
            Task { await gameCenter.submit(streak: streak) }
        }
        // Lock-screen snooze: the app is woken in the background, so bring
        // the game current, snooze, and schedule the next round.
        notificationDelegate.onSnoozeAction = { [weak game, weak notifications] in
            guard let game, let notifications else { return }
            game.reconcile()
            game.snooze()
            await notifications.scheduleForBackground(game: game)
        }
        UNUserNotificationCenter.current().delegate = notificationDelegate
        notifications.configure()
        _store = State(initialValue: store)
        _game = State(initialValue: game)
        _gameCenter = State(initialValue: gameCenter)
        _notifications = State(initialValue: notifications)
        _notificationDelegate = State(initialValue: notificationDelegate)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(game)
                .environment(gameCenter)
                .environment(notifications)
                .environment(music)
                .task {
                    gameCenter.authenticate()
                    await store.start()
                }
                .onChange(of: scenePhase) { _, newValue in
                    switch newValue {
                    case .background:
                        Task { await notifications.scheduleForBackground(game: game) }
                    case .active:
                        notifications.cancelAll()
                    default:
                        break
                    }
                }
        }
    }
}
