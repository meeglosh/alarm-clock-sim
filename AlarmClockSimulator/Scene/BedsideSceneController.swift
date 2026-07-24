import SceneKit
import UIKit

/// Builds and animates the low-poly bedside scene. The node names ("clock",
/// "hammer") are the hit-testing contract with GameSceneView.
@MainActor
final class BedsideSceneController {
    static let clockNodeName = "clock"
    static let hammerNodeName = "hammer"

    let scene = SCNScene()

    private let clockNode = SCNNode()
    private let hammerNode = SCNNode()
    private let hammerRestPosition = SCNVector3(0.85, 1.13, 0.35)

    var hammerWorldPosition: SCNVector3 { hammerNode.position }

    init() {
        buildScene()
    }

    // MARK: - Animations

    func setRinging(_ ringing: Bool) {
        if ringing {
            guard clockNode.action(forKey: "ring") == nil else { return }
            let shake = SCNAction.sequence([
                .rotateBy(x: 0, y: 0, z: 0.12, duration: 0.05),
                .rotateBy(x: 0, y: 0, z: -0.24, duration: 0.1),
                .rotateBy(x: 0, y: 0, z: 0.12, duration: 0.05),
            ])
            clockNode.runAction(.repeatForever(shake), forKey: "ring")
        } else {
            clockNode.removeAction(forKey: "ring")
            clockNode.runAction(.rotateTo(x: 0, y: 0, z: 0, duration: 0.1))
        }
    }

    func playSnoozePulse() {
        clockNode.runAction(.sequence([
            .scale(to: 1.12, duration: 0.08),
            .scale(to: 1.0, duration: 0.18),
        ]))
    }

    func playSmash() {
        let aboveClock = SCNVector3(clockNode.position.x + 0.5, 2.0, clockNode.position.z + 0.1)
        let impact = SCNVector3(clockNode.position.x + 0.15, 1.45, clockNode.position.z)
        let raise = SCNAction.group([
            .move(to: aboveClock, duration: 0.25),
            .rotateTo(x: 0, y: 0, z: CGFloat.pi * 0.45, duration: 0.25, usesShortestUnitArc: true),
        ])
        raise.timingMode = .easeOut
        let strike = SCNAction.move(to: impact, duration: 0.07)
        strike.timingMode = .easeIn
        hammerNode.runAction(.sequence([raise, strike])) { [weak self] in
            Task { @MainActor in
                self?.squashClock()
            }
        }
    }

    func resetForNewRun() {
        clockNode.removeAllActions()
        hammerNode.removeAllActions()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.2
        clockNode.scale = SCNVector3(1, 1, 1)
        clockNode.eulerAngles = SCNVector3(0, 0, 0)
        hammerNode.position = hammerRestPosition
        hammerNode.eulerAngles = SCNVector3(0, 0, 0)
        SCNTransaction.commit()
    }

    // MARK: - Hammer dragging

    func liftHammer() {
        hammerNode.removeAllActions()
        let lift = SCNAction.move(
            to: SCNVector3(hammerNode.position.x, 1.6, hammerNode.position.z),
            duration: 0.12
        )
        lift.timingMode = .easeOut
        hammerNode.runAction(lift)
    }

    func moveHammer(to position: SCNVector3) {
        hammerNode.position = position
    }

    func returnHammerToRest() {
        hammerNode.removeAllActions()
        let back = SCNAction.move(to: hammerRestPosition, duration: 0.2)
        back.timingMode = .easeOut
        hammerNode.runAction(back)
        hammerNode.runAction(.rotateTo(x: 0, y: 0, z: 0, duration: 0.2))
    }

    private func squashClock() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.12
        clockNode.scale = SCNVector3(1.25, 0.3, 1.25)
        clockNode.eulerAngles = SCNVector3(0, 0, 0.08)
        SCNTransaction.commit()
    }

    // MARK: - Scene construction

    private func buildScene() {
        scene.background.contents = UIColor(red: 0.07, green: 0.08, blue: 0.13, alpha: 1)

        let floor = SCNFloor()
        floor.reflectivity = 0.03
        floor.firstMaterial?.diffuse.contents = UIColor(red: 0.12, green: 0.11, blue: 0.16, alpha: 1)
        scene.rootNode.addChildNode(SCNNode(geometry: floor))

        buildTable()
        buildClock()
        buildHammer()
        buildCameraAndLights()
    }

    private func buildTable() {
        let woodColor = UIColor(red: 0.45, green: 0.30, blue: 0.18, alpha: 1)

        let top = SCNBox(width: 3.4, height: 0.16, length: 2.1, chamferRadius: 0.02)
        top.firstMaterial?.diffuse.contents = woodColor
        let topNode = SCNNode(geometry: top)
        topNode.position = SCNVector3(0, 1.0, 0)
        scene.rootNode.addChildNode(topNode)

        let legGeometry = SCNBox(width: 0.14, height: 0.92, length: 0.14, chamferRadius: 0.01)
        legGeometry.firstMaterial?.diffuse.contents = woodColor
        for (x, z) in [(-1.5, -0.85), (1.5, -0.85), (-1.5, 0.85), (1.5, 0.85)] {
            let leg = SCNNode(geometry: legGeometry)
            leg.position = SCNVector3(Float(x), 0.46, Float(z))
            scene.rootNode.addChildNode(leg)
        }
    }

    private func buildClock() {
        clockNode.name = Self.clockNodeName
        clockNode.position = SCNVector3(-0.75, 1.08, 0)

        let body = SCNBox(width: 0.72, height: 0.72, length: 0.32, chamferRadius: 0.1)
        body.firstMaterial?.diffuse.contents = UIColor(red: 0.85, green: 0.25, blue: 0.22, alpha: 1)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.36, 0)
        clockNode.addChildNode(bodyNode)

        let face = SCNCylinder(radius: 0.27, height: 0.03)
        face.firstMaterial?.diffuse.contents = UIColor(white: 0.96, alpha: 1)
        let faceNode = SCNNode(geometry: face)
        faceNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        faceNode.position = SCNVector3(0, 0.36, 0.16)
        clockNode.addChildNode(faceNode)

        let handColor = UIColor(white: 0.15, alpha: 1)
        let hourHand = SCNBox(width: 0.035, height: 0.16, length: 0.015, chamferRadius: 0)
        hourHand.firstMaterial?.diffuse.contents = handColor
        let hourNode = SCNNode(geometry: hourHand)
        hourNode.position = SCNVector3(0.03, 0.41, 0.185)
        hourNode.eulerAngles = SCNVector3(0, 0, -0.5)
        clockNode.addChildNode(hourNode)

        let minuteHand = SCNBox(width: 0.03, height: 0.22, length: 0.015, chamferRadius: 0)
        minuteHand.firstMaterial?.diffuse.contents = handColor
        let minuteNode = SCNNode(geometry: minuteHand)
        minuteNode.position = SCNVector3(-0.02, 0.42, 0.185)
        minuteNode.eulerAngles = SCNVector3(0, 0, 0.9)
        clockNode.addChildNode(minuteNode)

        let bell = SCNSphere(radius: 0.14)
        bell.firstMaterial?.diffuse.contents = UIColor(red: 0.95, green: 0.78, blue: 0.25, alpha: 1)
        for x in [Float(-0.22), Float(0.22)] {
            let bellNode = SCNNode(geometry: bell)
            bellNode.position = SCNVector3(x, 0.82, 0)
            clockNode.addChildNode(bellNode)
        }

        scene.rootNode.addChildNode(clockNode)
    }

    private func buildHammer() {
        hammerNode.name = Self.hammerNodeName
        hammerNode.position = hammerRestPosition

        let handle = SCNCylinder(radius: 0.045, height: 0.9)
        handle.firstMaterial?.diffuse.contents = UIColor(red: 0.76, green: 0.6, blue: 0.42, alpha: 1)
        let handleNode = SCNNode(geometry: handle)
        handleNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        handleNode.position = SCNVector3(0.1, 0, 0)
        hammerNode.addChildNode(handleNode)

        let head = SCNBox(width: 0.18, height: 0.18, length: 0.4, chamferRadius: 0.03)
        head.firstMaterial?.diffuse.contents = UIColor(white: 0.35, alpha: 1)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(-0.38, 0, 0)
        hammerNode.addChildNode(headNode)

        scene.rootNode.addChildNode(hammerNode)
    }

    private func buildCameraAndLights() {
        let target = SCNNode()
        target.position = SCNVector3(0, 1.1, 0)
        scene.rootNode.addChildNode(target)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 2.3, 3.8)
        let look = SCNLookAtConstraint(target: target)
        look.isGimbalLockEnabled = true
        cameraNode.constraints = [look]
        scene.rootNode.addChildNode(cameraNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 350
        ambient.light?.color = UIColor(white: 0.9, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 850
        key.light?.color = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        key.light?.castsShadow = true
        key.eulerAngles = SCNVector3(-0.9, -0.35, 0)
        scene.rootNode.addChildNode(key)
    }
}
