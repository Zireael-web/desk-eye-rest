//
//  ClockOutScheduler.swift
//  DeskEyeRest
//
//  Polls the wall clock once a minute (and once on launch) to decide whether
//  the Clock Out overlay should be on screen. Setting `clockOutEnabled = false`
//  immediately retracts the overlay.
//

import Foundation
import os.log

@MainActor
final class ClockOutScheduler {
    private let appState: AppState
    private let log = Logger(subsystem: "app.deskeyerest", category: "ClockOutScheduler")
    private var timer: DispatchSourceTimer?

    init(appState: AppState) {
        self.appState = appState
        startPolling()
    }

    private func startPolling() {
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        // Tick immediately, then every 30 seconds (cheap, deterministic).
        t.schedule(deadline: .now() + 1.0, repeating: 30.0, leeway: .seconds(2))
        t.setEventHandler { [weak self] in self?.refresh() }
        t.resume()
        timer = t
    }

    private func refresh() {
        let active = appState.settings.clockOutEnabled && isInsideClockOutWindow(now: Date())
        if appState.clockOutOverlayActive != active {
            appState.clockOutOverlayActive = active
            log.info("clock out: \(active, privacy: .public)")
        }
    }

    private func isInsideClockOutWindow(now: Date) -> Bool {
        let cal = Calendar.current
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        let nowMin = h * 60 + m
        let startMin = appState.settings.clockOutStartHour * 60 + appState.settings.clockOutStartMinute
        let endMin   = appState.settings.clockOutEndHour   * 60 + appState.settings.clockOutEndMinute
        if startMin == endMin { return false }
        if startMin < endMin {
            return nowMin >= startMin && nowMin < endMin
        } else {
            // Wraps midnight (typical: 18:00 → 05:00 next day)
            return nowMin >= startMin || nowMin < endMin
        }
    }
}
