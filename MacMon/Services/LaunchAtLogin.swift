import Foundation
import ServiceManagement

/// Обёртка над `SMAppService.mainApp` (macOS 13+) для автозапуска при входе.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Включить/выключить. Бросает ошибку при неудаче регистрации — UI её покажет.
    static func set(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        }
    }
}
