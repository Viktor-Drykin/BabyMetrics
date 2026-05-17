import Foundation
import Combine

protocol FeedingRepository {
    var entriesPublisher: AnyPublisher<[FeedingEntry], Never> { get }
    var activeFeedingStartPublisher: AnyPublisher<Date?, Never> { get }
    var activeFeedingSidePublisher: AnyPublisher<BreastSide?, Never> { get }

    func currentEntries() -> [FeedingEntry]
    func currentActiveFeedingStart() -> Date?
    func currentActiveFeedingSide() -> BreastSide?
    func startFeeding(at date: Date, side: BreastSide)
    func stopFeeding(at date: Date)
    func addEntry(startDate: Date, endDate: Date, side: BreastSide)
    func updateEntry(id: UUID, startDate: Date, endDate: Date, side: BreastSide)
    func deleteEntries(ids: [UUID])
    func replaceAllEntries(with newEntries: [FeedingEntry])
    func csvContent(from entries: [FeedingEntry]) -> String
}
