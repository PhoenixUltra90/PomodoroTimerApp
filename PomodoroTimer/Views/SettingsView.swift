//
//  SettingsView.swift
//  PomodoroTimer
//
//  Lets the user change the durations, the number of focus sessions before a
//  long break, and the auto-start toggle. It binds directly to the shared
//  view model, so every change is saved to UserDefaults automatically.
//
//  Each duration can be TYPED as minutes AND seconds. The session count can be
//  typed or stepped. Values are clamped to safe ranges so a typo can't break
//  the timer (a duration is always at least one second).
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject var viewModel: TimerViewModel

    // Tracks whether a number field is being edited, so we can show a
    // "Done" button to dismiss the number keypad (it has no return key).
    @FocusState private var isEditing: Bool

    var body: some View {
        Form {
            // Durations (minutes + seconds)
            Section("Durations") {
                DurationRow(title: "Focus",
                            totalSeconds: $viewModel.focusSeconds, isFocused: $isEditing)
                DurationRow(title: "Short Break",
                            totalSeconds: $viewModel.shortBreakSeconds, isFocused: $isEditing)
                DurationRow(title: "Long Break",
                            totalSeconds: $viewModel.longBreakSeconds, isFocused: $isEditing)
            }

            // Cycle length
            Section("Sessions") {
                NumberRow(title: "Focus sessions before long break",
                          value: $viewModel.sessionsBeforeLongBreak,
                          range: 1...12, isFocused: $isEditing)
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

/// A duration row with typeable minutes and seconds fields, e.g. "25 min 30 sec".
/// Edits update the bound total-seconds value, kept at a minimum of one second.
private struct DurationRow: View {
    let title: String
    @Binding var totalSeconds: Int
    @FocusState.Binding var isFocused: Bool

    private let maxMinutes = 180

    // Minutes part of the total (0...maxMinutes).
    private var minutes: Binding<Int> {
        Binding(
            get: { totalSeconds / 60 },
            set: { newValue in
                let m = min(max(newValue, 0), maxMinutes)
                totalSeconds = clampTotal(m * 60 + totalSeconds % 60)
            }
        )
    }

    // Seconds part of the total (0...59).
    private var seconds: Binding<Int> {
        Binding(
            get: { totalSeconds % 60 },
            set: { newValue in
                let s = min(max(newValue, 0), 59)
                totalSeconds = clampTotal((totalSeconds / 60) * 60 + s)
            }
        )
    }

    /// Keep the duration between 1 second and maxMinutes:59.
    private func clampTotal(_ value: Int) -> Int {
        min(max(value, 1), maxMinutes * 60 + 59)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)

            Spacer(minLength: 8)

            numberField(minutes, placeholder: "0")
            Text("min").foregroundStyle(.secondary)

            numberField(seconds, placeholder: "00")
            Text("sec").foregroundStyle(.secondary)
        }
    }

    private func numberField(_ binding: Binding<Int>, placeholder: String) -> some View {
        TextField(placeholder, value: binding, format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 44)
            .focused($isFocused)
            .textFieldStyle(.roundedBorder)
    }
}

/// A whole-number row with a typeable field and a stepper (used for the
/// "sessions before long break" count).
private struct NumberRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack {
            Text(title)

            Spacer(minLength: 12)

            TextField("", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 44)
                .focused($isFocused)
                .textFieldStyle(.roundedBorder)

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
