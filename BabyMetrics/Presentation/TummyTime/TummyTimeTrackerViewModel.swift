import Foundation
import Combine

@MainActor
final class TummyTimeTrackerViewModel: ObservableObject {
    @Published private(set) var entries: [TummyTimeEntry] = []
    @Published private(set) var activeTummyTimeStart: Date?
    @Published private(set) var timerNow: Date = Date()

    private let useCases: TummyTimeUseCases
    private let timer = ActiveSessionTimer()
    private var cancellables = Set<AnyCancellable>()

    init(useCases: TummyTimeUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()
        activeTummyTimeStart = useCases.getActiveTummyTimeStart()

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.entries = $0
                self?.updateTimerState()
            }
            .store(in: &cancellables)

        useCases.observeActiveTummyTimeStart()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.activeTummyTimeStart = $0
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

    var isTummyTimeActive: Bool {
        activeTummyTimeStart != nil
    }

    var latestTummyTimeEndDate: Date? {
        entries.filter { $0.endDate <= Date() }.map(\.endDate).max()
    }

    var activeDurationText: String {
        guard let start = activeTummyTimeStart else { return "0 хв" }
        return DurationTextFormatter.string(from: start, to: timerNow)
    }

    var sinceLastSessionText: String? {
        guard let latestEnd = latestTummyTimeEndDate else { return nil }
        return DurationTextFormatter.stringWithoutSeconds(from: latestEnd, to: timerNow)
    }

    func startTummyTime(at date: Date) {
        useCases.startTummyTime(date)
    }

    func stopTummyTime(at date: Date) {
        useCases.stopTummyTime(date)
    }

    func durationString(from startDate: Date, to endDate: Date) -> String {
        DurationTextFormatter.string(from: startDate, to: endDate)
    }

    private func updateTimerState() {
        let shouldRun = activeTummyTimeStart != nil || latestTummyTimeEndDate != nil
        timer.setIsRunning(shouldRun)
    }
}
