//
//  TimerMode.swift
//  PomodoroTimer
//
//  Describes the three kinds of sessions the timer can be in.
//  Each mode knows its own display title, SF Symbol icon, and accent color,
//  which keeps the view code clean and consistent.
//

import SwiftUI

enum TimerMode {
    case focus
    case shortBreak
    case longBreak

    /// Human-readable label shown on the main screen.
    var title: String {
        switch self {
        case .focus:      return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }

    /// SF Symbol name used next to the title.
    var iconName: String {
        switch self {
        case .focus:      return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "bed.double.fill"
        }
    }

    /// Accent color used for the ring and buttons in this mode.
    var accentColor: Color {
        switch self {
        case .focus:      return .red
        case .shortBreak: return .green
        case .longBreak:  return .blue
        }
    }
}
