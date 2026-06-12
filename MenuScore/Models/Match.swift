import Foundation

struct Team: Identifiable, Equatable {
    let code: String   // three-letter FIFA code, e.g. "MEX"
    let name: String
    let flag: String   // emoji flag

    var id: String { code }
}

enum MatchStatus: Equatable {
    case upcoming(kickoff: Date)
    case live(minute: Int)
    case finished

    var isLive: Bool {
        if case .live = self { return true }
        return false
    }

    /// Short text shown next to the score, e.g. "64′" or "FT".
    var shortLabel: String {
        switch self {
        case .upcoming(let kickoff):
            return kickoff.formatted(date: .omitted, time: .shortened)
        case .live(let minute):
            return "\(minute)′"
        case .finished:
            return "FT"
        }
    }

    /// Suffix appended to the menu bar label for live games.
    var menuBarSuffix: String {
        if case .live(let minute) = self { return " \(minute)′" }
        return ""
    }
}

struct Match: Identifiable, Equatable {
    let id: String
    let home: Team
    let away: Team
    var homeScore: Int?
    var awayScore: Int?
    var status: MatchStatus
    var group: String?
    var venue: String

    /// "2–1" for started games, "vs" otherwise.
    var scoreline: String {
        guard let homeScore, let awayScore else {
            return "\(home.code) vs \(away.code)"
        }
        return "\(home.code) \(homeScore)–\(awayScore) \(away.code)"
    }
}
