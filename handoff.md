# Session Handoff

Last updated: 2026-10-16. This file captures where the project stands so a future session can pick up without re-deriving state. Durable project knowledge (architecture, pipelines, ASC API recipes) lives in `CLAUDE.md`; this file is only the "what's in flight right now" layer.

## Where we are: 1.0.2 LIVE, nothing in review

As of the 2026-10-16 ASC API check:

- **1.0, 1.0.1, and 1.0.2 are all `READY_FOR_SALE`.** 1.0.2 (build 6) is the current live version.
- All 6 review submissions are `COMPLETE`, including 1.0.2's (`942629c8-72b4-49fb-b890-781feea70503`, submitted 2026-09-15). Nothing is pending review.
- A stray 1.0 `appStoreVersion` row (`a3d0f80e`) still sits in `PREPARE_FOR_SUBMISSION`. It's left over from a resubmission and is harmless.
- To re-check status any time: `python3 scripts/appstoreconnect/asc_api.py GET /v1/apps/6799553201/appStoreVersions` and `GET "/v1/reviewSubmissions?filter[app]=6799553201"`.

Likely next moves: watch the Game Center leaderboard for real scores, monitor crashes/reviews in ASC.

## What 1.0.2 was

1.0.2 changed metadata only. The third App Store screenshot had been captured during `SmashCinematicView`'s full-screen white flash, leaving a ~66% white blend baked into the uploaded PNG. The clean recovered frame (`img/final_smash_repaired.png`, screenshot ID `90114316-d87f-4005-acf1-e2609b817f89`) replaced it in the third slot. `CLAUDE.md` now notes to capture after the flash.

The build upload also exposed a stale manual-signing profile. The current App Store profile is `GAPCO AlarmClockSimulator App Store Sep 2026` (profile ID `U3H9G9G5RT`) for distribution certificate `WZGT4Z279S`. `ExportOptions.plist` and `CLAUDE.md` point to it.

## Repo state

- The 1.0.2 version bump (`project.yml` / regenerated `project.pbxproj`), the new signing profile in `ExportOptions.plist`, and the `CLAUDE.md` updates were committed 2026-10-16 alongside this file.
- `videos/` and the local `img/` marketing assets (`hero.png`, `title.png`, `icon-*.png`, `final_smash_repaired.png`) are gitignored and stay local only. The original `img/ACS-*` source mockups remain tracked.

## Open items

- Server-side receipt validation is flagged as post-MVP hardening (`Transaction.currentEntitlements` on-device for now).
- Game Center / real StoreKit flows still only verified via TestFlight/device, not Simulator.
- `scripts/appstoreconnect/asc_api.py` needs PyJWT + cryptography, which aren't installed for this machine's system `python3`. Either `pip3 install --user pyjwt cryptography` or use a throwaway venv (`python3 -m venv <dir> && <dir>/bin/pip install pyjwt cryptography`).

Resolved earlier (details in `CLAUDE.md`): the Paid + Free Apps Agreements (cause of the Guideline 2.1(b) subscribe-button rejection), and the IAP/subscription review screenshots (both products `APPROVED`).

## Session log

- **2026-08-20:** Checked review status via ASC API. The current submission (Aug 18) was `WAITING_FOR_REVIEW`, and the prior three submissions were withdrawn, not rejected. The Gmail integration lacked read scope, so the inbox couldn't be checked for App Review mail; scan manually for `noreply@email.apple.com`.
- **2026-08-25:** 1.0 approved and live; 1.0.1 (submitted Aug 21) also approved. Created this handoff file. Confirmed both IAP and subscription `APPROVED`. Added `scripts/appstoreconnect/asc_api.py` to the repo and folded the ASC submission gotchas into `CLAUDE.md`.
- **2026-09-15:** Shipped 1.0.2 (build 6) to review to replace the washed-out smash screenshot. Rotated to the `Sep 2026` provisioning profile.
- **2026-10-16:** Confirmed 1.0.2 approved and `READY_FOR_SALE`; nothing in review. Committed the outstanding 1.0.2 working-tree changes.
