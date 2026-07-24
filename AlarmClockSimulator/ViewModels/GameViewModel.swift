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
    func alarmRingingChanged(_ isRinging: Bool)
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

    static let dailyChallengeTarget = 5

    private(set) var phase: GamePhase = .idle
    private(set) var streak = 0
    private(set) var bestStreak = 0
    private(set) var nextAlarmDate: Date?
    private(set) var ringingSince: Date?
    private(set) var freezeExpiry: Date?
    /// Advanced by the tick loop while a run is active; views derive
    /// countdowns from this instead of re-rendering on their own timers.
    private(set) var displayNow = Date()

    // Lifetime stats, shown on the Stats screen.
    private(set) var totalRuns = 0
    private(set) var totalSnoozes = 0
    private(set) var totalSmashes = 0
    private(set) var totalOversleeps = 0
    private(set) var freezesApplied = 0
    /// Per-day counters (reset at local midnight); drive the daily
    /// challenge bar and daily mission progress.
    private(set) var dailyBestStreak = 0
    private(set) var dailySnoozes = 0
    private(set) var dailyRuns = 0
    private(set) var dailySmashes = 0

    let configuration: Configuration

    /// Fired once per run, with the final streak, whenever a run ends for
    /// any reason (smash or oversleep, including offline reconciliation).
    /// Wired to Game Center submission in the app; nil in tests by default.
    @ObservationIgnored var onRunEnded: ((Int, GameOverReason) -> Void)?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let isUnlimitedFreezeActive: () -> Bool
    @ObservationIgnored private let feedback: (any AlarmFeedback)?
    @ObservationIgnored private nonisolated(unsafe) var tickTask: Task<Void, Never>?
    @ObservationIgnored private var feedbackRinging = false

    private enum Key {
        static let streak = "game.streak"
        static let bestStreak = "game.bestStreak"
        static let runActive = "game.runActive"
        static let nextAlarm = "game.nextAlarmDate"
        static let ringingSince = "game.ringingSince"
        static let freezeExpiry = "game.freezeExpiry"
        static let totalRuns = "game.totalRuns"
        static let totalSnoozes = "game.totalSnoozes"
        static let totalSmashes = "game.totalSmashes"
        static let totalOversleeps = "game.totalOversleeps"
        static let freezesApplied = "game.freezesApplied"
        static let dailyBestStreak = "game.dailyBestStreak"
        static let dailySnoozes = "game.dailySnoozes"
        static let dailyRuns = "game.dailyRuns"
        static let dailySmashes = "game.dailySmashes"
        static let dailyStamp = "game.dailyStamp"
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
        totalRuns += 1
        rollDailyCountersIfNeeded(now: now)
        dailyRuns += 1
        persist()
    }

    func snooze(now: Date = Date()) {
        guard phase == .ringing else { return }
        completeSnooze(now: now)
        feedback?.snoozed()
        syncRingingFeedback()
    }

    func smash(now: Date = Date()) {
        guard phase.isRunActive else { return }
        totalSmashes += 1
        rollDailyCountersIfNeeded(now: now)
        dailySmashes += 1
        endRun(.smashed)
        feedback?.smashed()
        syncRingingFeedback()
    }

    /// Leave the game-over screen without starting a new run.
    func returnToMenu() {
        guard phase.isGameOver else { return }
        phase = .idle
        persist()
    }

    // MARK: - Freezes

    func applyConsumableFreeze(now: Date = Date()) {
        let base = max(now, freezeExpiry ?? now)
        freezeExpiry = base.addingTimeInterval(configuration.freezeDuration)
        freezesApplied += 1
        if phase == .ringing {
            completeSnooze(now: now)
        }
        persist()
        syncRingingFeedback()
    }

    func isFreezeActive(at date: Date) -> Bool {
        if isUnlimitedFreezeActive() { return true }
        if let freezeExpiry { return date < freezeExpiry }
        return false
    }

    /// The first alarm that will actually need the player's attention:
    /// alarms a freeze will auto-snooze are skipped. Nil when no run is
    /// active or the unlimited freeze means no alarm ever rings. Used to
    /// schedule background notifications.
    func firstUncoveredAlarmDate() -> Date? {
        guard phase.isRunActive else { return nil }
        if isUnlimitedFreezeActive() { return nil }
        if phase == .ringing { return ringingSince }
        guard var candidate = nextAlarmDate else { return nil }
        while isFreezeActive(at: candidate) {
            candidate = candidate.addingTimeInterval(configuration.alarmInterval)
        }
        return candidate
    }

    // MARK: - Daily challenge

    func dailyChallengeProgress(now: Date = Date()) -> Int {
        guard isSameChallengeDay(now) else { return 0 }
        return min(dailyBestStreak, Self.dailyChallengeTarget)
    }

    /// Progress toward today's mission, capped at its target. Yesterday's
    /// counters never leak in: a stale day stamp reads as zero.
    func missionProgress(for mission: DailyMission, now: Date = Date()) -> Int {
        guard isSameChallengeDay(now) else { return 0 }
        let value = switch mission.metric {
        case .bestStreak: dailyBestStreak
        case .snoozes: dailySnoozes
        case .runs: dailyRuns
        case .smashes: dailySmashes
        }
        return min(value, mission.target)
    }

    // MARK: - Time

    func reconcile(now: Date = Date()) {
        if phase == .ringing, let since = ringingSince {
            if isFreezeActive(at: now) {
                completeSnooze(now: now)
            } else if now.timeIntervalSince(since) > configuration.missWindow {
                endRun(.overslept, overslept: true)
            }
        }
        while phase == .counting, let next = nextAlarmDate, next <= now {
            if isFreezeActive(at: next) {
                creditSnooze(now: next)
                nextAlarmDate = next.addingTimeInterval(configuration.alarmInterval)
                persist()
            } else if now.timeIntervalSince(next) > configuration.missWindow {
                endRun(.overslept, overslept: true)
            } else {
                ringingSince = next
                phase = .ringing
                persist()
            }
        }
        if phase.isRunActive {
            displayNow = now
        }
        syncRingingFeedback()
    }

    func startTicking() {
        guard tickTask == nil else { return }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self else { return }
                self.reconcile(now: Date())
            }
        }
    }

    func stopTicking() {
        tickTask?.cancel()
        tickTask = nil
    }

    // MARK: - Private

    private func completeSnooze(now: Date) {
        creditSnooze(now: now)
        ringingSince = nil
        nextAlarmDate = now.addingTimeInterval(configuration.alarmInterval)
        phase = .counting
        persist()
    }

    private func creditSnooze(now: Date) {
        streak += 1
        bestStreak = max(bestStreak, streak)
        totalSnoozes += 1
        rollDailyCountersIfNeeded(now: now)
        dailySnoozes += 1
        dailyBestStreak = max(dailyBestStreak, streak)
    }

    private func rollDailyCountersIfNeeded(now: Date) {
        guard !isSameChallengeDay(now) else { return }
        defaults.set(challengeDayStamp(now), forKey: Key.dailyStamp)
        dailyBestStreak = 0
        dailySnoozes = 0
        dailyRuns = 0
        dailySmashes = 0
    }

    private func endRun(_ reason: GameOverReason, overslept: Bool = false) {
        if overslept {
            totalOversleeps += 1
        }
        bestStreak = max(bestStreak, streak)
        nextAlarmDate = nil
        ringingSince = nil
        phase = .gameOver(reason)
        persist()
        onRunEnded?(streak, reason)
    }

    private func syncRingingFeedback() {
        let ringing = phase == .ringing
        guard ringing != feedbackRinging else { return }
        feedbackRinging = ringing
        feedback?.alarmRingingChanged(ringing)
    }

    private func challengeDayStamp(_ now: Date) -> Double {
        Calendar.current.startOfDay(for: now).timeIntervalSince1970
    }

    private func isSameChallengeDay(_ now: Date) -> Bool {
        defaults.double(forKey: Key.dailyStamp) == challengeDayStamp(now)
    }

    #if DEBUG
    /// Screenshot/dev harness support: wipe any persisted run so launch
    /// arguments can force a specific screen deterministically.
    func debugResetToIdle() {
        phase = .idle
        streak = 0
        nextAlarmDate = nil
        ringingSince = nil
        freezeExpiry = nil
        persist()
    }
    #endif

    // MARK: - Persistence

    private func persist() {
        defaults.set(streak, forKey: Key.streak)
        defaults.set(bestStreak, forKey: Key.bestStreak)
        defaults.set(phase.isRunActive, forKey: Key.runActive)
        defaults.set(totalRuns, forKey: Key.totalRuns)
        defaults.set(totalSnoozes, forKey: Key.totalSnoozes)
        defaults.set(totalSmashes, forKey: Key.totalSmashes)
        defaults.set(totalOversleeps, forKey: Key.totalOversleeps)
        defaults.set(freezesApplied, forKey: Key.freezesApplied)
        defaults.set(dailyBestStreak, forKey: Key.dailyBestStreak)
        defaults.set(dailySnoozes, forKey: Key.dailySnoozes)
        defaults.set(dailyRuns, forKey: Key.dailyRuns)
        defaults.set(dailySmashes, forKey: Key.dailySmashes)
        setDate(nextAlarmDate, forKey: Key.nextAlarm)
        setDate(ringingSince, forKey: Key.ringingSince)
        setDate(freezeExpiry, forKey: Key.freezeExpiry)
    }

    private func restore() {
        bestStreak = defaults.integer(forKey: Key.bestStreak)
        freezeExpiry = date(forKey: Key.freezeExpiry)
        totalRuns = defaults.integer(forKey: Key.totalRuns)
        totalSnoozes = defaults.integer(forKey: Key.totalSnoozes)
        totalSmashes = defaults.integer(forKey: Key.totalSmashes)
        totalOversleeps = defaults.integer(forKey: Key.totalOversleeps)
        freezesApplied = defaults.integer(forKey: Key.freezesApplied)
        dailyBestStreak = defaults.integer(forKey: Key.dailyBestStreak)
        dailySnoozes = defaults.integer(forKey: Key.dailySnoozes)
        dailyRuns = defaults.integer(forKey: Key.dailyRuns)
        dailySmashes = defaults.integer(forKey: Key.dailySmashes)
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
