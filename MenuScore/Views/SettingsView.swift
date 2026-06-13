import SwiftUI

/// Preferences: menu-bar pin, notifications, launch at login, and the
/// list of favorite teams.
struct SettingsView: View {
    @EnvironmentObject private var store: MatchStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backBar
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    menuBarSection
                    notificationsSection
                    generalSection
                    favoritesSection
                }
                .padding(14)
            }
        }
        .frame(width: 320)
        .frame(maxHeight: 480)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .windowToolbar)
        .task { await store.loadAllMatches() }
    }

    private var backBar: some View {
        HStack {
            Button { dismiss() } label: {
                Label("Matches", systemImage: "chevron.left")
                    .font(.callout)
            }
            .buttonStyle(.borderless)
            Spacer()
            Text("Settings")
                .font(.headline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Sections

    private var menuBarSection: some View {
        section("Menu Bar") {
            Picker("Pin to menu bar", selection: pinnedBinding) {
                Text("Automatic").tag("")
                ForEach(store.allTeams) { team in
                    Text(team.flag.isEmpty ? team.name : "\(team.flag) \(team.name)")
                        .tag(team.code)
                }
            }
            Text("Automatic shows a live match first, then your favorites, then the next kickoff.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var notificationsSection: some View {
        section("Notifications") {
            Toggle("Goals, kickoffs & full-time", isOn: $settings.notificationsEnabled)
            Toggle("Only my favorite teams", isOn: $settings.favoritesOnlyNotifications)
                .disabled(!settings.notificationsEnabled || settings.favoriteTeamCodes.isEmpty)
        }
    }

    private var generalSection: some View {
        section("General") {
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
        }
    }

    private var favoritesSection: some View {
        section("My Teams") {
            if store.allTeams.isEmpty {
                Text(store.isLoadingAll ? "Loading teams…" : "No teams available yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.allTeams) { team in
                    Button {
                        settings.toggleFavorite(team.code)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: settings.isFavorite(team.code) ? "star.fill" : "star")
                                .foregroundStyle(settings.isFavorite(team.code) ? .yellow : .secondary)
                            Text(team.flag.isEmpty ? "⚽️" : team.flag)
                            Text(team.name)
                                .font(.callout)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - Helpers

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.heavy))
                .tracking(1)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private var pinnedBinding: Binding<String> {
        Binding(
            get: { settings.pinnedTeamCode ?? "" },
            set: { settings.pinnedTeamCode = $0.isEmpty ? nil : $0 }
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(MatchStore.preview)
        .environmentObject(AppSettings.shared)
}
