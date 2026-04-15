import Foundation
import Combine

@MainActor
final class BabyStatusDashboardViewModel: ObservableObject {
    @Published private(set) var lastFeedingDate: Date?
    @Published private(set) var activeSleepStart: Date?
    @Published private(set) var latestWakeDate: Date?

    private var cancellables = Set<AnyCancellable>()

    init(feedingUseCases: FeedingUseCases, sleepUseCases: SleepUseCases) {
        let feedingEntries = feedingUseCases.getEntries()
        lastFeedingDate = feedingEntries.map(\.date).max()

        let sleepEntries = sleepUseCases.getEntries()
        latestWakeDate = sleepEntries.map(\.endDate).max()
        activeSleepStart = sleepUseCases.getActiveSleepStart()

        feedingUseCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.lastFeedingDate = entries.map(\.date).max()
            }
            .store(in: &cancellables)

        sleepUseCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.latestWakeDate = entries.map(\.endDate).max()
            }
            .store(in: &cancellables)

        sleepUseCases.observeActiveSleepStart()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.activeSleepStart = $0
            }
            .store(in: &cancellables)
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
