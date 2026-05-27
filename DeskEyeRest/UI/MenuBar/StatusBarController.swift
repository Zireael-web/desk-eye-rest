//
//  StatusBarController.swift
//  DeskEyeRest
//
//  Owns the NSStatusItem (the menu-bar icon + countdown). Builds a fresh menu
//  on every click so that all menu items reflect the current AppState.
//

import AppKit
import SwiftUI
import Observation
import Combine

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private var observation: NSObjectProtocol?
    private var withdrawalToken: AnyCancellable?
    private var settingsWindowController: SettingsWindowController?

    init(appState: AppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        configureButton()
        rebuildMenu()

        // Subscribe to AppState observable changes so the title updates each tick.
        startObservingAppState()
    }

    /// External hook for AppDelegate (e.g. test auto-open).
    func openSettings() {
        openSettings(nil)
    }

    // MARK: - Button

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = trayIcon()
        button.imagePosition = .imageLeading
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        refreshTitle()
    }

    private func trayIcon() -> NSImage? {
        // Try asset catalog first (works in Xcode-built app); fall back to a loose
        // PNG bundled as a resource (works in manual swiftc builds without actool);
        // finally fall back to a system symbol.
        let img: NSImage?
        if let assetIcon = NSImage(named: "AppIcon") {
            img = assetIcon
        } else if let url = Bundle.main.url(forResource: "icon-32", withExtension: "png"),
                  let pngIcon = NSImage(contentsOf: url) {
            img = pngIcon
        } else {
            img = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "DeskEyeRest")
        }
        img?.size = NSSize(width: 18, height: 18)
        img?.isTemplate = false
        return img
    }

    private func refreshTitle() {
        guard let button = statusItem.button else { return }
        let style = appState.settings.menuBarStyle
        let countdown = appState.menuBarCountdownText
        switch style {
        case .iconAndTime:
            button.image?.isTemplate = false
            button.title = " " + countdown
        case .timeOnly:
            button.image = nil
            button.title = countdown
        case .iconOnly:
            button.image = trayIcon()
            button.title = ""
        }
    }

    // MARK: - Menu

    private func rebuildMenu() {
        let menu = NSMenu()

        // Header — countdown
        let headerTitle = NSMenuItem(title: "Next break in  \(appState.menuBarCountdownText)",
                                     action: nil, keyEquivalent: "")
        headerTitle.isEnabled = false
        menu.addItem(headerTitle)
        menu.addItem(.separator())

        // Phase 1: real wiring
        menu.addItem(makeItem("Start short break", key: "s", action: #selector(startShortBreak(_:))))
        menu.addItem(makeItem("Start long break",  key: "l", action: #selector(startLongBreak(_:))))
        menu.addItem(makeItem("Add 1 minute",       key: "1", action: #selector(addOneMinute(_:))))
        menu.addItem(makeItem("Add 5 minutes",      key: "5", action: #selector(addFiveMinutes(_:))))
        menu.addItem(makeShiftItem("Subtract 1 minute",  key: "1", action: #selector(subtractOneMinute(_:))))
        menu.addItem(makeShiftItem("Subtract 5 minutes", key: "5", action: #selector(subtractFiveMinutes(_:))))
        menu.addItem(makeItem("Restart timer",      key: "r", action: #selector(restartTimer(_:))))
        menu.addItem(.separator())

        let pauseTitle = appState.isRunning ? "Pause DeskEyeRest" : "Start DeskEyeRest"
        menu.addItem(makeItem(pauseTitle, key: "p", action: #selector(togglePause(_:))))
        menu.addItem(.separator())

        menu.addItem(makeItem("Settings…", key: ",", action: #selector(openSettings(_:))))
        menu.addItem(makeItem("Quit DeskEyeRest", key: "q", action: #selector(quit(_:))))

        statusItem.menu = menu
    }

    private func makeItem(_ title: String, key: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    /// Same as `makeItem` but the menu shortcut shows ⇧⌘<key> instead of ⌘<key>.
    /// Used for "Subtract N minutes" to distinguish from "Add N minutes" which
    /// re-uses the same digit keys.
    private func makeShiftItem(_ title: String, key: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = [.command, .shift]
        item.target = self
        return item
    }

    // MARK: - Actions

    @objc private func togglePause(_ sender: NSMenuItem) {
        appState.toggleTimer()
        rebuildMenu()
    }

    @objc func openSettings(_ sender: Any?) {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(appState: appState)
        }
        settingsWindowController?.show()
    }

    @objc private func quit(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }

    @objc private func startShortBreak(_ sender: NSMenuItem) {
        appState.startShortBreakNow()
    }

    @objc private func startLongBreak(_ sender: NSMenuItem) {
        appState.startLongBreakNow()
    }

    @objc private func addOneMinute(_ sender: NSMenuItem) {
        appState.extendFocus(byMinutes: 1)
    }

    @objc private func addFiveMinutes(_ sender: NSMenuItem) {
        appState.extendFocus(byMinutes: 5)
    }

    @objc private func subtractOneMinute(_ sender: NSMenuItem) {
        appState.extendFocus(byMinutes: -1)
    }

    @objc private func subtractFiveMinutes(_ sender: NSMenuItem) {
        appState.extendFocus(byMinutes: -5)
    }

    @objc private func restartTimer(_ sender: NSMenuItem) {
        appState.restartCycle()
    }

    // MARK: - Live updates

    private func startObservingAppState() {
        // Use the tracking closure pattern from Observation framework so the
        // status bar refreshes every time AppState changes.
        observe()
    }

    private func observe() {
        withObservationTracking {
            _ = appState.session
            _ = appState.settings.menuBarStyle
            _ = appState.isRunning
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.refreshTitle()
                self.rebuildMenu()
                // Re-arm the observation (one-shot semantics).
                self.observe()
            }
        }
    }
}

extension Notification.Name {
    static let openSettingsRequested = Notification.Name("DeskEyeRest.OpenSettingsRequested")
}
