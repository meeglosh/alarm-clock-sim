import XCTest
@testable import AlarmClockSimulator

/// Pure game-logic tests with injected time and an isolated UserDefaults
/// suite. No StoreKit or UI dependency; these run fine from the CLI.
@MainActor
final class GameViewModelTests: XCTestCase {
    private var defaults: UserDefaults!
    private let t0 = Date(timeIntervalSince1970: 1_753_000_000)
    private let config = GameViewModel.Configuration(
        alarmInterval: 600,
        missWindow: 60,
        freezeDuration: 43_200
    )

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "GameViewModelTests")
        defaults.removePersistentDomain(forName: "GameViewModelTests")
    }

    private func makeViewModel(unlimited: Bool = false) -> GameViewModel {
        GameViewModel(
            configuration: config,
            defaults: defaults,
            isUnlimitedFreezeActive: { unlimited }
        )
    }

    // MARK: - Basic loop

    func testStartRunSchedulesFirstAlarm() {
        let vm = makeViewModel()
        vm.startRun(now: t0)

        XCTAssertEqual(vm.phase, .counting)
        XCTAssertEqual(vm.streak, 0)
        XCTAssertEqual(vm.nextAlarmDate, t0.addingTimeInterval(600))
    }

    func testAlarmRingsWhenDue() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600))

        XCTAssertEqual(vm.phase, .ringing)
        XCTAssertEqual(vm.ringingSince, t0.addingTimeInterval(600))
    }

    func testSnoozeIncrementsStreakAndReschedules() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600))
        let snoozeTime = t0.addingTimeInterval(610)
        vm.snooze(now: snoozeTime)

        XCTAssertEqual(vm.phase, .counting)
        XCTAssertEqual(vm.streak, 1)
        XCTAssertEqual(vm.bestStreak, 1)
        XCTAssertEqual(vm.nextAlarmDate, snoozeTime.addingTimeInterval(600))
    }

    func testSnoozeDoesNothingWhileCounting() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.snooze(now: t0.addingTimeInterval(10))

        XCTAssertEqual(vm.phase, .counting)
        XCTAssertEqual(vm.streak, 0)
    }

    // MARK: - Losing

    func testUnansweredAlarmEndsRunAfterMissWindow() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600 + 61))

        XCTAssertEqual(vm.phase, .gameOver(.overslept))
    }

    func testRingingThenOversleeping() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600))
        XCTAssertEqual(vm.phase, .ringing)

        vm.reconcile(now: t0.addingTimeInterval(600 + 61))
        XCTAssertEqual(vm.phase, .gameOver(.overslept))
    }

    func testSmashEndsRunAndKeepsFinalStreak() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600))
        vm.snooze(now: t0.addingTimeInterval(605))
        vm.reconcile(now: t0.addingTimeInterval(1205))
        vm.snooze(now: t0.addingTimeInterval(1210))
        vm.smash(now: t0.addingTimeInterval(1300))

        XCTAssertEqual(vm.phase, .gameOver(.smashed))
        XCTAssertEqual(vm.streak, 2)
        XCTAssertEqual(vm.bestStreak, 2)
    }

    // MARK: - Freezes

    func testConsumableFreezeAutoSnoozesMissedAlarms() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.applyConsumableFreeze(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(3 * 600 + 30))

        XCTAssertEqual(vm.phase, .counting)
        XCTAssertEqual(vm.streak, 3)
        XCTAssertEqual(vm.nextAlarmDate, t0.addingTimeInterval(4 * 600))
    }

    func testFreezeExpiryCatchUpThenOversleep() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.applyConsumableFreeze(now: t0)
        // Freeze covers alarms strictly before t0+43200: alarms 600...42600,
        // which is 71 auto-snoozes. The alarm at exactly 43200 is uncovered
        // and by 43800 it is past the miss window.
        vm.reconcile(now: t0.addingTimeInterval(43_800))

        XCTAssertEqual(vm.phase, .gameOver(.overslept))
        XCTAssertEqual(vm.streak, 71)
        XCTAssertEqual(vm.bestStreak, 71)
    }

    func testUnlimitedFreezeAutoSnoozesIndefinitely() {
        let vm = makeViewModel(unlimited: true)
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(10 * 600 + 5))

        XCTAssertEqual(vm.phase, .counting)
        XCTAssertEqual(vm.streak, 10)
    }

    func testConsumableFreezesStack() {
        let vm = makeViewModel()
        vm.applyConsumableFreeze(now: t0)
        vm.applyConsumableFreeze(now: t0)

        XCTAssertEqual(vm.freezeExpiry, t0.addingTimeInterval(2 * 43_200))
    }

    func testApplyingFreezeWhileRingingSnoozesImmediately() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600))
        XCTAssertEqual(vm.phase, .ringing)

        let purchaseTime = t0.addingTimeInterval(610)
        vm.applyConsumableFreeze(now: purchaseTime)

        XCTAssertEqual(vm.phase, .counting)
        XCTAssertEqual(vm.streak, 1)
        XCTAssertEqual(vm.nextAlarmDate, purchaseTime.addingTimeInterval(600))
    }

    // MARK: - Notification scheduling support

    func testFirstUncoveredAlarmDateWithoutFreeze() {
        let vm = makeViewModel()
        vm.startRun(now: t0)

        XCTAssertEqual(vm.firstUncoveredAlarmDate(), t0.addingTimeInterval(600))
    }

    func testFirstUncoveredAlarmDateSkipsFrozenAlarms() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.applyConsumableFreeze(now: t0)

        // Alarms up to t0+42600 are auto-snoozed by the freeze; the first
        // one needing attention is at the freeze expiry boundary.
        XCTAssertEqual(vm.firstUncoveredAlarmDate(), t0.addingTimeInterval(43_200))
    }

    func testFirstUncoveredAlarmDateNilWithUnlimitedFreeze() {
        let vm = makeViewModel(unlimited: true)
        vm.startRun(now: t0)

        XCTAssertNil(vm.firstUncoveredAlarmDate())
    }

    func testFirstUncoveredAlarmDateNilWhenNoRunActive() {
        XCTAssertNil(makeViewModel().firstUncoveredAlarmDate())
    }

    func testFirstUncoveredAlarmDateWhileRinging() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600))

        XCTAssertEqual(vm.firstUncoveredAlarmDate(), t0.addingTimeInterval(600))
    }

    // MARK: - Daily counters and missions

    func testDailyCountersAccumulateAndRollOver() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600))
        vm.snooze(now: t0.addingTimeInterval(605))
        vm.smash(now: t0.addingTimeInterval(700))

        XCTAssertEqual(vm.dailyRuns, 1)
        XCTAssertEqual(vm.dailySnoozes, 1)
        XCTAssertEqual(vm.dailySmashes, 1)

        // Two days later everything resets on the next action.
        let later = t0.addingTimeInterval(2 * 86_400)
        vm.startRun(now: later)

        XCTAssertEqual(vm.dailyRuns, 1)
        XCTAssertEqual(vm.dailySnoozes, 0)
        XCTAssertEqual(vm.dailySmashes, 0)
        XCTAssertEqual(vm.dailyBestStreak, 0)
    }

    func testMissionProgressCapsAtTargetAndIgnoresStaleDays() {
        let vm = makeViewModel()
        let mission = DailyMission(
            metric: .snoozes,
            target: 2,
            title: "TEST",
            objective: "",
            flavor: "",
            emoji: "😴"
        )
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600))
        vm.snooze(now: t0.addingTimeInterval(605))
        vm.reconcile(now: t0.addingTimeInterval(1205))
        vm.snooze(now: t0.addingTimeInterval(1210))
        vm.reconcile(now: t0.addingTimeInterval(1810))
        vm.snooze(now: t0.addingTimeInterval(1815))

        XCTAssertEqual(vm.missionProgress(for: mission, now: t0.addingTimeInterval(1820)), 2)
        XCTAssertEqual(vm.missionProgress(for: mission, now: t0.addingTimeInterval(2 * 86_400)), 0)
    }

    // MARK: - Run-end hook

    func testOnRunEndedFiresWithFinalStreakOnSmash() {
        let vm = makeViewModel()
        var ended: [(Int, GameOverReason)] = []
        vm.onRunEnded = { ended.append(($0, $1)) }

        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600))
        vm.snooze(now: t0.addingTimeInterval(605))
        vm.smash(now: t0.addingTimeInterval(700))

        XCTAssertEqual(ended.count, 1)
        XCTAssertEqual(ended.first?.0, 1)
        XCTAssertEqual(ended.first?.1, .smashed)
    }

    func testOnRunEndedFiresOnOversleep() {
        let vm = makeViewModel()
        var ended: [(Int, GameOverReason)] = []
        vm.onRunEnded = { ended.append(($0, $1)) }

        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600 + 61))

        XCTAssertEqual(ended.count, 1)
        XCTAssertEqual(ended.first?.0, 0)
        XCTAssertEqual(ended.first?.1, .overslept)
    }

    // MARK: - Persistence

    func testPersistenceRestoresActiveRun() {
        let vm1 = makeViewModel()
        vm1.startRun(now: t0)
        vm1.reconcile(now: t0.addingTimeInterval(600))
        vm1.snooze(now: t0.addingTimeInterval(605))

        let vm2 = makeViewModel()

        XCTAssertEqual(vm2.phase, .counting)
        XCTAssertEqual(vm2.streak, 1)
        XCTAssertEqual(vm2.bestStreak, 1)
        XCTAssertEqual(vm2.nextAlarmDate, t0.addingTimeInterval(1205))
    }

    func testPersistenceRestoresRingingState() {
        let vm1 = makeViewModel()
        vm1.startRun(now: t0)
        vm1.reconcile(now: t0.addingTimeInterval(600))
        XCTAssertEqual(vm1.phase, .ringing)

        let vm2 = makeViewModel()

        XCTAssertEqual(vm2.phase, .ringing)
        XCTAssertEqual(vm2.ringingSince, t0.addingTimeInterval(600))
    }

    func testBestStreakSurvivesNewRun() {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.reconcile(now: t0.addingTimeInterval(600))
        vm.snooze(now: t0.addingTimeInterval(605))
        vm.smash(now: t0.addingTimeInterval(700))
        vm.startRun(now: t0.addingTimeInterval(800))

        XCTAssertEqual(vm.streak, 0)
        XCTAssertEqual(vm.bestStreak, 1)
    }
}
