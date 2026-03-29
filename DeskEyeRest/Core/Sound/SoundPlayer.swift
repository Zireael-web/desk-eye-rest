//
//  SoundPlayer.swift
//  DeskEyeRest
//
//  Tiny wrapper that plays the system "Glass"/"Pop"-style sounds on break
//  start/end. Phase 6 may swap to a curated AVAudioPlayer with our own assets.
//

import AppKit
import AVFoundation
import os.log

@MainActor
final class SoundPlayer {
    private let log = Logger(subsystem: "app.deskeyerest", category: "Sound")
    private var player: AVAudioPlayer?

    /// Play a soft single chime (system "Tink"). Volume scales 0–1.
    func playStartChime(volume: Double) {
        playSystemSound(named: "Tink", volume: volume)
    }

    /// Play a softer two-tone end ping (system "Pop").
    func playEndChime(volume: Double) {
        playSystemSound(named: "Pop", volume: volume)
    }

    private func playSystemSound(named name: String, volume: Double) {
        // System sounds live in /System/Library/Sounds/<Name>.aiff
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = Float(max(0, min(1, volume)))
            p.prepareToPlay()
            p.play()
            // Retain the player long enough to finish.
            self.player = p
        } catch {
            log.warning("could not play \(name, privacy: .public): \(error.localizedDescription, privacy: .private)")
        }
    }
}
