import Foundation

/// Abstraction over the live-score data provider so the source can be
/// swapped (ESPN today; API-Football or similar later) without touching
/// the store or views.
protocol WorldCupAPIClient: Sendable {
    /// Fetches recent, live, and upcoming World Cup matches.
    func fetchMatches() async throws -> [Match]
}

enum APIError: LocalizedError {
    case badURL
    case badStatus(Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .badURL: return "Could not build the scoreboard URL."
        case .badStatus(let code): return "Scoreboard request failed (HTTP \(code))."
        case .emptyResponse: return "The scoreboard response was empty."
        }
    }
}
