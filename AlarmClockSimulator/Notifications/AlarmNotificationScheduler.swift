import UserNotifications

/// Schedules local notifications so alarms reach the player while the app is
/// backgrounded or the device is locked. Only the next uncovered alarm is
/// scheduled (plus a last-chance nudge and an overslept notice); a snooze
/// from the notification's action button reschedules the next round.
@MainActor
@Observable
final class AlarmNotificationScheduler {
    nonisolated static let alarmCategoryID = "ALARM_CATEGORY"
    nonisolated static let snoozeActionID = "SNOOZE_ACTION"

    private(set) var isAuthorized = false

    @ObservationIgnored private let center = UNUserNotificationCenter.current()

    /// Call once at launch: registers the snooze action and syncs
    /// authorization state for players who already granted permission.
    func configure() {
        let snooze = UNNotificationAction(
            identifier: Self.snoozeActionID,
            title: "Snooze",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.alarmCategoryID,
            actions: [snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
        Task { await refreshAuthorizationStatus() }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            await refreshAuthorizationStatus()
            return
        }
        isAuthorized = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func scheduleForBackground(game: GameViewModel, now: Date = Date()) async {
        center.removeAllPendingNotificationRequests()
        guard isAuthorized, game.phase.isRunActive,
              let alarmDate = game.firstUncoveredAlarmDate() else {
            return
        }
        let missWindow = game.configuration.missWindow

        await schedule(
            id: "alarm.ring",
            title: "WAKE UP!",
            body: "Your alarm is ringing. Snooze within \(Int(missWindow)) seconds to keep your streak alive.",
            fireDate: alarmDate,
            now: now,
            isAlarm: true
        )
        await schedule(
            id: "alarm.lastChance",
            title: "Last chance!",
            body: "Snooze right now or your streak is toast.",
            fireDate: alarmDate.addingTimeInterval(missWindow / 2),
            now: now,
            isAlarm: true
        )
        await schedule(
            id: "alarm.overslept",
            title: "You overslept",
            body: "Your streak has ended. Open the app to start a new one.",
            fireDate: alarmDate.addingTimeInterval(missWindow + 1),
            now: now,
            isAlarm: false
        )
    }

    private func schedule(
        id: String,
        title: String,
        body: String,
        fireDate: Date,
        now: Date,
        isAlarm: Bool
    ) async {
        let delay = fireDate.timeIntervalSince(now)
        guard delay > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        // The game's own alarm tone, so it's unmistakable among other
        // notifications; the overslept notice keeps the system sound.
        content.sound = isAlarm
            ? UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
            : .default
        content.interruptionLevel = .timeSensitive
        if isAlarm {
            content.categoryIdentifier = Self.alarmCategoryID
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}

/// Routes notification callbacks back into the game. Held strongly by the
/// App struct because UNUserNotificationCenter's delegate reference is weak.
///
/// Deliberately implements the completion-handler delegate variants, NOT
/// the async ones: the async variants resume UIKit's post-delivery
/// bookkeeping (state restoration/snapshotting) on the Swift concurrency
/// pool, which asserts and crashes when a locked device processes the
/// notification. Completing explicitly on the main thread avoids that.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var onSnoozeAction: (@MainActor () async -> Void)?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // The in-app ringing UI handles alarms while foregrounded.
        DispatchQueue.main.async {
            completionHandler([])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let isSnooze = response.actionIdentifier == AlarmNotificationScheduler.snoozeActionID
        Task { @MainActor [weak self] in
            if isSnooze {
                await self?.onSnoozeAction?()
            }
            completionHandler()
        }
    }
}
