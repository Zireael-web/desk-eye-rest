//
//  DeskEyeRestApp.swift
//  DeskEyeRest
//
//  Entry point. We don't use SwiftUI's built-in `App` lifecycle for the menu-bar
//  controller because we need fine-grained NSStatusItem behaviour. Instead the
//  AppDelegate owns the status item and we open Settings via a SwiftUI Window.
//

import SwiftUI
import AppKit

@main
struct DeskEyeRestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The Settings window is owned by `SettingsWindowController` (AppKit).
        // We need *some* SwiftUI Scene to satisfy the App protocol — use a
        // singular `Window` (not `WindowGroup` or `Settings`) since it does NOT
        // auto-open at launch. We never call `openWindow(id:)` on it, so it
        // remains hidden for the entire app lifetime.
        Window("__hidden", id: "__hidden") {
            EmptyView()
                .frame(width: 0, height: 0)
        }
        .commandsRemoved()
        .windowResizability(.contentSize)
    }
}
