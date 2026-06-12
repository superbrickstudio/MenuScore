import Foundation

struct Team: Identifiable, Equatable {
    let code: String   // three-letter FIFA code, e.g. "MEX"
    let name: String
    let flag: String   // emoji flag, may be empty for unknown codes

    var id: String { code }

    /// "🇲🇽 MEX" or just "MEX" when no flag is known.
    var flaggedCode: String {
        flag.isEmpty ? code : "\(flag) \(code)"
    }
}

enum MatchStatus: Equatable {
    case upcoming(kickoff: Date)
    /// `display` comes from the provider, e.g. "64'", "45'+2", "HT".
    case live(display: String)
    case finished

    var isLive: Bool {
        if case .live = self { return true }
        return false
    }

    /// Short text shown next to the score, e.g. "64'" or "FT".
    var shortLabel: String {
        switch self {
        case .upcoming(let kickoff):
            if Calendar.current.isDateInToday(kickoff) {
                return kickoff.formatted(date: .omitted, time: .shortened)
            }
            return kickoff.formatted(.dateTime.weekday(.abbreviated).hour().minute())
        case .live(let display):
            return display
        case .finished:
            return "FT"
        }
    }

    /// Suffix appended to the menu bar label: the clock for live games,
    /// kickoff time for upcoming ones, FT for finished ones.
    var menuBarSuffix: String {
        switch self {
        case .live(let display):
            return " \(display)"
        case .upcoming:
            return " \(shortLabel)"
        case .finished:
            return " FT"
        }
    }
}

struct Match: Identifiable, Equatable {
    let id: String
    let date: Date
    let home: Team
    let away: Team
    var homeScore: Int?
    var awayScore: Int?
    var status: MatchStatus
    var stage: String?   // e.g. "Group A", "Round of 32"
    var venue: String

    /// "MEX 2–1 MAR" for started games, "MEX vs MAR" otherwise.
    var scoreline: String {
        guard let homeScore, let awayScore else {
            return "\(home.code) vs \(away.code)"
        }
        return "\(home.code) \(homeScore)–\(awayScore) \(away.code)"
    }
}
