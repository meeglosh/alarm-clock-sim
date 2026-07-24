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

## Project Setup (do this first, in Xcode — Claude Code drives from here on)
1. Create the Xcode project: App template, iOS, SwiftUI interface, Swift language.
2. Enable capabilities in Xcode: **Game Center** and **In-App Purchase**.
3. Commit the initial `project.pbxproj` before starting a Claude Code session — Claude Code can edit Swift files but new files won't auto-add to the Xcode target. You'll need to drag them into the target in Xcode (or set up XcodeGen/Tuist if you want that automated too).
4. Create the IAP products in App Store Connect (the consumable and the subscription) — this step can't be done by Claude Code, it requires the App Store Connect web UI and your Apple Developer account.

## Key Commands
```bash
xcodebuild build \
  -scheme AlarmClockSimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet

xcodebuild test \
  -scheme AlarmClockSimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
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
