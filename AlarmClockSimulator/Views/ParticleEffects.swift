import SwiftUI
import UIKit

/// CAEmitterLayer-backed particle effects for the smash cinematic and the
/// wreckage aftermath. Particle textures are drawn in code (shards, sparks,
/// soft smoke blobs), so no image assets are needed.
enum ParticleTexture {
    static let shard: CGImage? = draw(size: 24) { ctx, size in
        ctx.setFillColor(UIColor(white: 0.16, alpha: 1).cgColor)
        ctx.move(to: CGPoint(x: 2, y: 20))
        ctx.addLine(to: CGPoint(x: 10, y: 2))
        ctx.addLine(to: CGPoint(x: 22, y: 12))
        ctx.addLine(to: CGPoint(x: 14, y: 22))
        ctx.closePath()
        ctx.fillPath()
        ctx.setStrokeColor(UIColor(white: 0.45, alpha: 0.9).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: 2, y: 20))
        ctx.addLine(to: CGPoint(x: 10, y: 2))
        ctx.strokePath()
    }

    static let spark: CGImage? = draw(size: 12) { ctx, size in
        let colors = [
            UIColor(red: 1, green: 0.95, blue: 0.75, alpha: 1).cgColor,
            UIColor(red: 1, green: 0.45, blue: 0.05, alpha: 0).cgColor,
        ]
        let gradient = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: 6, y: 6), startRadius: 0,
            endCenter: CGPoint(x: 6, y: 6), endRadius: 6,
            options: []
        )
    }

    static let smoke: CGImage? = draw(size: 80) { ctx, size in
        let colors = [
            UIColor(white: 0.55, alpha: 0.55).cgColor,
            UIColor(white: 0.35, alpha: 0).cgColor,
        ]
        let gradient = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: 40, y: 40), startRadius: 4,
            endCenter: CGPoint(x: 40, y: 40), endRadius: 40,
            options: []
        )
    }

    private static func draw(size: CGFloat, _ block: (CGContext, CGFloat) -> Void) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            block(context.cgContext, size)
        }.cgImage
    }
}

/// One-shot debris + spark burst at `point`, with smoke that keeps rising
/// from the wreckage while the view stays mounted.
struct SmashParticlesView: UIViewRepresentable {
    /// Emitter origin in view coordinates.
    var point: CGPoint
    /// When false, only ambient smoke plays (used on the streak-ended screen).
    var burst: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false

        let smoke = CAEmitterLayer()
        smoke.emitterPosition = point
        smoke.emitterSize = CGSize(width: 90, height: 20)
        smoke.emitterShape = .line
        smoke.birthRate = burst ? 0 : 1
        let smokeCell = CAEmitterCell()
        smokeCell.contents = ParticleTexture.smoke
        smokeCell.birthRate = 3
        smokeCell.lifetime = 3.2
        smokeCell.velocity = 42
        smokeCell.velocityRange = 18
        smokeCell.emissionLongitude = -.pi / 2
        smokeCell.emissionRange = .pi / 7
        smokeCell.scale = 0.6
        smokeCell.scaleRange = 0.35
        smokeCell.scaleSpeed = 0.55
        smokeCell.alphaSpeed = -0.32
        smokeCell.spin = 0.4
        smokeCell.spinRange = 0.8
        smoke.emitterCells = [smokeCell]
        view.layer.addSublayer(smoke)

        if burst {
            addBurst(to: view)
            // Smoke starts billowing right after the impact burst.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                smoke.birthRate = 1
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func addBurst(to view: UIView) {
        let layer = CAEmitterLayer()
        layer.emitterPosition = point
        layer.emitterSize = CGSize(width: 60, height: 40)
        layer.emitterShape = .rectangle
        layer.renderMode = .additive
        layer.beginTime = CACurrentMediaTime()

        let shard = CAEmitterCell()
        shard.contents = ParticleTexture.shard
        shard.birthRate = 260
        shard.lifetime = 1.4
        shard.lifetimeRange = 0.5
        shard.velocity = 480
        shard.velocityRange = 320
        shard.emissionRange = .pi * 2
        shard.yAcceleration = 620
        shard.scale = 0.55
        shard.scaleRange = 0.5
        // Rapid scale growth reads as debris flying toward the camera.
        shard.scaleSpeed = 1.7
        shard.spin = 6
        shard.spinRange = 10
        shard.alphaSpeed = -0.7

        let spark = CAEmitterCell()
        spark.contents = ParticleTexture.spark
        spark.birthRate = 700
        spark.lifetime = 0.8
        spark.lifetimeRange = 0.4
        spark.velocity = 620
        spark.velocityRange = 380
        spark.emissionRange = .pi * 2
        spark.yAcceleration = 300
        spark.scale = 0.7
        spark.scaleRange = 0.6
        spark.scaleSpeed = 0.9
        spark.alphaSpeed = -1.2

        layer.emitterCells = [shard, spark]
        view.layer.addSublayer(layer)

        // A burst, not a fountain: cut birth quickly, let particles live out.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            layer.birthRate = 0
        }
    }
}
