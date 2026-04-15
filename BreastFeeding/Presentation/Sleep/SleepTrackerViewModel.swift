import Foundation
import Combine

@MainActor
final class SleepTrackerViewModel: ObservableObject {
    @Published private(set) var entries: [SleepEntry] = []
    @Published private(set) var activeSleepStart: Date?

    private let useCases: SleepUseCases
    private var cancellables = Set<AnyCancellable>()

    init(useCases: SleepUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()
        activeSleepStart = useCases.getActiveSleepStart()

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.entries = $0
            }
            .store(in: &cancellables)

        useCases.observeActiveSleepStart()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.activeSleepStart = $0
            }
            .store(in: &cancellables)
    }

    var isSleeping: Bool {
        activeSleepStart != nil
    }

    var latestWakeDate: Date? {
        entries.map(\.endDate).max()
    }

    func startSleepNow() {
        useCases.startSleep(Date())
    }

    func stopSleepNow() {
        useCases.stopSleep(Date())
    }

    func durationString(from startDate: Date, to endDate: Date) -> String {
        let seconds = max(0, Int(endDate.timeIntervalSince(startDate)))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days) д") }
        if hours > 0 { parts.append("\(hours) год") }
        if minutes > 0 || parts.isEmpty { parts.append("\(minutes) хв") }
        return parts.joined(separator: " ")
    }
}
