//
//  VideoDetector.swift
//  DeskEyeRest
//
//  PHASE-2.5 NOTE — Video Detection is currently a safe no-op.
//
//  The original implementation called `MRMediaRemoteGetNowPlayingApplicationIsPlaying`
//  in `MediaRemote.framework` via `dlsym`. That private symbol works through
//  macOS 14/15 but on macOS 26 traps with EXC_BREAKPOINT (Apple appears to
//  have removed or changed the function signature, and there is no public
//  replacement). The previous version also blocked the main thread on a
//  semaphore, which deadlocked the UI when the reply never arrived — the
//  whole app went unresponsive after the user enabled the toggle.
//
//  We now keep the polling timer and the Settings toggle intact for forward-
//  compatibility, but the actual detection returns `false` so
//  `detection.videoActive` is never asserted. The focus cycle behaves exactly
//  as if no video were playing, regardless of the toggle state.
//
//  Phase 3 should replace this with a safe heuristic — for example:
//    • NSWorkspace.shared.frontmostApplication.bundleIdentifier ∈ known set
//      (com.apple.QuickTimePlayerX, com.google.Chrome on a YouTube tab, …)
//    • CGWindowListCopyWindowInfo + fullscreen detection
//    • NowPlayingInfoCenter (public, but only sees our own app's info)
//

import Foundation
import os.log

@MainActor
final class VideoDetector {
    private let appState: AppState
    private let log = Logger(subsystem: "app.deskeyerest", category: "VideoDetector")
    private var pollingTimer: DispatchSourceTimer?

    init(appState: AppState) {
        self.appState = appState
        startPolling()
    }

    private func startPolling() {
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        t.schedule(deadline: .now() + 5.0, repeating: 10.0, leeway: .seconds(2))
        t.setEventHandler { [weak self] in
            Task { @MainActor in self?.tick() }
        }
        t.resume()
        pollingTimer = t
    }

    private func tick() {
        // Safe no-op. Always reports "no video playing", so the focus cycle
        // is never affected by this detector. The Settings toggle is purely
        // cosmetic until Phase 3 lands a non-private-API replacement.
        if appState.detection.videoActive {
            appState.detection.videoActive = false
        }
    }
}
