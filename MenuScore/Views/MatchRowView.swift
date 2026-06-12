import SwiftUI

/// One match in the scoreboard list.
struct MatchRowView: View {
    let match: Match

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                teamLabel(match.home)
                Spacer()
                centerLabel
                Spacer()
                teamLabel(match.away, trailing: true)
            }

            HStack(spacing: 4) {
                if match.status.isLive {
                    LiveDot()
                }
                Text(match.status.shortLabel)
                    .font(.caption2.weight(match.status.isLive ? .bold : .regular))
                    .foregroundStyle(match.status.isLive ? .red : .secondary)
                if let group = match.group {
                    Text("· Group \(group)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            match.status.isLive ? .red.opacity(0.35) : Color.primary.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
    }

    private var centerLabel: some View {
        Group {
            if let home = match.homeScore, let away = match.awayScore {
                Text("\(home) – \(away)")
                    .font(.title3.weight(.bold).monospacedDigit())
            } else {
                Text("vs")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func teamLabel(_ team: Team, trailing: Bool = false) -> some View {
        HStack(spacing: 6) {
            if trailing {
                Text(team.code).font(.callout.weight(.semibold))
                Text(team.flag).font(.title3)
            } else {
                Text(team.flag).font(.title3)
                Text(team.code).font(.callout.weight(.semibold))
            }
        }
    }
}

/// Pulsing red dot for live matches.
struct LiveDot: View {
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(.red)
            .frame(width: 6, height: 6)
            .opacity(pulsing ? 0.3 : 1)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsing)
            .onAppear { pulsing = true }
    }
}
