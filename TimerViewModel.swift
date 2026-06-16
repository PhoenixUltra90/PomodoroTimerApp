//
//  TimerViewModel.swift
//  PomodoroTimer
//
//  This is the "brain" of the app (the VM in MVVM).
//  It owns BOTH the running timer state AND the user's saved settings,
//  so there is a single source of truth and nothing can get out of sync.
//
//  Views observe this object: any time a @Published value changes,
//  SwiftUI automatically redraws the screen.
//

import Foundation
import SwiftUI

final class TimerViewModel: ObservableObject {

    // MARK: - UserDefaults keys (where settings are saved on disk)

    private enum Keys {
        static let focusMinutes            = "focusMinutes"
        static let shortBreakMinutes       = "shortBreakMinutes"
        static let longBreakMinutes        = "longBreakMinutes"
        static let sessionsBeforeLongBreak = "sessionsBeforeLongBreak"
        static let autoStartNext           = "autoStartNext"
    }

    // MARK: - Default values (used on first launch and "Reset to Defaults")

    private enum Defaults {
        static let focusMinutes            = 25
        static let shortBreakMinutes       = 5
        static let longBreakMinutes        = 15
        static let sessionsBeforeLongBreak = 4
        static let autoStartNext           = false
    }

    // MARK: - Saved settings
    //
    // Each setting saves itself to UserDefaults whenever it changes (didSet).
    // Changing a duration while idle also refreshes the time shown on screen.

    @Published var focusMinutes: Int {
        didSet { saveSettings(); refreshTimeIfIdle() }
    }
    @Published var shortBreakMinutes: Int {
        didSet { saveSettings(); refreshTimeIfIdle() }
    }
    @Published var longBreakMinutes: Int {
        didSet { saveSettings(); refreshTimeIfIdle() }
    }
    @Published var sessionsBeforeLongBreak: Int {
        didSet { saveSettings() }
    }
    @Published var autoStartNext: Bool {
        didSet { saveSettings() }
    }

    // MARK: - Live timer state (read-only from the outside)

    @Published private(set) var mode: TimerMode = .focus
    @Published private(set) var secondsRemaining: Int
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var completedFocusSessions: Int = 0

    /// The repeating 1-second timer. It is nil whenever the timer is paused/stopped.
    private var timer: Timer?

    // MARK: - Setup

    init() {
        let store = UserDefaults.standard

        // Load each setting, falling back to the default if nothing is saved yet.
        // (Property observers / didSet do NOT fire for assignments inside init.)
        focusMinutes            = (store.object(forKey: Keys.focusMinutes) as? Int) ?? Defaults.focusMinutes
        shortBreakMinutes       = (store.object(forKey: Keys.shortBreakMinutes) as? Int) ?? Defaults.shortBreakMinutes
        longBreakMinutes        = (store.object(forKey: Keys.longBreakMinutes) as? Int) ?? Defaults.longBreakMinutes
        sessionsBeforeLongBreak = (store.object(forKey: Keys.sessionsBeforeLongBreak) as? Int) ?? Defaults.sessionsBeforeLongBreak
        autoStartNext           = (store.object(forKey: Keys.autoStartNext) as? Bool) ?? Defaults.autoStartNext

        // Start on a fresh Focus session.
        secondsRemaining = focusMinutes * 60
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Values the views display

    /// Total seconds for the current mode (e.g. 25 * 60 for a 25-minute focus).
    var totalSecondsForCurrentMode: Int {
        duration(for: mode)
    }

    /// Progress from 0 (just started) to 1 (finished). Used by the ring.
    var progress: Double {
        let total = totalSecondsForCurrentMode
        guard total > 0 else { return 0 }
        return 1 - Double(secondsRemaining) / Double(total)
    }

    /// Countdown text in MM:SS form, e.g. "04:09".
    var timeString: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    /// Session counter text, e.g. "Pomodoro 1 of 4".
    var sessionDisplay: String {
        let cycle = max(1, sessionsBeforeLongBreak)
        let current = (completedFocusSessions % cycle) + 1
        return "Pomodoro \(current) of \(cycle)"
    }

    // MARK: - Controls (called by the buttons)

    /// Start (or resume) counting down.
    func start() {
        guard !isRunning, secondsRemaining > 0 else { return }
        isRunning = true

        // Always replace any existing timer to avoid double-counting.
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    /// Pause without losing the remaining time.
    func pause() {
        stopTimer()
    }

    /// Reset the CURRENT mode back to its full length.
    func reset() {
        stopTimer()
        secondsRemaining = totalSecondsForCurrentMode
    }

    /// Immediately move to the next mode (manual skip).
    /// Skipping a Focus session counts it toward the long-break cycle so the
    /// "Pomodoro X of N" cadence stays correct.
    func skip() {
        stopTimer()
        advanceToNextMode()
        secondsRemaining = totalSecondsForCurrentMode
    }

    /// Restore every setting to its default value.
    func resetToDefaults() {
        focusMinutes            = Defaults.focusMinutes
        shortBreakMinutes       = Defaults.shortBreakMinutes
        longBreakMinutes        = Defaults.longBreakMinutes
        sessionsBeforeLongBreak = Defaults.sessionsBeforeLongBreak
        autoStartNext           = Defaults.autoStartNext
        reset()
    }

    // MARK: - Private helpers

    /// Called once per second by the timer.
    private func tick() {
        if secondsRemaining > 0 {
            secondsRemaining -= 1
        }
        if secondsRemaining == 0 {
            finishSession()
        }
    }

    /// Runs when a session reaches 0.
    private func finishSession() {
        stopTimer()
        Feedback.sessionEnded()          // haptic + sound
        advanceToNextMode()              // switch focus <-> break
        secondsRemaining = totalSecondsForCurrentMode

        // Only keep going automatically if the user turned that on in Settings.
        if autoStartNext {
            start()
        }
    }

    /// Decides which mode comes next and updates the session counter.
    private func advanceToNextMode() {
        if mode == .focus {
            completedFocusSessions += 1
            let cycle = max(1, sessionsBeforeLongBreak)
            let cycleComplete = completedFocusSessions % cycle == 0
            mode = cycleComplete ? .longBreak : .shortBreak
        } else {
            // After any break, return to focus.
            mode = .focus
        }
    }

    /// Stop and clear the timer.
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    /// Minutes -> seconds for a given mode.
    private func duration(for mode: TimerMode) -> Int {
        switch mode {
        case .focus:      return focusMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak:  return longBreakMinutes * 60
        }
    }

    /// If the timer is not running, update the shown time to match new settings.
    private func refreshTimeIfIdle() {
        if !isRunning {
            secondsRemaining = totalSecondsForCurrentMode
        }
    }

    /// Write all settings to UserDefaults.
    private func saveSettings() {
        let store = UserDefaults.standard
        store.set(focusMinutes,            forKey: Keys.focusMinutes)
        store.set(shortBreakMinutes,       forKey: Keys.shortBreakMinutes)
        store.set(longBreakMinutes,        forKey: Keys.longBreakMinutes)
        store.set(sessionsBeforeLongBreak, forKey: Keys.sessionsBeforeLongBreak)
        store.set(autoStartNext,           forKey: Keys.autoStartNext)
    }
}
