import SwiftUI

/// Full match detail: big scoreboard, venue, and a timeline of goals
/// and cards. Looks the match up in the store by ID so it stays fresh
/// as polling updates arrive.
struct MatchDetailView: View {
    @EnvironmentObject private var store: MatchStore
    @Environment(\.dismiss) private var dismiss

    let matchID: String
    /// Snapshot used if the match drops out of the store's date window.
    let fallback: Match

    private var match: Match {
        store.matches.first(where: { $0.id == matchID }) ?? fallback
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backBar

            ScrollView {
                VStack(spacing: 14) {
                    scoreboard

                    VStack(spacing: 2) {
                        if let stage = match.stage {
                            Text(stage)
                                .font(.caption.weight(.semibold))
                        }
                        if !match.venue.isEmpty {
                            Text(match.venue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if case .upcoming(let kickoff) = match.status {
                            Text(kickoff.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .multilineTextAlignment(.center)

                    Divider()

                    timeline
                }
                .padding(12)
            }
        }
        .frame(width: 320)
        .frame(maxHeight: 480)
        // The branded backBar handles navigation; hide the system back
        // button and its toolbar strip.
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .windowToolbar)
    }

    private var backBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Label("All matches", systemImage: "chevron.left")
                    .font(.callout.weight(.semibold))
            }
            .buttonStyle(.borderless)
            Spacer()
            if match.status.isLive {
                HStack(spacing: 4) {
                    LiveDot(color: .white)
                    Text(match.status.shortLabel)
                        .font(.caption.weight(.bold))
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Brand.gradient)
    }

    private var scoreboard: some View {
        HStack(alignment: .top) {
            teamColumn(match.home)
            Spacer()
            VStack(spacing: 2) {
                if let home = match.homeScore, let away = match.awayScore {
                    Text("\(home) – \(away)")
                        .font(Brand.displayFont(size: 32).monospacedDigit())
                } else {
                    Text("vs")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                Text(match.status.shortLabel)
                    .font(.caption.weight(match.status.isLive ? .bold : .regular))
                    .foregroundStyle(match.status.isLive ? Brand.red : Color.secondary)
            }
            Spacer()
            teamColumn(match.away)
        }
        .padding(.top, 4)
    }

    private func teamColumn(_ team: Team) -> some View {
        VStack(spacing: 4) {
            Text(team.flag.isEmpty ? "⚽️" : team.flag)
                .font(.system(size: 34))
            Text(team.code)
                .font(.callout.weight(.bold))
            Text(team.name)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 86)
    }

    @ViewBuilder
    private var timeline: some View {
        if case .upcoming = match.status {
            placeholder("Kickoff hasn't happened yet.")
        } else if match.events.isEmpty {
            placeholder("No goals or cards yet.")
        } else {
            VStack(spacing: 6) {
                ForEach(match.events) { event in
                    eventRow(event)
                }
            }
        }
    }

    private func eventRow(_ event: MatchEvent) -> some View {
        HStack(spacing: 6) {
            if event.isHome {
                eventText(event)
                Spacer(minLength: 24)
            } else {
                Spacer(minLength: 24)
                eventText(event)
            }
        }
    }

    private func eventText(_ event: MatchEvent) -> some View {
        HStack(spacing: 5) {
            Text(event.clockDisplay)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 30, alignment: .trailing)
            Text(event.kind.symbol)
                .font(.caption)
            Text(event.playerName + event.kind.suffix)
                .font(.callout)
                .lineLimit(1)
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }
}

#Preview {
    let match = MatchStore.sampleMatches[0]
    return MatchDetailView(matchID: match.id, fallback: match)
        .environmentObject(MatchStore.preview)
}
