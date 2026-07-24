import SwiftUI

/// Full-bleed title art with a pulsing tap-to-start prompt.
struct LoaderView: View {
    var onContinue: () -> Void
    @State private var pulsing = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("bgMain")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.68),
                    .init(color: Palette.background.opacity(0.97), location: 0.84),
                    .init(color: Palette.background, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Text("TAP TO START")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .tracking(6)
                .foregroundStyle(.white.opacity(pulsing ? 0.95 : 0.35))
                .shadow(color: Palette.cyan.opacity(pulsing ? 0.8 : 0.1), radius: 10)
                .padding(.bottom, 60)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onContinue)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}
