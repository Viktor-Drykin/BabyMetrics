import Foundation
import Combine

protocol SleepRepository {
    var entriesPublisher: AnyPublisher<[SleepEntry], Never> { get }
    var activeSleepStartPublisher: AnyPublisher<Date?, Never> { get }

    func currentEntries() -> [SleepEntry]
    func currentActiveSleepStart() -> Date?
    func startSleep(at date: Date)
    func stopSleep(at date: Date)
    func updateEntry(id: UUID, startDate: Date, endDate: Date)
    func deleteEntries(ids: [UUID])
    func replaceAllEntries(with newEntries: [SleepEntry])
    func csvContent(from entries: [SleepEntry]) -> String
}
