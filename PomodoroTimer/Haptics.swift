//
//  Haptics.swift
//  PomodoroTimer
//
//  A tiny helper that plays feedback when a session ends.
//  We keep it separate so the rest of the app can simply call
//  `Feedback.sessionEnded()` without worrying about the details.
//
//  Note: Haptics (vibration) only work on a REAL iPhone — the Simulator
//  cannot vibrate. The system sound, however, will play in the Simulator.
//

import UIKit
import AudioToolbox

enum Feedback {

    /// Plays a success vibration plus a short system sound.
    static func sessionEnded() {
        // 1) Haptic (vibration) — felt only on a physical device.
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // 2) System sound — a built-in tone, no audio file needed.
        //    1322 is a gentle "complete" chime. Try 1007 or 1016 for alternatives.
        AudioServicesPlaySystemSound(1322)
    }
}
