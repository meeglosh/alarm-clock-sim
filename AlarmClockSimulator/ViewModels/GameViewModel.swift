import Foundation
import Observation

enum GamePhase: Equatable {
    case idle
    case counting
    case ringing
    case gameOver(GameOverReason)

    var isRunActive: Bool {
        self == .counting || self == .ringing
    }

    var isGameOver: Bool {
        if case .gameOver = self { return true }
        return false
    }
}

enum GameOverReason: Equatable {
    case smashed
    case overslept
}

@MainActor
protocol AlarmFeedback: AnyObject {
    func alarmPulse()
    func snoozed()
    func smashed()
}

/// Single source of truth for the gameplay loop. Every rule is evaluated
/// against wall-clock dates rather than accumulated timer ticks, so
/// backgrounding, app relaunch, and dropped frames all resolve the same way:
/// `reconcile(now:)` replays whatever should have happened since the last
/// observation, including crediting auto-snoozes for alarms covered by a
/// freeze and ending the run if an alarm went unanswered past the miss
/// window.
@MainActor
@Observable
final class GameViewModel {
    struct Configuration {
        var alarmInterval: TimeInterval = 10 * 60
        var missWindow: TimeInterval = 60
        var freezeDuration: TimeInterval = 12 * 60 * 60
    }

    private(set) var phase: GamePhase = .idle
    private(set) var streak = 0
    private(set) var bestStreak = 0
    private(set) var nextAlarmDate: Date?
    private(set) var ringingSince: Date?
    private(set) var freezeExpiry: Date?
    /// Advanced by the tick loop while a run is active; views derive
    /// countdowns from this instead of re-rendering on their own timers.
    private(set) var displayNow = Date()

    let configuration: Configuration

    /// Fired once per run, with the final streak, whenever a run ends for
    /// any reason (smash or oversleep, including offline reconciliation).
    /// Wired to Game Center submission in the app; nil in tests by default.
    @ObservationIgnored var onRunEnded: ((Int, GameOverReason) -> Void)?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let isUnlimitedFreezeActive: () -> Bool
    @ObservationIgnored private let feedback: (any AlarmFeedback)?
    @ObservationIgnored private nonisolated(unsafe) var tickTask: Task<Void, Never>?
    @ObservationIgnored private var lastPulseAt: Date?

    private enum Key {
        static let streak = "game.streak"
        static let bestStreak = "game.bestStreak"
        static let runActive = "game.runActive"
        static let nextAlarm = "game.nextAlarmDate"
        static let ringingSince = "game.ringingSince"
        static let freezeExpiry = "game.freezeExpiry"
    }

    init(configuration: Configuration = Configuration(),
         defaults: UserDefaults = .standard,
         isUnlimitedFreezeActive: @escaping () -> Bool = { false },
         feedback: (any AlarmFeedback)? = nil) {
        self.configuration = configuration
        self.defaults = defaults
        self.isUnlimitedFreezeActive = isUnlimitedFreezeActive
        self.feedback = feedback
        restore()
    }

    deinit {
        tickTask?.cancel()
    }

    // MARK: - Player actions

    func startRun(now: Date = Date()) {
        guard !phase.isRunActive else { return }
        streak = 0
        ringingSince = nil
        nextAlarmDate = now.addingTimeInterval(configuration.alarmInterval)
        phase = .counting
        persist()
    }

    func snooze(now: Date = Date()) {
        guard phase == .ringing else { return }
        completeSnooze(now: now)
        feedback?.snoozed()
    }

    func smash(now: Date = Date()) {
        guard phase.isRunActive else { return }
        endRun(.smashed)
        feedback?.smashed()
    }

    // MARK: - Freezes

    func applyConsumableFreeze(now: Date = Date()) {
        let base = max(now, freezeExpiry ?? now)
        freezeExpiry = base.addingTimeInterval(configuration.freezeDuration)
        if phase == .ringing {
            completeSnooze(now: now)
        }
        persist()
    }

    func isFreezeActive(at date: Date) -> Bool {
        if isUnlimitedFreezeActive() { return true }
        if let freezeExpiry { return date < freezeExpiry }
        return false
    }

    // MARK: - Time

    func reconcile(now: Date = Date()) {
        if phase == .ringing, let since = ringingSince {
            if isFreezeActive(at: now) {
                completeSnooze(now: now)
            } else if now.timeIntervalSince(since) > configuration.missWindow {
                endRun(.overslept)
            }
        }
        while phase == .counting, let next = nextAlarmDate, next <= now {
            if isFreezeActive(at: next) {
                streak += 1
                bestStreak = max(bestStreak, streak)
                nextAlarmDate = next.addingTimeInterval(configuration.alarmInterval)
                persist()
            } else if now.timeIntervalSince(next) > configuration.missWindow {
                endRun(.overslept)
            } else {
                ringingSince = next
                phase = .ringing
                persist()
            }
        }
        if phase.isRunActive {
            displayNow = now
        }
    }

    func startTicking() {
        guard tickTask == nil else { return }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self else { return }
                self.tick(now: Date())
            }
        }
    }

    func stopTicking() {
        tickTask?.cancel()
        tickTask = nil
    }

    // MARK: - Private

    private func tick(now: Date) {
        reconcile(now: now)
        guard phase == .ringing else {
            lastPulseAt = nil
            return
        }
        if lastPulseAt.map({ now.timeIntervalSince($0) >= 1 }) ?? true {
            lastPulseAt = now
            feedback?.alarmPulse()
        }
    }

    private func completeSnooze(now: Date) {
        streak += 1
        bestStreak = max(bestStreak, streak)
        ringingSince = nil
        nextAlarmDate = now.addingTimeInterval(configuration.alarmInterval)
        phase = .counting
        persist()
    }

    private func endRun(_ reason: GameOverReason) {
        bestStreak = max(bestStreak, streak)
        nextAlarmDate = nil
        ringingSince = nil
        phase = .gameOver(reason)
        persist()
        onRunEnded?(streak, reason)
    }

    // MARK: - Persistence

    private func persist() {
        defaults.set(streak, forKey: Key.streak)
        defaults.set(bestStreak, forKey: Key.bestStreak)
        defaults.set(phase.isRunActive, forKey: Key.runActive)
        setDate(nextAlarmDate, forKey: Key.nextAlarm)
        setDate(ringingSince, forKey: Key.ringingSince)
        setDate(freezeExpiry, forKey: Key.freezeExpiry)
    }

    private func restore() {
        bestStreak = defaults.integer(forKey: Key.bestStreak)
        freezeExpiry = date(forKey: Key.freezeExpiry)
        guard defaults.bool(forKey: Key.runActive) else { return }
        streak = defaults.integer(forKey: Key.streak)
        nextAlarmDate = date(forKey: Key.nextAlarm)
        ringingSince = date(forKey: Key.ringingSince)
        if ringingSince != nil {
            phase = .ringing
        } else if nextAlarmDate != nil {
            phase = .counting
        }
    }

    private func setDate(_ date: Date?, forKey key: String) {
        if let date {
            defaults.set(date.timeIntervalSince1970, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func date(forKey key: String) -> Date? {
        guard defaults.object(forKey: key) != nil else { return nil }
        return Date(timeIntervalSince1970: defaults.double(forKey: key))
    }
}
