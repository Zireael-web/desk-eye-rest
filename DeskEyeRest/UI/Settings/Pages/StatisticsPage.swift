//
//  StatisticsPage.swift
//  DeskEyeRest
//
//  Pulls real BreakLog data from `appState.historyStore.logs` (Codable-on-disk
//  store) and aggregates per-period metrics + a yearly heatmap.
//

import SwiftUI

private enum StatsPeriod: String, CaseIterable, Hashable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
    case all = "All"
}

struct StatisticsPage: View {
    @Environment(AppState.self) private var appState
    @State private var period: StatsPeriod = .all

    var body: some View {
        let logs = appState.historyStore.logs

        SettingsPage(title: "Statistics") {
            Text("Track your break habits and see how you're building a healthier work routine.")
                .font(.uiSans(14))
                .foregroundStyle(Color.textSecondary)
                .padding(.bottom, -Spacing.sm)

            // Heatmap card
            SettingsCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    SettingsSectionTitle(
                        "Break Activity",
                        subtitle: "Your break consistency this year."
                    )
                    YearlyHeatmap(logs: logs)
                    HStack {
                        HStack(spacing: 8) {
                            Text("How it works:")
                                .font(.uiSans(11))
                                .foregroundStyle(Color.textSecondary)
                            ForEach([0.0, 0.4, 0.8, 1.0], id: \.self) { intensity in
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(heatmapCellColor(intensity: intensity))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        Spacer()
                        Text(daysWithBreaksLabel(logs: logs))
                            .font(.tabularMono(11))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }

            // Metrics card
            SettingsCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        SettingsSectionTitle("Break Statistics")
                        Spacer()
                        Picker("", selection: $period) {
                            ForEach(StatsPeriod.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 280)
                        .labelsHidden()
                    }

                    HStack {
                        Text("Metric").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Value").frame(width: 80, alignment: .trailing)
                    }
                    .font(.uiSans(11))
                    .foregroundStyle(Color.textSecondary)

                    SettingsDivider()

                    let m = computeMetrics(logs: filtered(logs: logs, by: period))
                    MetricRow(symbol: "figure.walk", title: "Total Breaks",
                              subtitle: "completed breaks", value: "\(m.total)")
                    SettingsDivider()
                    MetricRow(symbol: "timer", title: "Short Breaks",
                              subtitle: "quick pauses", value: "\(m.short)")
                    SettingsDivider()
                    MetricRow(symbol: "pause.circle", title: "Long Breaks",
                              subtitle: "deep rest", value: "\(m.long)")
                    SettingsDivider()
                    MetricRow(symbol: "forward.fill", title: "Skip Rate",
                              subtitle: "breaks skipped", value: m.skipRateString)
                    SettingsDivider()
                    MetricRow(symbol: "flame", title: "Best Streak",
                              subtitle: "days staying consistent", value: "\(bestStreakDays(logs: logs))")
                }
            }

            // Delete history
            SettingsCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Delete History")
                            .font(.uiSansBold(15))
                            .foregroundStyle(Color.textPrimary)
                        Text("Clear all break data permanently.")
                            .font(.uiSans(12))
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        appState.historyStore.deleteAll()
                    } label: {
                        Label("Delete All", systemImage: "trash")
                            .font(.uiSans(13))
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.coral)
                }
            }
        }
    }
}

// MARK: - Aggregations

private struct Metrics {
    var total: Int = 0
    var short: Int = 0
    var long: Int = 0
    var skipped: Int = 0
    var skipRateString: String {
        guard total > 0 else { return "—" }
        let pct = Double(skipped) / Double(total) * 100
        return String(format: "%.1f%%", pct)
    }
}

private func computeMetrics(logs: [BreakLog]) -> Metrics {
    var m = Metrics()
    for log in logs {
        m.total += 1
        switch log.kind {
        case .short: m.short += 1
        case .long:  m.long += 1
        }
        if log.skipped { m.skipped += 1 }
    }
    return m
}

private func filtered(logs: [BreakLog], by period: StatsPeriod) -> [BreakLog] {
    let cal = Calendar.current
    let now = Date()
    switch period {
    case .all:   return logs
    case .today: return logs.filter { cal.isDate($0.startedAt, inSameDayAs: now) }
    case .week:
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        return logs.filter { $0.startedAt >= weekStart }
    case .month:
        guard let monthStart = cal.dateInterval(of: .month, for: now)?.start else { return [] }
        return logs.filter { $0.startedAt >= monthStart }
    }
}

private func bestStreakDays(logs: [BreakLog]) -> Int {
    let cal = Calendar.current
    let dayKeys: Set<Date> = Set(
        logs.filter { !$0.skipped }
            .compactMap { cal.dateInterval(of: .day, for: $0.startedAt)?.start }
    )
    let sorted = dayKeys.sorted()
    var best = 0
    var current = 0
    var prev: Date?
    for day in sorted {
        if let prev, cal.dateComponents([.day], from: prev, to: day).day == 1 {
            current += 1
        } else {
            current = 1
        }
        prev = day
        best = max(best, current)
    }
    return best
}

private func daysWithBreaksLabel(logs: [BreakLog]) -> String {
    let cal = Calendar.current
    let count = Set(logs.compactMap {
        cal.dateInterval(of: .day, for: $0.startedAt)?.start
    }).count
    return "\(count) day\(count == 1 ? "" : "s") with breaks this year"
}

// MARK: - Heatmap

private struct YearlyHeatmap: View {
    let logs: [BreakLog]

    var body: some View {
        let intensities = computeIntensities(logs: logs)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                ForEach(["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul",
                         "Aug", "Sep", "Oct", "Nov", "Dec"], id: \.self) { m in
                    Text(m)
                        .font(.tabularMono(10))
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            VStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { weekday in
                    HStack(spacing: 2) {
                        ForEach(0..<53, id: \.self) { week in
                            let key = cellKey(week: week, weekday: weekday)
                            let intensity = intensities[key] ?? 0
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(heatmapCellColor(intensity: intensity))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }

    private func cellKey(week: Int, weekday: Int) -> String { "\(week)-\(weekday)" }

    private func computeIntensities(logs: [BreakLog]) -> [String: Double] {
        let cal = Calendar.current
        let now = Date()
        guard let yearStart = cal.dateInterval(of: .year, for: now)?.start else { return [:] }
        var counts: [String: Int] = [:]
        for log in logs where log.startedAt >= yearStart && !log.skipped {
            guard let weekday = cal.dateComponents([.weekday], from: log.startedAt).weekday else { continue }
            let week = (cal.dateComponents([.day], from: yearStart, to: log.startedAt).day ?? 0) / 7
            let key = "\(min(week, 52))-\((weekday - 1 + 7) % 7)"
            counts[key, default: 0] += 1
        }
        let maxCount = max(1, counts.values.max() ?? 0)
        return counts.mapValues { Double($0) / Double(maxCount) }
    }
}

private func heatmapCellColor(intensity: Double) -> Color {
    switch intensity {
    case 0:        return Color.tealSoft.opacity(0.18)
    case 0..<0.34: return Color.tealMid.opacity(0.45)
    case 0.34..<0.7: return Color.coral.opacity(0.6)
    default:       return Color.brandAccent.opacity(0.85)
    }
}

// MARK: - Metric row

private struct MetricRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(Color.tealMid)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.uiSansBold(13))
                Text(subtitle).font(.uiSans(11)).foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Text(value)
                .font(.tabularMono(20))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.vertical, Spacing.xs)
    }
}
