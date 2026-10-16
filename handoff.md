# Session Handoff

Last updated: 2026-10-16 (evening). This file captures where the project stands so a future session can pick up without re-deriving state. Durable project knowledge (architecture, pipelines, ASC API recipes) lives in `CLAUDE.md`; this file is only the "what's in flight right now" layer.

## Where we are: 1.0.3 WAITING FOR REVIEW (ASO listing refresh)

As of 2026-10-16:

- **1.0.3 (build 7) is `WAITING_FOR_REVIEW`.** Review submission `05870194-3dd2-4d3f-a15b-de5c39a712ff`, appStoreVersion `e5c7a9c7-c703-49e6-a380-42032ff7a696`, build `b6e88fd8-863f-4017-a92e-7cafd285438e`. Release type `AFTER_APPROVAL`. No code changes; it only exists because name/subtitle/keywords/description/category can only change with a new version.
- 1.0, 1.0.1, and 1.0.2 are `READY_FOR_SALE`; 1.0.2 is live until 1.0.3 is approved.
- A stray 1.0 `appStoreVersion` row (`a3d0f80e`) still sits in `PREPARE_FOR_SUBMISSION`. It's left over from a resubmission and is harmless.
- To re-check status: `python3 scripts/appstoreconnect/asc_api.py GET /v1/apps/6799553201/appStoreVersions` and `GET "/v1/reviewSubmissions?filter[app]=6799553201"`.

### Why 1.0.3: moving off the "AI slop" framing

Downloads were low and the self-deprecating "AI slop" pitch wasn't landing, so the listing was rewritten around how frustrating the game is (still tongue-in-cheek) and optimized for search:

- **Name:** unchanged, `Alarm Clock Simulator` (user's choice; brand kept, search terms go in subtitle/keywords).
- **Subtitle:** `100% Certified AI Slop` → `Snooze or Smash: A Rage Game` (subtitle is indexed for search; the old one wasted it).
- **Keywords** (100/100 chars, no words repeated from name/subtitle, since Apple already indexes those): `hardest,impossible,annoying,frustrating,wake,hammer,streak,funny,timer,sleep,challenge,hard,joke,tap`. Old set wasted space on `alarm,clock,snooze` (already in the name) plus `slop,ai`.
- **Description:** rewritten around the frustration; fake "reviews" section and all AI mentions removed; subscription terms, EULA, privacy, and "Real Life Comes First" note kept. Not search-indexed on iOS, so it affects downloads, not ranking.
- **Promotional text:** updated on the live 1.0.2 immediately (no review needed) and inherited by 1.0.3.
- **Secondary category:** added `Entertainment` (primary stays Games > Casual).
- Screenshots inherited unchanged from 1.0.2 (verified by checksum, incl. the repaired smash frame). They have no AI wording. The support/marketing page also had none.

Possible follow-ups: add caption banners to the screenshots (known to help downloads); after ~2 weeks live, compare impressions/downloads in ASC Analytics against before and swap out keywords that aren't bringing traffic.

## What 1.0.2 was

1.0.2 changed metadata only. The third App Store screenshot had been captured during `SmashCinematicView`'s full-screen white flash, leaving a ~66% white blend baked into the uploaded PNG. The clean recovered frame (`img/final_smash_repaired.png`, screenshot ID `90114316-d87f-4005-acf1-e2609b817f89`) replaced it in the third slot. `CLAUDE.md` now notes to capture after the flash.

The build upload also exposed a stale manual-signing profile. The current App Store profile is `GAPCO AlarmClockSimulator App Store Sep 2026` (profile ID `U3H9G9G5RT`) for distribution certificate `WZGT4Z279S`. `ExportOptions.plist` and `CLAUDE.md` point to it.

## Repo state

- 1.0.3: `project.yml` bumped to 1.0.3 / build 7 and the project regenerated.
- The 1.0.2 version bump (`project.yml` / regenerated `project.pbxproj`), the new signing profile in `ExportOptions.plist`, and the `CLAUDE.md` updates were committed 2026-10-16 alongside this file.
- All `img/` assets are tracked in git, including the marketing/source assets (`hero.png`, `title.png`, `icon-*.png`, `final_smash_repaired.png`). `videos/` (App Store preview mp4s) is gitignored and stays local only.

## Open items

- Server-side receipt validation is flagged as post-MVP hardening (`Transaction.currentEntitlements` on-device for now).
- Game Center / real StoreKit flows still only verified via TestFlight/device, not Simulator.
- `scripts/appstoreconnect/asc_api.py` needs PyJWT + cryptography, which aren't installed for this machine's system `python3`. Either `pip3 install --user pyjwt cryptography` or use a throwaway venv (`python3 -m venv <dir> && <dir>/bin/pip install pyjwt cryptography`).

Resolved earlier (details in `CLAUDE.md`): the Paid + Free Apps Agreements (cause of the Guideline 2.1(b) subscribe-button rejection), and the IAP/subscription review screenshots (both products `APPROVED`).

## Session log

- **2026-08-20:** Checked review status via ASC API. The current submission (Aug 18) was `WAITING_FOR_REVIEW`, and the prior three submissions were withdrawn, not rejected. The Gmail integration lacked read scope, so the inbox couldn't be checked for App Review mail; scan manually for `noreply@email.apple.com`.
- **2026-08-25:** 1.0 approved and live; 1.0.1 (submitted Aug 21) also approved. Created this handoff file. Confirmed both IAP and subscription `APPROVED`. Added `scripts/appstoreconnect/asc_api.py` to the repo and folded the ASC submission gotchas into `CLAUDE.md`.
- **2026-09-15:** Shipped 1.0.2 (build 6) to review to replace the washed-out smash screenshot. Rotated to the `Sep 2026` provisioning profile.
- **2026-10-16:** Confirmed 1.0.2 approved and `READY_FOR_SALE`; nothing in review. Committed the outstanding 1.0.2 working-tree changes. Decided asset storage: all `img/` images are committed to git; `videos/` (preview mp4s) is gitignored and kept local only.
- **2026-10-16 (later):** Rewrote the store listing away from the AI slop framing and optimized it for search (see top). Updated live promo text, shipped metadata-only 1.0.3 (build 7) and submitted for review. `asc_api.py` was run from a scratchpad venv with PyJWT.
