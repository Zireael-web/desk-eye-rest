//
//  FlashReminderPage.swift
//  DeskEyeRest
//
//  Settings → Flash Reminder. Two sub-tabs:
//    1. General — toggle, interval, duration
//    2. Style   — color swatches, style preset, message text
//

import SwiftUI

private enum FlashTab: String, CaseIterable, Hashable {
    case general, style
}

struct FlashReminderPage: View {
    @Environment(AppState.self) private var appState
    @State private var subTab: FlashTab = .general

    var body: some View {
        @Bindable var appState = appState

        SettingsPage(title: "Flash Reminder") {
            HStack(alignment: .top) {
                Spacer()
                Button {
                    appState.triggerFlashReminder()
                } label: {
                    Label("Play demo", systemImage: "play.fill")
                        .font(.uiSans(13))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandAccent)
            }
            .padding(.bottom, -Spacing.lg)

            SettingsSubTabBar(
                selection: $subTab,
                labels: [.general: "General", .style: "Style"]
            )

            switch subTab {
            case .general: generalTab(appState: appState)
            case .style:   styleTab(appState: appState)
            }
        }
    }

    @ViewBuilder
    private func generalTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            ToggleRow("Flash Reminder",
                      subtitle: "Gentle screen flashes that catch your attention without disrupting your flow. Tailor these gentle alerts to remind you to adjust your posture, sit up straight, or any other habit you want to reinforce.",
                      isOn: $appState.settings.flashReminderEnabled)
        }

        SettingsCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flash Interval")
                        .font(.uiSansBold(15))
                    Text("The time between two flash reminders")
                        .font(.uiSans(12))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Picker("", selection: $appState.settings.flashIntervalMinutes) {
                    ForEach([5, 10, 15, 20, 30, 45, 60], id: \.self) { m in
                        Text("\(m) min").tag(m)
                    }
                }
                .frame(width: 100)
                .labelsHidden()
            }
        }

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                SettingsSectionTitle(
                    "Flash Duration",
                    subtitle: "The duration in milliseconds that the flash reminder is presented on screen."
                )

                VStack(spacing: 4) {
                    Text("\(appState.settings.flashDurationMs)")
                        .font(.tabularMono(64))
                        .foregroundStyle(Color.brandAccent)
                    Text("milliseconds")
                        .font(.uiSans(12))
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Slider(
                    value: Binding(
                        get: { Double(appState.settings.flashDurationMs) },
                        set: { appState.settings.flashDurationMs = Int($0) }
                    ),
                    in: 400...900,
                    step: 50
                )
                .tint(Color.tealDeep)

                HStack {
                    ForEach([400, 500, 600, 700, 800, 900], id: \.self) { tick in
                        Text("\(tick)")
                            .font(.tabularMono(10))
                            .foregroundStyle(Color.textSecondary)
                        if tick != 900 { Spacer() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func styleTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle(
                    "Flash Color",
                    subtitle: "Choose the color that will grab your attention."
                )

                let palette: [String] = [
                    "#A0524D", "#8E5A37", "#A39046", "#5E8556", "#3F6B83",
                    "#7A4F8E", "#7E3F4F", "#7A7A7A", "#1F1F1F", "#FFFFFF",
                ]

                HStack(spacing: 10) {
                    ForEach(palette, id: \.self) { hex in
                        let isSelected = hex.uppercased() == appState.settings.flashColorHex.uppercased()
                        Button {
                            appState.settings.flashColorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? Color.brandAccent : Color.tealSoft.opacity(0.5),
                                                lineWidth: isSelected ? 2 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle(
                    "Choose Your Flash Style",
                    subtitle: "Select from our curated flash reminder styles to match your preference."
                )
                HStack(spacing: Spacing.md) {
                    FlashStyleCard(title: "Default", isSelected: true, color: Color.tealDeep)
                    FlashStyleCard(title: "Photo Flash", isSelected: false,
                                   color: Color.tealMid.opacity(0.6))
                }
            }
        }

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle(
                    "Message Configuration",
                    subtitle: "Customize the text that appears during your flash reminder."
                )
                TextField("Watch your posture", text: $appState.settings.flashMessage)
                    .textFieldStyle(.roundedBorder)
                    .font(.uiSans(15))
            }
        }
    }
}

// MARK: - Helpers

private struct FlashStyleCard: View {
    let title: String
    let isSelected: Bool
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(color)
                    .aspectRatio(16/9, contentMode: .fit)
                Text("Your text")
                    .font(.uiSans(13))
                    .foregroundStyle(Color.sand.opacity(0.9))
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.brandAccent)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .stroke(isSelected ? Color.brandAccent : Color.tealSoft.opacity(0.4),
                            lineWidth: isSelected ? 2 : 1)
            )
            Text(title)
                .font(.uiSansBold(13))
                .foregroundStyle(isSelected ? Color.brandAccent : Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Color from hex

extension Color {
    init(hex: String) {
        var h = hex
        if h.hasPrefix("#") { h.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xff) / 255
        let g = Double((rgb >> 8)  & 0xff) / 255
        let b = Double( rgb        & 0xff) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
