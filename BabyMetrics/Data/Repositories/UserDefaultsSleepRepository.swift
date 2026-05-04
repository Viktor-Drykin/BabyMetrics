import Foundation
import Combine

@MainActor
final class UserDefaultsSleepRepository: ObservableObject, SleepRepository {
    @Published private(set) var entries: [SleepEntry] = []
    @Published private(set) var activeSleepStart: Date?

    var entriesPublisher: AnyPublisher<[SleepEntry], Never> {
        $entries.eraseToAnyPublisher()
    }

    var activeSleepStartPublisher: AnyPublisher<Date?, Never> {
        $activeSleepStart.eraseToAnyPublisher()
    }

    private let entriesStorageKey: String
    private let activeSleepStorageKey: String
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        entriesStorageKey: String = "sleep_entries",
        activeSleepStorageKey: String = "sleep_active_start"
    ) {
        self.userDefaults = userDefaults
        self.entriesStorageKey = entriesStorageKey
        self.activeSleepStorageKey = activeSleepStorageKey
        loadEntries()
        loadActiveSleepStart()
    }

    func currentEntries() -> [SleepEntry] {
        entries
    }

    func currentActiveSleepStart() -> Date? {
        activeSleepStart
    }

    func startSleep(at date: Date) {
        guard activeSleepStart == nil else { return }
        activeSleepStart = date
        saveActiveSleepStart()
    }

    func stopSleep(at date: Date) {
        guard let startDate = activeSleepStart else { return }
        let endDate = max(date, startDate)
        let entry = SleepEntry(id: UUID(), startDate: startDate, endDate: endDate)
        entries.insert(entry, at: 0)
        entries.sort { $0.startDate > $1.startDate }
        activeSleepStart = nil
        saveEntries()
        saveActiveSleepStart()
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

    func replaceAllEntries(with newEntries: [SleepEntry]) {
        entries = newEntries.sorted { $0.startDate > $1.startDate }
        saveEntries()
    }

    func csvContent(from entries: [SleepEntry]) -> String {
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
            entries = try decoder.decode([SleepEntry].self, from: data)
        } catch {
            entries = []
        }
    }

    private func loadActiveSleepStart() {
        activeSleepStart = userDefaults.object(forKey: activeSleepStorageKey) as? Date
    }

    private func saveEntries() {
        do {
            let data = try encoder.encode(entries)
            userDefaults.set(data, forKey: entriesStorageKey)
        } catch {
            // Ignore save errors for now.
        }
    }

    private func saveActiveSleepStart() {
        userDefaults.set(activeSleepStart, forKey: activeSleepStorageKey)
    }
}
