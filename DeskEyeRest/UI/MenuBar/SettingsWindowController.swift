//
//  SettingsWindowController.swift
//  DeskEyeRest
//
//  AppKit-based controller for the Settings window. We can't drive SwiftUI's
//  `openWindow` action from outside a SwiftUI view, so we host the SwiftUI
//  `SettingsView` inside an NSHostingController in our own NSWindow.
//

import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 740),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DeskEyeRest Settings"
        window.titlebarAppearsTransparent = false
        window.center()
        window.contentMinSize = NSSize(width: 980, height: 640)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        window.contentViewController = NSHostingController(
            rootView: SettingsView().environment(appState)
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    // Hide the window on close instead of releasing — so reopening is fast.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
