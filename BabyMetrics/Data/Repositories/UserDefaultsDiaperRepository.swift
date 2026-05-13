import Foundation
import Combine

@MainActor
final class UserDefaultsDiaperRepository: ObservableObject, DiaperRepository {
    @Published private(set) var entries: [DiaperEntry] = []

    var entriesPublisher: AnyPublisher<[DiaperEntry], Never> {
        $entries.eraseToAnyPublisher()
    }

    private let storageKey: String
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "diaper_entries"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        loadEntries()
    }

    func currentEntries() -> [DiaperEntry] { entries }

    func addEntry(date: Date, type: DiaperType, weightGrams: Int?) {
        let entry = DiaperEntry(id: UUID(), date: date, type: type, weightGrams: weightGrams)
        entries.insert(entry, at: 0)
        entries.sort { $0.date > $1.date }
        saveEntries()
    }

    func updateEntry(id: UUID, date: Date, type: DiaperType, weightGrams: Int?) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].date = date
        entries[index].type = type
        entries[index].weightGrams = weightGrams
        entries.sort { $0.date > $1.date }
        saveEntries()
    }

    func deleteEntries(ids: [UUID]) {
        let idSet = Set(ids)
        entries.removeAll { idSet.contains($0.id) }
        saveEntries()
    }

    func replaceAllEntries(with newEntries: [DiaperEntry]) {
        entries = newEntries.sorted { $0.date > $1.date }
        saveEntries()
    }

    func csvContent(from entries: [DiaperEntry]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var rows = ["date,type,weight_g"]
        rows.append(contentsOf: entries.map {
            let weight = $0.weightGrams.map { "\($0)" } ?? ""
            return "\(formatter.string(from: $0.date)),\($0.type.rawValue),\(weight)"
        })
        return rows.joined(separator: "\n")
    }

    private func loadEntries() {
        guard let data = userDefaults.data(forKey: storageKey) else { entries = []; return }
        do {
            entries = try decoder.decode([DiaperEntry].self, from: data)
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
