//
//  MeetingDetector.swift
//  DeskEyeRest
//
//  Polls CoreAudio for any audio input device whose `isRunningSomewhere`
//  property is true (i.e. an app is currently capturing audio — typically a
//  meeting). Updates `appState.detection.meetingActive`.
//
//  We deliberately use *property polling* rather than an active stream so we
//  never need the user's microphone permission. Privacy-by-design.
//

import CoreAudio
import Foundation
import os.log

@MainActor
final class MeetingDetector {
    private let appState: AppState
    private let log = Logger(subsystem: "app.deskeyerest", category: "MeetingDetector")
    private var pollingTimer: DispatchSourceTimer?

    init(appState: AppState) {
        self.appState = appState
        startPolling()
    }

    private func startPolling() {
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        t.schedule(deadline: .now() + 1.0, repeating: 2.0, leeway: .milliseconds(200))
        t.setEventHandler { [weak self] in
            guard let self else { return }
            let active = MeetingDetector.anyInputDeviceRunning()
            if appState.settings.meetingDetectionEnabled {
                if appState.detection.meetingActive != active {
                    appState.detection.meetingActive = active
                    log.info("meeting detection: \(active, privacy: .public)")
                }
            } else if appState.detection.meetingActive {
                appState.detection.meetingActive = false
            }
        }
        t.resume()
        pollingTimer = t
    }

    // MARK: - CoreAudio probing

    /// Returns `true` if any *input* device (microphone) is currently running
    /// somewhere — i.e., some app holds an active capture stream.
    static func anyInputDeviceRunning() -> Bool {
        for deviceID in inputDeviceIDs() {
            if isDeviceRunningSomewhere(deviceID) { return true }
        }
        return false
    }

    private static func inputDeviceIDs() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size
        )
        guard status == noErr, size > 0 else { return [] }
        let count = Int(size) / MemoryLayout<AudioObjectID>.size
        var ids = [AudioObjectID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &ids
        )
        guard status == noErr else { return [] }

        // Filter to devices that have at least one input stream.
        return ids.filter { hasInputStreams($0) }
    }

    private static func hasInputStreams(_ deviceID: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size)
        return status == noErr && size > 0
    }

    private static func isDeviceRunningSomewhere(_ deviceID: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &running)
        return status == noErr && running != 0
    }
}
