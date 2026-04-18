//
//  SettingsStore.swift
//  DeskEyeRest
//
//  Persists `Settings` as a JSON blob in UserDefaults. Wraps in `@Observable`
//  so SwiftUI views react to changes automatically.
//

import Foundation
import Observation
import os.log

@Observable
@MainActor
final class SettingsStore {
    private static let key = "DeskEyeRest.Settings.v1"
    private let log = Logger(subsystem: "app.deskeyerest", category: "SettingsStore")

    var settings: Settings {
        didSet { persist() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(Settings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = Settings()
            persist()
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: Self.key)
        } catch {
            log.error("Failed to persist settings: \(error.localizedDescription, privacy: .private)")
        }
    }
}
