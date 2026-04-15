import Foundation
import Combine

@MainActor
final class UserDefaultsFeedingRepository: ObservableObject, FeedingRepository {
    @Published private(set) var entries: [FeedingEntry] = []

    var entriesPublisher: AnyPublisher<[FeedingEntry], Never> {
        $entries.eraseToAnyPublisher()
    }

    private let storageKey: String
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "feeding_entries"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        loadEntries()
    }

    func currentEntries() -> [FeedingEntry] {
        entries
    }

    func addEntry(date: Date, side: BreastSide) {
        let entry = FeedingEntry(id: UUID(), date: date, side: side)
        entries.insert(entry, at: 0)
        saveEntries()
    }

    func updateEntry(id: UUID, date: Date, side: BreastSide) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].date = date
        entries[index].side = side
        saveEntries()
    }

    func deleteEntries(ids: [UUID]) {
        let idSet = Set(ids)
        entries.removeAll { idSet.contains($0.id) }
        saveEntries()
    }

    func replaceAllEntries(with newEntries: [FeedingEntry]) {
        entries = newEntries.sorted { $0.date > $1.date }
        saveEntries()
    }

    func csvContent(from entries: [FeedingEntry]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var rows = ["date,side"]
        rows.append(contentsOf: entries.map { "\(formatter.string(from: $0.date)),\($0.side.rawValue)" })
        return rows.joined(separator: "\n")
    }

    private func loadEntries() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            entries = []
            return
        }

        do {
            entries = try decoder.decode([FeedingEntry].self, from: data)
        } catch {
            entries = []
        }
    }

    private func saveEntries() {
        do {
            let data = try encoder.encode(entries)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            // Ignore save errors for now.
        }
    }
}
