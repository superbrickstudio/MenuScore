import Foundation
import UserNotifications

/// Posts local notifications for match moments (kickoff, goals,
/// full-time). The app must be running; delivery lags the real event
/// by up to one polling interval.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private var hasRequestedAuthorization = false

    func requestAuthorizationIfNeeded() {
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { _, _ in }
    }

    /// Compares two fetches and posts notifications for what changed.
    func notifyChanges(from old: [Match], to new: [Match]) {
        let previousByID = Dictionary(
            old.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        for match in new {
            guard let previous = previousByID[match.id] else { continue }

            if !previous.status.isLive && match.status.isLive {
                post(
                    id: "\(match.id)-kickoff",
                    title: "Kickoff",
                    body: "\(match.home.name) vs \(match.away.name) is underway."
                )
            }

            if let homeNow = match.homeScore, let awayNow = match.awayScore,
               previous.homeScore != nil || previous.awayScore != nil,
               (homeNow, awayNow) != (previous.homeScore ?? 0, previous.awayScore ?? 0) {
                let scoringTeam = homeNow > (previous.homeScore ?? 0) ? match.home : match.away
                let newGoals = match.events.filter { event in
                    event.kind != .yellowCard && event.kind != .redCard
                        && !previous.events.contains(event)
                }
                let scorer = newGoals.last.map { "\($0.playerName) \($0.clockDisplay)" }
                post(
                    id: "\(match.id)-goal-\(homeNow)-\(awayNow)",
                    title: "⚽️ Goal — \(scoringTeam.name)!",
                    body: "\(match.scoreline)" + (scorer.map { " · \($0)" } ?? "")
                )
            }

            if previous.status.isLive && match.status == .finished {
                post(
                    id: "\(match.id)-fulltime",
                    title: "Full time",
                    body: match.scoreline
                )
            }
        }
    }

    private func post(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: id, content: content, trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
