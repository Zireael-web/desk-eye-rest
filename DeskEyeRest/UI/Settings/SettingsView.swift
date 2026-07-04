//
//  SettingsView.swift
//  DeskEyeRest
//
//  Phase 0: NavigationSplitView shell with sidebar + General page.
//  Phase 3+ adds Breaks / Focus / Flash / Exercises / Clock Out / Statistics
//  pages as full implementations.
//

import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general, breaks, focusMode, flashReminder, exercises, clockOut, statistics, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:       return "General"
        case .breaks:        return "Breaks"
        case .focusMode:     return "Focus mode"
        case .flashReminder: return "Flash Reminder"
        case .exercises:     return "Exercises"
        case .clockOut:      return "Clock Out"
        case .statistics:    return "Statistics"
        case .about:         return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .general:       return "gearshape"
        case .breaks:        return "pause.circle"
        case .focusMode:     return "target"
        case .flashReminder: return "bolt"
        case .exercises:     return "arrow.left.and.right"
        case .clockOut:      return "moon"
        case .statistics:    return "chart.bar"
        case .about:         return "info.circle"
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPane
        }
        .navigationSplitViewStyle(.balanced)
        .background(Color.surfacePrimary)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            // Brand block at top
            HStack(spacing: Spacing.md) {
                BrandIcon()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("DeskEye")
                        .font(.uiSansBold(16))
                        .foregroundStyle(Color.textPrimary)
                    Text("Rest")
                        .font(.uiSans(16))
                        .foregroundStyle(Color.brandAccent)
                }
            }
            .padding(.vertical, Spacing.lg)
            .listRowBackground(Color.clear)

            ForEach(SettingsSection.allCases.filter { $0 != .about }) { section in
                NavigationLink(value: section) {
                    Label(section.title, systemImage: section.systemImage)
                        .font(.uiSans(14))
                }
            }

            Section {
                NavigationLink(value: SettingsSection.about) {
                    Label("About", systemImage: "info.circle")
                        .font(.uiSans(13))
                }
            }
        }
        .navigationSplitViewColumnWidth(220)
        .scrollContentBackground(.hidden)
        .background(Color.surfaceCard)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailPane: some View {
        switch selection {
        case .general:       GeneralPage()
        case .breaks:        BreaksPage()
        case .focusMode:     FocusModePage()
        case .flashReminder: FlashReminderPage()
        case .exercises:     ExercisesPage()
        case .clockOut:      ClockOutPage()
        case .statistics:    StatisticsPage()
        case .about:         AboutPage()
        case .none:
            GeneralPage()
        }
    }
}

/// Loads the brand icon either from the asset catalog (Xcode build) or from a
/// loose PNG resource (manual swiftc build) — whichever is present.
struct BrandIcon: View {
    var body: some View {
        if let nsImage = NSImage(named: "AppIcon") {
            Image(nsImage: nsImage).resizable()
        } else if let url = Bundle.main.url(forResource: "icon-256", withExtension: "png"),
                  let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage).resizable()
        } else {
            Image(systemName: "eye.fill")
                .resizable()
                .foregroundStyle(Color.tealDeep)
        }
    }
}
