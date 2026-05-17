import Foundation
import Combine

@MainActor
final class UserDefaultsFeedingRepository: ObservableObject, FeedingRepository {
    @Published private(set) var entries: [FeedingEntry] = []
    @Published private(set) var activeFeedingStart: Date?
    @Published private(set) var activeFeedingSide: BreastSide?

    var entriesPublisher: AnyPublisher<[FeedingEntry], Never> {
        $entries.eraseToAnyPublisher()
    }

    var activeFeedingStartPublisher: AnyPublisher<Date?, Never> {
        $activeFeedingStart.eraseToAnyPublisher()
    }

    var activeFeedingSidePublisher: AnyPublisher<BreastSide?, Never> {
        $activeFeedingSide.eraseToAnyPublisher()
    }

    private let entriesStorageKey: String
    private let activeFeedingStorageKey: String
    private let activeFeedingSideStorageKey: String
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        entriesStorageKey: String = "feeding_entries",
        activeFeedingStorageKey: String = "feeding_active_start",
        activeFeedingSideStorageKey: String = "feeding_active_side"
    ) {
        self.userDefaults = userDefaults
        self.entriesStorageKey = entriesStorageKey
        self.activeFeedingStorageKey = activeFeedingStorageKey
        self.activeFeedingSideStorageKey = activeFeedingSideStorageKey
        loadEntries()
        loadActiveFeedingStart()
        loadActiveFeedingSide()
    }

    func currentEntries() -> [FeedingEntry] {
        entries
    }

    func currentActiveFeedingStart() -> Date? {
        activeFeedingStart
    }

    func currentActiveFeedingSide() -> BreastSide? {
        activeFeedingSide
    }

    func startFeeding(at date: Date, side: BreastSide) {
        guard activeFeedingStart == nil else { return }
        activeFeedingStart = date
        activeFeedingSide = side
        saveActiveFeedingStart()
        saveActiveFeedingSide()
    }

    func stopFeeding(at date: Date) {
        guard let startDate = activeFeedingStart, let side = activeFeedingSide else { return }
        addEntry(startDate: startDate, endDate: date, side: side)
        activeFeedingStart = nil
        activeFeedingSide = nil
        saveActiveFeedingStart()
        saveActiveFeedingSide()
    }

    func addEntry(startDate: Date, endDate: Date, side: BreastSide) {
        let entry = FeedingEntry(id: UUID(), startDate: startDate, endDate: endDate, side: side)
        entries.insert(entry, at: 0)
        entries.sort { $0.startDate > $1.startDate }
        saveEntries()
    }

    func updateEntry(id: UUID, startDate: Date, endDate: Date, side: BreastSide) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].startDate = min(startDate, endDate)
        entries[index].endDate = max(startDate, endDate)
        entries[index].side = side
        entries.sort { $0.startDate > $1.startDate }
        saveEntries()
    }

    func deleteEntries(ids: [UUID]) {
        let idSet = Set(ids)
        entries.removeAll { idSet.contains($0.id) }
        saveEntries()
    }

    func replaceAllEntries(with newEntries: [FeedingEntry]) {
        entries = newEntries.sorted { $0.startDate > $1.startDate }
        saveEntries()
    }

    func csvContent(from entries: [FeedingEntry]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var rows = ["start_date,end_date,duration_minutes,side"]
        rows.append(contentsOf: entries.map {
            let durationMinutes = Int($0.duration / 60)
            return "\(formatter.string(from: $0.startDate)),\(formatter.string(from: $0.endDate)),\(durationMinutes),\($0.side.rawValue)"
        })
        return rows.joined(separator: "\n")
    }

    private func loadEntries() {
        guard let data = userDefaults.data(forKey: entriesStorageKey) else {
            entries = []
            return
        }

        do {
            entries = try decoder.decode([FeedingEntry].self, from: data)
            entries.sort { $0.startDate > $1.startDate }
        } catch {
            entries = []
        }
    }

    private func loadActiveFeedingStart() {
        activeFeedingStart = userDefaults.object(forKey: activeFeedingStorageKey) as? Date
    }

    private func loadActiveFeedingSide() {
        guard let rawValue = userDefaults.string(forKey: activeFeedingSideStorageKey) else {
            activeFeedingSide = nil
            return
        }
        activeFeedingSide = BreastSide(rawValue: rawValue)
    }

    private func saveEntries() {
        do {
            let data = try encoder.encode(entries)
            userDefaults.set(data, forKey: entriesStorageKey)
        } catch {
            // Ignore save errors for now.
        }
    }

    private func saveActiveFeedingStart() {
        userDefaults.set(activeFeedingStart, forKey: activeFeedingStorageKey)
    }

    private func saveActiveFeedingSide() {
        userDefaults.set(activeFeedingSide?.rawValue, forKey: activeFeedingSideStorageKey)
    }
}
