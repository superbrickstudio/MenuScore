import Foundation
import Combine

/// User preferences, persisted to UserDefaults. A single shared instance
/// so non-view code (the store) can read it while views observe it as an
/// EnvironmentObject.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }

    private enum Keys {
        static let notifications = "notificationsEnabled"
    }

    private init() {
        notificationsEnabled = (defaults.object(forKey: Keys.notifications) as? Bool) ?? true
    }
}
