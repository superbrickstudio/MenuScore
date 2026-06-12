import SwiftUI

/// The panel that opens when the menu bar item is clicked.
struct ScoreboardView: View {
    @EnvironmentObject private var store: MatchStore

    var body: some View {
        NavigationStack {
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
            .navigationDestination(for: Match.self) { match in
                MatchDetailView(matchID: match.id, fallback: match)
            }
        }
        .frame(width: 320)
        .frame(maxHeight: 480)
    }

    @ViewBuilder
    private var matchSections: some View {
        if !store.liveMatches.isEmpty {
            sectionLabel("Live", color: Brand.red)
            ForEach(store.liveMatches) { match in
                matchLink(match)
            }
        }
        if !store.upcomingMatches.isEmpty {
            sectionLabel("Upcoming")
            ForEach(store.upcomingMatches) { match in
                matchLink(match)
            }
        }
        if !store.finishedMatches.isEmpty {
            sectionLabel("Results")
            ForEach(store.finishedMatches) { match in
                matchLink(match)
            }
        }
    }

    private func matchLink(_ match: Match) -> some View {
        NavigationLink(value: match) {
            MatchRowView(match: match)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Show match details")
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
            Text("⚽️")
                .font(.system(size: 15))
            Text("MENUSCORE ′26")
                .font(Brand.displayFont(size: 15))
                .italic()
                .tracking(0.5)
            Spacer()
            Button {
                Task { await store.refresh() }
            } label: {
                if store.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderless)
            .help("Refresh now")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Brand.gradient)
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

    private func sectionLabel(_ title: String, color: Color = .secondary) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.heavy))
            .tracking(1)
            .foregroundStyle(color)
    }
}

#Preview {
    ScoreboardView()
        .environmentObject(MatchStore.preview)
}
