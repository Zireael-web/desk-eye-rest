//
//  GeneralPage.swift
//  DeskEyeRest
//
//  General settings page with 5 sub-tabs:
//    1. General        — Run at login, idle thresholds
//    2. Working Hours  — per-day on/off + time range (Configure modal — Phase 2)
//    3. Smart Breaks   — Meeting / Video / Focus Filters detection toggles
//    4. Keyboard Shortcuts — 7 hotkey rows (real binding via KeyboardShortcuts — Phase 1)
//    5. Menu Bar       — Icon style + timer format
//

import SwiftUI

private enum GeneralTab: String, CaseIterable, Hashable {
    case general, workingHours, smartBreaks, keyboardShortcuts, menuBar
}

struct GeneralPage: View {
    @Environment(AppState.self) private var appState
    @State private var subTab: GeneralTab = .general
    @State private var showWorkingHoursModal: Bool = false

    var body: some View {
        @Bindable var appState = appState

        SettingsPage(title: "General") {
            SettingsSubTabBar(
                selection: $subTab,
                labels: [
                    .general:           "General",
                    .workingHours:      "Working Hours",
                    .smartBreaks:       "Smart Breaks",
                    .keyboardShortcuts: "Keyboard Shortcuts",
                    .menuBar:           "Menu Bar",
                ]
            )

            switch subTab {
            case .general:           generalTab(appState: appState)
            case .workingHours:      workingHoursTab(appState: appState)
            case .smartBreaks:       smartBreaksTab(appState: appState)
            case .keyboardShortcuts: keyboardShortcutsTab()
            case .menuBar:           menuBarTab(appState: appState)
            }
        }
        .sheet(isPresented: $showWorkingHoursModal) {
            WorkingHoursSheet(onClose: { showWorkingHoursModal = false })
        }
    }

    // MARK: - 1. General

    @ViewBuilder
    private func generalTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ToggleRow("Run DeskEyeRest",
                          subtitle: "Launch when Mac starts.",
                          isOn: Binding(
                            get: { appState.settings.runAtLogin },
                            set: { newValue in
                                appState.settings.runAtLogin = newValue
                                appState.syncRunAtLogin()
                            }
                          ))
                SettingsDivider()
                ToggleRow("Start timer automatically on app launch",
                          subtitle: "Begin focus countdown immediately when DeskEyeRest opens.",
                          isOn: $appState.settings.startTimerAutomaticallyOnLaunch)
            }
        }

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle(
                    "Idle Time",
                    subtitle: "Set intervals for pausing and resetting a timer, triggered by inactivity on your Mac after a specified time."
                )
                LabeledMinuteRow("Pause timer after",
                                 value: $appState.settings.idlePauseAfterMinutes,
                                 range: 0...60)
                LabeledMinuteRow("Reset timer after",
                                 value: $appState.settings.idleResetAfterMinutes,
                                 range: 0...120)
            }
        }
    }

    // MARK: - 2. Working Hours

    @ViewBuilder
    private func workingHoursTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Working Hours")
                        .font(.uiSansBold(15))
                        .foregroundStyle(Color.textPrimary)
                    Text("Specify on which days and at what time you want to use the app. DeskEyeRest will only remind you during your configured working hours.")
                        .font(.uiSans(12))
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: $appState.settings.workingHoursEnabled)
                    .toggleStyle(.switch).labelsHidden().tint(Color.tealDeep)
            }
            HStack {
                Spacer()
                Button {
                    showWorkingHoursModal = true
                } label: {
                    Label("Configure", systemImage: "gearshape")
                        .font(.uiSans(13))
                }
                .buttonStyle(.bordered)
                .disabled(!appState.settings.workingHoursEnabled)
            }
        }
    }

    // MARK: - 3. Smart Breaks

    @ViewBuilder
    private func smartBreaksTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ToggleRow("Meeting Detection",
                          subtitle: "Automatically pauses when your camera or microphone is in use, so you won't be interrupted during important calls and meetings.",
                          isOn: $appState.settings.meetingDetectionEnabled)
                HStack {
                    Spacer()
                    Button {
                        // Phase 2 — Configure modal (per-device opt-in/out)
                    } label: {
                        Label("Configure", systemImage: "gearshape")
                            .font(.uiSans(13))
                    }
                    .buttonStyle(.bordered)
                    .disabled(!appState.settings.meetingDetectionEnabled)
                }
            }
        }

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ToggleRow("Video Detection",
                          subtitle: "Automatically pauses when you're watching videos (YouTube, VLC, Netflix, and more), allowing you to enjoy your content without interruption.",
                          isOn: $appState.settings.videoDetectionEnabled)
                HStack {
                    Spacer()
                    Button {
                        // Phase 2 — Configure modal
                    } label: {
                        Label("Configure", systemImage: "gearshape")
                            .font(.uiSans(13))
                    }
                    .buttonStyle(.bordered)
                    .disabled(!appState.settings.videoDetectionEnabled)
                }
            }
        }

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Focus Filters")
                            .font(.uiSansBold(15))
                            .foregroundStyle(Color.textPrimary)
                        Text("Configure which Focus modes should pause your breaks. For example, pause breaks during your \"Work\" mode but not during \"Personal\" time.")
                            .font(.uiSans(12))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button {
                        // Phase 2 — open Apple Focus settings
                    } label: {
                        Label("Learn More", systemImage: "arrow.up.right.square")
                            .font(.uiSans(13))
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - 4. Keyboard Shortcuts

    @ViewBuilder
    private func keyboardShortcutsTab() -> some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle(
                    "Customize Your Shortcuts",
                    subtitle: "Allow DeskEyeRest to respond to keyboard shortcuts from any application. All shortcuts must include the Command (⌘) key."
                )

                ShortcutRow(systemSymbol: "arrow.clockwise.circle",
                            title: "Restart DeskEyeRest",
                            subtitle: "Reset the current timer and start over.")
                ShortcutRow(systemSymbol: "plus.circle",
                            title: "Add One Minute",
                            subtitle: "Extend the current focus session by one minute.")
                ShortcutRow(systemSymbol: "plus.circle",
                            title: "Add Five Minutes",
                            subtitle: "Extend the current focus session by five minutes.")
                ShortcutRow(systemSymbol: "play.circle",
                            title: "Start Short Break",
                            subtitle: "Immediately begin a short break session.")
                ShortcutRow(systemSymbol: "play.circle",
                            title: "Start Long Break",
                            subtitle: "Immediately begin a long break session.")
                ShortcutRow(systemSymbol: "play.circle.fill",
                            title: "Start DeskEyeRest",
                            subtitle: "Start the DeskEyeRest timer and enable break reminders.")
                ShortcutRow(systemSymbol: "pause.circle.fill",
                            title: "Stop DeskEyeRest",
                            subtitle: "Pause the DeskEyeRest timer and disable break reminders.")
            }
        }
    }

    // MARK: - 5. Menu Bar

    @ViewBuilder
    private func menuBarTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle(
                    "Adjust Appearance",
                    subtitle: "Customize how DeskEyeRest appears in your menu bar for the perfect balance of information and discretion."
                )

                HStack {
                    Text("Choose what appears in your menu bar")
                        .font(.uiSans(14))
                    Spacer()
                    Picker("", selection: $appState.settings.menuBarStyle) {
                        Text("Icon & Time").tag(MenuBarStyle.iconAndTime)
                        Text("Time Only").tag(MenuBarStyle.timeOnly)
                        Text("Icon Only").tag(MenuBarStyle.iconOnly)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 280)
                }

                HStack {
                    Text("Timer Style")
                        .font(.uiSans(14))
                    Spacer()
                    Picker("", selection: $appState.settings.timerFormat) {
                        Text("26:46").tag(TimerFormat.hms)
                        Text("26m").tag(TimerFormat.compact)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 160)
                }
            }
        }
    }
}

// MARK: - Shortcut row (placeholder; Phase 1 wires KeyboardShortcuts.Recorder)

private struct ShortcutRow: View {
    let systemSymbol: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Image(systemName: systemSymbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.tealMid)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.uiSansBold(14))
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.uiSans(12))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                // Phase 1 — KeyboardShortcuts.Recorder
            } label: {
                Label("Set shortcut", systemImage: "plus")
                    .font(.uiSans(12))
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}
