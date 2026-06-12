import Foundation

/// Holds the matches shown by the app.
///
/// Phase 1: static sample data so the UI can be designed and tested.
/// Phase 2 will replace `sampleMatches` with a polling API client.
@MainActor
final class MatchStore: ObservableObject {
    @Published var matches: [Match] = MatchStore.sampleMatches

    /// The match surfaced in the menu bar: the first live one,
    /// otherwise the next upcoming one.
    var featuredMatch: Match? {
        matches.first(where: { $0.status.isLive }) ?? matches.first
    }

    var liveMatches: [Match] { matches.filter { $0.status.isLive } }
    var otherMatches: [Match] { matches.filter { !$0.status.isLive } }

    // MARK: - Sample data (placeholder until Phase 2)

    static let sampleMatches: [Match] = {
        let mex = Team(code: "MEX", name: "Mexico", flag: "🇲🇽")
        let mar = Team(code: "MAR", name: "Morocco", flag: "🇲🇦")
        let usa = Team(code: "USA", name: "United States", flag: "🇺🇸")
        let jpn = Team(code: "JPN", name: "Japan", flag: "🇯🇵")
        let arg = Team(code: "ARG", name: "Argentina", flag: "🇦🇷")
        let can = Team(code: "CAN", name: "Canada", flag: "🇨🇦")

        let tonight = Calendar.current.date(
            bySettingHour: 19, minute: 0, second: 0, of: .now
        ) ?? .now

        return [
            Match(
                id: "sample-1",
                home: mex, away: mar,
                homeScore: 2, awayScore: 1,
                status: .live(minute: 64),
                group: "A",
                venue: "Estadio Azteca, Mexico City"
            ),
            Match(
                id: "sample-2",
                home: usa, away: jpn,
                homeScore: nil, awayScore: nil,
                status: .upcoming(kickoff: tonight),
                group: "D",
                venue: "SoFi Stadium, Los Angeles"
            ),
            Match(
                id: "sample-3",
                home: arg, away: can,
                homeScore: 3, awayScore: 0,
                status: .finished,
                group: "B",
                venue: "MetLife Stadium, New Jersey"
            ),
        ]
    }()
}
