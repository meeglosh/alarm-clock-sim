import XCTest
@testable import AlarmClockSimulator

@MainActor
final class CollectionTests: XCTestCase {
    private var defaults: UserDefaults!
    private let t0 = Date(timeIntervalSince1970: 1_753_000_000)

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "CollectionTests")
        defaults.removePersistentDomain(forName: "CollectionTests")
    }

    private func makeViewModel() -> GameViewModel {
        GameViewModel(
            configuration: GameViewModel.Configuration(alarmInterval: 600, missWindow: 60, freezeDuration: 43_200),
            defaults: defaults
        )
    }

    func testItemIDsAreUnique() {
        let ids = ClockCollection.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testEverythingLockedInitially() {
        XCTAssertEqual(makeViewModel().unlockedCollectionCount, 0)
    }

    func testFirstSmashUnlocksOldFaithful() throws {
        let vm = makeViewModel()
        vm.startRun(now: t0)
        vm.smash(now: t0.addingTimeInterval(10))

        let oldFaithful = try XCTUnwrap(ClockCollection.all.first { $0.id == "oldFaithful" })
        XCTAssertTrue(vm.isUnlocked(oldFaithful))
        XCTAssertEqual(vm.unlockedCollectionCount, 1)
    }

    func testProgressCapsAtThreshold() throws {
        let vm = makeViewModel()
        for i in 0..<3 {
            vm.startRun(now: t0.addingTimeInterval(Double(i) * 1000))
            vm.smash(now: t0.addingTimeInterval(Double(i) * 1000 + 10))
        }
        let oldFaithful = try XCTUnwrap(ClockCollection.all.first { $0.id == "oldFaithful" })
        XCTAssertEqual(vm.collectionProgress(oldFaithful), 1)
    }
}
