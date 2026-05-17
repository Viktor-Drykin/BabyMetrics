import Foundation
import Combine

@MainActor
final class SleepTrackerViewModel: ObservableObject {
    @Published private(set) var entries: [SleepEntry] = []
    @Published private(set) var activeSleepStart: Date?
    @Published private(set) var timerNow: Date = Date()

    private let useCases: SleepUseCases
    private let timer = ActiveSessionTimer()
    private var cancellables = Set<AnyCancellable>()

    init(useCases: SleepUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()
        activeSleepStart = useCases.getActiveSleepStart()

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.entries = $0
                self?.updateTimerState()
            }
            .store(in: &cancellables)

        useCases.observeActiveSleepStart()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.activeSleepStart = $0
                self?.updateTimerState()
            }
            .store(in: &cancellables)

        timer.$now
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.timerNow = $0
            }
            .store(in: &cancellables)

        updateTimerState()
    }

    var isSleeping: Bool {
        activeSleepStart != nil
    }

    var latestWakeDate: Date? {
        entries.filter { $0.endDate <= Date() }.map(\.endDate).max()
    }

    var activeSleepDurationText: String {
        guard let startDate = activeSleepStart else { return "0 хв" }
        return DurationTextFormatter.string(from: startDate, to: timerNow)
    }

    var awakeDurationText: String? {
        guard let latestWakeDate else { return nil }
        return DurationTextFormatter.string(from: latestWakeDate, to: timerNow)
    }

    func startSleep(at date: Date) {
        useCases.startSleep(date)
    }

    func stopSleep(at date: Date) {
        useCases.stopSleep(date)
    }

    func durationString(from startDate: Date, to endDate: Date) -> String {
        DurationTextFormatter.string(from: startDate, to: endDate)
    }

    private func updateTimerState() {
        let shouldRun = activeSleepStart != nil || latestWakeDate != nil
        timer.setIsRunning(shouldRun)
    }
}
