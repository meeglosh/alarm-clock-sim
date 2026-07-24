import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    ContentView()
        .environment(GameViewModel())
        .environment(StoreManager())
        .environment(GameCenterManager())
        .environment(AlarmNotificationScheduler())
}
