import SwiftUI

/// Group tables computed from finished group-stage matches.
struct StandingsView: View {
    @EnvironmentObject private var store: MatchStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backBar
            Divider()

            ScrollView {
                if store.isLoadingStandings && store.standings.isEmpty {
                    loading
                } else if store.standings.isEmpty {
                    placeholder
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(store.standings) { group in
                            groupTable(group)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(width: 320)
        .frame(maxHeight: 480)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .windowToolbar)
        .task { await store.loadStandings() }
    }

    private var backBar: some View {
        HStack {
            Button { dismiss() } label: {
                Label("Matches", systemImage: "chevron.left")
                    .font(.callout)
            }
            .buttonStyle(.borderless)
            Spacer()
            Text("Standings")
                .font(.headline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func groupTable(_ group: GroupStanding) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.group)
                .font(.subheadline.weight(.bold))

            headerRow

            ForEach(Array(group.rows.enumerated()), id: \.element.id) { index, row in
                standingRow(position: index + 1, row: row)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("#").frame(width: 18, alignment: .leading)
            Text("Team").frame(maxWidth: .infinity, alignment: .leading)
            numberCell("P")
            numberCell("W")
            numberCell("D")
            numberCell("L")
            numberCell("GD", width: 26)
            numberCell("Pts", width: 28)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private func standingRow(position: Int, row: Standing) -> some View {
        HStack(spacing: 0) {
            Text("\(position)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(position <= 2 ? .primary : .secondary)
                .frame(width: 18, alignment: .leading)
            HStack(spacing: 5) {
                TeamFlag(team: row.team, height: 14)
                Text(row.team.code).font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            numberCell("\(row.played)")
            numberCell("\(row.won)")
            numberCell("\(row.drawn)")
            numberCell("\(row.lost)")
            numberCell(signed(row.goalDifference), width: 26)
            numberCell("\(row.points)", width: 28, bold: true)
        }
        .padding(.vertical, 3)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func numberCell(_ text: String, width: CGFloat = 20, bold: Bool = false) -> some View {
        Text(text)
            .font(.caption.monospacedDigit().weight(bold ? .bold : .regular))
            .frame(width: width, alignment: .trailing)
    }

    private func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }

    private var loading: some View {
        ProgressView("Loading standings…")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "tablecells")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(store.standingsError ?? "No group results yet.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}

#Preview {
    StandingsView()
        .environmentObject(MatchStore.preview)
}
