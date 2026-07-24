import SwiftUI

struct ContentView: View {
    var body: some View {
        GameView()
    }
}

#Preview {
    ContentView()
        .environment(GameViewModel())
        .environment(StoreManager())
}
