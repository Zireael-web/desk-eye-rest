//
//  AppState.swift
//  DeskEyeRest
//
//  Single source of truth for all observable runtime state. Everything
//  (StatusBarController, Settings views, overlays) reads from this object via
//  the SwiftUI environment or direct injection.
//

import Foundation
import Observation
import UserNotifications
import os.log

@Observable
@MainActor
final class AppState {
    // MARK: - Sub-stores
    let settingsStore: SettingsStore
    let exerciseStore: ExerciseStore
    let historyStore: HistoryStore
    private let timerEngine: TimerEngine
    let soundPlayer = SoundPlayer()  // exposed so Settings → Sound preview can call it
    private let log = Logger(subsystem: "app.deskeyerest", category: "AppState")

    /// Tracks the BreakLog id of the in-progress break so we can mark it
    /// complete/skipped on transition.
    private var currentBreakLogID: UUID?

    // MARK: - Live session state
    var session: SessionState = .idle
    var lastTickAt: Date = .distantPast

    /// Number of short breaks completed since the last long break (used to gate
    /// long-break cadence per `Settings.longBreakAfterShortCount`).
    var shortBreaksSinceLong: Int = 0

    /// Aggregated detector flags (Meeting / Video / Focus). When any is true
    /// during `.focusing`, the countdown is paused but state stays focusing
    /// (so a return to free state immediately resumes).
    var detection: DetectionState = DetectionState()

    /// True when the Clock Out overlay should be on screen. Toggled by
    /// `ClockOutScheduler`.
    var clockOutOverlayActive: Bool = false

    /// Set non-nil while a Flash Reminder is showing. Cleared when the flash
    /// duration elapses. Holds the trigger timestamp so the overlay view can
    /// compute fade progress.
    var flashEvent: FlashEvent?

    // MARK: - Convenience pass-throughs
    var settings: Settings {
        get { settingsStore.settings }
        set { settingsStore.settings = newValue }
    }

    init() {
        self.settingsStore = SettingsStore()
        self.exerciseStore = ExerciseStore()
        self.historyStore = HistoryStore()
        self.timerEngine = TimerEngine()
        self.timerEngine.onTick = { [weak self] in
            guard let self else { return }
            Task { @MainActor in self.tick() }
        }
        let focusSeconds = TimeInterval(settingsStore.settings.focusDurationMinutes * 60)
        self.session = .focusing(remaining: focusSeconds, since: Date())

        // Sync login item with persisted toggle on launch.
        LoginItemController.sync(enabled: settingsStore.settings.runAtLogin)
    }

    /// Called by SettingsStore (or directly from Settings UI) when the
    /// runAtLogin toggle changes.
    func syncRunAtLogin() {
        LoginItemController.sync(enabled: settings.runAtLogin)
    }

    // MARK: - Timer control

    func startTimer() {
        timerEngine.start()
        log.info("timer started")
    }

    func stopTimer() {
        timerEngine.stop()
        log.info("timer stopped")
    }

    func toggleTimer() {
        if timerEngine.isRunning { stopTimer() } else { startTimer() }
    }

    var isRunning: Bool { timerEngine.isRunning }

    // MARK: - User actions (called from menu / hotkeys)

    func restartCycle() {
        let focusSeconds = TimeInterval(settingsStore.settings.focusDurationMinutes * 60)
        session = .focusing(remaining: focusSeconds, since: Date())
        log.info("cycle restarted")
    }

    /// Adjust the remaining time of the current focus cycle by `m` minutes.
    /// Positive values extend the cycle, negative values shrink it. A floor of
    /// 5 seconds is enforced so subtracting more than is left doesn't underflow
    /// (and doesn't accidentally tip the timer into preBreakAlert / break on
    /// the next tick — if the user wants the break, they can use `Start short
    /// break` directly).
    ///
    /// Works in BOTH `.focusing` AND `.preBreakAlert` states. In the alert
    /// window (cursor "break is coming" reminder), the same adjustment is
    /// applied to `breakStartsIn`; if the result moves past the alert lead
    /// window, the session snaps back to `.focusing` and the pre-break
    /// reminder disappears — that's the expected "no, give me more time"
    /// behaviour. Without this branch, hotkeys silently no-op as soon as
    /// the alert appears (the bug we just fixed).
    func extendFocus(byMinutes m: Int) {
        let delta = TimeInterval(m * 60)

        if case .focusing(let remaining, let started) = session {
            let next = max(5, remaining + delta)
            session = .focusing(remaining: next, since: started)
            log.info("focus adjusted by \(m, privacy: .public) min → \(Int(next), privacy: .public)s remaining")
            return
        }

        if case .preBreakAlert(let kind, let breakStartsIn) = session {
            let next = max(5, breakStartsIn + delta)
            let lead = TimeInterval(settings.preBreakReminderLeadSeconds)
            if next > lead {
                // Past the alert window — return to plain .focusing and
                // the pre-break reminder UI clears.
                session = .focusing(remaining: next, since: Date())
                log.info("pre-break cancelled by \(m, privacy: .public) min adj → focusing \(Int(next), privacy: .public)s")
            } else {
                // Still inside the alert window — just push the
                // imminent-break countdown forward/back.
                session = .preBreakAlert(kind: kind, breakStartsIn: next)
                log.info("pre-break adjusted by \(m, privacy: .public) min → \(Int(next), privacy: .public)s till break")
            }
            return
        }
    }

    /// Immediately enter a short break (skips remaining focus time and pre-break alert).
    /// Routes through `beginBreak()` so history logging, sound, and lock-screen
    /// side effects fire identically to an organic break.
    func startShortBreakNow() {
        beginBreak(kind: .short)
        log.info("short break started manually")
    }

    func startLongBreakNow() {
        beginBreak(kind: .long)
        log.info("long break started manually")
    }

    /// Skip the current break — behaviour depends on commitment mode.
    /// In Committed mode this is a no-op (caller should not even show the button).
    func skipCurrentBreak() {
        guard case .breaking(_, let kind, _, _) = session else { return }
        switch settings.breakCommitment {
        case .committed:
            return
        case .flexible:
            session = .skipped(after: kind, at: Date())
            log.info("break skipped (flexible)")
            if let id = currentBreakLogID {
                historyStore.markBreakSkipped(id: id)
                currentBreakLogID = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.returnToFocus()
            }
        case .mindful:
            session = .focusing(remaining: 5 * 60, since: Date())
            log.info("break delayed 5 min (mindful)")
            if let id = currentBreakLogID {
                historyStore.markBreakSkipped(id: id)
                currentBreakLogID = nil
            }
        }
    }

    private func returnToFocus() {
        let focusSeconds = TimeInterval(settings.focusDurationMinutes * 60)
        session = .focusing(remaining: focusSeconds, since: Date())
    }

    // MARK: - Clock Out controls (called from ClockOutOverlayView)

    /// Manually exit Clock Out — slides the overlay away. ClockOutScheduler
    /// will not re-show it until the user moves the end time *or* the next
    /// midnight rolls over (start window enters again).
    func endClockOut() {
        clockOutOverlayActive = false
        log.info("clock-out exited manually")
    }

    /// Extend the Clock Out window's end time by N minutes. Caller can do
    /// `+5` / `+15` from the overlay buttons.
    func extendClockOutEnd(byMinutes m: Int) {
        var endTotal = settings.clockOutEndHour * 60 + settings.clockOutEndMinute + m
        endTotal = ((endTotal % (24 * 60)) + (24 * 60)) % (24 * 60)
        settings.clockOutEndHour = endTotal / 60
        settings.clockOutEndMinute = endTotal % 60
        log.info("clock-out end extended by \(m, privacy: .public) min")
    }

    // MARK: - Flash Reminder (called from FlashScheduler)

    /// Triggers a flash event with current settings. Cleared automatically
    /// after `flashDurationMs`.
    func triggerFlashReminder() {
        let event = FlashEvent(
            triggeredAt: Date(),
            durationMs: settings.flashDurationMs,
            colorHex: settings.flashColorHex,
            message: settings.flashMessage
        )
        flashEvent = event
        let durationSec = Double(settings.flashDurationMs) / 1000.0
        DispatchQueue.main.asyncAfter(deadline: .now() + durationSec) { [weak self] in
            // Clear only if the same event is still live.
            if self?.flashEvent?.id == event.id {
                self?.flashEvent = nil
            }
        }
    }

    // MARK: - Tick — full state machine

    private func tick() {
        lastTickAt = Date()

        // Working-hours gate: pause focus cycle outside configured hours.
        if !WorkingHoursGate.isActive(at: Date(), settings: settings) {
            if case .focusing = session { return }
        }

        // Smart-breaks detection gate: pause focus countdown when meeting /
        // video / focus-filter active. Doesn't pause an in-progress break.
        if detection.shouldPauseTimer {
            if case .focusing = session { return }
            if case .preBreakAlert = session { return }
        }

        // Idle gating: pause the cycle if user has been idle long enough.
        let idleSeconds = IdleDetector.secondsIdle()
        let pauseAfter = TimeInterval(settings.idlePauseAfterMinutes * 60)
        let resetAfter = TimeInterval(settings.idleResetAfterMinutes * 60)
        if pauseAfter > 0 && idleSeconds >= resetAfter {
            // Long idle → reset cycle entirely.
            if case .focusing = session, idleSeconds >= resetAfter {
                let focusSeconds = TimeInterval(settings.focusDurationMinutes * 60)
                session = .focusing(remaining: focusSeconds, since: Date())
                return
            }
        }
        if pauseAfter > 0 && idleSeconds >= pauseAfter {
            // Short-to-medium idle → don't decrement timer this tick.
            // (We don't transition to .idle so that a flicker of activity
            // resumes seamlessly.)
            if case .focusing = session { return }
        }

        switch session {

        case .idle:
            // No active session — nothing to do. (Manual user action will
            // transition out of idle.)
            return

        case .focusing(let remaining, let started):
            let next = max(0, remaining - 1)
            let lead = TimeInterval(settings.preBreakReminderLeadSeconds)
            // Pre-break alert window: when remaining drops to lead seconds.
            if next > 0 && next == lead {
                let nextKind = nextBreakKind()
                session = .preBreakAlert(kind: nextKind, breakStartsIn: lead)
                log.info("pre-break alert (\(nextKind == .short ? "short" : "long", privacy: .public))")
            } else if next == 0 {
                // Time to break.
                beginBreakAfterFocus(focusStartedAt: started)
            } else {
                session = .focusing(remaining: next, since: started)
            }

        case .preBreakAlert(let kind, let breakStartsIn):
            let next = max(0, breakStartsIn - 1)
            if next == 0 {
                beginBreak(kind: kind)
            } else {
                session = .preBreakAlert(kind: kind, breakStartsIn: next)
            }

        case .breaking(let remaining, let kind, let started, let exerciseName):
            let next = max(0, remaining - 1)
            if next == 0 {
                completeBreak(kind: kind)
            } else {
                session = .breaking(remaining: next, kind: kind, started: started, exerciseName: exerciseName)
            }

        case .resuming, .skipped:
            // Visual transition states; auto-handled with asyncAfter callbacks.
            return
        }
    }

    // MARK: - Internal transitions

    private func nextBreakKind() -> BreakKind {
        if settings.longBreaksEnabled,
           shortBreaksSinceLong + 1 >= settings.longBreakAfterShortCount {
            return .long
        }
        return .short
    }

    private func beginBreakAfterFocus(focusStartedAt _: Date) {
        let kind = nextBreakKind()
        beginBreak(kind: kind)
    }

    private func beginBreak(kind: BreakKind) {
        let dur = kind == .short
            ? TimeInterval(settings.shortBreakDurationSeconds)
            : TimeInterval(settings.longBreakDurationSeconds)
        let exercise = pickExercise(for: kind)
        session = .breaking(remaining: dur, kind: kind,
                             started: Date(), exerciseName: exercise?.displayTitle)
        log.info("break started: \(kind == .short ? "short" : "long", privacy: .public) for \(Int(dur), privacy: .public)s")

        currentBreakLogID = historyStore.logBreakStart(
            kind: kind, exerciseTitle: exercise?.displayTitle
        )

        if settings.soundOnBreakStart {
            soundPlayer.playStartChime(volume: settings.soundVolume)
        }

        let shouldLock = (kind == .short && settings.lockScreenOnShortBreak)
                      || (kind == .long  && settings.lockScreenOnLongBreak)
        if shouldLock {
            ScreenLocker.sleepDisplayNow()
        }
    }

    private func completeBreak(kind: BreakKind) {
        switch kind {
        case .short: shortBreaksSinceLong += 1
        case .long:  shortBreaksSinceLong = 0
        }
        session = .resuming(after: kind, completedAt: Date())
        log.info("break completed: \(kind == .short ? "short" : "long", privacy: .public)")

        if let id = currentBreakLogID {
            historyStore.markBreakComplete(id: id)
            currentBreakLogID = nil
        }

        if settings.soundOnBreakEnd {
            soundPlayer.playEndChime(volume: settings.soundVolume)
        }

        // Break Detection — post a "welcome back" notification so the user
        // can confirm/log the just-completed break.
        if settings.alertOnBreakReturn {
            let nc = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "Break complete"
            content.body = kind == .short
                ? "Welcome back. Your eyes thank you."
                : "Welcome back from your long break."
            content.sound = nil
            let req = UNNotificationRequest(
                identifier: "breakReturn-\(Date().timeIntervalSince1970)",
                content: content, trigger: nil
            )
            nc.add(req)
        }

        // Brief visual pause then return to focus.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.returnToFocus()
        }
    }

    private func pickExercise(for kind: BreakKind) -> Exercise? {
        exerciseStore.exercises.first { $0.assignedTo == kind }
    }

    // MARK: - Display helpers

    /// Formatted countdown for the menu-bar item. Returns "—" when idle.
    /// Honors `Settings.timerFormat`: `.hms` produces `26:46`, `.compact`
    /// produces `27m` (rounded up to whole minutes).
    var menuBarCountdownText: String {
        let secs: Int
        switch session {
        case .focusing(let remaining, _):
            secs = Int(remaining)
        case .preBreakAlert(_, let breakStartsIn):
            secs = Int(breakStartsIn)
        case .breaking(let remaining, _, _, _):
            secs = Int(remaining)
        case .idle, .resuming, .skipped:
            return "—"
        }
        switch settings.timerFormat {
        case .hms:
            return formatTimer(seconds: secs)
        case .compact:
            let m = (secs + 59) / 60
            return "\(m)m"
        }
    }

    /// True iff a break overlay should be on screen.
    var isInBreak: Bool {
        if case .breaking = session { return true }
        return false
    }
}

/// Formats `90` → `"01:30"`, `60` → `"01:00"`, `7` → `"00:07"`.
func formatTimer(seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}
