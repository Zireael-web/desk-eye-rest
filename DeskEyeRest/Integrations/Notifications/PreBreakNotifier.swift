//
//  PreBreakNotifier.swift
//  DeskEyeRest
//
//  Watches AppState for the `.preBreakAlert` transition and posts a system
//  notification (`Display pre-break notification` setting) and/or a cursor
//  reminder panel (`Show cursor break reminder` setting — Phase 1.5 stub).
//

import AppKit
import UserNotifications
import Observation
import os.log

@MainActor
final class PreBreakNotifier: NSObject {
    private let appState: AppState
    private let log = Logger(subsystem: "app.deskeyerest", category: "PreBreakNotifier")
    private var lastSeenAlertKind: BreakKind?
    private var didRequestAuthorization = false

    init(appState: AppState) {
        self.appState = appState
        super.init()
        UNUserNotificationCenter.current().delegate = self
        observe()
    }

    func requestAuthorizationIfNeeded() {
        guard !didRequestAuthorization else { return }
        didRequestAuthorization = true
        let log = self.log
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { ok, err in
            if let err {
                log.warning("notification auth error: \(err.localizedDescription, privacy: .private)")
            } else if !ok {
                log.info("notification authorization denied")
            }
        }
    }

    // MARK: - State observation

    private func observe() {
        withObservationTracking {
            _ = appState.session
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.handle(state: self.appState.session)
                self.observe()
            }
        }
    }

    private func handle(state: SessionState) {
        switch state {
        case .preBreakAlert(let kind, _):
            // Fire on each new entry into preBreakAlert.
            if lastSeenAlertKind != kind {
                lastSeenAlertKind = kind
                postSystemNotification(kind: kind)
            }
        default:
            lastSeenAlertKind = nil
        }
    }

    // MARK: - System notifications

    private func postSystemNotification(kind: BreakKind) {
        guard appState.settings.displayPreBreakNotification else { return }
        requestAuthorizationIfNeeded()

        let content = UNMutableNotificationContent()
        content.title = kind == .short ? "Short break coming up" : "Long break coming up"
        content.body = "Take \(Int(appState.settings.preBreakReminderLeadSeconds)) seconds, then step away."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "preBreakAlert-\(kind == .short ? "short" : "long")-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil  // immediate
        )
        let log = self.log
        UNUserNotificationCenter.current().add(request) { err in
            if let err {
                log.warning("notification post error: \(err.localizedDescription, privacy: .private)")
            }
        }
        log.info("pre-break notification posted: \(kind == .short ? "short" : "long", privacy: .public)")
    }
}

// MARK: - Show banners while we're foreground (default would suppress)

extension PreBreakNotifier: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
