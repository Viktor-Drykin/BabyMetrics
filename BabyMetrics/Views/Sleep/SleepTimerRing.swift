import SwiftUI

struct SleepTimerRing: View {
    let elapsed: TimeInterval
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.sleepLight, lineWidth: 6)
            Circle()
                .trim(from: 0, to: isActive ? min(elapsed / 3600, 1.0) : 0)
                .stroke(Color.moduleSleep, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: elapsed)
            VStack(spacing: 2) {
                Text(DurationFormatter.clock(elapsed))
                    .font(.title3).fontWeight(.semibold).monospacedDigit()
                    .foregroundStyle(Color.sleepDark)
                Text(isActive ? "sleeping" : "awake")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 160, height: 160)
        .accessibilityElement()
        .accessibilityLabel(Text(isActive ? "Sleeping" : "Not sleeping"))
        .accessibilityValue(Text(DurationFormatter.clock(elapsed)))
    }
}
