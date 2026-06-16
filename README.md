# PomodoroTimer

A clean, modern Pomodoro timer app for iPhone, built with **Swift** and **SwiftUI**
using the **MVVM** pattern. Helps you focus with timed work sessions, short breaks,
and long breaks.

## Features

- Circular progress ring with a large **MM:SS** countdown
- Three modes: **Focus**, **Short Break**, **Long Break**
- **Start / Pause / Reset / Skip** controls
- Session counter (e.g. *Pomodoro 1 of 4*)
- Automatic mode switching — long break after every *N* focus sessions
- Haptic + system-sound feedback when a session ends
- **Settings** (saved with `UserDefaults`):
  - Focus, short-break, and long-break lengths
  - Focus sessions before a long break
  - Auto-start next session (off by default)
  - Reset to defaults
- Works in light and dark mode

## Project structure

| File | Responsibility |
|------|----------------|
| `PomodoroTimerApp.swift` | App entry point; creates the shared `TimerViewModel`. |
| `TimerMode.swift` | The three modes and their title, icon, and color. |
| `TimerViewModel.swift` | All timer logic and saved settings (the MVVM "brain"). |
| `ProgressRingView.swift` | Reusable circular progress ring. |
| `ContentView.swift` | Main timer screen (display + buttons only). |
| `SettingsView.swift` | Settings form. |
| `Haptics.swift` | End-of-session haptic + sound helper. |

## Getting started

1. In Xcode: **File ▸ New ▸ Project… ▸ iOS ▸ App**. Name it `PomodoroTimer`,
   Interface **SwiftUI**, Language **Swift**.
2. Delete the auto-generated `PomodoroTimerApp.swift` and `ContentView.swift`.
3. Drag all the `.swift` files from this repo into the Xcode project navigator,
   checking **"Copy items if needed"** and the **PomodoroTimer** target.
4. Pick a simulator (e.g. iPhone 15) and press **Run (⌘R)**.

> Note: this repository contains the Swift source files. Create the Xcode project
> as above and add these files to it. Haptics are only felt on a real device; the
> sound also plays in the Simulator.

## Possible future upgrades

- Local notifications when a session ends in the background
- Daily streaks and statistics
- Selectable color themes
- Home/Lock Screen widget (WidgetKit + Live Activity)
- iCloud sync of session history
