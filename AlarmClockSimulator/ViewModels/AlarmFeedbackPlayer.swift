import AudioToolbox
import UIKit

/// Alarm and interaction feedback via system sounds and haptics. System
/// sound 1005 is the built-in alarm tone; a custom bundled sound can replace
/// it later without touching game logic.
@MainActor
final class AlarmFeedbackPlayer: AlarmFeedback {
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    func alarmPulse() {
        AudioServicesPlaySystemSound(1005)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    func snoozed() {
        notificationGenerator.notificationOccurred(.success)
    }

    func smashed() {
        impactGenerator.impactOccurred()
    }
}
