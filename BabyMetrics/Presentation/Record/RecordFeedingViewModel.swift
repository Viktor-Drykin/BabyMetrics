import Foundation
import Combine

@MainActor
final class RecordFeedingViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var selectedSide: BreastSide = .left
    @Published var showSavedMessage = false
    @Published private(set) var entries: [FeedingEntry] = []

    private let useCases: FeedingUseCases
    private var cancellables = Set<AnyCancellable>()

    init(useCases: FeedingUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()
        selectedSide = suggestedSide(from: entries)

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.entries = $0
                self?.selectedSide = self?.suggestedSide(from: $0) ?? .left
            }
            .store(in: &cancellables)
    }

    var lastFeedingDate: Date? {
        let now = Date()
        return entries
            .map(\.date)
            .filter { $0 <= now }
            .max()
    }

    func onAppear() {
        selectedDate = Date()
        selectedSide = suggestedSide(from: entries)
    }

    func onSceneBecameActive() {
        selectedDate = Date()
        selectedSide = suggestedSide(from: entries)
    }

    func saveFeeding() {
        useCases.addEntry(todayDate(withTimeFrom: selectedDate), selectedSide)
        selectedSide = opposite(of: selectedSide)
        selectedDate = Date()
        showSavedMessage = true
    }

    func hideSavedMessage() {
        showSavedMessage = false
    }

    func timeSinceString(from date: Date, to now: Date) -> String {
        let calendar = Calendar.current
        let safeNow = max(now, date)
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: safeNow)
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        var parts: [String] = []
        if days > 0 { parts.append("\(days) д") }
        if hours > 0 { parts.append("\(hours) год") }
        if minutes > 0 || parts.isEmpty { parts.append("\(minutes) хв") }
        return parts.joined(separator: " ")
    }

    private func todayDate(withTimeFrom date: Date) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        todayComponents.hour = timeComponents.hour
        todayComponents.minute = timeComponents.minute
        todayComponents.second = 0
        return calendar.date(from: todayComponents) ?? now
    }

    private func suggestedSide(from entries: [FeedingEntry]) -> BreastSide {
        guard let latestEntry = entries.max(by: { $0.date < $1.date }) else {
            return .left
        }
        return opposite(of: latestEntry.side)
    }

    private func opposite(of side: BreastSide) -> BreastSide {
        side == .left ? .right : .left
    }
}
