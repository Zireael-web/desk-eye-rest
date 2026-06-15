//
//  BreaksPage.swift
//  DeskEyeRest
//
//  Settings → Breaks. Six sub-tabs:
//    1. Short Break       — duration slider + assigned exercises
//    2. Long Break        — toggle + minutes/seconds + cadence + assigned exercises
//    3. Break Management  — Commitment mode (Flexible/Mindful/Committed) + Screen Lock
//    4. Notifications     — pre-break notif + cursor reminder + lead/stay seconds
//    5. Style             — DeskEyeRest preset + Personal image
//    6. Sound Effects     — start/end sound + volume + preview
//

import SwiftUI

private enum BreaksTab: String, CaseIterable, Hashable {
    case shortBreak, longBreak, management, notifications, style, soundEffects
}

struct BreaksPage: View {
    @Environment(AppState.self) private var appState
    @State private var subTab: BreaksTab = .shortBreak

    var body: some View {
        @Bindable var appState = appState

        SettingsPage(title: "Breaks") {
            SettingsSubTabBar(
                selection: $subTab,
                labels: [
                    .shortBreak:    "Short Break",
                    .longBreak:     "Long Break",
                    .management:    "Break Management",
                    .notifications: "Notifications",
                    .style:         "Style",
                    .soundEffects:  "Sound Effects",
                ]
            )

            switch subTab {
            case .shortBreak:    shortBreakTab(appState: appState)
            case .longBreak:     longBreakTab(appState: appState)
            case .management:    managementTab(appState: appState)
            case .notifications: notificationsTab(appState: appState)
            case .style:         styleTab(appState: appState)
            case .soundEffects:  soundEffectsTab(appState: appState)
            }
        }
    }

    // MARK: - 1. Short Break

    @ViewBuilder
    private func shortBreakTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                SettingsSectionTitle(
                    "Break Duration",
                    subtitle: "Set the length of your short breaks. Use these moments to momentarily shift your focus away from your display."
                )

                VStack(spacing: 8) {
                    Text(formatSeconds(appState.settings.shortBreakDurationSeconds))
                        .font(.tabularMono(96))
                        .foregroundStyle(Color.brandAccent)
                    Text("seconds")
                        .font(.uiSans(13))
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)

                Slider(
                    value: Binding(
                        get: { Double(appState.settings.shortBreakDurationSeconds) },
                        set: { appState.settings.shortBreakDurationSeconds = Int($0) }
                    ),
                    in: 10...180,
                    step: 5
                )
                .tint(Color.tealDeep)

                HStack {
                    ForEach([10, 15, 20, 30, 45, 60, 120, 180], id: \.self) { tick in
                        Text("\(tick)")
                            .font(.tabularMono(11))
                            .foregroundStyle(Color.textSecondary)
                        if tick != 180 { Spacer() }
                    }
                }
            }
        }

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle(
                    "Assigned Exercises",
                    subtitle: "These exercises will be prompted during your short breaks."
                )
                ExerciseChip(index: 1, name: "Eye break", subtitle: "Short Break Exercise")
                HStack {
                    Spacer()
                    Text("Manage Exercises  →")
                        .font(.uiSans(12))
                        .foregroundStyle(Color.brandAccent)
                }
            }
        }
    }

    // MARK: - 2. Long Break

    @ViewBuilder
    private func longBreakTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ToggleRow("Long breaks",
                          subtitle: "Long breaks offer a chance to fully disconnect from your screen, stretch, and refresh. Use this time to reset your mind and body for improved focus and productivity.",
                          isOn: $appState.settings.longBreaksEnabled)

                if appState.settings.longBreaksEnabled {
                    SettingsDivider()

                    HStack(spacing: Spacing.lg) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Minutes").font(.uiSans(12)).foregroundStyle(Color.textSecondary)
                            TextField("", value: Binding(
                                get: { appState.settings.longBreakDurationSeconds / 60 },
                                set: { appState.settings.longBreakDurationSeconds = $0 * 60 + appState.settings.longBreakDurationSeconds % 60 }
                            ), format: .number)
                                .frame(width: 80)
                                .multilineTextAlignment(.center)
                                .font(.tabularMono(15))
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Seconds").font(.uiSans(12)).foregroundStyle(Color.textSecondary)
                            TextField("", value: Binding(
                                get: { appState.settings.longBreakDurationSeconds % 60 },
                                set: { appState.settings.longBreakDurationSeconds = (appState.settings.longBreakDurationSeconds / 60) * 60 + $0 }
                            ), format: .number)
                                .frame(width: 80)
                                .multilineTextAlignment(.center)
                                .font(.tabularMono(15))
                                .textFieldStyle(.roundedBorder)
                        }
                        Spacer()
                    }

                    SettingsDivider()

                    HStack {
                        Text("After how many short breaks should there be a long break?")
                            .font(.uiSans(13))
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Stepper(value: $appState.settings.longBreakAfterShortCount, in: 1...10) {
                            Text("\(appState.settings.longBreakAfterShortCount) breaks")
                                .font(.tabularMono(13))
                        }
                    }
                }
            }
        }

        if appState.settings.longBreaksEnabled {
            SettingsCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    SettingsSectionTitle(
                        "Assigned Exercises",
                        subtitle: "These exercises will be prompted during your long breaks."
                    )
                    ExerciseChip(index: 1, name: "Stretch", subtitle: "Long Break Exercise")
                    HStack {
                        Spacer()
                        Text("Manage Exercises  →")
                            .font(.uiSans(12))
                            .foregroundStyle(Color.brandAccent)
                    }
                }
            }
        }
    }

    // MARK: - 3. Break Management

    @ViewBuilder
    private func managementTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle(
                    "Break Commitment",
                    subtitle: "Choose how strict you want to be with breaks. Flexible lets you skip when needed. Mindful lets you delay by a few minutes. Committed means no exceptions."
                )

                HStack(spacing: Spacing.md) {
                    CommitmentCard(
                        title: "Flexible",
                        subtitle: "Skip when needed",
                        systemImage: "arrow.triangle.2.circlepath",
                        isSelected: appState.settings.breakCommitment == .flexible
                    ) { appState.settings.breakCommitment = .flexible }
                    CommitmentCard(
                        title: "Mindful",
                        subtitle: "Delay by 1 or 5 min",
                        systemImage: "leaf",
                        isSelected: appState.settings.breakCommitment == .mindful
                    ) { appState.settings.breakCommitment = .mindful }
                    CommitmentCard(
                        title: "Committed",
                        subtitle: "No exceptions",
                        systemImage: "lock",
                        isSelected: appState.settings.breakCommitment == .committed
                    ) { appState.settings.breakCommitment = .committed }
                }
            }
        }

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle("Screen Lock")
                ToggleRow("Lock screen for short breaks",
                          isOn: $appState.settings.lockScreenOnShortBreak)
                SettingsDivider()
                ToggleRow("Lock screen for long breaks",
                          isOn: $appState.settings.lockScreenOnLongBreak)
            }
        }
    }

    // MARK: - 4. Notifications

    @ViewBuilder
    private func notificationsTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle("Break Reminder")
                ToggleRow("Display pre-break notification",
                          isOn: $appState.settings.displayPreBreakNotification)
                ToggleRow("Show cursor break reminder",
                          isOn: $appState.settings.showCursorBreakReminder)

                SettingsDivider()

                HStack {
                    Text("Show reminder")
                        .font(.uiSans(14))
                    Spacer()
                    TextField("", value: $appState.settings.preBreakReminderLeadSeconds, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .font(.tabularMono(14))
                        .textFieldStyle(.roundedBorder)
                    Text("sec  before the break starts")
                        .font(.uiSans(13))
                        .foregroundStyle(Color.textSecondary)
                }

                HStack {
                    Text("Reminder stays on screen for")
                        .font(.uiSans(14))
                    Spacer()
                    TextField("", value: $appState.settings.preBreakReminderStaysSeconds, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .font(.tabularMono(14))
                        .textFieldStyle(.roundedBorder)
                    Text("sec")
                        .font(.uiSans(13))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }

        SettingsCard {
            ToggleRow("Break Detection",
                      subtitle: "Alert me when I return so I can log the break I just took.",
                      isOn: $appState.settings.alertOnBreakReturn)
        }
    }

    // MARK: - 5. Style

    @ViewBuilder
    private func styleTab(appState: AppState) -> some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle(
                    "Choose Your Style",
                    subtitle: "Select from our collection or create your own personalized background."
                )

                HStack(spacing: Spacing.md) {
                    StylePresetCard(
                        title: "DeskEyeRest",
                        subtitle: "Clean & focused",
                        previewBackground: Color.tealDeep,
                        isSelected: true
                    )
                    StylePresetCard(
                        title: "Personal",
                        subtitle: "Your custom image",
                        previewBackground: Color.tealSoft.opacity(0.3),
                        isSelected: false,
                        showsDropZone: true
                    )
                }
            }
        }
    }

    // MARK: - 6. Sound Effects

    @ViewBuilder
    private func soundEffectsTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    SettingsSectionTitle("Sound Effects")
                    Spacer()
                    Button {
                        appState.soundPlayer.playStartChime(volume: appState.settings.soundVolume)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            appState.soundPlayer.playEndChime(volume: appState.settings.soundVolume)
                        }
                    } label: {
                        Label("Preview", systemImage: "play")
                            .font(.uiSans(13))
                    }
                    .buttonStyle(.bordered)
                }

                ToggleRow("Play a short sound when the pause starts",
                          isOn: $appState.settings.soundOnBreakStart)
                ToggleRow("Play a short sound when the pause ends",
                          isOn: $appState.settings.soundOnBreakEnd)

                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(Color.textSecondary)
                    Slider(value: $appState.settings.soundVolume, in: 0...1)
                        .tint(Color.tealDeep)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, Spacing.sm)
            }
        }
    }
}

// MARK: - Helpers

private func formatSeconds(_ s: Int) -> String { "\(s)" }

private struct ExerciseChip: View {
    let index: Int
    let name: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle().fill(Color.tealDeep).frame(width: 26, height: 26)
                Text("\(index)")
                    .font(.uiSansBold(11))
                    .foregroundStyle(Color.sand)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.uiSansBold(14))
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.uiSans(11))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
    }
}

private struct CommitmentCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(isSelected ? Color.brandAccent : Color.textSecondary)
                    Text(title)
                        .font(.uiSansBold(14))
                        .foregroundStyle(Color.textPrimary)
                }
                Text(subtitle)
                    .font(.uiSans(12))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .stroke(isSelected ? Color.brandAccent : Color.tealSoft.opacity(0.4),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct StylePresetCard: View {
    let title: String
    let subtitle: String
    let previewBackground: Color
    let isSelected: Bool
    var showsDropZone: Bool = false

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(previewBackground)
                    .aspectRatio(16/9, contentMode: .fit)
                if showsDropZone {
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.tealMid)
                        Text("Drop image here")
                            .font(.uiSans(11))
                            .foregroundStyle(Color.textSecondary)
                        Text("or click to browse")
                            .font(.uiSans(10))
                            .foregroundStyle(Color.textTertiary)
                    }
                } else {
                    // DeskEyeRest preview: timer + Skip pill silhouette
                    VStack(spacing: 8) {
                        Text("00:21")
                            .font(.tabularMono(32))
                            .foregroundStyle(Color.sand)
                        Text("Rest your eyes")
                            .font(.displaySerif(14))
                            .foregroundStyle(Color.sand.opacity(0.85))
                        Capsule()
                            .strokeBorder(Color.sand.opacity(0.6), lineWidth: 1)
                            .frame(width: 50, height: 18)
                    }
                }
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
                            style: StrokeStyle(lineWidth: isSelected ? 2 : 1,
                                               dash: showsDropZone ? [4, 4] : []))
            )
            VStack(spacing: 2) {
                Text(title)
                    .font(.uiSansBold(13))
                    .foregroundStyle(isSelected ? Color.brandAccent : Color.textPrimary)
                Text(subtitle)
                    .font(.uiSans(11))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
