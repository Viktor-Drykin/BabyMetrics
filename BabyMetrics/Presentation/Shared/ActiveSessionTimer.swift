import Foundation
import Combine

@MainActor
final class ActiveSessionTimer: ObservableObject {
    @Published private(set) var now: Date = Date()

    private let interval: TimeInterval
    private var timerCancellable: AnyCancellable?

    init(interval: TimeInterval = 1) {
        self.interval = interval
    }

    func setIsRunning(_ isRunning: Bool) {
        if isRunning {
            start()
        } else {
            stop()
        }
    }

    deinit {
        timerCancellable?.cancel()
    }

    private func start() {
        guard timerCancellable == nil else { return }
        now = Date()
        timerCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] value in
                self?.now = value
            }
    }

    private func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
        now = Date()
    }
}

enum DurationTextFormatter {
    static func string(from startDate: Date, to endDate: Date) -> String {
        let seconds = max(0, Int(endDate.timeIntervalSince(startDate)))
        return string(fromSeconds: seconds)
    }

    static func stringWithoutSeconds(from startDate: Date, to endDate: Date) -> String {
        let seconds = max(0, Int(endDate.timeIntervalSince(startDate)))
        return stringWithoutSeconds(fromSeconds: seconds)
    }

    static func string(fromSeconds seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        let days = safeSeconds / 86_400
        let hours = (safeSeconds % 86_400) / 3_600
        let minutes = (safeSeconds % 3_600) / 60
        let remainingSeconds = safeSeconds % 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days) д") }
        if hours > 0 { parts.append("\(hours) год") }
        if minutes > 0 || days > 0 || hours > 0 { parts.append("\(minutes) хв") }
        parts.append("\(remainingSeconds) с")
        return parts.joined(separator: " ")
    }

    static func stringWithoutSeconds(fromSeconds seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        let days = safeSeconds / 86_400
        let hours = (safeSeconds % 86_400) / 3_600
        let minutes = (safeSeconds % 3_600) / 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days) д") }
        if hours > 0 { parts.append("\(hours) год") }
        parts.append("\(minutes) хв")
        return parts.joined(separator: " ")
    }
}
