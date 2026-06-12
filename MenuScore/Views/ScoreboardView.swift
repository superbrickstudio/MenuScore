import SwiftUI

/// The panel that opens when the menu bar item is clicked.
struct ScoreboardView: View {
    @EnvironmentObject private var store: MatchStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if store.matches.isEmpty {
                        emptyState
                    } else {
                        matchSections
                    }
                }
                .padding(12)
            }

            footer
        }
        .frame(width: 320)
        .frame(maxHeight: 480)
    }

    @ViewBuilder
    private var matchSections: some View {
        if !store.liveMatches.isEmpty {
            sectionLabel("Live")
            ForEach(store.liveMatches) { match in
                MatchRowView(match: match)
            }
        }
        if !store.upcomingMatches.isEmpty {
            sectionLabel("Upcoming")
            ForEach(store.upcomingMatches) { match in
                MatchRowView(match: match)
            }
        }
        if !store.finishedMatches.isEmpty {
            sectionLabel("Results")
            ForEach(store.finishedMatches) { match in
                MatchRowView(match: match)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: store.errorMessage == nil ? "soccerball" : "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(store.errorMessage ?? "No matches in the next few days.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.yellow)
            Text("World Cup 2026")
                .font(.headline)
            Spacer()
            Button {
                Task { await store.refresh() }
            } label: {
                if store.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderless)
            .help("Refresh now")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.5))
    }

    private var footer: some View {
        HStack {
            if let error = store.errorMessage, !store.matches.isEmpty {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            } else if let updated = store.lastUpdated {
                Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Loading…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.5))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    ScoreboardView()
        .environmentObject(MatchStore.preview)
}
