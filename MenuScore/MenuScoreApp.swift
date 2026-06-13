import SwiftUI

@main
struct MenuScoreApp: App {
    @StateObject private var store = MatchStore()
    @StateObject private var settings = AppSettings.shared

    init() {
        LoginItem.enable()
    }

    var body: some Scene {
        MenuBarExtra {
            ScoreboardView()
                .environmentObject(store)
                .environmentObject(settings)
        } label: {
            MenuBarLabel(match: store.featuredMatch)
        }
        .menuBarExtraStyle(.window)
    }
}

/// The compact label shown in the menu bar itself.
/// Constrained to a single line of text and/or an icon by macOS.
struct MenuBarLabel: View {
    let match: Match?

    var body: some View {
        if let match {
            Text(labelText(for: match))
                .font(.body.monospacedDigit())
        } else {
            Image(systemName: "soccerball")
        }
    }

    /// Compact, flags-first label: "🇨🇦 0–0 🇧🇦 64'". Falls back to the
    /// team code when no flag is known for it.
    private func labelText(for match: Match) -> String {
        let home = match.home.flag.isEmpty ? match.home.code : match.home.flag
        let away = match.away.flag.isEmpty ? match.away.code : match.away.flag
        let middle: String
        if let homeScore = match.homeScore, let awayScore = match.awayScore {
            middle = "\(homeScore)–\(awayScore)"
        } else {
            middle = "vs"
        }
        return "\(home) \(middle) \(away)\(match.status.menuBarSuffix)"
    }
}
