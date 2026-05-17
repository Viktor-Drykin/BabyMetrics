import Foundation
import Combine

protocol TummyTimeRepository {
    var entriesPublisher: AnyPublisher<[TummyTimeEntry], Never> { get }
    var activeTummyTimeStartPublisher: AnyPublisher<Date?, Never> { get }

    func currentEntries() -> [TummyTimeEntry]
    func currentActiveTummyTimeStart() -> Date?
    func startTummyTime(at date: Date)
    func stopTummyTime(at date: Date)
    func updateEntry(id: UUID, startDate: Date, endDate: Date)
    func deleteEntries(ids: [UUID])
    func replaceAllEntries(with newEntries: [TummyTimeEntry])
    func csvContent(from entries: [TummyTimeEntry]) -> String
}
