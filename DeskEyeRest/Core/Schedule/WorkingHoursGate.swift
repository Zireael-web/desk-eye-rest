//
//  WorkingHoursGate.swift
//  DeskEyeRest
//
//  Pure helper that decides whether DeskEyeRest should be active at a given
//  point in time per the user's `WorkingDay` configuration.
//

import Foundation

enum WorkingHoursGate {
    /// Returns `true` when the focus/break cycle should run at `now`.
    /// When the feature is disabled in settings, always returns `true`.
    static func isActive(at now: Date, settings: Settings,
                         calendar: Calendar = .current) -> Bool {
        guard settings.workingHoursEnabled else { return true }
        let weekday = calendar.component(.weekday, from: now)  // 1 = Sunday
        guard let day = settings.workingHours.first(where: { $0.weekday == weekday }) else {
            return true
        }
        if !day.enabled { return false }
        let h = calendar.component(.hour, from: now)
        let m = calendar.component(.minute, from: now)
        let nowMinutes = h * 60 + m
        let startMin = day.startHour * 60 + day.startMinute
        let endMin   = day.endHour   * 60 + day.endMinute
        if startMin <= endMin {
            return nowMinutes >= startMin && nowMinutes < endMin
        } else {
            // Wrap past midnight (rare; we still respect it)
            return nowMinutes >= startMin || nowMinutes < endMin
        }
    }
}
