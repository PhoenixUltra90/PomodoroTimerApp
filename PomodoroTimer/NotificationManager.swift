//
//  NotificationManager.swift
//  PomodoroTimer
//
//  Schedules a local notification for the moment the current session ends.
//  Because the trigger is based on the wall clock, the alert fires at the right
//  time even if the app is in the background or the screen is locked.
//
//  We keep this separate so the view model can simply call
//  `NotificationManager.scheduleSessionEnd(...)` and `cancelScheduled()`.
//

import Foundation
import UserNotifications

enum NotificationManager {

    /// One fixed identifier so we only ever have a single pending alert.
    private static let sessionEndID = "pomodoro.session.end"

    /// Ask the user once for permission to show alerts and play sounds.
    /// Safe to call on every launch — iOS only prompts the first time.
    static func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in
                // Nothing to do here. If the user declines, the in-app
                // haptic + sound still work while the app is open.
            }
    }

    /// Schedule the "session finished" alert `seconds` from now.
    static func scheduleSessionEnd(after seconds: Int, modeTitle: String) {
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(modeTitle) finished"
        content.body = "Tap to start your next session."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: sessionEndID,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [sessionEndID])
        center.add(request)
    }

    /// Cancel any pending "session finished" alert (used on pause/reset/skip).
    static func cancelScheduled() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [sessionEndID])
    }
}
