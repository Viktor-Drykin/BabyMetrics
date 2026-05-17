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
        let diaperCount: Int
        let totalDiaperWeightGrams: Int
        let tummyTimeCount: Int
        let totalTummyTimeDuration: TimeInterval

        var id: String { "\(date.timeIntervalSince1970)" }
    }

    struct EventItem: Identifiable {
        enum Kind {
            case feeding(side: BreastSide, duration: TimeInterval)
            case sleep(startDate: Date, endDate: Date)
            case diaper(type: DiaperType, weightGrams: Int?)
            case tummyTime(startDate: Date, endDate: Date)
        }

        let id: String
        let date: Date
        let kind: Kind
    }

    @Published private(set) var events: [EventItem] = []

    private let feedingUseCases: FeedingUseCases
    private let sleepUseCases: SleepUseCases
    private let diaperUseCases: DiaperUseCases
    private let tummyTimeUseCases: TummyTimeUseCases
    private var cancellables = Set<AnyCancellable>()

    init(feedingUseCases: FeedingUseCases, sleepUseCases: SleepUseCases, diaperUseCases: DiaperUseCases, tummyTimeUseCases: TummyTimeUseCases) {
        self.feedingUseCases = feedingUseCases
        self.sleepUseCases = sleepUseCases
        self.diaperUseCases = diaperUseCases
        self.tummyTimeUseCases = tummyTimeUseCases

        rebuildEvents(
            feedingEntries: feedingUseCases.getEntries(),
            sleepEntries: sleepUseCases.getEntries(),
            diaperEntries: diaperUseCases.getEntries(),
            tummyTimeEntries: tummyTimeUseCases.getEntries()
        )

        Publishers.CombineLatest4(
            feedingUseCases.observeEntries(),
            sleepUseCases.observeEntries(),
            diaperUseCases.observeEntries(),
            tummyTimeUseCases.observeEntries()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] feedingEntries, sleepEntries, diaperEntries, tummyTimeEntries in
            self?.rebuildEvents(feedingEntries: feedingEntries, sleepEntries: sleepEntries, diaperEntries: diaperEntries, tummyTimeEntries: tummyTimeEntries)
        }
        .store(in: &cancellables)
    }

    func durationString(from startDate: Date, to endDate: Date) -> String {
        DurationTextFormatter.string(from: startDate, to: endDate)
    }

    func durationString(fromSeconds seconds: Int) -> String {
        DurationTextFormatter.string(fromSeconds: seconds)
    }

    var daySections: [DaySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) {
            calendar.startOfDay(for: $0.date)
        }

        return grouped
            .map { day, dayEvents in
                var feedingCount = 0
                var sleepCount = 0
                var diaperCount = 0
                var tummyTimeCount = 0
                var totalDiaperWeightGrams = 0
                var totalSleepDuration: TimeInterval = 0
                var totalTummyTimeDuration: TimeInterval = 0
                for event in dayEvents {
                    switch event.kind {
                    case .feeding:
                        feedingCount += 1
                    case .sleep(let startDate, let endDate):
                        sleepCount += 1
                        totalSleepDuration += max(0, endDate.timeIntervalSince(startDate))
                    case .diaper(_, let weightGrams):
                        diaperCount += 1
                        totalDiaperWeightGrams += max(0, weightGrams ?? 0)
                    case .tummyTime(let startDate, let endDate):
                        tummyTimeCount += 1
                        totalTummyTimeDuration += max(0, endDate.timeIntervalSince(startDate))
                    }
                }

                return DaySection(
                    date: day,
                    events: dayEvents.sorted { $0.date > $1.date },
                    feedingCount: feedingCount,
                    sleepCount: sleepCount,
                    totalSleepDuration: totalSleepDuration,
                    diaperCount: diaperCount,
                    totalDiaperWeightGrams: totalDiaperWeightGrams,
                    tummyTimeCount: tummyTimeCount,
                    totalTummyTimeDuration: totalTummyTimeDuration
                )
            }
            .sorted { $0.date > $1.date }
    }

    private func rebuildEvents(feedingEntries: [FeedingEntry], sleepEntries: [SleepEntry], diaperEntries: [DiaperEntry], tummyTimeEntries: [TummyTimeEntry]) {
        let feedingItems = feedingEntries.map {
            EventItem(
                id: "feeding-\($0.id.uuidString)",
                date: $0.startDate,
                kind: .feeding(side: $0.side, duration: $0.duration)
            )
        }

        let sleepItems = sleepEntries.flatMap { entry -> [EventItem] in
            let calendar = Calendar.current
            var segments: [EventItem] = []
            var segmentStart = entry.startDate
            var index = 0
            while segmentStart < entry.endDate {
                let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: segmentStart))!
                let segmentEnd = min(entry.endDate, nextMidnight)
                segments.append(EventItem(
                    id: "sleep-\(entry.id.uuidString)-\(index)",
                    date: segmentStart,
                    kind: .sleep(startDate: segmentStart, endDate: segmentEnd)
                ))
                segmentStart = segmentEnd
                index += 1
            }
            return segments
        }

        let diaperItems = diaperEntries.map {
            EventItem(
                id: "diaper-\($0.id.uuidString)",
                date: $0.date,
                kind: .diaper(type: $0.type, weightGrams: $0.weightGrams)
            )
        }

        let tummyTimeItems = tummyTimeEntries.flatMap { entry -> [EventItem] in
            let calendar = Calendar.current
            var segments: [EventItem] = []
            var segmentStart = entry.startDate
            var index = 0
            while segmentStart < entry.endDate {
                let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: segmentStart))!
                let segmentEnd = min(entry.endDate, nextMidnight)
                segments.append(EventItem(
                    id: "tummy-\(entry.id.uuidString)-\(index)",
                    date: segmentStart,
                    kind: .tummyTime(startDate: segmentStart, endDate: segmentEnd)
                ))
                segmentStart = segmentEnd
                index += 1
            }
            return segments
        }

        events = (feedingItems + sleepItems + diaperItems + tummyTimeItems).sorted { $0.date > $1.date }
    }
}
