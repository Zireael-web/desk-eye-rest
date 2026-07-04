//
//  WorkingHoursSheet.swift
//  DeskEyeRest
//
//  Modal that lets the user enable/disable each weekday and pick its
//  start/end times.
//

import SwiftUI

struct WorkingHoursSheet: View {
    @Environment(AppState.self) private var appState
    var onClose: () -> Void

    private static let weekdayNames: [Int: String] = [
        1: "Sunday", 2: "Monday", 3: "Tuesday", 4: "Wednesday",
        5: "Thursday", 6: "Friday", 7: "Saturday",
    ]
    private static let order = [2, 3, 4, 5, 6, 7, 1]  // Mon → Sun (system order)

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Working Hours")
                        .font(.displaySerif(36))
                        .foregroundStyle(Color.textPrimary)
                    Text("Configure when DeskEyeRest should be active each day.")
                        .font(.uiSans(13))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Button("Done") { onClose() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brandAccent)
            }

            ForEach(Self.order, id: \.self) { weekday in
                if let idx = appState.settings.workingHours.firstIndex(where: { $0.weekday == weekday }) {
                    DayRow(
                        name: Self.weekdayNames[weekday] ?? "?",
                        day: $appState.settings.workingHours[idx]
                    )
                }
            }

            Spacer()
        }
        .padding(Spacing.xxl)
        .frame(minWidth: 600, minHeight: 580)
        .background(Color.surfacePrimary)
    }
}

private struct DayRow: View {
    let name: String
    @Binding var day: WorkingDay

    var body: some View {
        HStack(spacing: Spacing.lg) {
            Toggle("", isOn: $day.enabled)
                .toggleStyle(.switch).labelsHidden().tint(Color.brandAccent)
            Text(name)
                .font(.uiSansBold(14))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 100, alignment: .leading)
            Spacer()
            HStack(spacing: 4) {
                MiniIntField(value: $day.startHour, range: 0...23, width: 36)
                Text(":").font(.tabularMono(14))
                MiniIntField(value: $day.startMinute, range: 0...59, width: 36)
            }
            .opacity(day.enabled ? 1 : 0.4)
            Image(systemName: "arrow.right")
                .foregroundStyle(Color.textSecondary)
                .opacity(day.enabled ? 1 : 0.4)
            HStack(spacing: 4) {
                MiniIntField(value: $day.endHour, range: 0...23, width: 36)
                Text(":").font(.tabularMono(14))
                MiniIntField(value: $day.endMinute, range: 0...59, width: 36)
            }
            .opacity(day.enabled ? 1 : 0.4)
        }
        .padding(.vertical, 6)
    }
}

private struct MiniIntField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let width: CGFloat

    var body: some View {
        TextField("", value: $value, format: .number)
            .frame(width: width)
            .multilineTextAlignment(.center)
            .font(.tabularMono(14))
            .textFieldStyle(.roundedBorder)
    }
}
