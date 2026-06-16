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

This repo is a **ready-to-run Xcode project** — no setup, no dragging files.

```bash
git clone https://github.com/PhoenixUltra90/PomodoroTimerApp.git
cd PomodoroTimerApp
open PomodoroTimer.xcodeproj
```

Then in Xcode:

1. Pick a simulator (e.g. **iPhone 16**) from the device menu at the top.
2. Press **Run (⌘R)**.

To run on a real iPhone: select your device, then in the **PomodoroTimer** target ▸
**Signing & Capabilities**, set **Team** to your Apple ID and change
`PRODUCT_BUNDLE_IDENTIFIER` if needed.

> Haptics are only felt on a real device; the end-of-session sound also plays in
> the Simulator. The project targets **iOS 18.0+** and is built with **Xcode 16+**
> (uses the synchronized-folder project format).

## Possible future upgrades

- Local notifications when a session ends in the background
- Daily streaks and statistics
- Selectable color themes
- Home/Lock Screen widget (WidgetKit + Live Activity)
- iCloud sync of session history
