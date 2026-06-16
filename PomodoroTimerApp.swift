//
//  PomodoroTimerApp.swift
//  PomodoroTimer
//
//  This is the entry point of the app (marked with @main).
//  It creates ONE TimerViewModel that lives for the whole app's lifetime
//  using @StateObject, then hands it to ContentView.
//

import SwiftUI

@main
struct PomodoroTimerApp: App {

    // @StateObject means "create this object once and keep it alive."
    // The whole app shares this single source of truth.
    @StateObject private var viewModel = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
