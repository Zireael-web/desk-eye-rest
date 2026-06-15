//
//  AboutPage.swift
//  DeskEyeRest
//
//  Settings → About. Version, privacy, and local system information.
//

import SwiftUI

struct AboutPage: View {
    var body: some View {
        SettingsPage(title: "About") {
            VStack(spacing: Spacing.lg) {
                BrandIcon()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.top, Spacing.lg)

                HStack(spacing: 0) {
                    Text("DeskEye")
                        .font(.uiSansBold(28))
                        .foregroundStyle(Color.textPrimary)
                    Text("Rest")
                        .font(.uiSans(28))
                        .foregroundStyle(Color.brandAccent)
                }

                VStack(spacing: 4) {
                    Text(versionLabel)
                        .font(.tabularMono(13))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().stroke(Color.tealSoft.opacity(0.4), lineWidth: 1)
                        )
                    Text("Build \(buildLabel)")
                        .font(.tabularMono(11))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.lg)

            // Project and privacy summary
            SettingsCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    SettingsSectionTitle(
                        "Built for focused work",
                        subtitle: "DeskEyeRest is a native macOS menu-bar app for intentional screen breaks."
                    )
                    AboutPill(systemImage: "lock.shield",
                              title: "Privacy",
                              subtitle: "Settings and break history stay on this Mac")
                }
            }

            // System info
            SettingsCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SettingsSectionTitle("System")
                    InfoRow(label: "macOS",         value: ProcessInfo.processInfo.operatingSystemVersionString)
                    InfoRow(label: "Architecture",  value: archString())
                    InfoRow(label: "Bundle ID",     value: Bundle.main.bundleIdentifier ?? "—")
                }
            }
        }
    }

    private var versionLabel: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return "Version \(v ?? "—")"
    }

    private var buildLabel: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private func archString() -> String {
        #if arch(arm64)
        return "Apple Silicon (arm64)"
        #elseif arch(x86_64)
        return "Intel (x86_64)"
        #else
        return "unknown"
        #endif
    }
}

private struct AboutPill: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 18))
                .foregroundStyle(Color.brandAccent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.uiSansBold(13))
                Text(subtitle).font(.uiSans(11)).foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.uiSans(13))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.tabularMono(12))
                .foregroundStyle(Color.textPrimary)
        }
    }
}
