//
//  FocusModePage.swift
//  DeskEyeRest
//
//  Settings → Focus mode. Single-tab page with the focus duration slider.
//

import SwiftUI

struct FocusModePage: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        SettingsPage(title: "Focus Mode") {
            SettingsCard {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    SettingsSectionTitle(
                        "Focus Duration",
                        subtitle: "Set your ideal focus duration, and dive deep into your tasks. When time's up, the app seamlessly transitions you into a well-deserved break."
                    )

                    VStack(spacing: 8) {
                        Text("\(appState.settings.focusDurationMinutes)")
                            .font(.tabularMono(96))
                            .foregroundStyle(Color.brandAccent)
                        Text("minutes")
                            .font(.uiSans(13))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)

                    Slider(
                        value: Binding(
                            get: { Double(appState.settings.focusDurationMinutes) },
                            set: { appState.settings.focusDurationMinutes = Int($0) }
                        ),
                        in: 10...90,
                        step: 5
                    )
                    .tint(Color.tealDeep)

                    HStack {
                        ForEach([10, 15, 20, 30, 45, 60, 90], id: \.self) { tick in
                            Text("\(tick)")
                                .font(.tabularMono(11))
                                .foregroundStyle(Color.textSecondary)
                            if tick != 90 { Spacer() }
                        }
                    }
                }
            }
        }
    }
}
