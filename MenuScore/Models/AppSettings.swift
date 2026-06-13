import Foundation
import ServiceManagement

/// User preferences, persisted to UserDefaults. A single shared instance
/// so non-view code (the store, notifications) can read it while views
/// observe it as an EnvironmentObject.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    @Published var favoriteTeamCodes: Set<String> {
        didSet { defaults.set(Array(favoriteTeamCodes), forKey: Keys.favorites) }
    }

    /// Team whose match is forced into the menu bar. `nil` = automatic
    /// (live match first, then favorites, then next kickoff).
    @Published var pinnedTeamCode: String? {
        didSet { defaults.set(pinnedTeamCode, forKey: Keys.pinned) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }

    @Published var favoritesOnlyNotifications: Bool {
        didSet { defaults.set(favoritesOnlyNotifications, forKey: Keys.favoritesOnly) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            applyLaunchAtLogin()
        }
    }

    private enum Keys {
        static let favorites = "favoriteTeamCodes"
        static let pinned = "pinnedTeamCode"
        static let notifications = "notificationsEnabled"
        static let favoritesOnly = "favoritesOnlyNotifications"
        static let launchAtLogin = "launchAtLogin"
    }

    private init() {
        // didSet does not fire during init, so these don't write back.
        favoriteTeamCodes = Set(defaults.stringArray(forKey: Keys.favorites) ?? [])
        pinnedTeamCode = defaults.string(forKey: Keys.pinned)
        notificationsEnabled = (defaults.object(forKey: Keys.notifications) as? Bool) ?? true
        favoritesOnlyNotifications = defaults.bool(forKey: Keys.favoritesOnly)
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
    }

    func isFavorite(_ code: String) -> Bool {
        favoriteTeamCodes.contains(code)
    }

    func toggleFavorite(_ code: String) {
        if favoriteTeamCodes.contains(code) {
            favoriteTeamCodes.remove(code)
            if pinnedTeamCode == code { pinnedTeamCode = nil }
        } else {
            favoriteTeamCodes.insert(code)
        }
    }

    /// Registers or unregisters the app as a login item. Failures are
    /// non-fatal — on an unsigned debug build this can throw, and the
    /// toggle simply won't take effect at the system level.
    private func applyLaunchAtLogin() {
        do {
            let service = SMAppService.mainApp
            if launchAtLogin {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled { try service.unregister() }
            }
        } catch {
            NSLog("MenuScore: launch-at-login update failed: \(error.localizedDescription)")
        }
    }
}
