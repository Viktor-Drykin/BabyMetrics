import Foundation
import Combine

@MainActor
final class UserDefaultsGrowthRepository: ObservableObject, GrowthRepository {
    @Published private(set) var entries: [GrowthEntry] = []

    var entriesPublisher: AnyPublisher<[GrowthEntry], Never> {
        $entries.eraseToAnyPublisher()
    }

    private let storageKey: String
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "growth_entries"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        loadEntries()
    }

    func currentEntries() -> [GrowthEntry] {
        entries
    }

    func addEntry(_ entry: GrowthEntry) {
        entries.insert(entry, at: 0)
        entries.sort { $0.date > $1.date }
        saveEntries()
    }

    func updateEntry(id: UUID, date: Date, weightKg: Double?, heightCm: Double?, headCm: Double?) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].date = date
        entries[index].weightKg = weightKg
        entries[index].heightCm = heightCm
        entries[index].headCm = headCm
        entries.sort { $0.date > $1.date }
        saveEntries()
    }

    func deleteEntries(ids: [UUID]) {
        let idSet = Set(ids)
        entries.removeAll { idSet.contains($0.id) }
        saveEntries()
    }

    func replaceAllEntries(with newEntries: [GrowthEntry]) {
        entries = newEntries.sorted { $0.date > $1.date }
        saveEntries()
    }

    private func loadEntries() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            entries = []
            return
        }
        do {
            entries = try decoder.decode([GrowthEntry].self, from: data)
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
