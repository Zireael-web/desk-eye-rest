//
//  LoginItemController.swift
//  DeskEyeRest
//
//  Wraps macOS 13+ `SMAppService` for "Open at Login" registration. We sync
//  the SMAppService state with `Settings.runAtLogin` whenever the toggle
//  changes (or on app launch).
//

import Foundation
import ServiceManagement
import os.log

@MainActor
enum LoginItemController {
    private static let log = Logger(subsystem: "app.deskeyerest", category: "LoginItem")

    /// Make the system match `enabled`. Idempotent — safe to call repeatedly.
    static func sync(enabled: Bool) {
        let service = SMAppService.mainApp
        let current = service.status == .enabled
        guard current != enabled else { return }
        do {
            if enabled {
                try service.register()
                log.info("login item registered")
            } else {
                try service.unregister()
                log.info("login item unregistered")
            }
        } catch {
            log.warning("login item sync failed: \(error.localizedDescription, privacy: .private)")
        }
    }

    /// Read-only check used by SettingsStore on launch to keep state in sync.
    static var isCurrentlyRegistered: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
