//
//  AppDelegate.swift
//  DeskEyeRest
//

import AppKit
import SwiftUI
import os.log

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState: AppState
    private(set) var statusBarController: StatusBarController!
    private var breakOverlayManager: BreakOverlayManager!
    private var preBreakNotifier: PreBreakNotifier!
    private var cursorReminderManager: CursorReminderManager!
    private var hotkeys: HotKeyRegistry!
    private var meetingDetector: MeetingDetector!
    private var focusModeDetector: FocusModeDetector!
    private var videoDetector: VideoDetector!
    private var clockOutOverlayManager: ClockOutOverlayManager!
    private var clockOutScheduler: ClockOutScheduler!
    private var flashOverlayManager: FlashOverlayManager!
    private var flashScheduler: FlashReminderScheduler!
    private let log = Logger(subsystem: "app.deskeyerest", category: "AppDelegate")

    override init() {
        self.appState = AppState()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("applicationDidFinishLaunching")

        NSApplication.shared.setActivationPolicy(.accessory)
        registerBundledFonts()

        statusBarController = StatusBarController(appState: appState)
        breakOverlayManager = BreakOverlayManager(appState: appState)
        preBreakNotifier = PreBreakNotifier(appState: appState)
        cursorReminderManager = CursorReminderManager(appState: appState)
        hotkeys = HotKeyRegistry()
        registerDefaultHotkeys()

        meetingDetector = MeetingDetector(appState: appState)
        focusModeDetector = FocusModeDetector(appState: appState)
        videoDetector = VideoDetector(appState: appState)

        clockOutOverlayManager = ClockOutOverlayManager(appState: appState)
        clockOutScheduler = ClockOutScheduler(appState: appState)
        flashOverlayManager = FlashOverlayManager(appState: appState)
        flashScheduler = FlashReminderScheduler(appState: appState)

        if appState.settings.startTimerAutomaticallyOnLaunch {
            appState.startTimer()
        }

        if ProcessInfo.processInfo.environment["DESKEYEREST_AUTOOPEN_SETTINGS"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.statusBarController.openSettings()
            }
        }
        if ProcessInfo.processInfo.environment["DESKEYEREST_TEST_TRIGGER_SHORT_BREAK"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.appState.startShortBreakNow()
            }
        }
        if ProcessInfo.processInfo.environment["DESKEYEREST_TEST_TRIGGER_CLOCK_OUT"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.appState.clockOutOverlayActive = true
            }
        }
        if ProcessInfo.processInfo.environment["DESKEYEREST_TEST_TRIGGER_FLASH"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.appState.triggerFlashReminder()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.stopTimer()
    }

    // MARK: - Hotkeys

    private func registerDefaultHotkeys() {
        let mods: NSEvent.ModifierFlags = [.command, .option]
        hotkeys.register(name: "Start short break", keyCode: VirtualKey.s, modifierFlags: mods) { [weak self] in
            self?.appState.startShortBreakNow()
        }
        hotkeys.register(name: "Start long break", keyCode: VirtualKey.l, modifierFlags: mods) { [weak self] in
            self?.appState.startLongBreakNow()
        }
        hotkeys.register(name: "Restart timer", keyCode: VirtualKey.r, modifierFlags: mods) { [weak self] in
            self?.appState.restartCycle()
        }
        hotkeys.register(name: "Add 1 minute", keyCode: VirtualKey.key1, modifierFlags: mods) { [weak self] in
            self?.appState.extendFocus(byMinutes: 1)
        }
        hotkeys.register(name: "Add 5 minutes", keyCode: VirtualKey.key5, modifierFlags: mods) { [weak self] in
            self?.appState.extendFocus(byMinutes: 5)
        }
        let modsShift: NSEvent.ModifierFlags = [.command, .option, .shift]
        hotkeys.register(name: "Subtract 1 minute", keyCode: VirtualKey.key1, modifierFlags: modsShift) { [weak self] in
            self?.appState.extendFocus(byMinutes: -1)
        }
        hotkeys.register(name: "Subtract 5 minutes", keyCode: VirtualKey.key5, modifierFlags: modsShift) { [weak self] in
            self?.appState.extendFocus(byMinutes: -5)
        }
        hotkeys.register(name: "Pause/Resume timer", keyCode: VirtualKey.p, modifierFlags: mods) { [weak self] in
            self?.appState.toggleTimer()
        }
        hotkeys.register(name: "Skip break", keyCode: VirtualKey.b, modifierFlags: mods) { [weak self] in
            self?.appState.skipCurrentBreak()
        }
    }

    // MARK: - Bundled fonts

    /// Registers all `.ttf` files inside Resources/Fonts so we can use them
    /// via `Font(name:size:)` regardless of system installation.
    private func registerBundledFonts() {
        guard let fontsURL = Bundle.main.resourceURL?.appendingPathComponent("Fonts"),
              let urls = try? FileManager.default
                  .contentsOfDirectory(at: fontsURL, includingPropertiesForKeys: nil)
        else {
            log.warning("Resources/Fonts directory not found — bundled fonts unavailable")
            return
        }
        let fontURLs = urls.filter { $0.pathExtension.lowercased() == "ttf" }
        guard !fontURLs.isEmpty else {
            log.warning("No .ttf files found in Resources/Fonts")
            return
        }
        CTFontManagerRegisterFontURLs(
            fontURLs as CFArray,
            .process,
            true
        ) { [log] errors, done in
            let cfArray: CFArray = errors
            let asNSArray = cfArray as NSArray
            if asNSArray.count > 0 {
                log.error("Failed to register \(asNSArray.count, privacy: .public) bundled fonts")
            }
            return true
        }
        log.info("Registered \(fontURLs.count, privacy: .public) bundled fonts")
    }
}
