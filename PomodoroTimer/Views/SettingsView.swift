//
//  SettingsView.swift
//  PomodoroTimer
//
//  Lets the user change the durations, the number of focus sessions before a
//  long break, and the auto-start toggle. It binds directly to the shared
//  view model, so every change is saved to UserDefaults automatically.
//
//  Each number can be TYPED into a text field or nudged with the stepper.
//  Values are clamped to a safe range so a typo can't break the timer.
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject var viewModel: TimerViewModel

    // Tracks whether a number field is being edited, so we can show a
    // "Done" button to dismiss the number keypad (it has no return key).
    @FocusState private var isEditing: Bool

    var body: some View {
        Form {
            // Durations
            Section("Durations (minutes)") {
                NumberRow(title: "Focus", value: $viewModel.focusMinutes,
                          range: 1...180, unit: "min", isFocused: $isEditing)
                NumberRow(title: "Short Break", value: $viewModel.shortBreakMinutes,
                          range: 1...60, unit: "min", isFocused: $isEditing)
                NumberRow(title: "Long Break", value: $viewModel.longBreakMinutes,
                          range: 1...120, unit: "min", isFocused: $isEditing)
            }

            // Cycle length
            Section("Sessions") {
                NumberRow(title: "Focus sessions before long break",
                          value: $viewModel.sessionsBeforeLongBreak,
                          range: 1...12, unit: nil, isFocused: $isEditing)
            }

            // Auto-start
            Section {
                Toggle("Auto-start next session", isOn: $viewModel.autoStartNext)
            } footer: {
                Text("When on, the next timer begins automatically after one finishes. When off, it waits for you to tap Start.")
            }

            // Reset
            Section {
                Button(role: .destructive) {
                    viewModel.resetToDefaults()
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        // "Done" button above the number keypad to dismiss it.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isEditing = false }
            }
        }
    }
}

/// A single settings row: a title, a typeable number field, an optional unit
/// label (e.g. "min"), and a stepper. The value is kept inside `range`.
private struct NumberRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var unit: String?
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack {
            Text(title)

            Spacer(minLength: 12)

            TextField("", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 56)
                .focused($isFocused)
                .textFieldStyle(.roundedBorder)

            if let unit {
                Text(unit)
                    .foregroundStyle(.secondary)
            }

            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
        // Keep the value within range even when it is typed (not just stepped).
        .onChange(of: value) { _, newValue in
            let clamped = min(max(newValue, range.lowerBound), range.upperBound)
            if clamped != newValue {
                value = clamped
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: TimerViewModel())
    }
}
