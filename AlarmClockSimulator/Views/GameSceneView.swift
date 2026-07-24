import SceneKit
import SwiftUI

/// SwiftUI wrapper for the SceneKit view. Tap the clock to snooze; drag the
/// hammer and release it over the clock to smash. The drag is the deliberate,
/// multi-step gesture that keeps the lose-state from firing accidentally.
struct GameSceneView: UIViewRepresentable {
    let controller: BedsideSceneController
    var isHammerEnabled: Bool
    var onClockTap: () -> Void
    var onHammerSmash: () -> Void

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = controller.scene
        view.antialiasingMode = .multisampling4X
        view.isPlaying = true

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: GameSceneView
        private var isDraggingHammer = false
        private var hammerScreenZ: Float = 0

        init(parent: GameSceneView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            if nodeName(in: view, at: gesture.location(in: view)) == BedsideSceneController.clockNodeName {
                parent.onClockTap()
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            let location = gesture.location(in: view)

            switch gesture.state {
            case .began:
                guard parent.isHammerEnabled,
                      nodeName(in: view, at: location) == BedsideSceneController.hammerNodeName else {
                    return
                }
                isDraggingHammer = true
                hammerScreenZ = view.projectPoint(parent.controller.hammerWorldPosition).z
                parent.controller.liftHammer()
            case .changed:
                guard isDraggingHammer else { return }
                var world = view.unprojectPoint(
                    SCNVector3(Float(location.x), Float(location.y), hammerScreenZ)
                )
                world.y = max(world.y, 1.3)
                parent.controller.moveHammer(to: world)
            case .ended:
                guard isDraggingHammer else { return }
                isDraggingHammer = false
                let dropTarget = nodeName(
                    in: view,
                    at: location,
                    excluding: BedsideSceneController.hammerNodeName
                )
                if dropTarget == BedsideSceneController.clockNodeName {
                    parent.onHammerSmash()
                } else {
                    parent.controller.returnHammerToRest()
                }
            case .cancelled, .failed:
                if isDraggingHammer {
                    isDraggingHammer = false
                    parent.controller.returnHammerToRest()
                }
            default:
                break
            }
        }

        /// Hit-tests every node along the ray (not just the closest) so the
        /// dragged hammer floating in front of the clock can be skipped.
        private func nodeName(in view: SCNView, at point: CGPoint, excluding excludedName: String? = nil) -> String? {
            let results = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
            for result in results {
                if let name = namedAncestor(of: result.node), name != excludedName {
                    return name
                }
            }
            return nil
        }

        private func namedAncestor(of node: SCNNode) -> String? {
            var current: SCNNode? = node
            while let node = current {
                if let name = node.name { return name }
                current = node.parent
            }
            return nil
        }
    }
}
