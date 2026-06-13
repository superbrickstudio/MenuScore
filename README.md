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
- [x] **Phase 2 — Live data**: API client, polling engine, real scores
- [x] **Phase 3 — Stats panel**: tap a match for scorers and cards
- [x] **Phase 4 — Polish**: notifications, group standings, launch at
  login (automatic), settings panel
- [ ] **Phase 5 — Distribution**: icon, notarization, auto-updates

## Architecture notes

- Pure SwiftUI using `MenuBarExtra` with the `.window` style.
- `MatchStore` is the single source of truth: it polls the API on an
  adaptive cadence (30 s while a match is live, 60 s near kickoff,
  5 min otherwise) and exposes live/upcoming/finished collections.
- Data comes from ESPN's public scoreboard JSON (`site.api.espn.com`,
  league `fifa.world`) — no API key needed. It is unofficial, so the
  decoder treats every field as optional and the provider sits behind
  the `WorldCupAPIClient` protocol, making it swappable (e.g. for
  API-Football) without touching the store or views.
- The app is sandboxed with only the network-client entitlement.
