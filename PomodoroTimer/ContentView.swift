//
//  ContentView.swift
//  PomodoroTimer
//
//  The main timer screen. It only DISPLAYS data from the view model and
//  forwards button taps to it — it contains no timer logic itself.
//

import SwiftUI

struct ContentView: View {

    // We observe the shared view model created in PomodoroTimerApp.
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                modeHeader
                timerRing
                Spacer()
                controlButtons
            }
            .padding()
            .navigationTitle("Pomodoro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView(viewModel: viewModel)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        // Tint everything (back button, etc.) with the current mode color.
        .tint(viewModel.mode.accentColor)
    }

    // MARK: - Pieces of the screen

    /// Mode title + session counter ("Focus" / "Pomodoro 1 of 4").
    private var modeHeader: some View {
        VStack(spacing: 8) {
            Label(viewModel.mode.title, systemImage: viewModel.mode.iconName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(viewModel.mode.accentColor)

            Text(viewModel.sessionDisplay)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// The ring with the big MM:SS countdown in the middle.
    private var timerRing: some View {
        ZStack {
            ProgressRingView(
                progress: viewModel.progress,
                color: viewModel.mode.accentColor
            )

            VStack(spacing: 4) {
                Text(viewModel.timeString)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()          // keeps width steady each second

                Text(viewModel.isRunning ? "Running" : "Paused")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 260, height: 260)
        .padding(.top, 8)
    }

    /// Start/Pause (primary) plus Reset and Skip.
    private var controlButtons: some View {
        VStack(spacing: 16) {
            // Primary Start / Pause button.
            Button {
                if viewModel.isRunning {
                    viewModel.pause()
                } else {
                    viewModel.start()
                }
            } label: {
                Label(
                    viewModel.isRunning ? "Pause" : "Start",
                    systemImage: viewModel.isRunning ? "pause.fill" : "play.fill"
                )
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.mode.accentColor)

            // Secondary Reset / Skip buttons, side by side.
            HStack(spacing: 16) {
                Button {
                    viewModel.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.skip()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    ContentView(viewModel: TimerViewModel())
}
