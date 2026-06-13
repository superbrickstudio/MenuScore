import Foundation

/// Single source of truth for match data. Polls the API on an adaptive
/// cadence: fast while a match is live, slower otherwise.
@MainActor
final class MatchStore: ObservableObject {
    @Published private(set) var matches: [Match] = []
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRefreshing = false

    /// Full-tournament fetch, loaded on demand for standings and the
    /// complete team list (the regular `matches` window is only a few days).
    @Published private(set) var allMatches: [Match] = []
    @Published private(set) var isLoadingAll = false
    @Published private(set) var allMatchesError: String?

    private let client: any WorldCupAPIClient
    private var pollTask: Task<Void, Never>?

    init(client: any WorldCupAPIClient = ESPNClient(), startPolling: Bool = true) {
        self.client = client
        if startPolling { startPollingAndRefresh() }
    }

    // MARK: - Derived collections

    /// The match surfaced in the menu bar, honoring the user's pin and
    /// favorites before falling back to the global next-up match.
    func featuredMatch(favorites: Set<String>, pinned: String?) -> Match? {
        if let pinned, let match = preferredMatch(involving: [pinned]) {
            return match
        }
        if !favorites.isEmpty, let match = preferredMatch(involving: favorites) {
            return match
        }
        return liveMatches.first ?? upcomingMatches.first ?? finishedMatches.first
    }

    /// First live, else next upcoming, else most recent finished match
    /// involving any of the given team codes.
    private func preferredMatch(involving codes: Set<String>) -> Match? {
        func involves(_ match: Match) -> Bool {
            codes.contains(match.home.code) || codes.contains(match.away.code)
        }
        return liveMatches.first(where: involves)
            ?? upcomingMatches.first(where: involves)
            ?? finishedMatches.first(where: involves)
    }

    func matchInvolves(_ match: Match, anyOf codes: Set<String>) -> Bool {
        codes.contains(match.home.code) || codes.contains(match.away.code)
    }

    /// Group standings computed from the full tournament when available,
    /// otherwise from the current window.
    var standings: [GroupStanding] {
        StandingsBuilder.build(from: allMatches.isEmpty ? matches : allMatches)
    }

    /// Every team seen, for the favorites picker. Prefers the full
    /// tournament list, falling back to the current window.
    var allTeams: [Team] {
        let source = allMatches.isEmpty ? matches : allMatches
        var seen: [String: Team] = [:]
        for match in source {
            seen[match.home.code] = match.home
            seen[match.away.code] = match.away
        }
        return seen.values.sorted { $0.name < $1.name }
    }

    var liveMatches: [Match] {
        matches.filter { $0.status.isLive }
    }

    var upcomingMatches: [Match] {
        matches
            .filter { if case .upcoming = $0.status { return true } else { return false } }
            .sorted { $0.date < $1.date }
    }

    var finishedMatches: [Match] {
        matches
            .filter { $0.status == .finished }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Polling

    func startPollingAndRefresh() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.refresh()
                let seconds = self.pollInterval
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let fresh = try await client.fetchMatches()
            let settings = AppSettings.shared
            // Only notify on changes between fetches, never on launch.
            if lastUpdated != nil {
                if settings.notificationsEnabled {
                    let filter = settings.favoritesOnlyNotifications
                        ? settings.favoriteTeamCodes : nil
                    NotificationManager.shared.notifyChanges(
                        from: matches, to: fresh, favoritesFilter: filter
                    )
                }
            } else {
                NotificationManager.shared.requestAuthorizationIfNeeded()
            }
            matches = fresh
            lastUpdated = .now
            errorMessage = nil
        } catch {
            // Keep showing the last good data; just surface the problem.
            errorMessage = error.localizedDescription
        }
    }

    /// Loads the full tournament for standings and the team list.
    func loadAllMatches() async {
        guard !isLoadingAll else { return }
        isLoadingAll = true
        defer { isLoadingAll = false }
        do {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
            let from = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)) ?? .now
            let to = calendar.date(from: DateComponents(year: 2026, month: 7, day: 31)) ?? .now
            allMatches = try await client.fetchMatches(from: from, to: to)
            allMatchesError = nil
        } catch {
            allMatchesError = error.localizedDescription
        }
    }

    private var pollInterval: TimeInterval {
        if !liveMatches.isEmpty { return 30 }
        if let next = upcomingMatches.first, next.date.timeIntervalSinceNow < 15 * 60 {
            return 60
        }
        if errorMessage != nil && matches.isEmpty { return 60 }
        return 5 * 60
    }

    // MARK: - Previews

    static var preview: MatchStore {
        let store = MatchStore(startPolling: false)
        store.matches = sampleMatches
        store.lastUpdated = .now
        return store
    }

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
                id: "sample-1", date: .now,
                home: mex, away: mar,
                homeScore: 2, awayScore: 1,
                status: .live(display: "64'"),
                stage: "Group A",
                venue: "Estadio Azteca, Mexico City"
            ),
            Match(
                id: "sample-2", date: tonight,
                home: usa, away: jpn,
                homeScore: nil, awayScore: nil,
                status: .upcoming(kickoff: tonight),
                stage: "Group D",
                venue: "SoFi Stadium, Los Angeles"
            ),
            Match(
                id: "sample-3", date: .now.addingTimeInterval(-7200),
                home: arg, away: can,
                homeScore: 3, awayScore: 0,
                status: .finished,
                stage: "Group B",
                venue: "MetLife Stadium, New Jersey"
            ),
        ]
    }()
}
