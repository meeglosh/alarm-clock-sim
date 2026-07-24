import AVFoundation
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
        impactGenerator.impactOccurred()
    }

    private func loadPlayer(_ name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }
}
