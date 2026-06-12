import SwiftUI

/// The panel that opens when the menu bar item is clicked. Flat rows
/// with hairline dividers on the system's frosted panel material.
struct ScoreboardView: View {
    @EnvironmentObject private var store: MatchStore

    private var orderedMatches: [Match] {
        store.liveMatches + store.upcomingMatches + store.finishedMatches
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider()

                ScrollView {
                    if store.matches.isEmpty {
                        emptyState
                    } else {
                        matchList
                    }
                }

                Divider()
                footer
            }
            .navigationDestination(for: Match.self) { match in
                MatchDetailView(matchID: match.id, fallback: match)
            }
        }
        .frame(width: 320)
        .frame(maxHeight: 480)
    }

    private var matchList: some View {
        VStack(spacing: 0) {
            ForEach(orderedMatches) { match in
                NavigationLink(value: match) {
                    MatchRowView(match: match)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Show match details")

                if match.id != orderedMatches.last?.id {
                    Divider()
                        .padding(.leading, 14)
                }
            }
        }
        .padding(.vertical, 2)
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
        HStack(spacing: 7) {
            Image(systemName: "soccerball")
                .foregroundStyle(.secondary)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

#Preview {
    ScoreboardView()
        .environmentObject(MatchStore.preview)
}
