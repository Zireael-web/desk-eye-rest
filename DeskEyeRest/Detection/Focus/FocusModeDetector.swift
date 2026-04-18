//
//  FocusModeDetector.swift
//  DeskEyeRest
//
//  Reads `INFocusStatusCenter.default.focusStatus.isFocused` — true when a
//  macOS Focus mode (Do Not Disturb / Work / Personal / Sleep / etc.) is
//  currently active.
//
//  Phase 2 pulls just the boolean. Phase 6 plus an Intents Extension can let
//  the user pick *which* Focus modes pause DeskEyeRest (per-mode filters).
//

import Foundation
import Intents
import os.log

@MainActor
final class FocusModeDetector {
    private let appState: AppState
    private let log = Logger(subsystem: "app.deskeyerest", category: "FocusModeDetector")
    private var pollingTimer: DispatchSourceTimer?

    init(appState: AppState) {
        self.appState = appState
        startPolling()
    }

    private func startPolling() {
        // Only call into INFocusStatusCenter if auth has already been granted —
        // calling requestAuthorization without the proper entitlement
        // crashes (TCC SIGABRT) on macOS 14+. Ad-hoc development builds do
        // not have the entitlement, so we observe but do not ask.
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        t.schedule(deadline: .now() + 5.0, repeating: 10.0, leeway: .seconds(1))
        t.setEventHandler { [weak self] in
            self?.refresh()
        }
        t.resume()
        pollingTimer = t
    }

    private func refresh() {
        let center = INFocusStatusCenter.default
        // Only read authorizationStatus — never request — to avoid crashing
        // unentitled builds.
        guard center.authorizationStatus == .authorized else { return }

        let active = center.focusStatus.isFocused ?? false
        if appState.detection.focusModeBlocking != active {
            appState.detection.focusModeBlocking = active
            log.info("focus mode: \(active, privacy: .public)")
        }
    }
}
