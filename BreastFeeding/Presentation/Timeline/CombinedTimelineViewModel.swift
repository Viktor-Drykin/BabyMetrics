import Foundation
import Combine

@MainActor
final class CombinedTimelineViewModel: ObservableObject {
    struct DaySection: Identifiable {
        let date: Date
        let events: [EventItem]
        let feedingCount: Int
        let sleepCount: Int
        let totalSleepDuration: TimeInterval

        var id: String { "\(date.timeIntervalSince1970)" }
    }

    struct EventItem: Identifiable {
        enum Kind {
            case feeding(side: BreastSide)
            case sleep(startDate: Date, endDate: Date)
        }

        let id: String
        let date: Date
        let kind: Kind
    }

    @Published private(set) var events: [EventItem] = []

    private let feedingUseCases: FeedingUseCases
    private let sleepUseCases: SleepUseCases
    private var cancellables = Set<AnyCancellable>()

    init(feedingUseCases: FeedingUseCases, sleepUseCases: SleepUseCases) {
        self.feedingUseCases = feedingUseCases
        self.sleepUseCases = sleepUseCases

        rebuildEvents(
            feedingEntries: feedingUseCases.getEntries(),
            sleepEntries: sleepUseCases.getEntries()
        )

        Publishers.CombineLatest(
            feedingUseCases.observeEntries(),
            sleepUseCases.observeEntries()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] feedingEntries, sleepEntries in
            self?.rebuildEvents(feedingEntries: feedingEntries, sleepEntries: sleepEntries)
        }
        .store(in: &cancellables)
    }

    func durationString(from startDate: Date, to endDate: Date) -> String {
        let seconds = max(0, Int(endDate.timeIntervalSince(startDate)))
        return durationString(fromSeconds: seconds)
    }

    func durationString(fromSeconds seconds: Int) -> String {
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days) д") }
        if hours > 0 { parts.append("\(hours) год") }
        if minutes > 0 || parts.isEmpty { parts.append("\(minutes) хв") }
        return parts.joined(separator: " ")
    }

    var daySections: [DaySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) {
            calendar.startOfDay(for: $0.date)
        }

        return grouped
            .map { day, dayEvents in
                let feedingCount = dayEvents.reduce(into: 0) { partialResult, event in
                    if case .feeding = event.kind {
                        partialResult += 1
                    }
                }

                var sleepCount = 0
                var totalSleepDuration: TimeInterval = 0
                for event in dayEvents {
                    if case .sleep(let startDate, let endDate) = event.kind {
                        sleepCount += 1
                        totalSleepDuration += max(0, endDate.timeIntervalSince(startDate))
                    }
                }

                return DaySection(
                    date: day,
                    events: dayEvents.sorted { $0.date > $1.date },
                    feedingCount: feedingCount,
                    sleepCount: sleepCount,
                    totalSleepDuration: totalSleepDuration
                )
            }
            .sorted { $0.date > $1.date }
    }

    private func rebuildEvents(feedingEntries: [FeedingEntry], sleepEntries: [SleepEntry]) {
        let feedingItems = feedingEntries.map {
            EventItem(
                id: "feeding-\($0.id.uuidString)",
                date: $0.date,
                kind: .feeding(side: $0.side)
            )
        }

        let sleepItems = sleepEntries.map {
            EventItem(
                id: "sleep-\($0.id.uuidString)",
                date: $0.startDate,
                kind: .sleep(startDate: $0.startDate, endDate: $0.endDate)
            )
        }

        events = (feedingItems + sleepItems).sorted { $0.date > $1.date }
    }
}
