# Session Handoff

Last updated: 2026-08-25. This file captures where the project stands so a future session can pick up without re-deriving state. Durable project knowledge (architecture, pipelines, ASC API recipes) lives in `CLAUDE.md`; this file is only the "what's in flight right now" layer.

## Where we are: APPROVED AND LIVE 🎉

As of the 2026-08-25 ASC API check:

- **v1.0 and v1.0.1 are both `READY_FOR_SALE`** — the app is on the App Store.
- The 1.0 submission from Aug 18 (`cd64224b`) completed, and a **1.0.1 was submitted 2026-08-21 (`e34358e3`) and also completed** — so an update shipped right behind the initial approval.
- Earlier submissions (Aug 14–15) were withdrawn/superseded (`COMPLETE` with items `REMOVED`), not rejections.
- A stray 1.0 `appStoreVersion` row still sits in `PREPARE_FOR_SUBMISSION` — resubmission artifact, harmless.
- To re-check status any time: JWT via PyJWT against the ASC API (key `QGMKYYB893`, app ID `6799553201` — full recipe in `CLAUDE.md`), query `/v1/apps/6799553201/appStoreVersions` and `/v1/reviewSubmissions?filter[app]=6799553201`.

Likely next moves now that it's live: watch Game Center leaderboard for real scores, monitor crashes/reviews in ASC.

## Repo state

- 5 commits were local-only until this handoff was pushed (icon rework, Info.plist version-key fix, subscription-screen legal links, notification primer/banner work, iPhone-only + privacy manifest).
- Untracked but intentionally kept out of the commit: new `img/` marketing/source assets (`hero.png`, `title.png`, `icon-*.png`, `ACS-appStore-icon2.jpg`) and `videos/` (App Store preview mp4s: `AlarmClockSim-coreGameplay.mp4`, `AlarmClockSim-streak.mp4`, `combined.mp4`). Decide deliberately whether these belong in git (the mp4s are large binaries) or should stay local / move to LFS.
- Working-tree modifications to `project.pbxproj`, `project.yml`, `ExportOptions.plist` existed at session start on 2026-08-20; by 2026-08-25 the tracked files were clean apart from the untracked assets above.

## Open items (pre-launch checklist)

- ~~Paid Apps Agreement~~ — resolved. This was the actual cause of a Guideline
  2.1(b) rejection ("Unable to Complete Request" on the subscribe button
  during review): the Paid Apps Agreement was active, but a separate **Free
  Apps Agreement** also needed signing (this app is priced Free with IAP)
  and hadn't been. Both are now active — `GET /v2/inAppPurchases/6799549502`
  and `GET /v1/subscriptions/6799567335` both report `state: APPROVED`, and
  real production purchases are confirmed working since Apple's own review
  completed the subscribe flow successfully.
- ~~IAP/subscription App Store review screenshot~~ — resolved, uploaded via
  the reserve-then-PUT flow (`POST /v1/inAppPurchaseAppStoreReviewScreenshots`
  / `POST /v1/subscriptionAppStoreReviewScreenshots`). Both products'
  `state` is `APPROVED`, not `MISSING_METADATA` anymore.
- Server-side receipt validation is flagged as post-MVP hardening (`Transaction.currentEntitlements` on-device for now).
- Game Center / real StoreKit flows still only verified via TestFlight/device, not Simulator.

## Reusable tooling

The App Store Connect API client now lives in the repo at
`scripts/appstoreconnect/asc_api.py` (JWT auth via PyJWT, same key as
above) — no need to reconstruct it from scratch each session anymore.
Usage: `python3 scripts/appstoreconnect/asc_api.py GET|POST|PATCH|DELETE <path> ['<json-body>']`.

## Session log

- **2026-08-20:** Checked review status via ASC API — current submission (Aug 18) `WAITING_FOR_REVIEW`, prior three submissions withdrawn not rejected. Gmail integration lacked read scope, so inbox couldn't be checked for App Review mail; scan manually for `noreply@email.apple.com`.
- **2026-08-25 (earlier):** Re-checked ASC — **1.0 approved and live; 1.0.1 (submitted Aug 21) also approved; both `READY_FOR_SALE`.** Created this handoff file; committed and pushed it along with the 5 pending commits.
- **2026-08-25 (later):** Confirmed both IAP and subscription now show `state: APPROVED` (previously `MISSING_METADATA` per the open items above — that resolved itself once the review screenshots and Free Apps Agreement were sorted during the Aug 18 rejection cycle). Added `scripts/appstoreconnect/asc_api.py` to the repo so the API client persists across sessions instead of being reconstructed from memory each time (it had already been rebuilt twice from scratch earlier in the project due to living only in an ephemeral scratchpad). Folded the App Store Connect submission gotchas (agreements, per-territory subscription pricing, Game Center version linking, Info.plist version-key bug, single review attachment limit, etc.) into `CLAUDE.md` rather than duplicating them here.
