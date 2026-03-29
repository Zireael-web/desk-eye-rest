//
//  ExerciseStore.swift
//  DeskEyeRest
//
//  In-memory store for exercises during Phase 0.5. Phase 4 swaps the storage
//  backend to SwiftData (`@Model final class Exercise { ... }`) without
//  changing the public API consumed by `ExercisesPage`.
//

import Foundation
import Observation

struct Exercise: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var displayTitle: String
    var detail: String
    var assignedTo: BreakKind
    var isBuiltIn: Bool

    init(id: UUID = UUID(),
         name: String,
         displayTitle: String,
         detail: String,
         assignedTo: BreakKind,
         isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.displayTitle = displayTitle
        self.detail = detail
        self.assignedTo = assignedTo
        self.isBuiltIn = isBuiltIn
    }
}

@Observable
@MainActor
final class ExerciseStore {
    var exercises: [Exercise] {
        didSet { scheduleSave() }
    }
    private let fileURL: URL
    private var saveTimer: DispatchSourceTimer?

    init() {
        let dir = URL.applicationSupportDirectory
            .appending(path: "DeskEyeRest", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appending(path: "exercises.json")

        // Try load; fall back to built-in defaults on first launch.
        var loadedFromDisk = false
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Exercise].self, from: data),
           !decoded.isEmpty {
            self.exercises = decoded
            loadedFromDisk = true
        } else {
            self.exercises = ExerciseStore.builtInDefaults()
        }

        // Swift `didSet` doesn't fire from inside an initializer, so when we
        // use the built-in defaults on first launch we have to persist them
        // explicitly — otherwise the JSON file stays absent until the user
        // adds/edits an exercise.
        if !loadedFromDisk {
            flush()
        }
    }

    static func builtInDefaults() -> [Exercise] {
        [
            Exercise(
                name: "Eye break",
                displayTitle: "Rest Your Eyes, Refresh Your Mind",
                detail: "Gentle reminders to protect your vision and boost focus. Take a moment - your eyes deserve it.",
                assignedTo: .short,
                isBuiltIn: true
            ),
            Exercise(
                name: "Stretch",
                displayTitle: "Stretch Your Body, Energize Your Work",
                detail: "Reminder to flex and refocus. Boost your body, boost your work.",
                assignedTo: .long,
                isBuiltIn: true
            ),
        ]
    }

    func add(_ exercise: Exercise) { exercises.append(exercise) }

    func update(_ exercise: Exercise) {
        if let idx = exercises.firstIndex(where: { $0.id == exercise.id }) {
            exercises[idx] = exercise
        }
    }

    func delete(id: UUID) {
        exercises.removeAll { $0.id == id && !$0.isBuiltIn }
    }

    // MARK: - Persistence

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
            let data = try encoder.encode(exercises)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // best-effort; not critical
        }
    }
}
