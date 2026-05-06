//
//  ScreenLocker.swift
//  DeskEyeRest
//
//  Locks (sleeps) the display via `pmset displaysleepnow`. This is not
//  sandbox-compatible.
//

import Foundation
import os.log

@MainActor
enum ScreenLocker {
    private static let log = Logger(subsystem: "app.deskeyerest", category: "ScreenLock")

    static func sleepDisplayNow() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["displaysleepnow"]
        do {
            try task.run()
            log.info("display sleep requested")
        } catch {
            log.warning("pmset failed: \(error.localizedDescription, privacy: .private)")
        }
    }
}
