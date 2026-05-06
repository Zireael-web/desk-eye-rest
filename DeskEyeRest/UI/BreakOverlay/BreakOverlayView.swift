//
//  BreakOverlayView.swift
//  DeskEyeRest
//
//  Full-screen content rendered inside `BreakOverlayWindow`. A code-rendered
//  dusty-teal gradient and calibration arcs keep the timer, hero text, and
//  commitment-aware bottom button legible without an external image asset.
//

import SwiftUI

struct BreakOverlayView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            // Tiny calibration labels in corners. Cream + soft shadow keep them
            // legible against the dark gradient.
            VStack {
                HStack {
                    Text(cornerLeftLabel)
                        .font(.tabularMono(13))
                        .foregroundStyle(Color.sand.opacity(0.70))
                        .shadow(color: .black.opacity(0.55), radius: 3, x: 0, y: 1)
                    Spacer()
                    Text(cornerRightLabel)
                        .font(.tabularMono(13))
                        .foregroundStyle(Color.sand.opacity(0.70))
                        .shadow(color: .black.opacity(0.55), radius: 3, x: 0, y: 1)
                }
                .padding(.horizontal, 60)
                .padding(.top, 30)
                Spacer()
            }

            // Centerpiece — wrapped in a GeometryReader-free full-width VStack
            // and each row uses `.frame(maxWidth: .infinity)` so glyphs center
            // against the SCREEN axis. Drops the previous `.padding(.horizontal, 80)
            // + .frame(.infinity)` combo: with every Text already full-width,
            // the outer .padding was creating an asymmetric measurement pass
            // on certain display configurations and nudging the visual center
            // off-axis.
            VStack(spacing: Spacing.lg) {
                Text(timerText)
                    .font(.tabularMono(240))
                    .foregroundStyle(Color.sand)
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 2)

                Text(heroTitle)
                    .font(.displaySerif(84))
                    .foregroundStyle(Color.sand.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 2)
                    .padding(.top, Spacing.md)

                if let subline = heroSubline {
                    Text(subline)
                        .font(.displaySerifItalic(38))
                        .foregroundStyle(Color.tealSoft.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .shadow(color: .black.opacity(0.35), radius: 5, x: 0, y: 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Bottom button area (commitment-aware) — force the VStack
            // full-width with center alignment so the intrinsic-sized pill
            // button sits at the geometric center of the screen instead of
            // wherever the shrunk VStack happens to land in the ZStack.
            VStack {
                Spacer()
                bottomButtons
                    .padding(.bottom, 90)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Keep the background separate from the foreground layout so it does
        // not influence the measurement pass for the centered content.
        .background {
            backgroundLayer
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    /// A self-contained gradient treatment with subtle calibration arcs.
    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color.inkDeep, Color.navyDeep],
                startPoint: .top, endPoint: .bottom
            )

            CalibrationArcs()
                .stroke(Color.sand.opacity(0.06), lineWidth: 1)
                .padding(.top, 40)
        }
    }

    // MARK: - Computed display values

    private var timerText: String {
        if case .breaking(let remaining, _, _, _) = appState.session {
            return formatTimer(seconds: Int(remaining))
        }
        return "00:00"
    }

    private var heroTitle: String {
        if case .breaking(_, _, _, let exerciseName) = appState.session,
           let name = exerciseName {
            return name
        }
        return "Rest your eyes"
    }

    private var heroSubline: String? {
        if case .breaking(_, let kind, _, _) = appState.session {
            // Use the assigned exercise's detail (truncated) as subline.
            // ── Trim whitespace: if the source `detail` has a leading space
            // (very common — exercises were authored as "Reminder to flex…"
            // with stray whitespace from old data), the un-trimmed first
            // sentence visibly shifts the rendered text to the right of the
            // screen axis because SwiftUI centers the GLYPH bounding box,
            // and the leading space widens that box on the right side only.
            let ex = appState.exerciseStore.exercises.first { $0.assignedTo == kind }
            return ex?.detail
                .split(separator: ".")
                .first
                .map(String.init)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Refresh your mind"
    }

    private var cornerLeftLabel: String {
        if case .breaking(let remaining, let kind, _, _) = appState.session {
            return "\(kind == .short ? "SHORT" : "LONG")  ·  BREAK  ·  \(Int(remaining))s"
        }
        return "BREAK"
    }

    private var cornerRightLabel: String {
        "DeskEyeRest"
    }

    // MARK: - Bottom buttons (commitment-aware)

    @ViewBuilder
    private var bottomButtons: some View {
        switch appState.settings.breakCommitment {
        case .flexible:
            OverlayPillButton(label: "Skip") { appState.skipCurrentBreak() }
        case .mindful:
            HStack(spacing: Spacing.md) {
                OverlayPillButton(label: "Delay 5 min") { appState.skipCurrentBreak() }
            }
        case .committed:
            EmptyView()
        }
    }
}

// MARK: - Bits

private struct OverlayPillButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.uiSans(17))
                .foregroundStyle(Color.sand.opacity(0.85))
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .overlay(
                    Capsule().stroke(Color.sand.opacity(0.45), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.escape, modifiers: [])
    }
}

/// Concentric soft arcs above the centerpiece — matches the brand calibration motif.
private struct CalibrationArcs: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY - 80
        for i in 0..<8 {
            let r = CGFloat(220 + i * 80)
            p.addArc(
                center: CGPoint(x: cx, y: cy),
                radius: r,
                startAngle: .degrees(-160),
                endAngle: .degrees(-20),
                clockwise: false
            )
            p.move(to: .zero)
        }
        return p
    }
}
