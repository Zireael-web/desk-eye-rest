//
//  FlashOverlayView.swift
//  DeskEyeRest
//
//  Brief screen-flash with a centered message. Renders on top of the user's
//  workspace at low opacity for `flashDurationMs`, then fades out.
//

import SwiftUI

struct FlashOverlayView: View {
    @Environment(AppState.self) private var appState
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            if let event = appState.flashEvent {
                Color(hex: event.colorHex)
                    .opacity(0.72)
                    .ignoresSafeArea()
                    .transition(.opacity)
                VStack(spacing: Spacing.sm) {
                    BrandIcon()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text(event.message)
                        .font(.displaySerif(36))
                        .foregroundStyle(Color.inkDeep)
                    Text("Sit up. Breathe. Soften your shoulders.")
                        .font(.uiSans(14))
                        .foregroundStyle(Color.inkDeep.opacity(0.75))
                }
                .padding(Spacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .fill(Color.sand)
                )
            }
        }
        .opacity(opacity)
        // CRITICAL: trigger the fade-in BOTH on initial appearance AND on
        // subsequent flashEvent changes. `.onChange` does NOT fire for the
        // initial value, and by the time this view is first hosted by
        // FlashOverlayManager, `appState.flashEvent` is ALREADY non-nil
        // (the manager creates panels in response to that very event). So
        // without `.onAppear`, opacity stays at 0 forever and the user
        // never sees the flash — only an invisible empty overlay.
        .onAppear { startFlashAnimationIfNeeded() }
        .onChange(of: appState.flashEvent) { _, newValue in
            if newValue != nil {
                startFlashAnimationIfNeeded()
            } else {
                withAnimation(.easeOut(duration: 0.20)) { opacity = 0 }
            }
        }
    }

    private func startFlashAnimationIfNeeded() {
        guard let event = appState.flashEvent else { return }
        withAnimation(.easeIn(duration: 0.18)) { opacity = 1 }
        let fadeStart = Double(event.durationMs) / 1000.0 - 0.20
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, fadeStart)) {
            withAnimation(.easeOut(duration: 0.20)) { opacity = 0 }
        }
    }
}
