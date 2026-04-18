//
//  IdleDetector.swift
//  DeskEyeRest
//
//  Detects how long the user has been idle (no input events). Used to pause
//  the focus timer after `idlePauseAfterMinutes` and reset it after
//  `idleResetAfterMinutes`.
//

import AppKit
import os.log

/// Pure wrapper over `CGEventSource.secondsSinceLastEventType`.
/// Read on every tick from the AppState; no internal queue or polling.
@MainActor
struct IdleDetector {
    /// Seconds since the last user input (mouse / keyboard / scroll / etc.).
    /// Returns 0 if the API call fails.
    static func secondsIdle() -> TimeInterval {
        let any = CGEventType(rawValue: ~0) ?? .null
        let s = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: any)
        return s.isFinite && s >= 0 ? s : 0
    }
}
