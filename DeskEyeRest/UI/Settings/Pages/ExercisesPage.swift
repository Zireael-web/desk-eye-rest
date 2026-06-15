//
//  ExercisesPage.swift
//  DeskEyeRest
//
//  Settings → Exercises. Single page with a search field, table-like list,
//  and a sheet for Add/Edit.
//

import SwiftUI

struct ExercisesPage: View {
    @Environment(AppState.self) private var appState
    @State private var search: String = ""
    @State private var addSheet: Bool = false

    var body: some View {
        SettingsPage(title: "Exercises") {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create custom exercises that you can assign to short or long breaks, tailoring your breaks to your personal needs.")
                        .font(.uiSans(13))
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button {
                    addSheet = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .font(.uiSans(13))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandAccent)
            }

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.textSecondary)
                TextField("Search exercises…", text: $search)
                    .textFieldStyle(.plain)
                    .font(.uiSans(13))
            }
            .padding(Spacing.sm)
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))

            SettingsCard {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Name").frame(width: 140, alignment: .leading)
                        Text("Title").frame(width: 220, alignment: .leading)
                        Text("Description").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Assigned to").frame(width: 130, alignment: .leading)
                    }
                    .font(.uiSans(11))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.vertical, Spacing.sm)

                    SettingsDivider()

                    ForEach(filteredExercises()) { ex in
                        ExerciseRow(exercise: ex)
                            .padding(.vertical, Spacing.md)
                        SettingsDivider()
                    }
                }
            }
        }
        .sheet(isPresented: $addSheet) {
            AddExerciseSheet { newEx in
                appState.exerciseStore.add(newEx)
                addSheet = false
            } onCancel: {
                addSheet = false
            }
        }
    }

    private func filteredExercises() -> [Exercise] {
        let all = appState.exerciseStore.exercises
        guard !search.isEmpty else { return all }
        let q = search.lowercased()
        return all.filter {
            $0.name.lowercased().contains(q) ||
            $0.displayTitle.lowercased().contains(q) ||
            $0.detail.lowercased().contains(q)
        }
    }
}

// MARK: - Row

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(alignment: .top) {
            Text(exercise.name)
                .font(.uiSansBold(13))
                .frame(width: 140, alignment: .leading)
            Text(exercise.displayTitle)
                .font(.uiSans(13))
                .frame(width: 220, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(exercise.detail)
                .font(.uiSans(13))
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Circle()
                    .fill(exercise.assignedTo == .short ? Color.tealMid : Color.coral)
                    .frame(width: 8, height: 8)
                Text(exercise.assignedTo == .short ? "Short Break" : "Long Break")
                    .font(.uiSans(13))
            }
            .frame(width: 130, alignment: .leading)
        }
    }
}

// MARK: - Add sheet

private struct AddExerciseSheet: View {
    var onSave: (Exercise) -> Void
    var onCancel: () -> Void

    @State private var name: String = ""
    @State private var displayTitle: String = ""
    @State private var detail: String = ""
    @State private var assignment: BreakKind = .short

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Add Exercise")
                    .font(.displaySerif(36))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button("Cancel") { onCancel() }
                    .buttonStyle(.bordered)
                Button {
                    onSave(Exercise(
                        name: name,
                        displayTitle: displayTitle,
                        detail: detail,
                        assignedTo: assignment
                    ))
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandAccent)
                .disabled(name.isEmpty || displayTitle.isEmpty)
            }

            FormField(
                title: "Exercise Name",
                subtitle: "A unique identifier to help you organize your exercises.",
                placeholder: "Eye break",
                text: $name
            )
            FormField(
                title: "Display Title",
                subtitle: "The main title shown during break sessions.",
                placeholder: "Rest Your Eyes, Refresh Your Mind",
                text: $displayTitle
            )
            FormField(
                title: "Description",
                subtitle: "Detailed instructions or motivation text for your break.",
                placeholder: "A gentle reminder to step away from your screen…",
                text: $detail,
                multiline: true
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Break Assignment")
                    .font(.uiSansBold(14))
                    .foregroundStyle(Color.textPrimary)
                Text("Choose which breaks will include this exercise.")
                    .font(.uiSans(12))
                    .foregroundStyle(Color.textSecondary)
                Picker("", selection: $assignment) {
                    Text("Short Break").tag(BreakKind.short)
                    Text("Long Break").tag(BreakKind.long)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            Spacer()
        }
        .padding(Spacing.xxl)
        .frame(minWidth: 540, minHeight: 580)
        .background(Color.surfacePrimary)
    }
}

private struct FormField: View {
    let title: String
    let subtitle: String
    let placeholder: String
    @Binding var text: String
    var multiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.uiSansBold(14))
                .foregroundStyle(Color.textPrimary)
            Text(subtitle)
                .font(.uiSans(12))
                .foregroundStyle(Color.textSecondary)
            if multiline {
                TextEditor(text: $text)
                    .font(.uiSans(13))
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(Color.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(.uiSans(13))
            }
        }
    }
}
