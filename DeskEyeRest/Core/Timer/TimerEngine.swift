//
//  TimerEngine.swift
//  DeskEyeRest
//
//  1-second tick driven by `DispatchSourceTimer` (more reliable than Foundation
//  `Timer` and tolerant of run-loop variations).
//

import Foundation

@MainActor
final class TimerEngine {
    private let queue = DispatchQueue(label: "app.deskeyerest.timer", qos: .userInitiated)
    private var source: DispatchSourceTimer?
    private(set) var isRunning: Bool = false

    /// Called every tick on the main actor.
    var onTick: (() -> Void)?

    func start(interval: TimeInterval = 1.0) {
        guard !isRunning else { return }
        let s = DispatchSource.makeTimerSource(queue: queue)
        s.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(50))
        s.setEventHandler { [weak self] in
            // Hop to main for state updates.
            DispatchQueue.main.async { self?.onTick?() }
        }
        source = s
        s.resume()
        isRunning = true
    }

    func stop() {
        source?.cancel()
        source = nil
        isRunning = false
    }
}
