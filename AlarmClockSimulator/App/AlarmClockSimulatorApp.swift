import SwiftUI

@main
struct AlarmClockSimulatorApp: App {
    @State private var store: StoreManager
    @State private var game: GameViewModel

    init() {
        let store = StoreManager()
        let game = GameViewModel(
            isUnlimitedFreezeActive: { [weak store] in store?.isUnlimitedFreezeActive ?? false },
            feedback: AlarmFeedbackPlayer()
        )
        store.onConsumableGranted = { [weak game] productID in
            guard productID == .streakFreeze12h else { return }
            game?.applyConsumableFreeze()
        }
        _store = State(initialValue: store)
        _game = State(initialValue: game)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(game)
                .task { await store.start() }
        }
    }
}
