import GameKit
import UIKit

/// Game Center authentication and leaderboard submission. Scores that can't
/// be submitted (not signed in, offline, transient error) are kept as a
/// pending high score in UserDefaults and retried after the next successful
/// authentication, so a game-over is never silently dropped.
@MainActor
@Observable
final class GameCenterManager {
    /// Must match the leaderboard ID configured in App Store Connect.
    static let leaderboardID = "com.meeglosh.AlarmClockSimulator.longestStreak"

    private(set) var isAuthenticated = false

    @ObservationIgnored private let defaults: UserDefaults

    private enum Key {
        static let pendingScore = "gamecenter.pendingScore"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Call once at startup. Setting the handler kicks off authentication;
    /// GameKit also re-invokes it on foreground transitions.
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, _ in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    self.present(viewController)
                }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if self.isAuthenticated {
                    await self.submitPendingScore()
                }
            }
        }
    }

    /// Records the score locally first, then submits the best pending value.
    /// Game Center keeps each player's highest score, so re-submitting an
    /// older best after a missed attempt is always safe.
    func submit(streak: Int) async {
        guard streak > 0 else { return }
        let pending = max(streak, defaults.integer(forKey: Key.pendingScore))
        defaults.set(pending, forKey: Key.pendingScore)
        guard isAuthenticated else { return }
        do {
            try await GKLeaderboard.submitScore(
                pending,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [Self.leaderboardID]
            )
            defaults.removeObject(forKey: Key.pendingScore)
        } catch {
            // Score stays pending; retried on next auth or game-over.
        }
    }

    private func submitPendingScore() async {
        let pending = defaults.integer(forKey: Key.pendingScore)
        guard pending > 0 else { return }
        await submit(streak: pending)
    }

    private func present(_ viewController: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else {
            return
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        top.present(viewController, animated: true)
    }
}
