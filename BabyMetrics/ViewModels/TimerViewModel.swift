import Foundation
import Observation

/// Reusable elapsed-time timer for any active session (sleep, feeding, activities).
/// The owning view persists the session's `startTime` separately so a background kill
/// never loses data; this object only drives the live readout.
@MainActor
@Observable
final class TimerViewModel {
    private(set) var startTime: Date?
    private(set) var elapsed: TimeInterval = 0
    @ObservationIgnored private var timer: Timer?

    var isRunning: Bool { startTime != nil }

    /// Starts (or resumes) ticking from the given start time.
    func start(at date: Date = .now) {
        startTime = date
        tick()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    /// Resumes a persisted session if one exists (called on appear / launch).
    func resume(from date: Date?) {
        guard let date, !isRunning else { return }
        start(at: date)
    }

    func pause() {
        timer?.invalidate()
        timer = nil
    }

    /// Stops the timer and returns the final elapsed interval.
    @discardableResult
    func stop() -> TimeInterval {
        let result = elapsed
        pause()
        startTime = nil
        elapsed = 0
        return result
    }

    private func tick() {
        guard let startTime else { return }
        elapsed = max(0, Date.now.timeIntervalSince(startTime))
    }
}
