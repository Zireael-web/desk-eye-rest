//
//  SettingsSubTabBar.swift
//  DeskEyeRest
//
//  Pill-row tab navigation used at the top of multi-tab settings pages.
//  Active tab gets bold weight + 2pt teal underline; inactive tabs are mid teal.
//

import SwiftUI

struct SettingsSubTabBar<Tab: Hashable & CaseIterable & RawRepresentable>: View
where Tab.RawValue == String, Tab.AllCases: RandomAccessCollection {
    @Binding var selection: Tab
    let labels: [Tab: String]

    init(selection: Binding<Tab>, labels: [Tab: String]) {
        self._selection = selection
        self.labels = labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.xxl) {
                ForEach(Array(Tab.allCases), id: \.self) { tab in
                    let isActive = tab == selection
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { selection = tab }
                    } label: {
                        VStack(spacing: 6) {
                            Text(labels[tab] ?? tab.rawValue)
                                .font(isActive ? .uiSansBold(14) : .uiSans(14))
                                .foregroundStyle(isActive ? Color.textPrimary : Color.textSecondary)
                            Rectangle()
                                .fill(isActive ? Color.brandAccent : Color.clear)
                                .frame(height: 2)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            // Hairline rule under the whole bar (the active underline overlays it)
            Rectangle()
                .fill(Color.tealSoft.opacity(0.5))
                .frame(height: 1)
                .offset(y: -1)
        }
        .padding(.bottom, Spacing.lg)
    }
}
