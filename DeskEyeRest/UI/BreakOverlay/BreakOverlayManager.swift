//
//  BreakOverlayManager.swift
//  DeskEyeRest
//
//  Coordinates per-screen `BreakOverlayWindow` instances based on
//  `appState.session`. When state enters `.breaking`, opens an overlay window
//  on every connected display. When state leaves `.breaking`, closes them.
//

import AppKit
import SwiftUI
import Observation
import os.log

@MainActor
final class BreakOverlayManager {
    private let appState: AppState
    private let log = Logger(subsystem: "app.deskeyerest", category: "BreakOverlay")
    private var windows: [BreakOverlayWindow] = []

    init(appState: AppState) {
        self.appState = appState
        observe()

        // Refresh on display configuration changes (plug/unplug monitor).
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.appState.isInBreak {
                    self.closeAll()
                    self.openOnAllScreens()
                }
            }
        }
    }

    // MARK: - State observation

    private func observe() {
        withObservationTracking {
            _ = appState.session
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.applyState()
                self.observe()  // re-arm one-shot tracking
            }
        }
    }

    private func applyState() {
        if appState.isInBreak {
            if windows.isEmpty {
                openOnAllScreens()
            }
        } else {
            if !windows.isEmpty {
                closeAll()
            }
        }
    }

    // MARK: - Window management

    private func openOnAllScreens() {
        let screens = NSScreen.screens
        log.info("opening on \(screens.count, privacy: .public) screen(s)")
        for screen in screens {
            let view = BreakOverlayView()
                .environment(appState)
            let panel = BreakOverlayWindow(screen: screen, content: view)
            panel.orderFrontRegardless()
            // Re-enforce the full-screen frame AFTER ordering, in case macOS
            // adjusted it during the order-front transition.
            panel.enforceFullScreen(on: screen)
            windows.append(panel)
        }
        log.info("opened \(self.windows.count, privacy: .public) break overlay windows")
    }

    private func closeAll() {
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
        log.info("closed break overlay windows")
    }
}
