//
//  FlashEvent.swift
//  DeskEyeRest
//

import Foundation

struct FlashEvent: Equatable {
    let id: UUID = UUID()
    let triggeredAt: Date
    let durationMs: Int
    let colorHex: String
    let message: String
}
