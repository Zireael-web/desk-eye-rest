//
//  FlashReminderScheduler.swift
//  DeskEyeRest
//
//  Fires `appState.triggerFlashReminder()` every `flashIntervalMinutes` while
//  the user is *focusing* (i.e. actually working — not on a break, not
//  clocked out, not detected meeting/video).
//

import Foundation
import os.log

@MainActor
final class FlashReminderScheduler {
    private let appState: AppState
    private let log = Logger(subsystem: "app.deskeyerest", category: "FlashReminder")
    private var timer: DispatchSourceTimer?
    private var lastFiredAt: Date = .distantPast

    init(appState: AppState) {
        self.appState = appState
        startPolling()
    }

    private func startPolling() {
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        // Tick once per minute — interval is granular enough.
        t.schedule(deadline: .now() + 5.0, repeating: 60.0, leeway: .seconds(2))
        t.setEventHandler { [weak self] in self?.refresh() }
        t.resume()
        timer = t
    }

    private func refresh() {
        guard appState.settings.flashReminderEnabled else { return }
        // Flash reminders are tied to the main focus tracker — they should
        // only fire while the user is ACTIVELY focusing. That means:
        //   • the underlying timer engine is running (not user-paused via
        //     ⌘⌥P / menu Pause toggle);
        //   • the session is specifically `.focusing` (not idle, not pre-
        //     break alert, not breaking — these are covered by isInBreak
        //     below for break state, but explicit `.focusing` also excludes
        //     idle and pre-break-alert which previously slipped through).
        guard appState.isRunning else { return }
        guard case .focusing = appState.session else { return }
        guard !appState.isInBreak else { return }
        guard !appState.clockOutOverlayActive else { return }
        guard !appState.detection.shouldPauseTimer else { return }
        guard WorkingHoursGate.isActive(at: Date(), settings: appState.settings) else { return }

        let interval = TimeInterval(appState.settings.flashIntervalMinutes * 60)
        let now = Date()
        if now.timeIntervalSince(lastFiredAt) >= interval {
            lastFiredAt = now
            appState.triggerFlashReminder()
            log.info("flash fired")
        }
    }
}
