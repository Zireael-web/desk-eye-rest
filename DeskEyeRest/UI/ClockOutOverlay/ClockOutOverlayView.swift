//
//  ClockOutOverlayView.swift
//  DeskEyeRest
//
//  Full-screen Clock Out overlay. Background uses our own "horizon at dusk"
//  geometric arcs. Header pill shows
//  current time + time remaining until the resume hour. Center logo + title +
//  description + bottom buttons (+5, +15, Skip → swipe-to-exit).
//

import SwiftUI

struct ClockOutOverlayView: View {
    @Environment(AppState.self) private var appState
    var onExit: () -> Void
    var onExtend5: () -> Void
    var onExtend15: () -> Void

    @State private var swipeProgress: CGFloat = 0
    @State private var swipeMode: Bool = false

    var body: some View {
        ZStack {
            // Gradient background — deep navy dark mode
            LinearGradient(
                colors: [Color.navyDeep, Color.inkDeep],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            // Horizon arcs — slow soft sweep above the centerline
            HorizonArcs()
                .stroke(Color.sand.opacity(0.07), lineWidth: 1)
                .ignoresSafeArea()

            // Top header pill: Current Time | Time Remaining
            VStack {
                headerPill
                    .padding(.top, 50)
                Spacer()
            }

            // Center column: icon + title + description
            VStack(spacing: Spacing.lg) {
                BrandIcon()
                    .frame(width: 130, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .padding(.bottom, Spacing.lg)

                Text(appState.settings.clockOutTitle)
                    .font(.displaySerif(96))
                    .foregroundStyle(Color.sand)
                    .multilineTextAlignment(.center)

                Text(appState.settings.clockOutDescription)
                    .font(.uiSans(18))
                    .foregroundStyle(Color.tealSoft.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 80)
            }

            // Bottom buttons
            VStack {
                Spacer()
                bottomControls
                    .padding(.bottom, 100)
            }

            // Corner labels
            VStack {
                HStack {
                    Text("CLOCK · OUT  ·  \(formatHM(appState.settings.clockOutStartHour, appState.settings.clockOutStartMinute)) → \(formatHM(appState.settings.clockOutEndHour, appState.settings.clockOutEndMinute))")
                        .font(.tabularMono(13))
                        .foregroundStyle(Color.tealSoft.opacity(0.5))
                    Spacer()
                    Text("DeskEyeRest")
                        .font(.tabularMono(13))
                        .foregroundStyle(Color.tealSoft.opacity(0.5))
                }
                .padding(.horizontal, 60)
                .padding(.top, 30)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header pill

    private var headerPill: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT TIME")
                    .font(.uiSans(10))
                    .foregroundStyle(Color.tealSoft.opacity(0.7))
                Text(currentTimeText)
                    .font(.tabularMono(18))
                    .foregroundStyle(Color.sand)
            }
            .frame(width: 120, alignment: .leading)
            .padding(.leading, Spacing.md)

            Rectangle()
                .fill(Color.tealSoft.opacity(0.4))
                .frame(width: 1, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text("REMAINING")
                    .font(.uiSans(10))
                    .foregroundStyle(Color.tealSoft.opacity(0.7))
                Text(remainingText)
                    .font(.tabularMono(18))
                    .foregroundStyle(Color.sand)
            }
            .frame(width: 120, alignment: .leading)
            .padding(.leading, Spacing.md)
        }
        .frame(width: 280, height: 64)
        .background(
            Capsule().fill(Color.inkDeep.opacity(0.6))
        )
    }

    // MARK: - Bottom controls (swipe-to-exit when Skip pressed)

    private var bottomControls: some View {
        Group {
            if swipeMode {
                swipeToExit
            } else {
                buttonsRow
            }
        }
    }

    private var buttonsRow: some View {
        HStack(spacing: Spacing.md) {
            ClockOutPill(label: "+5", action: onExtend5)
            ClockOutPill(label: "+15", action: onExtend15)
            ClockOutPill(label: "Skip", action: { withAnimation { swipeMode = true } })
        }
    }

    private var swipeToExit: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .stroke(Color.sand.opacity(0.5), lineWidth: 1)
            Capsule()
                .fill(Color.sand.opacity(0.15))
                .frame(width: max(50, swipeProgress))
            HStack {
                Circle()
                    .fill(Color.sand.opacity(0.85))
                    .frame(width: 36, height: 36)
                    .padding(.leading, 4)
                Spacer()
            }
            Text("Swipe to exit")
                .font(.uiSans(15))
                .foregroundStyle(Color.sand.opacity(0.85))
                .frame(maxWidth: .infinity)
        }
        .frame(width: 280, height: 44)
        .gesture(
            DragGesture()
                .onChanged { v in
                    swipeProgress = max(0, min(244, v.translation.width))
                }
                .onEnded { _ in
                    if swipeProgress > 200 {
                        onExit()
                    } else {
                        withAnimation { swipeProgress = 0 }
                    }
                }
        )
    }

    // MARK: - Time helpers

    private var currentTimeText: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }

    private var remainingText: String {
        let now = Date()
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = appState.settings.clockOutEndHour
        comps.minute = appState.settings.clockOutEndMinute
        guard var end = cal.date(from: comps) else { return "—" }
        if end <= now { end = cal.date(byAdding: .day, value: 1, to: end) ?? end }
        let diff = Int(end.timeIntervalSince(now))
        let h = diff / 3600
        let m = (diff % 3600) / 60
        return "\(h)h \(m)m"
    }

    private func formatHM(_ h: Int, _ m: Int) -> String {
        String(format: "%02d:%02d", h, m)
    }
}

// MARK: - Pill

private struct ClockOutPill: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.uiSans(17))
                .foregroundStyle(Color.sand.opacity(0.85))
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .overlay(Capsule().stroke(Color.sand.opacity(0.45), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Horizon arcs background

private struct HorizonArcs: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let baseY = rect.midY + 160
        for i in 0..<7 {
            let r = CGFloat(900 + i * 180)
            p.addArc(
                center: CGPoint(x: cx, y: baseY),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(360),
                clockwise: false
            )
            p.move(to: .zero)
        }
        return p
    }
}
