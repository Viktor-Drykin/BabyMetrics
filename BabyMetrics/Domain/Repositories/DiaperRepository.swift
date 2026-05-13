import Foundation
import Combine

protocol DiaperRepository {
    var entriesPublisher: AnyPublisher<[DiaperEntry], Never> { get }

    func currentEntries() -> [DiaperEntry]
    func addEntry(date: Date, type: DiaperType, weightGrams: Int?)
    func updateEntry(id: UUID, date: Date, type: DiaperType, weightGrams: Int?)
    func deleteEntries(ids: [UUID])
    func replaceAllEntries(with entries: [DiaperEntry])
    func csvContent(from entries: [DiaperEntry]) -> String
}
