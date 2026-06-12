# MenuScore ⚽️

Live 2026 World Cup scores in your Mac menu bar. Click the score to open a
styled panel with match details.

## Requirements

- macOS 13 (Ventura) or later to run
- Xcode 16 or later to build

## Building & running

1. Open `MenuScore.xcodeproj` in Xcode.
2. Press **⌘R**.

The app has no Dock icon or main window — look for the score in the
**menu bar** (top-right of the screen). Click it to open the scoreboard
panel; use the **Quit** button in the panel to stop the app.

If Xcode complains about signing, select the *MenuScore* target →
*Signing & Capabilities* and choose your personal team (or leave it on
"Sign to Run Locally").

## Roadmap

- [x] **Phase 1 — Skeleton**: menu bar item + styled popover with sample data
- [ ] **Phase 2 — Live data**: API client, polling engine, real scores
- [ ] **Phase 3 — Stats panel**: match detail, scorers, standings
- [ ] **Phase 4 — Polish**: favorite team, notifications, launch at login, settings
- [ ] **Phase 5 — Distribution**: icon, notarization, auto-updates

## Architecture notes

- Pure SwiftUI using `MenuBarExtra` with the `.window` style.
- `MatchStore` is the single source of truth for match data; in Phase 2 it
  will poll a `WorldCupAPI` protocol so data providers are swappable.
- The app is sandboxed with the network-client entitlement already enabled,
  ready for Phase 2.
