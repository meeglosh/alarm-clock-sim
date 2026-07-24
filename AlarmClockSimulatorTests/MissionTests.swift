import XCTest
@testable import AlarmClockSimulator

final class MissionTests: XCTestCase {
    private let calendar = Calendar.current
    private let t0 = Date(timeIntervalSince1970: 1_753_000_000)

    func testSameDayYieldsSameMission() {
        let morning = t0
        let evening = calendar.startOfDay(for: t0).addingTimeInterval(23 * 3600)

        XCTAssertEqual(
            MissionFactory.mission(for: morning),
            MissionFactory.mission(for: evening)
        )
    }

    func testMissionsVaryAcrossDays() {
        var metrics = Set<String>()
        var missions = Set<String>()
        for dayOffset in 0..<30 {
            let date = t0.addingTimeInterval(Double(dayOffset) * 86_400)
            let mission = MissionFactory.mission(for: date)
            metrics.insert(mission.title)
            missions.insert("\(mission.title)|\(mission.target)|\(mission.flavor)")
        }
        XCTAssertGreaterThanOrEqual(metrics.count, 3, "a month should span several mission types")
        XCTAssertGreaterThanOrEqual(missions.count, 15, "a month should rarely repeat exact missions")
    }

    func testTargetsStayWithinDesignedBounds() {
        for dayOffset in 0..<365 {
            let date = t0.addingTimeInterval(Double(dayOffset) * 86_400)
            let mission = MissionFactory.mission(for: date)
            switch mission.metric {
            case .bestStreak:
                XCTAssertTrue((3...12).contains(mission.target))
            case .snoozes:
                XCTAssertTrue((6...20).contains(mission.target))
            case .runs:
                XCTAssertTrue((2...4).contains(mission.target))
            case .smashes:
                XCTAssertTrue((1...2).contains(mission.target))
            }
        }
    }
}
