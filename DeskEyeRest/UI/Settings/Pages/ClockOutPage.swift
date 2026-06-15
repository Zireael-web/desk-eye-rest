//
//  ClockOutPage.swift
//  DeskEyeRest
//
//  Settings → Clock Out. Three sub-tabs (only General visible until toggle ON):
//    1. General       — toggle, time range, title, description
//    2. Notifications — end-of-day reminder
//    3. Notes         — free-form text saved between sessions
//

import SwiftUI

private enum ClockOutTab: String, CaseIterable, Hashable {
    case general, notifications, notes
}

struct ClockOutPage: View {
    @Environment(AppState.self) private var appState
    @State private var subTab: ClockOutTab = .general

    var body: some View {
        @Bindable var appState = appState

        SettingsPage(title: "Clock Out") {
            HStack(alignment: .top) {
                Spacer()
                Button {
                    // Phase 4 — actually trigger Clock Out demo
                } label: {
                    Label("Play demo", systemImage: "play.fill")
                        .font(.uiSans(13))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandAccent)
                .disabled(!appState.settings.clockOutEnabled)
            }
            .padding(.bottom, -Spacing.lg)

            SettingsSubTabBar(
                selection: $subTab,
                labels: [
                    .general:       "General",
                    .notifications: "Notifications",
                    .notes:         "Notes",
                ]
            )

            switch subTab {
            case .general:       generalTab(appState: appState)
            case .notifications: notificationsTab(appState: appState)
            case .notes:         notesTab(appState: appState)
            }
        }
    }

    @ViewBuilder
    private func generalTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            ToggleRow("Clock Out",
                      subtitle: "Create healthy boundaries between work and personal time with automated screen reminders that encourage you to step away from your laptop.",
                      isOn: $appState.settings.clockOutEnabled)
        }

        if appState.settings.clockOutEnabled {
            SettingsCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    SettingsSectionTitle(
                        "Clock Out Duration",
                        subtitle: "Define when you want to stop and resume your laptop work."
                    )
                    HStack(spacing: Spacing.lg) {
                        TimeField(label: "Start",
                                  hour: $appState.settings.clockOutStartHour,
                                  minute: $appState.settings.clockOutStartMinute)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(Color.textSecondary)
                        TimeField(label: "End",
                                  hour: $appState.settings.clockOutEndHour,
                                  minute: $appState.settings.clockOutEndMinute)
                        Spacer()
                    }
                }
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.uiSansBold(15))
                        Text("The main message displayed during your clock out session.")
                            .font(.uiSans(12))
                            .foregroundStyle(Color.textSecondary)
                    }
                    TextField("Time to Switch Off", text: $appState.settings.clockOutTitle)
                        .textFieldStyle(.roundedBorder)
                        .font(.uiSans(15))
                }
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.uiSansBold(15))
                        Text("A supportive message to help you disconnect and recharge.")
                            .font(.uiSans(12))
                            .foregroundStyle(Color.textSecondary)
                    }
                    TextEditor(text: $appState.settings.clockOutDescription)
                        .font(.uiSans(13))
                        .frame(minHeight: 80)
                        .padding(4)
                        .background(Color.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                                .stroke(Color.tealSoft.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
    }

    @ViewBuilder
    private func notificationsTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            ToggleRow("Clock Out Time Reminder",
                      subtitle: "Display end-of-day reminder.",
                      isOn: $appState.settings.clockOutTimeReminderEnabled)
        }
    }

    @ViewBuilder
    private func notesTab(appState: AppState) -> some View {
        @Bindable var appState = appState

        SettingsCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SettingsSectionTitle(
                    "Notes from your Clock Out sessions",
                    subtitle: "Keep track of your thoughts, reflections, or plans during your time away from the screen."
                )
                TextEditor(text: $appState.settings.clockOutNotes)
                    .font(.uiSans(13))
                    .frame(minHeight: 200)
                    .padding(4)
                    .background(Color.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .stroke(Color.tealSoft.opacity(0.4), lineWidth: 1)
                    )
                Text("Your notes are automatically saved as you type.")
                    .font(.uiSans(11))
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

// MARK: - Time field

private struct TimeField: View {
    let label: String
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.uiSans(12)).foregroundStyle(Color.textSecondary)
            HStack(spacing: 4) {
                TextField("", value: $hour, format: .number)
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                    .font(.tabularMono(15))
                    .textFieldStyle(.roundedBorder)
                Text(":").font(.tabularMono(15))
                TextField("", value: $minute, format: .number)
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                    .font(.tabularMono(15))
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}
