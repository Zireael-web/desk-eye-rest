//
//  HotKeyRegistry.swift
//  DeskEyeRest
//
//  Thin Swift wrapper around Carbon's `RegisterEventHotKey` for system-wide
//  keyboard shortcuts. Doesn't require Accessibility permission (unlike
//  NSEvent.addGlobalMonitorForEvents).
//
//  Phase 1.5: 7 hardcoded sensible defaults for the actions defined in
//  StatusBarController menu. Phase 6 swaps in user-configurable bindings via
//  the Settings → Keyboard Shortcuts page.
//

import AppKit
import Carbon.HIToolbox
import os.log

@MainActor
final class HotKeyRegistry {
    private let log = Logger(subsystem: "app.deskeyerest", category: "Hotkeys")
    private var registrations: [(EventHotKeyRef, () -> Void)] = []
    private var idCounter: UInt32 = 1
    private var eventHandler: EventHandlerRef?

    init() {
        installEventHandler()
    }

    deinit {
        // We intentionally leak Carbon handles on app shutdown — macOS reclaims
        // them. Doing it properly requires non-isolated ref handling.
    }

    /// Register a global hotkey. `chord` example: `("S", [.command, .option])`.
    func register(name: String,
                  keyCode: Int,
                  modifierFlags: NSEvent.ModifierFlags,
                  handler: @escaping () -> Void) {
        let id = idCounter
        idCounter += 1
        let hotKeyID = EventHotKeyID(signature: 0x44455252 /* 'DERR' */, id: id)
        var ref: EventHotKeyRef?
        let modifiers = carbonFlags(from: modifierFlags)
        let status = RegisterEventHotKey(
            UInt32(keyCode), modifiers, hotKeyID,
            GetApplicationEventTarget(), 0, &ref
        )
        if status == noErr, let ref {
            registrations.append((ref, handler))
            log.info("registered hotkey '\(name, privacy: .public)' id=\(id, privacy: .public)")
        } else {
            log.warning("hotkey '\(name, privacy: .public)' RegisterEventHotKey failed: \(status, privacy: .public)")
        }
    }

    private func carbonFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command)  { result |= UInt32(cmdKey) }
        if flags.contains(.option)   { result |= UInt32(optionKey) }
        if flags.contains(.shift)    { result |= UInt32(shiftKey) }
        if flags.contains(.control)  { result |= UInt32(controlKey) }
        return result
    }

    // MARK: - Carbon event handling

    private func installEventHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind:  OSType(kEventHotKeyPressed))
        let unmanaged = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, eventRef, userData) -> OSStatus in
                guard let userData, let eventRef else { return OSStatus(eventNotHandledErr) }
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr else { return status }
                let registry = Unmanaged<HotKeyRegistry>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    registry.dispatch(id: hotKeyID.id)
                }
                return noErr
            },
            1,
            &spec,
            unmanaged,
            &eventHandler
        )
    }

    private func dispatch(id: UInt32) {
        // registrations are appended in registration order; id maps to (idx + 1)
        let idx = Int(id) - 1
        guard registrations.indices.contains(idx) else { return }
        registrations[idx].1()
    }
}

// Common virtual key codes — Phase 1.5 defaults.
enum VirtualKey {
    static let s: Int = 0x01
    static let l: Int = 0x25
    static let r: Int = 0x0F
    static let p: Int = 0x23
    static let key1: Int = 0x12
    static let key5: Int = 0x17
    static let b: Int = 0x0B
}
