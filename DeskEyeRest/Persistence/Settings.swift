//
//  Settings.swift
//  DeskEyeRest
//
//  Persisted user preferences. Single Codable struct serialised as JSON in
//  UserDefaults. Defaults use common break-reminder timings.
//

import Foundation

struct Settings: Codable, Equatable {
    var schemaVersion: Int = 1

    // MARK: - General
    var runAtLogin: Bool = false
    var startTimerAutomaticallyOnLaunch: Bool = true
    var idlePauseAfterMinutes: Int = 1
    var idleResetAfterMinutes: Int = 5

    // MARK: - Working hours (Phase 2)
    var workingHoursEnabled: Bool = false
    // Each weekday holds (enabled, startHour, startMinute, endHour, endMinute).
    var workingHours: [WorkingDay] = WorkingDay.weekdayDefaults()

    // MARK: - Smart breaks (Phase 2)
    var meetingDetectionEnabled: Bool = true
    var videoDetectionEnabled: Bool = false

    // MARK: - Menu bar (Phase 0)
    var menuBarStyle: MenuBarStyle = .iconAndTime
    var timerFormat: TimerFormat = .hms

    // MARK: - Breaks
    var shortBreakDurationSeconds: Int = 30
    var longBreakDurationSeconds: Int = 180
    var longBreakAfterShortCount: Int = 3
    var longBreaksEnabled: Bool = true
    var breakCommitment: BreakCommitment = .flexible
    var lockScreenOnShortBreak: Bool = false
    var lockScreenOnLongBreak: Bool = false
    var displayPreBreakNotification: Bool = true
    var showCursorBreakReminder: Bool = true
    var preBreakReminderLeadSeconds: Int = 20
    var preBreakReminderStaysSeconds: Int = 20
    var alertOnBreakReturn: Bool = false
    var soundOnBreakStart: Bool = false
    var soundOnBreakEnd: Bool = true
    var soundVolume: Double = 0.4

    // MARK: - Focus mode
    var focusDurationMinutes: Int = 30

    // MARK: - Flash reminder
    var flashReminderEnabled: Bool = true
    var flashIntervalMinutes: Int = 10
    var flashDurationMs: Int = 900
    var flashColorHex: String = "#9DBCBE"
    var flashMessage: String = "Watch your posture"

    // MARK: - Clock out
    var clockOutEnabled: Bool = false
    var clockOutStartHour: Int = 17
    var clockOutStartMinute: Int = 0
    var clockOutEndHour: Int = 5
    var clockOutEndMinute: Int = 0
    var clockOutTitle: String = "Time to Switch Off"
    var clockOutDescription: String = "It's time to turn off the screen. Treat yourself to a break from the digital world now."
    var clockOutTimeReminderEnabled: Bool = false
    var clockOutNotes: String = ""
}

// MARK: - Sub-types

enum MenuBarStyle: String, Codable, CaseIterable {
    case iconAndTime, timeOnly, iconOnly
}

enum TimerFormat: String, Codable, CaseIterable {
    case hms          // 26:46
    case compact      // 26m
}

enum BreakCommitment: String, Codable, CaseIterable {
    case flexible      // Skip when needed
    case mindful       // Delay 1 or 5 minutes
    case committed     // No exceptions
}

struct WorkingDay: Codable, Equatable, Hashable {
    var weekday: Int     // 1 = Sunday, 2 = Monday, ... ISO-like (Calendar.weekday)
    var enabled: Bool
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int

    static func weekdayDefaults() -> [WorkingDay] {
        // Mon–Fri 9:00–17:00 enabled; Sat–Sun off.
        return (1...7).map { wd in
            let isWorkday = wd >= 2 && wd <= 6
            return WorkingDay(weekday: wd, enabled: isWorkday,
                              startHour: 9, startMinute: 0,
                              endHour: 17, endMinute: 0)
        }
    }
}
