import SwiftUI

/// The destruction moment: white-hot flash, the mockups' actual impact
/// artwork slammed over the scene, camera shake, debris and sparks flying
/// at the camera, then billowing smoke before handing off to the
/// streak-ended screen. SFX and haptics fire via game.smash() at impact.
struct SmashCinematicView: View {
    /// Called at the moment of impact; the caller runs game.smash() here so
    /// the run ends (and the score records) exactly when the hammer lands.
    var onImpact: () -> Void
    var onFinished: () -> Void

    @State private var flashOpacity: Double = 0
    @State private var burstVisible = false
    @State private var shakeT: CGFloat = 0
    @State private var particlesActive = false
    @State private var dimOpacity: Double = 0

    var body: some View {
        GeometryReader { proxy in
            let layout = SceneImageLayout(container: proxy.size)
            // Where the artwork's clock face sits: particle origin.
            let impactRect = layout.rect(x: 0.5, y: 0.5, width: 0.001, height: 0.001)
            // The smashBurst crop spans y 540-1260 of the 1847-tall mockup.
            let burstRect = layout.rect(x: 0, y: 540.0 / 1847.0, width: 1, height: 720.0 / 1847.0)

            ZStack {
                Group {
                    Image("bgMain")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()

                    if burstVisible {
                        Image("smashBurst")
                            .resizable()
                            .frame(width: burstRect.width, height: burstRect.height)
                            .position(x: burstRect.midX, y: burstRect.midY)
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .black, location: 0.09),
                                        .init(color: .black, location: 0.91),
                                        .init(color: .clear, location: 1),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(width: burstRect.width, height: burstRect.height)
                                .position(x: burstRect.midX, y: burstRect.midY)
                            )
                    }

                    if particlesActive {
                        SmashParticlesView(
                            point: CGPoint(x: impactRect.midX, y: impactRect.midY),
                            burst: true
                        )
                        .allowsHitTesting(false)
                    }
                }
                .modifier(ShakeEffect(travel: 16, shakes: 8, animatableData: shakeT))

                Color.black.opacity(dimOpacity)
                Color.white.opacity(flashOpacity)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear(perform: run)
    }

    private func run() {
        Task { @MainActor in
            // Wind-up beat, then impact.
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeIn(duration: 0.05)) { flashOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(60))
            onImpact()
            burstVisible = true
            particlesActive = true
            withAnimation(.linear(duration: 0.7)) { shakeT = 1 }
            withAnimation(.easeOut(duration: 0.35)) { flashOpacity = 0 }

            // Let the debris fly and the smoke build.
            try? await Task.sleep(for: .milliseconds(1500))
            withAnimation(.easeIn(duration: 0.45)) { dimOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(450))
            onFinished()
        }
    }
}
