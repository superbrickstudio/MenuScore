import SwiftUI

/// App preferences.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backBar
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    notificationsSection
                    aboutSection
                }
                .padding(14)
            }
        }
        .frame(width: 320)
        .frame(maxHeight: 480)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .windowToolbar)
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

    private var notificationsSection: some View {
        section("Notifications") {
            Toggle("Goals, kickoffs & full-time", isOn: $settings.notificationsEnabled)
        }
    }

    private var aboutSection: some View {
        section("About") {
            Text("MenuScore launches automatically at login.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

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
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings.shared)
}
