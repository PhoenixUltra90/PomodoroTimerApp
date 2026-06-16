//
//  SettingsView.swift
//  PomodoroTimer
//
//  Lets the user change the durations, the number of focus sessions before a
//  long break, and the auto-start toggle. It binds directly to the shared
//  view model, so every change is saved to UserDefaults automatically.
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        Form {
            // Durations
            Section("Durations (minutes)") {
                Stepper("Focus: \(viewModel.focusMinutes)",
                        value: $viewModel.focusMinutes, in: 1...90)

                Stepper("Short Break: \(viewModel.shortBreakMinutes)",
                        value: $viewModel.shortBreakMinutes, in: 1...30)

                Stepper("Long Break: \(viewModel.longBreakMinutes)",
                        value: $viewModel.longBreakMinutes, in: 1...60)
            }

            // Cycle length
            Section("Sessions") {
                Stepper("Focus sessions before long break: \(viewModel.sessionsBeforeLongBreak)",
                        value: $viewModel.sessionsBeforeLongBreak, in: 1...10)
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
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: TimerViewModel())
    }
}
