//
//  ProgressRingView.swift
//  PomodoroTimer
//
//  A reusable circular progress ring. It draws a faint full circle in the
//  background and a colored arc on top that grows as `progress` goes 0 -> 1.
//  Kept in its own file so the main screen stays easy to read.
//

import SwiftUI

struct ProgressRingView: View {
    /// How full the ring is, from 0.0 (empty) to 1.0 (complete).
    var progress: Double
    /// The ring's color (usually the current mode's accent color).
    var color: Color
    /// Thickness of the ring.
    var lineWidth: CGFloat = 16

    var body: some View {
        ZStack {
            // Faint background track.
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            // Foreground arc that fills up over time.
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                // Start the arc at the top (12 o'clock) instead of the right side.
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)
        }
    }
}

#Preview {
    ProgressRingView(progress: 0.35, color: .red)
        .frame(width: 200, height: 200)
        .padding()
}
