//
//  AppStateTests.swift
//  DeskEyeRestTests
//

import Testing
@testable import DeskEyeRest

@Suite("AppState (Phase 0)")
struct AppStateTests {
    @Test("formatTimer formats seconds correctly")
    func formatTimerWorks() {
        #expect(formatTimer(seconds: 0) == "00:00")
        #expect(formatTimer(seconds: 7) == "00:07")
        #expect(formatTimer(seconds: 60) == "01:00")
        #expect(formatTimer(seconds: 90) == "01:30")
        #expect(formatTimer(seconds: 1500) == "25:00")
        #expect(formatTimer(seconds: 1606) == "26:46")
    }

    @MainActor
    @Test("AppState initializes with focusing state at default duration")
    func initialState() {
        let state = AppState()
        switch state.session {
        case .focusing(let remaining, _):
            #expect(Int(remaining) == 30 * 60)  // default focusDurationMinutes
        default:
            Issue.record("Expected initial state to be .focusing")
        }
    }

    @Test("Settings round-trips through JSON Codable")
    func settingsCodable() throws {
        let original = Settings()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Settings.self, from: data)
        #expect(original == decoded)
    }
}
