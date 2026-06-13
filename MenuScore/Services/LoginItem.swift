import Foundation
import ServiceManagement

/// Registers MenuScore to launch at login automatically. Called once at
/// startup. Failures are non-fatal — on an unsigned debug build this can
/// throw, and registration simply won't take effect.
enum LoginItem {
    static func enable() {
        do {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("MenuScore: launch-at-login registration failed: \(error.localizedDescription)")
        }
    }
}
