import Foundation
import Combine

@MainActor
final class UserDefaultsTummyTimeRepository: ObservableObject, TummyTimeRepository {
    @Published private(set) var entries: [TummyTimeEntry] = []
    @Published private(set) var activeTummyTimeStart: Date?

    var entriesPublisher: AnyPublisher<[TummyTimeEntry], Never> {
        $entries.eraseToAnyPublisher()
    }

    var activeTummyTimeStartPublisher: AnyPublisher<Date?, Never> {
        $activeTummyTimeStart.eraseToAnyPublisher()
    }

    private let entriesStorageKey: String
    private let activeTummyTimeStorageKey: String
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        entriesStorageKey: String = "tummy_time_entries",
        activeTummyTimeStorageKey: String = "tummy_time_active_start"
    ) {
        self.userDefaults = userDefaults
        self.entriesStorageKey = entriesStorageKey
        self.activeTummyTimeStorageKey = activeTummyTimeStorageKey
        loadEntries()
        loadActiveTummyTimeStart()
    }

    func currentEntries() -> [TummyTimeEntry] {
        entries
    }

    func currentActiveTummyTimeStart() -> Date? {
        activeTummyTimeStart
    }

    func startTummyTime(at date: Date) {
        guard activeTummyTimeStart == nil else { return }
        activeTummyTimeStart = date
        saveActiveTummyTimeStart()
    }

    func stopTummyTime(at date: Date) {
        guard let startDate = activeTummyTimeStart else { return }
        let endDate = max(date, startDate)
        guard endDate > startDate else { return }

        let entry = TummyTimeEntry(id: UUID(), startDate: startDate, endDate: endDate)
        entries.insert(entry, at: 0)
        entries.sort { $0.startDate > $1.startDate }
        activeTummyTimeStart = nil
        saveEntries()
        saveActiveTummyTimeStart()
    }

    func updateEntry(id: UUID, startDate: Date, endDate: Date) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].startDate = min(startDate, endDate)
        entries[index].endDate = max(startDate, endDate)
        entries.sort { $0.startDate > $1.startDate }
        saveEntries()
    }

    func deleteEntries(ids: [UUID]) {
        let idSet = Set(ids)
        entries.removeAll { idSet.contains($0.id) }
        saveEntries()
    }

    func replaceAllEntries(with newEntries: [TummyTimeEntry]) {
        entries = newEntries.sorted { $0.startDate > $1.startDate }
        saveEntries()
    }

    func csvContent(from entries: [TummyTimeEntry]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var rows = ["start_date,end_date,duration_minutes"]
        rows.append(contentsOf: entries.map {
            let durationMinutes = Int($0.duration / 60)
            return "\(formatter.string(from: $0.startDate)),\(formatter.string(from: $0.endDate)),\(durationMinutes)"
        })
        return rows.joined(separator: "\n")
    }

    private func loadEntries() {
        guard let data = userDefaults.data(forKey: entriesStorageKey) else {
            entries = []
            return
        }

        do {
            entries = try decoder.decode([TummyTimeEntry].self, from: data)
            entries.sort { $0.startDate > $1.startDate }
        } catch {
            entries = []
        }
    }

    private func loadActiveTummyTimeStart() {
        activeTummyTimeStart = userDefaults.object(forKey: activeTummyTimeStorageKey) as? Date
    }

    private func saveEntries() {
        do {
            let data = try encoder.encode(entries)
            userDefaults.set(data, forKey: entriesStorageKey)
        } catch {
            // Ignore save errors for now.
        }
    }

    private func saveActiveTummyTimeStart() {
        userDefaults.set(activeTummyTimeStart, forKey: activeTummyTimeStorageKey)
    }
}
