//
//  SessionState.swift
//  DeskEyeRest
//
//  The high-level state machine of the focus / break cycle.
//
//  Phase 0 only really uses `.focusing`. Phase 1 will populate the rest.
//

import Foundation

enum BreakKind: String, Codable, Equatable, Hashable {
    case short
    case long
}

enum SessionState: Equatable {
    /// No active timer. Triggered by long idle, working-hours-off, manual stop.
    case idle

    /// Counting down inside a focus session.
    case focusing(remaining: TimeInterval, since: Date)

    /// Pre-break notification is showing (countdown to overlay).
    case preBreakAlert(kind: BreakKind, breakStartsIn: TimeInterval)

    /// Break overlay is on screen.
    case breaking(remaining: TimeInterval, kind: BreakKind, started: Date, exerciseName: String?)

    /// Break completed, animating back into focus.
    case resuming(after: BreakKind, completedAt: Date)

    /// User skipped the break.
    case skipped(after: BreakKind, at: Date)
}
