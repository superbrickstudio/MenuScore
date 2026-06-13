import Foundation

/// Live scores from ESPN's public scoreboard JSON
/// (site.api.espn.com, league "fifa.world"). No API key required.
///
/// The endpoint is unofficial, so every field is decoded as optional and
/// mapping degrades gracefully when something is missing.
struct ESPNClient: WorldCupAPIClient {
    private static let base = "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard"

    /// Default window: yesterday through three days out, so the panel
    /// shows recent results alongside live and upcoming games.
    func fetchMatches() async throws -> [Match] {
        try await fetchMatches(
            from: .now.addingTimeInterval(-86_400),
            to: .now.addingTimeInterval(3 * 86_400)
        )
    }

    func fetchMatches(from: Date, to: Date) async throws -> [Match] {
        var request = URLRequest(url: try scoreboardURL(from: from, to: to))
        request.setValue("MenuScore/0.4 (macOS)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.badStatus(http.statusCode)
        }
        let scoreboard = try JSONDecoder().decode(ESPNScoreboard.self, from: data)
        return (scoreboard.events ?? [])
            .compactMap(Self.match(from:))
            .sorted { $0.date < $1.date }
    }

    private func scoreboardURL(from: Date, to: Date) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let fromString = formatter.string(from: from)
        let toString = formatter.string(from: to)
        // limit=300 ensures wide ranges return every match in one page.
        guard let url = URL(string: "\(Self.base)?dates=\(fromString)-\(toString)&limit=300") else {
            throw APIError.badURL
        }
        return url
    }

    // MARK: - Mapping

    private static func match(from event: ESPNEvent) -> Match? {
        guard
            let competition = event.competitions?.first,
            let competitors = competition.competitors,
            let homeSide = competitors.first(where: { $0.homeAway == "home" }) ?? competitors.first,
            let awaySide = competitors.first(where: { $0.homeAway == "away" }) ?? competitors.last,
            let home = team(from: homeSide),
            let away = team(from: awaySide),
            home.code != away.code
        else { return nil }

        let date = parseDate(event.date ?? competition.date) ?? .now
        let status = matchStatus(from: event.status ?? competition.status, kickoff: date)

        // ESPN reports "0" scores before kickoff; suppress them so
        // unstarted matches render as "vs" instead of 0–0.
        let hasStarted: Bool
        if case .upcoming = status { hasStarted = false } else { hasStarted = true }

        var venue = competition.venue?.fullName ?? ""
        if let city = competition.venue?.address?.city, !city.isEmpty {
            venue += venue.isEmpty ? city : ", \(city)"
        }

        return Match(
            id: event.id,
            date: date,
            home: home,
            away: away,
            homeScore: hasStarted ? Int(homeSide.score ?? "") : nil,
            awayScore: hasStarted ? Int(awaySide.score ?? "") : nil,
            status: status,
            stage: stage(from: competition.notes),
            venue: venue,
            events: matchEvents(from: competition.details, homeTeamID: homeSide.team?.id)
        )
    }

    private static func matchEvents(
        from details: [ESPNDetail]?,
        homeTeamID: String?
    ) -> [MatchEvent] {
        (details ?? []).compactMap { detail in
            let kind: MatchEvent.Kind
            if detail.redCard == true {
                kind = .redCard
            } else if detail.yellowCard == true {
                kind = .yellowCard
            } else if detail.scoringPlay == true {
                kind = detail.ownGoal == true ? .ownGoal
                     : detail.penaltyKick == true ? .penaltyGoal
                     : .goal
            } else {
                return nil   // ignore substitutions, VAR notes, etc.
            }
            let player = detail.athletesInvolved?.first
            return MatchEvent(
                kind: kind,
                clockDisplay: detail.clock?.displayValue ?? "",
                playerName: player?.shortName ?? player?.displayName ?? "Unknown",
                isHome: detail.team?.id != nil && detail.team?.id == homeTeamID
            )
        }
    }

    private static func team(from competitor: ESPNCompetitor) -> Team? {
        guard let espnTeam = competitor.team else { return nil }
        let code = espnTeam.abbreviation ?? String((espnTeam.displayName ?? "???").prefix(3)).uppercased()
        let logoString = espnTeam.logo ?? espnTeam.logos?.first?.href
        return Team(
            code: code,
            name: espnTeam.shortDisplayName ?? espnTeam.displayName ?? code,
            flag: flagEmoji(forFIFACode: code),
            logoURL: logoString.flatMap { URL(string: $0) }
        )
    }

    private static func matchStatus(from status: ESPNStatus?, kickoff: Date) -> MatchStatus {
        switch status?.type?.state {
        case "in":
            // Prefer shortDetail ("45'+2", "HT") over the raw clock.
            let display = status?.type?.shortDetail ?? status?.displayClock ?? "LIVE"
            return .live(display: display)
        case "post":
            return .finished
        default:
            return .upcoming(kickoff: kickoff)
        }
    }

    /// Notes look like "Group Stage - Group A"; keep the part after the dash.
    private static func stage(from notes: [ESPNNote]?) -> String? {
        guard let headline = notes?.first?.headline, !headline.isEmpty else { return nil }
        if let dash = headline.range(of: " - ", options: .backwards) {
            return String(headline[dash.upperBound...])
        }
        return headline
    }

    private static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        // ESPN omits seconds ("2026-06-11T19:00Z"); try both shapes.
        let short = DateFormatter()
        short.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        short.timeZone = TimeZone(identifier: "UTC")
        if let date = short.date(from: string) { return date }
        return ISO8601DateFormatter().date(from: string)
    }
}

// MARK: - Flag emoji

/// Maps FIFA three-letter codes to emoji flags. Unknown codes fall back
/// to an empty string and the UI shows just the code.
func flagEmoji(forFIFACode code: String) -> String {
    switch code {
    case "ENG": return "🏴󠁧󠁢󠁥󠁮󠁧󠁿"
    case "SCO": return "🏴󠁧󠁢󠁳󠁣󠁴󠁿"
    case "WAL": return "🏴󠁧󠁢󠁷󠁬󠁳󠁿"
    default: break
    }
    let fifaToISO2: [String: String] = [
        "USA": "US", "MEX": "MX", "CAN": "CA",
        "ARG": "AR", "BRA": "BR", "URU": "UY", "COL": "CO", "ECU": "EC",
        "PAR": "PY", "CHI": "CL", "PER": "PE", "VEN": "VE", "BOL": "BO",
        "FRA": "FR", "GER": "DE", "ESP": "ES", "POR": "PT", "NED": "NL",
        "BEL": "BE", "CRO": "HR", "ITA": "IT", "SUI": "CH", "AUT": "AT",
        "DEN": "DK", "NOR": "NO", "SWE": "SE", "POL": "PL", "CZE": "CZ",
        "SVK": "SK", "SRB": "RS", "TUR": "TR", "UKR": "UA", "HUN": "HU",
        "ROU": "RO", "GRE": "GR", "IRL": "IE", "ALB": "AL", "BIH": "BA",
        "JPN": "JP", "KOR": "KR", "KSA": "SA", "IRN": "IR", "IRQ": "IQ",
        "QAT": "QA", "UZB": "UZ", "JOR": "JO", "UAE": "AE", "AUS": "AU",
        "NZL": "NZ", "MAR": "MA", "SEN": "SN", "GHA": "GH", "NGA": "NG",
        "CIV": "CI", "CMR": "CM", "EGY": "EG", "TUN": "TN", "ALG": "DZ",
        "RSA": "ZA", "CPV": "CV", "MLI": "ML", "BFA": "BF", "COD": "CD",
        "GAB": "GA", "ZAM": "ZM", "PAN": "PA", "CRC": "CR", "HON": "HN",
        "JAM": "JM", "HAI": "HT", "CUW": "CW", "TRI": "TT", "SUR": "SR",
    ]
    guard let iso2 = fifaToISO2[code] else { return "" }
    return iso2.unicodeScalars.reduce(into: "") { flag, scalar in
        if let regional = UnicodeScalar(127_397 + scalar.value) {
            flag.unicodeScalars.append(regional)
        }
    }
}

// MARK: - ESPN response shapes (all optional by design)

struct ESPNScoreboard: Decodable {
    let events: [ESPNEvent]?
}

struct ESPNEvent: Decodable {
    let id: String
    let date: String?
    let status: ESPNStatus?
    let competitions: [ESPNCompetition]?
}

struct ESPNCompetition: Decodable {
    let date: String?
    let venue: ESPNVenue?
    let competitors: [ESPNCompetitor]?
    let status: ESPNStatus?
    let notes: [ESPNNote]?
    let details: [ESPNDetail]?
}

struct ESPNDetail: Decodable {
    let type: ESPNDetailType?
    let clock: ESPNClock?
    let team: ESPNTeamRef?
    let scoringPlay: Bool?
    let penaltyKick: Bool?
    let ownGoal: Bool?
    let redCard: Bool?
    let yellowCard: Bool?
    let athletesInvolved: [ESPNAthlete]?

    struct ESPNDetailType: Decodable {
        let text: String?
    }

    struct ESPNClock: Decodable {
        let value: Double?
        let displayValue: String?
    }

    struct ESPNTeamRef: Decodable {
        let id: String?
    }

    struct ESPNAthlete: Decodable {
        let displayName: String?
        let shortName: String?
    }
}

struct ESPNNote: Decodable {
    let headline: String?
}

struct ESPNVenue: Decodable {
    let fullName: String?
    let address: ESPNAddress?

    struct ESPNAddress: Decodable {
        let city: String?
    }
}

struct ESPNCompetitor: Decodable {
    let homeAway: String?
    let score: String?
    let team: ESPNTeam?
}

struct ESPNTeam: Decodable {
    let id: String?
    let abbreviation: String?
    let displayName: String?
    let shortDisplayName: String?
    let logo: String?
    let logos: [Logo]?

    struct Logo: Decodable {
        let href: String?
    }
}

struct ESPNStatus: Decodable {
    let displayClock: String?
    let period: Int?
    let type: ESPNStatusType?
}

struct ESPNStatusType: Decodable {
    let state: String?
    let completed: Bool?
    let detail: String?
    let shortDetail: String?
}
