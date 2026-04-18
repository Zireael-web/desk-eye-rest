//
//  BreakLog.swift
//  DeskEyeRest
//
//  Simple Codable record. We use a JSON-file store rather than SwiftData
//  because SwiftData's @Model macro depends on Xcode's SwiftDataMacros plugin
//  (not present in the standalone Command Line Tools toolchain we use for
//  offline type-checking). For modest local histories (hundreds of entries),
//  Codable-on-disk is faster, simpler, and more transparent.
//

import Foundation

struct BreakLog: Codable, Identifiable, Equatable {
    var id: UUID
    var kind: BreakKind
    var startedAt: Date
    var endedAt: Date?
    var skipped: Bool
    var exerciseTitle: String?

    init(id: UUID = UUID(),
         kind: BreakKind,
         startedAt: Date,
         endedAt: Date? = nil,
         skipped: Bool = false,
         exerciseTitle: String? = nil) {
        self.id = id
        self.kind = kind
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.skipped = skipped
        self.exerciseTitle = exerciseTitle
    }
}
