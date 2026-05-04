import Foundation
import Combine

protocol GrowthRepository {
    var entriesPublisher: AnyPublisher<[GrowthEntry], Never> { get }

    func currentEntries() -> [GrowthEntry]
    func addEntry(_ entry: GrowthEntry)
    func updateEntry(id: UUID, date: Date, weightKg: Double?, heightCm: Double?, headCm: Double?)
    func deleteEntries(ids: [UUID])
    func replaceAllEntries(with entries: [GrowthEntry])
}
