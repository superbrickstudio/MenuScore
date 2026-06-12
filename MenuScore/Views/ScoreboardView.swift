import SwiftUI

/// The panel that opens when the menu bar item is clicked.
struct ScoreboardView: View {
    @EnvironmentObject private var store: MatchStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !store.liveMatches.isEmpty {
                        sectionLabel("Live")
                        ForEach(store.liveMatches) { match in
                            MatchRowView(match: match)
                        }
                    }
                    if !store.otherMatches.isEmpty {
                        sectionLabel("Today")
                        ForEach(store.otherMatches) { match in
                            MatchRowView(match: match)
                        }
                    }
                }
                .padding(12)
            }

            footer
        }
        .frame(width: 320)
        .frame(maxHeight: 480)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.yellow)
            Text("World Cup 2026")
                .font(.headline)
            Spacer()
            Text("SAMPLE DATA")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.orange.opacity(0.2), in: Capsule())
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.5))
    }

    private var footer: some View {
        HStack {
            Text("Live scores arrive in Phase 2")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        .environmentObject(MatchStore())
}
