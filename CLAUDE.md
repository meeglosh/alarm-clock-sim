# Alarm Clock Simulator

## Project Overview
A native iOS game. An alarm goes off every 10 minutes. The player either:
- Hits **snooze** → streak +1, alarm resets for another 10 minutes
- Grabs the **hammer** and smashes the alarm → game over, streak is final

Streaks post to a **global leaderboard**. Monetization via streak freezes (see IAP below).

## Platform
- iOS 17+ only
- Swift 5.9+ / SwiftUI for UI chrome, SceneKit for the 3D bedside table scene
- Scene: a bedside table with an alarm clock (interactive — snooze button) and a hammer (interactive — smash gesture). Keep the 3D scene simple and low-poly; this is not a graphics showcase, the loop is the whole game.

## Core Gameplay Loop
1. Timer counts down 10:00 → alarm triggers (sound + visual: clock shakes/rings)
2. Player taps snooze button (on-screen tap or tap the 3D clock model) → streak += 1, timer resets, brief "safe" animation
3. Player instead taps/swipes the hammer onto the clock → game over screen, final streak recorded
4. If a streak freeze is active, a triggered alarm during the freeze window auto-snoozes without requiring player input

## Leaderboard
- Use **GameKit / Game Center** for the global leaderboard (simplest native option, no backend to stand up). Submit streak score via `GKLeaderboard` on game-over.
- If Game Center feels too limiting later (custom leaderboard UI, cross-platform), that's a decision to revisit explicitly, not something to switch to unprompted.

## In-App Purchases (StoreKit 2)
- **Consumable**: "12 Hours of Peace" streak freeze — $1.99. Suspends alarm triggers for 12 hours; streak stays alive without snooze taps during that window.
- **Auto-renewable subscription**: Unlimited streak freezes — $4.99/month. While active, alarms never end the game even if the hammer is used accidentally (or disable the hammer interaction entirely during freeze — decide and note here once chosen).
- Use StoreKit 2's `Product` / `Transaction` APIs, not the older StoreKit 1 APIs.
- Restore purchases must be supported (App Store requirement).
- All purchases need server-side receipt validation eventually — for MVP, on-device `Transaction.currentEntitlements` is fine, but flag this as a pre-launch hardening item.

## Architecture
- Pattern: MVVM — `@Observable` view models for game state (timer, streak, freeze status), SwiftUI views for UI, SceneKit nodes for the 3D scene
- Game state (`GameState`: idle / ringing / snoozed / gameOver) drives both the SwiftUI overlay and the SceneKit animations — single source of truth, not duplicated state
- Persist current streak + best streak locally (UserDefaults or SwiftData is fine for this scale)

## Project Setup
The Xcode project is generated via **XcodeGen** from `project.yml` rather than hand-edited in Xcode. This solves the "new Swift files don't auto-add to the target" problem: any file placed under `AlarmClockSimulator/` is picked up automatically the next time the project is regenerated.

1. Done: `AlarmClockSimulator.xcodeproj` generated from `project.yml` (App target, iOS 17+, SwiftUI, `AlarmClockSimulatorTests` target).
2. Done: Game Center entitlement (`com.apple.developer.game-center`) is set in `AlarmClockSimulator/AlarmClockSimulator.entitlements` and wired via `CODE_SIGN_ENTITLEMENTS`. In-App Purchase needs no entitlement or capability toggle to function — StoreKit 2 works once the products exist in App Store Connect (see below).
3. **Still needed, in Xcode (one-time, human):** open the project, sign in with your Apple ID, and set `DEVELOPMENT_TEAM` — either in Xcode's Signing & Capabilities tab or directly in `project.yml`. Nothing will run on-device or use Game Center until this is set.
4. **Still needed, App Store Connect (human only):** create the IAP products — the consumable ("12 Hours of Peace", $1.99) and the auto-renewable subscription ($4.99/month). Claude Code cannot do this; it requires the App Store Connect web UI and your Apple Developer account.
5. After adding/removing Swift files: run `xcodegen generate` to resync the project (instead of dragging files into a target in Xcode), then commit the regenerated `AlarmClockSimulator.xcodeproj`.

## Key Commands
```bash
xcodebuild build \
  -scheme AlarmClockSimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -quiet

xcodebuild test \
  -scheme AlarmClockSimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -quiet 2>&1 | tail -30

xcrun simctl list devices available
```

## Things to Watch For
- Game Center and real StoreKit purchases can't be fully tested in the simulator for sandbox/production flows — flag anything that needs a real device or TestFlight
- Don't let the hammer-smash interaction be too easy to trigger by accident (this is the "lose" state) — flag UX/hit-testing decisions rather than guessing
- New Swift files need manual Xcode target membership (see Project Setup above)

## Testing
- Unit tests: streak logic, timer/freeze interactions, IAP entitlement checks — pure Swift, no SceneKit/UI dependency
- Manual testing on simulator for the 3D scene and animations; Game Center/IAP sandbox flows need a real device or TestFlight build
