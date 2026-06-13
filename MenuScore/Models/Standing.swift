import Foundation

/// A single team's row in a group table.
struct Standing: Identifiable, Hashable {
    let team: Team
    var played = 0
    var won = 0
    var drawn = 0
    var lost = 0
    var goalsFor = 0
    var goalsAgainst = 0

    var id: String { team.code }
    var points: Int { won * 3 + drawn }
    var goalDifference: Int { goalsFor - goalsAgainst }
}

/// One group's ranked table.
struct GroupStanding: Identifiable, Hashable {
    let group: String   // e.g. "Group A"
    let rows: [Standing]
    var id: String { group }
}

/// Computes group standings from finished group-stage matches. Robust to
/// a partial match list — it simply tallies whatever finished games it
/// is given, so it works mid-tournament.
enum StandingsBuilder {
    static func build(from matches: [Match]) -> [GroupStanding] {
        var groups: [String: [String: Standing]] = [:]

        for match in matches {
            guard
                let stage = match.stage,
                let group = groupLabel(from: stage),
                match.status == .finished,
                let homeGoals = match.homeScore,
                let awayGoals = match.awayScore
            else { continue }

            var table = groups[group] ?? [:]
            var home = table[match.home.code] ?? Standing(team: match.home)
            var away = table[match.away.code] ?? Standing(team: match.away)

            home.played += 1
            away.played += 1
            home.goalsFor += homeGoals
            home.goalsAgainst += awayGoals
            away.goalsFor += awayGoals
            away.goalsAgainst += homeGoals

            if homeGoals > awayGoals {
                home.won += 1
                away.lost += 1
            } else if homeGoals < awayGoals {
                away.won += 1
                home.lost += 1
            } else {
                home.drawn += 1
                away.drawn += 1
            }

            table[match.home.code] = home
            table[match.away.code] = away
            groups[group] = table
        }

        return groups
            .map { group, table in
                let rows = table.values.sorted(by: rank)
                return GroupStanding(group: group, rows: rows)
            }
            .sorted { $0.group < $1.group }
    }

    /// Extracts a normalized group label ("Group A") from a stage string,
    /// tolerating ESPN variants like "Group A", "Group Stage - Group A",
    /// or "FIFA World Cup, Group A". Returns nil for non-group stages
    /// (knockout rounds). World Cup 2026 has groups A–L.
    private static func groupLabel(from stage: String) -> String? {
        let upper = stage.uppercased()
        for letter in "ABCDEFGHIJKL" {
            if upper.contains("GROUP \(letter)") {
                return "Group \(letter)"
            }
        }
        return nil
    }

    /// FIFA group ranking: points, then goal difference, then goals for,
    /// then alphabetical as a stable fallback.
    private static func rank(_ a: Standing, _ b: Standing) -> Bool {
        if a.points != b.points { return a.points > b.points }
        if a.goalDifference != b.goalDifference { return a.goalDifference > b.goalDifference }
        if a.goalsFor != b.goalsFor { return a.goalsFor > b.goalsFor }
        return a.team.code < b.team.code
    }
}
