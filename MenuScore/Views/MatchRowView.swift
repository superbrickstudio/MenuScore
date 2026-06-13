import SwiftUI

/// One match as a flat, full-width row: flags at the edges, the score
/// or kickoff time centered, stage caption above, status below.
struct MatchRowView: View {
    let match: Match

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .center) {
            teamColumn(match.home)
            Spacer()
            VStack(spacing: 1) {
                if let stage = match.stage {
                    Text(stage)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                centerLabel
                statusLine
            }
            Spacer()
            teamColumn(match.away)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Rectangle()
                .fill(isHovered ? Color.primary.opacity(0.06) : .clear)
        )
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var centerLabel: some View {
        switch match.status {
        case .upcoming(let kickoff):
            Text(kickoff.formatted(date: .omitted, time: .shortened))
                .font(.title3.weight(.semibold).monospacedDigit())
        default:
            if let home = match.homeScore, let away = match.awayScore {
                Text("\(home) – \(away)")
                    .font(.title3.weight(.semibold).monospacedDigit())
            } else {
                Text("–")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        switch match.status {
        case .live(let display):
            HStack(spacing: 4) {
                LiveDot()
                Text(display)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Brand.live)
            }
        case .finished:
            Text("FT")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .upcoming(let kickoff):
            Text(relativeDay(of: kickoff))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func relativeDay(of date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.wide))
    }

    private func teamColumn(_ team: Team) -> some View {
        VStack(spacing: 3) {
            TeamFlag(team: team, height: 22)
            Text(team.code)
                .font(.caption.weight(.semibold))
        }
        .frame(width: 52)
        .help(team.name)
    }
}

/// Steadily pulsing dot for live matches. Driven by TimelineView so the
/// opacity is recomputed per frame with no implicit animation — the dot
/// stays fixed in place and never affects layout.
struct LiveDot: View {
    var color: Color = Brand.live

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            // Triangle wave: a 2-second pulse between 0.35 and 1.0 opacity,
            // using only arithmetic so no math import is needed.
            let phase = t.truncatingRemainder(dividingBy: 2.0) / 2.0
            let triangle = phase < 0.5 ? phase * 2 : (1 - phase) * 2
            let pulse = 0.35 + 0.65 * triangle
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .opacity(pulse)
        }
        .frame(width: 6, height: 6)
    }
}
