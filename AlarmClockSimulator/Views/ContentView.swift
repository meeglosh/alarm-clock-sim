import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Alarm Clock Simulator")
                    .font(.title)

                NavigationLink("Streak Freezes") {
                    StoreView()
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
