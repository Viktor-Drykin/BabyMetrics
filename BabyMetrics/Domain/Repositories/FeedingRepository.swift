import Foundation
import Combine

protocol FeedingRepository {
    var entriesPublisher: AnyPublisher<[FeedingEntry], Never> { get }

    func currentEntries() -> [FeedingEntry]
    func addEntry(date: Date, side: BreastSide)
    func updateEntry(id: UUID, date: Date, side: BreastSide)
    func deleteEntries(ids: [UUID])
    func replaceAllEntries(with newEntries: [FeedingEntry])
    func csvContent(from entries: [FeedingEntry]) -> String
}
