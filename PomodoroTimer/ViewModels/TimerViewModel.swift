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
        // Durations are now stored as a total number of SECONDS.
        static let focusSeconds            = "focusSeconds"
        static let shortBreakSeconds       = "shortBreakSeconds"
        static let longBreakSeconds        = "longBreakSeconds"
        static let sessionsBeforeLongBreak = "sessionsBeforeLongBreak"
        static let autoStartNext           = "autoStartNext"

        // Old minute-based keys, kept only so existing saved settings can be
        // migrated to the new seconds keys on first launch after the update.
        static let legacyFocusMinutes      = "focusMinutes"
        static let legacyShortBreakMinutes = "shortBreakMinutes"
        static let legacyLongBreakMinutes  = "longBreakMinutes"
    }

    // MARK: - Default values (used on first launch and "Reset to Defaults")

    private enum Defaults {
        static let focusSeconds            = 25 * 60   // 25:00
        static let shortBreakSeconds       = 5 * 60    // 05:00
        static let longBreakSeconds        = 15 * 60   // 15:00
        static let sessionsBeforeLongBreak = 4
        static let autoStartNext           = false
    }

    // MARK: - Saved settings
    //
    // Each setting saves itself to UserDefaults whenever it changes (didSet).
    // Changing a duration while idle also refreshes the time shown on screen.

    // Total length of each mode, in seconds.
    @Published var focusSeconds: Int {
        didSet { saveSettings(); refreshTimeIfIdle() }
    }
    @Published var shortBreakSeconds: Int {
        didSet { saveSettings(); refreshTimeIfIdle() }
    }
    @Published var longBreakSeconds: Int {
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

    /// The exact wall-clock moment the current session will reach 0.
    /// We count down to this date (instead of just subtracting 1 each tick) so the
    /// time stays correct even if the app was backgrounded for a while.
    private var endDate: Date?

    // MARK: - Setup

    init() {
        let store = UserDefaults.standard

        // Load each setting, falling back to the default if nothing is saved yet.
        // (Property observers / didSet do NOT fire for assignments inside init.)
        // We read the focus value into a local first because Swift won't let us
        // access `self.focusSeconds` until every stored property is initialized.
        let loadedFocusSeconds  = TimerViewModel.loadSeconds(store, Keys.focusSeconds, Keys.legacyFocusMinutes, Defaults.focusSeconds)
        focusSeconds            = loadedFocusSeconds
        shortBreakSeconds       = TimerViewModel.loadSeconds(store, Keys.shortBreakSeconds, Keys.legacyShortBreakMinutes, Defaults.shortBreakSeconds)
        longBreakSeconds        = TimerViewModel.loadSeconds(store, Keys.longBreakSeconds, Keys.legacyLongBreakMinutes, Defaults.longBreakSeconds)
        sessionsBeforeLongBreak = (store.object(forKey: Keys.sessionsBeforeLongBreak) as? Int) ?? Defaults.sessionsBeforeLongBreak
        autoStartNext           = (store.object(forKey: Keys.autoStartNext) as? Bool) ?? Defaults.autoStartNext

        // Start on a fresh Focus session.
        secondsRemaining = loadedFocusSeconds
    }

    /// Reads a duration in seconds. If only the old minute-based value exists
    /// (from a previous version), it is converted so settings aren't lost.
    private static func loadSeconds(_ store: UserDefaults, _ secondsKey: String,
                                    _ legacyMinutesKey: String, _ defaultSeconds: Int) -> Int {
        if let seconds = store.object(forKey: secondsKey) as? Int {
            return seconds
        }
        if let minutes = store.object(forKey: legacyMinutesKey) as? Int {
            return minutes * 60
        }
        return defaultSeconds
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

        // Record when this session ends and schedule the matching alert.
        endDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        NotificationManager.scheduleSessionEnd(after: secondsRemaining, modeTitle: mode.title)

        // Always replace any existing timer to avoid double-counting.
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateRemaining()
        }
    }

    /// Pause without losing the remaining time.
    func pause() {
        // Capture the precise remaining time before we throw away the end date.
        if let endDate {
            secondsRemaining = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
        }
        stopTimer()
    }

    /// Re-check the remaining time when the app comes back to the foreground.
    /// While backgrounded the 1-second timer is paused by the system, so this
    /// catches the display up (and finishes the session if time already ran out).
    func syncToForeground() {
        if isRunning {
            updateRemaining()
        }
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
        focusSeconds            = Defaults.focusSeconds
        shortBreakSeconds       = Defaults.shortBreakSeconds
        longBreakSeconds        = Defaults.longBreakSeconds
        sessionsBeforeLongBreak = Defaults.sessionsBeforeLongBreak
        autoStartNext           = Defaults.autoStartNext
        reset()
    }

    // MARK: - Private helpers

    /// Called once per second by the timer (and on returning to the foreground).
    /// Recomputes the remaining time from the saved end date.
    private func updateRemaining() {
        guard let endDate else { return }
        let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
        secondsRemaining = max(0, remaining)
        if remaining <= 0 {
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

    /// Stop and clear the timer, and cancel any pending end-of-session alert.
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        isRunning = false
        NotificationManager.cancelScheduled()
    }

    /// Total seconds for a given mode.
    private func duration(for mode: TimerMode) -> Int {
        switch mode {
        case .focus:      return focusSeconds
        case .shortBreak: return shortBreakSeconds
        case .longBreak:  return longBreakSeconds
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
        store.set(focusSeconds,            forKey: Keys.focusSeconds)
        store.set(shortBreakSeconds,       forKey: Keys.shortBreakSeconds)
        store.set(longBreakSeconds,        forKey: Keys.longBreakSeconds)
        store.set(sessionsBeforeLongBreak, forKey: Keys.sessionsBeforeLongBreak)
        store.set(autoStartNext,           forKey: Keys.autoStartNext)
    }
}
