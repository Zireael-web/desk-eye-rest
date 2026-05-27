//
//  SettingsCard.swift
//  DeskEyeRest
//
//  Reusable building blocks for the Settings UI. Every page composes from
//  these so that styling stays consistent and a token change here propagates
//  everywhere.
//

import SwiftUI

// MARK: - Card

/// Sand-warm card container used to group related controls.
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}

// MARK: - Section title (used inside a Card)

struct SettingsSectionTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.uiSansBold(18))
                .foregroundStyle(Color.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.uiSans(13))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Toggle row

/// A row with a title + optional subtitle on the left and a switch on the right.
struct ToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.uiSansBold(15))
                    .foregroundStyle(Color.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.uiSans(12))
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(Color.tealDeep)
        }
    }
}

// MARK: - Minute stepper

/// Compact integer-minute input with a stepper.
struct MinuteStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    init(value: Binding<Int>, range: ClosedRange<Int> = 0...60, unit: String = "min") {
        self._value = value
        self.range = range
        self.unit = unit
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            TextField("", value: $value, format: .number)
                .frame(width: 50)
                .multilineTextAlignment(.trailing)
                .font(.tabularMono(14))
                .textFieldStyle(.roundedBorder)
            Text(unit)
                .font(.uiSans(13))
                .foregroundStyle(Color.textSecondary)
            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
    }
}

// MARK: - Number-with-unit row

/// "Pause timer after [stepper] min"-style row.
struct LabeledMinuteRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    init(_ label: String,
         value: Binding<Int>,
         range: ClosedRange<Int> = 0...60,
         unit: String = "min") {
        self.label = label
        self._value = value
        self.range = range
        self.unit = unit
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.uiSans(14))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            MinuteStepper(value: $value, range: range, unit: unit)
        }
    }
}

// MARK: - Page container (page title + scrollable body)

struct SettingsPage<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text(title)
                    .font(.displaySerif(56))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.bottom, Spacing.sm)
                content()
                Spacer(minLength: Spacing.xxl)
            }
            .padding(Spacing.xxxl)
            .frame(maxWidth: 900, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.surfacePrimary)
    }
}

// MARK: - Section header (between cards on the same page)

struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.uiSansBold(16))
            .foregroundStyle(Color.textPrimary)
            .padding(.top, Spacing.lg)
    }
}

// MARK: - Hairline divider that respects token

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.tealSoft.opacity(0.4))
            .frame(height: 1)
    }
}
