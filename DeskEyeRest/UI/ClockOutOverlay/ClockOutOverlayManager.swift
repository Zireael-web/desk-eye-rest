//
//  ClockOutOverlayManager.swift
//  DeskEyeRest
//
//  Per-display Clock Out overlay panels. Mirrors BreakOverlayManager's design
//  but driven by `appState.clockOutOverlayActive` (set by ClockOutScheduler).
//

import AppKit
import SwiftUI
import Observation
import os.log

@MainActor
final class ClockOutOverlayManager {
    private let appState: AppState
    private let log = Logger(subsystem: "app.deskeyerest", category: "ClockOutOverlay")
    private var windows: [BreakOverlayWindow] = []  // reuse our overlay-window class

    init(appState: AppState) {
        self.appState = appState
        observe()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if appState.clockOutOverlayActive {
                    self.closeAll()
                    self.openOnAllScreens()
                }
            }
        }
    }

    private func observe() {
        withObservationTracking {
            _ = appState.clockOutOverlayActive
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.apply()
                self.observe()
            }
        }
    }

    private func apply() {
        if appState.clockOutOverlayActive, windows.isEmpty {
            openOnAllScreens()
        } else if !appState.clockOutOverlayActive, !windows.isEmpty {
            closeAll()
        }
    }

    private func openOnAllScreens() {
        for screen in NSScreen.screens {
            let view = ClockOutOverlayView(
                onExit:    { [weak self] in self?.appState.endClockOut() },
                onExtend5: { [weak self] in self?.appState.extendClockOutEnd(byMinutes: 5) },
                onExtend15:{ [weak self] in self?.appState.extendClockOutEnd(byMinutes: 15) }
            ).environment(appState)
            let panel = BreakOverlayWindow(screen: screen, content: view)
            panel.orderFrontRegardless()
            windows.append(panel)
        }
        log.info("opened \(self.windows.count, privacy: .public) clock-out overlay windows")
    }

    private func closeAll() {
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
        log.info("closed clock-out overlay windows")
    }
}
