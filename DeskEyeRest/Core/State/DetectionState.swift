//
//  DetectionState.swift
//  DeskEyeRest
//
//  Aggregated flags from environmental detectors. AppState combines them into
//  `shouldPauseTimer` which the focus tick consults each second.
//

import Foundation

struct DetectionState: Equatable {
    var meetingActive: Bool = false
    var videoActive: Bool = false
    var focusModeBlocking: Bool = false

    var shouldPauseTimer: Bool {
        meetingActive || videoActive || focusModeBlocking
    }
}
