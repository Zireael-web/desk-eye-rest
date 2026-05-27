//
//  FlashOverlayManager.swift
//  DeskEyeRest
//
//  Per-display flash overlay panels. Mounted permanently (cheap — empty when
//  no flash event) so transitions are instant.
//

import AppKit
import SwiftUI
import Observation
import os.log

@MainActor
final class FlashOverlayManager {
    private let appState: AppState
    private let log = Logger(subsystem: "app.deskeyerest", category: "FlashOverlay")
    private var windows: [BreakOverlayWindow] = []

    init(appState: AppState) {
        self.appState = appState
        observe()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.closeAll()
                if appState.flashEvent != nil {
                    self.openOnAllScreens()
                }
            }
        }
    }

    private func observe() {
        withObservationTracking {
            _ = appState.flashEvent
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.apply()
                self.observe()
            }
        }
    }

    private func apply() {
        if appState.flashEvent != nil, windows.isEmpty {
            openOnAllScreens()
        } else if appState.flashEvent == nil, !windows.isEmpty {
            // Wait for fade-out animation to complete before tearing down.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self, self.appState.flashEvent == nil else { return }
                self.closeAll()
            }
        }
    }

    private func openOnAllScreens() {
        for screen in NSScreen.screens {
            let view = FlashOverlayView().environment(appState)
            let panel = BreakOverlayWindow(screen: screen, content: view)
            panel.ignoresMouseEvents = true  // never blocks user input
            panel.orderFrontRegardless()
            windows.append(panel)
        }
        log.info("flash shown on \(self.windows.count, privacy: .public) screens")
    }

    private func closeAll() {
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
    }
}
