import Foundation

/// The museum of silenced clocks: collectibles unlocked by lifetime
/// milestones. Purely derived from GameViewModel's stats, so there is no
/// extra persistence and unlocks can never get out of sync.
struct CollectionItem: Identifiable, Equatable {
    enum Metric: Equatable {
        case smashes
        case snoozes
        case runs
        case bestStreak
        case freezes
        case oversleeps
    }

    let id: String
    let emoji: String
    let name: String
    let flavor: String
    let metric: Metric
    let threshold: Int

    var requirementText: String {
        switch metric {
        case .smashes: threshold == 1 ? "Smash your first clock" : "Smash \(threshold) clocks"
        case .snoozes: "Snooze \(threshold) times"
        case .runs: "Start \(threshold) runs"
        case .bestStreak: "Reach a \(threshold) streak"
        case .freezes: threshold == 1 ? "Use a streak freeze" : "Use \(threshold) streak freezes"
        case .oversleeps: "Oversleep once"
        }
    }
}

enum ClockCollection {
    static let all: [CollectionItem] = [
        CollectionItem(
            id: "oldFaithful", emoji: "⏰", name: "Old Faithful",
            flavor: "Your first victim. It never saw the hammer coming.",
            metric: .smashes, threshold: 1
        ),
        CollectionItem(
            id: "beeper", emoji: "📟", name: "The Beeper",
            flavor: "Beeped its last beep.",
            metric: .snoozes, threshold: 10
        ),
        CollectionItem(
            id: "wristNemesis", emoji: "⌚", name: "Wrist Nemesis",
            flavor: "Followed you everywhere. Not anymore.",
            metric: .snoozes, threshold: 50
        ),
        CollectionItem(
            id: "kitchenNightmare", emoji: "⏲️", name: "Kitchen Nightmare",
            flavor: "Its eggs were never soft-boiled.",
            metric: .snoozes, threshold: 150
        ),
        CollectionItem(
            id: "clockRadio", emoji: "📻", name: "Clock Radio",
            flavor: "Woke you with ads for mattresses. The irony.",
            metric: .snoozes, threshold: 500
        ),
        CollectionItem(
            id: "navigator", emoji: "🧭", name: "The Navigator",
            flavor: "Always pointing at 'get up'. Wrong direction.",
            metric: .runs, threshold: 20
        ),
        CollectionItem(
            id: "grandfathersRegret", emoji: "🕰️", name: "Grandfather's Regret",
            flavor: "Tick. Tock. Silence.",
            metric: .bestStreak, threshold: 25
        ),
        CollectionItem(
            id: "sunriseSimulator", emoji: "🌞", name: "Sunrise Simulator",
            flavor: "Simulated its final sunrise.",
            metric: .bestStreak, threshold: 50
        ),
        CollectionItem(
            id: "centurion", emoji: "💯", name: "The Centurion",
            flavor: "One hundred snoozes of pure defiance.",
            metric: .bestStreak, threshold: 100
        ),
        CollectionItem(
            id: "cryoChamber", emoji: "❄️", name: "Cryo Chamber",
            flavor: "Frozen in time, exactly as intended.",
            metric: .freezes, threshold: 1
        ),
        CollectionItem(
            id: "oneThatGotAway", emoji: "💤", name: "The One That Got Away",
            flavor: "It rang. You didn't. Respect.",
            metric: .oversleeps, threshold: 1
        ),
        CollectionItem(
            id: "demolitionExpert", emoji: "🔨", name: "Demolition Expert",
            flavor: "Ten clocks. Zero remorse.",
            metric: .smashes, threshold: 10
        ),
    ]
}

extension GameViewModel {
    func collectionValue(for metric: CollectionItem.Metric) -> Int {
        switch metric {
        case .smashes: totalSmashes
        case .snoozes: totalSnoozes
        case .runs: totalRuns
        case .bestStreak: bestStreak
        case .freezes: freezesApplied
        case .oversleeps: totalOversleeps
        }
    }

    func isUnlocked(_ item: CollectionItem) -> Bool {
        collectionValue(for: item.metric) >= item.threshold
    }

    func collectionProgress(_ item: CollectionItem) -> Int {
        min(collectionValue(for: item.metric), item.threshold)
    }

    var unlockedCollectionCount: Int {
        ClockCollection.all.filter(isUnlocked).count
    }
}
