//
//  CursorReminderManager.swift
//  DeskEyeRest
//
//  Shows the CursorReminderWindow during `.preBreakAlert` and updates its
//  position to follow the cursor every ~150 ms.
//

import AppKit
import SwiftUI
import Observation
import os.log

@MainActor
final class CursorReminderManager {
    private let appState: AppState
    private var window: CursorReminderWindow?
    private var followTimer: DispatchSourceTimer?
    private let log = Logger(subsystem: "app.deskeyerest", category: "CursorReminder")

    init(appState: AppState) {
        self.appState = appState
        observe()
    }

    private func observe() {
        withObservationTracking {
            _ = appState.session
            _ = appState.settings.showCursorBreakReminder
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.apply()
                self.observe()
            }
        }
    }

    private func apply() {
        let shouldShow: Bool
        if case .preBreakAlert = appState.session,
           appState.settings.showCursorBreakReminder {
            shouldShow = true
        } else {
            shouldShow = false
        }

        if shouldShow, window == nil {
            let view = CursorReminderView().environment(appState)
            let w = CursorReminderWindow(content: view)
            w.orderFrontRegardless()
            window = w
            startFollowing()
            log.info("cursor reminder shown")

            // Auto-hide after `preBreakReminderStaysSeconds` even if the alert
            // continues — keep the reminder briefer than the full pre-break
            // window.
            let stays = max(1, appState.settings.preBreakReminderStaysSeconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stays)) { [weak self] in
                guard let self else { return }
                if case .preBreakAlert = self.appState.session {
                    self.stopFollowing()
                    self.window?.orderOut(nil)
                    self.window = nil
                }
            }
        } else if !shouldShow, window != nil {
            stopFollowing()
            window?.orderOut(nil)
            window = nil
            log.info("cursor reminder hidden")
        }
    }

    private func startFollowing() {
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        t.schedule(deadline: .now(), repeating: 0.05, leeway: .milliseconds(20))
        t.setEventHandler { [weak self] in
            guard let self, let w = self.window else { return }
            let mouse = NSEvent.mouseLocation  // bottom-left origin
            // Position 18 px to the right and 18 px down from the cursor
            // (NSWindow origin is bottom-left)
            let frame = w.frame
            let pos = NSPoint(x: mouse.x + 18, y: mouse.y - frame.height - 18)
            w.setFrameOrigin(pos)
        }
        t.resume()
        followTimer = t
    }

    private func stopFollowing() {
        followTimer?.cancel()
        followTimer = nil
    }
}
