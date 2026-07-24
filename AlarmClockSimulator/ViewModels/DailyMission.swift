import Foundation

/// One mission per calendar day, generated deterministically from the date:
/// same day always yields the same mission (no server, survives reinstall),
/// and a new one appears at local midnight. Templates x parameters x flavor
/// lines give effectively unlimited variety.
struct DailyMission: Equatable {
    enum Metric: Equatable {
        case bestStreak
        case snoozes
        case runs
        case smashes
    }

    let metric: Metric
    let target: Int
    let title: String
    let objective: String
    let flavor: String
    let emoji: String
}

enum MissionFactory {
    /// splitmix64: tiny, high-quality, deterministic across launches.
    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    private static let flavorLines = [
        "The alarm fears commitment. Show it some.",
        "Sleep is a negotiation. Open strong.",
        "Your pillow believes in you.",
        "Legends are forged between alarms.",
        "The mug said it best: no snooze, no win.",
        "Ten more minutes is a lifestyle.",
        "Somewhere, a sheep is judging you.",
        "Do it for the leaderboard. And the nap.",
        "Morning is a scam. Collect your refund.",
        "Every snooze is a tiny act of rebellion.",
    ]

    static func mission(for date: Date, calendar: Calendar = .current) -> DailyMission {
        let day = Int(calendar.startOfDay(for: date).timeIntervalSince1970.rounded() / 86_400)
        var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(day)) &* 0x0BAD_5EED)
        let flavor = flavorLines.randomElement(using: &rng) ?? flavorLines[0]
        let roll = Int.random(in: 0..<100, using: &rng)

        switch roll {
        case 0..<40:
            let target = Int.random(in: 3...12, using: &rng)
            return DailyMission(
                metric: .bestStreak,
                target: target,
                title: "SNOOZE MARATHON",
                objective: "Survive \(target) alarms in a single run.",
                flavor: flavor,
                emoji: "🔥"
            )
        case 40..<70:
            let target = Int.random(in: 6...20, using: &rng)
            return DailyMission(
                metric: .snoozes,
                target: target,
                title: "SERIAL SNOOZER",
                objective: "Hit snooze \(target) times today, across any runs.",
                flavor: flavor,
                emoji: "😴"
            )
        case 70..<90:
            let target = Int.random(in: 2...4, using: &rng)
            return DailyMission(
                metric: .runs,
                target: target,
                title: "COMEBACK KID",
                objective: "Start \(target) separate runs today.",
                flavor: flavor,
                emoji: "🎮"
            )
        default:
            let target = Int.random(in: 1...2, using: &rng)
            return DailyMission(
                metric: .smashes,
                target: target,
                title: "DEMOLITION DAY",
                objective: target == 1
                    ? "Smash a clock today. Guilt-free."
                    : "Smash \(target) clocks today. Guilt-free.",
                flavor: flavor,
                emoji: "🔨"
            )
        }
    }
}
