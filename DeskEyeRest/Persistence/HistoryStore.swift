//
//  HistoryStore.swift
//  DeskEyeRest
//
//  Codable-on-disk store for BreakLog entries. Persists as JSON under
//  ~/Library/Application Support/DeskEyeRest/history.json. Saves on mutation
//  via debounce (50ms) so a burst of writes coalesces.
//

import Foundation
import Observation
import os.log

@Observable
@MainActor
final class HistoryStore {
    private(set) var logs: [BreakLog] = []
    private let log = Logger(subsystem: "app.deskeyerest", category: "HistoryStore")
    private let fileURL: URL
    private var saveTimer: DispatchSourceTimer?

    init() {
        let dir = URL.applicationSupportDirectory
            .appending(path: "DeskEyeRest", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appending(path: "history.json")
        load()
        // Touch the file on first launch so it visibly exists in the support
        // directory (zero-byte JSON `[]` until the first break is logged).
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            flush()
        }
    }

    // MARK: - Load / save

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            logs = try decoder.decode([BreakLog].self, from: data)
        } catch {
            log.warning("history load error: \(error.localizedDescription, privacy: .private)")
        }
    }

    private func scheduleSave() {
        saveTimer?.cancel()
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + 0.05)
        t.setEventHandler { [weak self] in self?.flush() }
        t.resume()
        saveTimer = t
    }

    private func flush() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(logs)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            log.warning("history save error: \(error.localizedDescription, privacy: .private)")
        }
    }

    // MARK: - Mutations

    @discardableResult
    func logBreakStart(kind: BreakKind, exerciseTitle: String?) -> UUID {
        let entry = BreakLog(kind: kind, startedAt: Date(), exerciseTitle: exerciseTitle)
        logs.append(entry)
        scheduleSave()
        return entry.id
    }

    func markBreakComplete(id: UUID) {
        guard let idx = logs.firstIndex(where: { $0.id == id }) else { return }
        logs[idx].endedAt = Date()
        logs[idx].skipped = false
        scheduleSave()
    }

    func markBreakSkipped(id: UUID) {
        guard let idx = logs.firstIndex(where: { $0.id == id }) else { return }
        logs[idx].endedAt = Date()
        logs[idx].skipped = true
        scheduleSave()
    }

    func deleteAll() {
        logs.removeAll()
        scheduleSave()
        log.info("history cleared")
    }

    // MARK: - Queries (sync and in-memory for modest local histories)

    func sortedDescending() -> [BreakLog] {
        logs.sorted { $0.startedAt > $1.startedAt }
    }
}
