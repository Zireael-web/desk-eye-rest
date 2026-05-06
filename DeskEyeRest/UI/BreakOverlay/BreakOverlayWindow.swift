//
//  BreakOverlayWindow.swift
//  DeskEyeRest
//
//  An NSPanel subclass configured for a full-screen, top-most, all-spaces,
//  no-chrome break overlay window. One instance per `NSScreen`.
//

import AppKit
import SwiftUI

@MainActor
final class BreakOverlayWindow: NSPanel {
    init(screen: NSScreen, content: some View) {
        let sf = screen.frame
        super.init(
            contentRect: sf,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Above almost everything but below screen-saver / dock chrome.
        self.level = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) - 1
        )

        // Span every Space, every fullscreen window, can't be Cmd-Tab'd to.
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle,
        ]

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false

        // Ignore mouse outside our hosted view (clicks pass through to the
        // overlay content but not to the desktop). We don't want users to
        // click through the overlay accidentally.
        self.ignoresMouseEvents = false

        // Host the SwiftUI content via NSHostingController, but DO NOT enable
        // `sizingOptions = [.preferredContentSize]` — that option makes the
        // hosting controller continually resize the window/view to SwiftUI's
        // intrinsic (preferred) size, and our root view uses
        // `frame(maxWidth: .infinity, maxHeight: .infinity)` which reports a
        // zero / minimal intrinsic size, causing the entire overlay panel to
        // collapse to a tiny rect after ordering-front. Leave sizingOptions
        // empty and let the explicit frame + autoresizingMask drive size.
        let controller = NSHostingController(rootView: content)
        controller.sizingOptions = []
        // macOS 26 hardened its system safe-area enforcement — even an
        // `.ignoresSafeArea()` SwiftUI modifier is not enough on a borderless
        // NSPanel; AppKit still reports the menu-bar height as a safe-area
        // inset, and the host's content frame stops short of the top edge
        // (showing a grey strip where the panel's clear/grey background
        // bleeds through). Setting `safeAreaRegions = []` on the hosting
        // controller tells AppKit not to report ANY safe-area insets into
        // the SwiftUI environment for this view tree.
        if #available(macOS 14.0, *) {
            controller.safeAreaRegions = []
        }
        self.contentViewController = controller

        controller.view.frame = NSRect(origin: .zero, size: sf.size)
        controller.view.autoresizingMask = [.width, .height]

        // Force the panel itself to the full screen-frame.
        self.setFrame(sf, display: true)
        self.setContentSize(sf.size)
    }

    /// Re-apply the full-screen frame. Manager calls this AFTER
    /// `orderFrontRegardless()` so any frame reset macOS performs during
    /// ordering is corrected.
    func enforceFullScreen(on screen: NSScreen) {
        let sf = screen.frame
        self.setFrame(sf, display: true)
        self.setContentSize(sf.size)
        if let cv = self.contentView {
            cv.frame = NSRect(origin: .zero, size: sf.size)
            cv.autoresizingMask = [.width, .height]
        }
    }

    // Allow the panel to become key so SwiftUI gestures (button clicks) work.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
