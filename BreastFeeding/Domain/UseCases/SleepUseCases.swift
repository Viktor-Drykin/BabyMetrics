import Foundation
import Combine

struct SleepUseCases {
    let observeEntries: () -> AnyPublisher<[SleepEntry], Never>
    let observeActiveSleepStart: () -> AnyPublisher<Date?, Never>
    let getEntries: () -> [SleepEntry]
    let getActiveSleepStart: () -> Date?
    let startSleep: (_ date: Date) -> Void
    let stopSleep: (_ date: Date) -> Void
    let updateEntry: (_ id: UUID, _ startDate: Date, _ endDate: Date) -> Void
    let deleteEntries: (_ ids: [UUID]) -> Void
    let replaceAllEntries: (_ entries: [SleepEntry]) -> Void
    let generateCSV: (_ entries: [SleepEntry]) -> String
}

extension SleepUseCases {
    init(repository: SleepRepository) {
        observeEntries = { repository.entriesPublisher }
        observeActiveSleepStart = { repository.activeSleepStartPublisher }
        getEntries = { repository.currentEntries() }
        getActiveSleepStart = { repository.currentActiveSleepStart() }
        startSleep = { date in repository.startSleep(at: date) }
        stopSleep = { date in repository.stopSleep(at: date) }
        updateEntry = { id, startDate, endDate in repository.updateEntry(id: id, startDate: startDate, endDate: endDate) }
        deleteEntries = { ids in repository.deleteEntries(ids: ids) }
        replaceAllEntries = { entries in repository.replaceAllEntries(with: entries) }
        generateCSV = { entries in repository.csvContent(from: entries) }
    }
}
