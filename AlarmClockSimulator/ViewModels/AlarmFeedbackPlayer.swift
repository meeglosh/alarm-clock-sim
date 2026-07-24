import AVFoundation
import CoreHaptics
import UIKit

/// Sound and haptics for the game, backed by the synthesized WAVs in
/// Resources (see scripts/gen_audio.py). Uses the .playback audio session
/// category so the alarm sounds even with the silent switch on; for an
/// alarm game, being audible is the whole point.
@MainActor
final class AlarmFeedbackPlayer: AlarmFeedback {
    private var alarmPlayer: AVAudioPlayer?
    private var smashPlayer: AVAudioPlayer?
    private var snoozePlayer: AVAudioPlayer?
    private var hapticTimer: Timer?
    private var hapticEngine: CHHapticEngine?
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        alarmPlayer = loadPlayer("alarm")
        smashPlayer = loadPlayer("smash")
        snoozePlayer = loadPlayer("snooze")
    }

    func alarmRingingChanged(_ isRinging: Bool) {
        if isRinging {
            guard alarmPlayer?.isPlaying != true else { return }
            try? AVAudioSession.sharedInstance().setActive(true)
            alarmPlayer?.numberOfLoops = -1
            alarmPlayer?.currentTime = 0
            alarmPlayer?.play()
            hapticTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                Task { @MainActor in
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            }
        } else {
            alarmPlayer?.stop()
            hapticTimer?.invalidate()
            hapticTimer = nil
        }
    }

    func snoozed() {
        snoozePlayer?.currentTime = 0
        snoozePlayer?.play()
        notificationGenerator.notificationOccurred(.success)
    }

    func smashed() {
        smashPlayer?.currentTime = 0
        smashPlayer?.play()
        playSmashHaptics()
    }

    // MARK: - Smash haptics

    /// A crash, not a tap: hard slam at impact, a rumble decaying underneath,
    /// and scattered aftershocks matching the debris clinks in the SFX.
    private func playSmashHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            playFallbackRumble()
            return
        }
        do {
            if hapticEngine == nil {
                hapticEngine = try CHHapticEngine()
            }
            guard let engine = hapticEngine else { return }
            try engine.start()
            let player = try engine.makePlayer(with: smashHapticPattern())
            try player.start(atTime: 0)
        } catch {
            playFallbackRumble()
        }
    }

    private func smashHapticPattern() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35),
                ],
                relativeTime: 0.02,
                duration: 0.75
            ),
        ]
        let aftershocks: [(TimeInterval, Float)] = [
            (0.16, 0.7), (0.28, 0.55), (0.42, 0.4), (0.58, 0.3), (0.72, 0.2),
        ]
        for (time, intensity) in aftershocks {
            events.append(
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7),
                    ],
                    relativeTime: time
                )
            )
        }
        let decay = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1.0),
                CHHapticParameterCurve.ControlPoint(relativeTime: 0.75, value: 0.0),
            ],
            relativeTime: 0.02
        )
        return try CHHapticPattern(events: events, parameterCurves: [decay])
    }

    private func playFallbackRumble() {
        impactGenerator.impactOccurred()
        let followUps: [(TimeInterval, CGFloat)] = [(0.15, 0.8), (0.3, 0.6), (0.45, 0.4)]
        for (delay, intensity) in followUps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [impactGenerator] in
                impactGenerator.impactOccurred(intensity: intensity)
            }
        }
    }

    private func loadPlayer(_ name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }
}
