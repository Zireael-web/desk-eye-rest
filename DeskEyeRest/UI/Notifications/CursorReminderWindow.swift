//
//  CursorReminderWindow.swift
//  DeskEyeRest
//
//  Small NSPanel that floats next to the user's cursor during the
//  `preBreakAlert` countdown. Non-invasive, semi-transparent, dismisses on
//  click or when the alert window closes.
//

import AppKit
import SwiftUI

@MainActor
final class CursorReminderWindow: NSPanel {
    init(content: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.level = .popUpMenu
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.ignoresMouseEvents = true  // never steals focus

        let host = NSHostingView(rootView: content)
        host.translatesAutoresizingMaskIntoConstraints = false
        self.contentView = host
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

struct CursorReminderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let s = appState.session
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .stroke(Color.tealSoft.opacity(0.35), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: progress(state: s))
                    .stroke(Color.coral, lineWidth: 2)
                    .rotationEffect(.degrees(-90))
                Text(text(state: s))
                    .font(.tabularMono(11))
                    .foregroundStyle(Color.sand)
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("Break in")
                    .font(.uiSans(10))
                    .foregroundStyle(Color.tealSoft)
                Text(textSubtitle(state: s))
                    .font(.uiSansBold(13))
                    .foregroundStyle(Color.sand)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.inkDeep.opacity(0.85))
        )
        .padding(4)
    }

    private func text(state: SessionState) -> String {
        if case .preBreakAlert(_, let secs) = state {
            return "\(Int(secs))"
        }
        return "—"
    }
    private func textSubtitle(state: SessionState) -> String {
        if case .preBreakAlert(let kind, let secs) = state {
            return "\(kind == .short ? "Short" : "Long") · \(Int(secs))s"
        }
        return ""
    }
    private func progress(state: SessionState) -> CGFloat {
        if case .preBreakAlert(_, let secs) = state {
            let lead = max(1.0, Double(appState.settings.preBreakReminderLeadSeconds))
            return CGFloat(1.0 - secs / lead)
        }
        return 0
    }
}
