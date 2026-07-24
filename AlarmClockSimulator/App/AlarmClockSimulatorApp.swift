import SwiftUI

@main
struct AlarmClockSimulatorApp: App {
    @State private var store: StoreManager
    @State private var game: GameViewModel
    @State private var gameCenter: GameCenterManager

    init() {
        let store = StoreManager()
        let gameCenter = GameCenterManager()
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
        _store = State(initialValue: store)
        _game = State(initialValue: game)
        _gameCenter = State(initialValue: gameCenter)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(game)
                .environment(gameCenter)
                .task {
                    gameCenter.authenticate()
                    await store.start()
                }
        }
    }
}
