import Foundation
import Combine

@MainActor
final class RecordFeedingViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var selectedSide: BreastSide = .left
    @Published var showSavedMessage = false
    @Published private(set) var entries: [FeedingEntry] = []
    @Published private(set) var activeFeedingStart: Date?
    @Published private(set) var activeFeedingSide: BreastSide?
    @Published private(set) var timerNow: Date = Date()

    private let useCases: FeedingUseCases
    private let timer = ActiveSessionTimer()
    private var cancellables = Set<AnyCancellable>()

    init(useCases: FeedingUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()
        activeFeedingStart = useCases.getActiveFeedingStart()
        activeFeedingSide = useCases.getActiveFeedingSide()
        selectedSide = suggestedSide(from: entries)
        timer.setIsRunning(activeFeedingStart != nil)

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.entries = $0
                guard let self else { return }
                if self.activeFeedingStart == nil {
                    self.selectedSide = self.suggestedSide(from: $0)
                }
            }
            .store(in: &cancellables)

        useCases.observeActiveFeedingStart()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.activeFeedingStart = $0
                self?.timer.setIsRunning($0 != nil)
            }
            .store(in: &cancellables)

        useCases.observeActiveFeedingSide()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.activeFeedingSide = $0
            }
            .store(in: &cancellables)

        timer.$now
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.timerNow = $0
            }
            .store(in: &cancellables)
    }

    var isFeeding: Bool {
        activeFeedingStart != nil
    }

    var lastFeedingDate: Date? {
        let now = Date()
        return entries
            .map(\.endDate)
            .filter { $0 <= now }
            .max()
    }

    var hasFutureFeedingEntries: Bool {
        let now = Date()
        return entries.contains { $0.startDate > now || $0.endDate > now }
    }

    var shouldShowLastFeedingInfo: Bool {
        !isFeeding && !hasFutureFeedingEntries && lastFeedingDate != nil
    }

    var activeFeedingDurationText: String {
        guard let startDate = activeFeedingStart else { return "0 хв" }
        return DurationTextFormatter.string(from: startDate, to: timerNow)
    }

    func onAppear() {
        selectedDate = Date()
        if !isFeeding {
            selectedSide = suggestedSide(from: entries)
        }
    }

    func onSceneBecameActive() {
        selectedDate = Date()
        if !isFeeding {
            selectedSide = suggestedSide(from: entries)
        }
    }

    func startFeeding(at customTime: Date?) {
        guard !isFeeding else { return }

        let startDate: Date
        if let customTime {
            startDate = todayDate(withTimeFrom: customTime)
        } else {
            startDate = Date()
        }

        useCases.startFeeding(startDate, selectedSide)
    }

    func stopFeeding() {
        guard isFeeding else { return }
        useCases.stopFeeding(Date())
        selectedSide = opposite(of: selectedSide)
        selectedDate = Date()
        showSavedMessage = true
    }

    func hideSavedMessage() {
        showSavedMessage = false
    }

    func timeSinceString(from date: Date, to now: Date) -> String {
        DurationTextFormatter.string(from: date, to: now)
    }

    func timeSinceMinutesString(from date: Date, to now: Date) -> String {
        DurationTextFormatter.stringWithoutSeconds(from: date, to: now)
    }

    private func todayDate(withTimeFrom date: Date) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        todayComponents.hour = timeComponents.hour
        todayComponents.minute = timeComponents.minute
        todayComponents.second = timeComponents.second ?? calendar.component(.second, from: now)
        return calendar.date(from: todayComponents) ?? now
    }

    private func suggestedSide(from entries: [FeedingEntry]) -> BreastSide {
        guard let latestEntry = entries.max(by: { $0.endDate < $1.endDate }) else {
            return .left
        }
        return opposite(of: latestEntry.side)
    }

    private func opposite(of side: BreastSide) -> BreastSide {
        side == .left ? .right : .left
    }
}
