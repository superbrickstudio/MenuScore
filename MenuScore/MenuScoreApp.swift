import SwiftUI

@main
struct MenuScoreApp: App {
    @StateObject private var store = MatchStore()

    var body: some Scene {
        MenuBarExtra {
            ScoreboardView()
                .environmentObject(store)
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
            Text("\(match.home.flag) \(match.scoreline) \(match.away.flag)\(match.status.menuBarSuffix)")
        } else {
            Image(systemName: "soccerball")
        }
    }
}
