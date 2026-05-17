import Foundation
import Combine

struct FeedingUseCases {
    let observeEntries: () -> AnyPublisher<[FeedingEntry], Never>
    let observeActiveFeedingStart: () -> AnyPublisher<Date?, Never>
    let observeActiveFeedingSide: () -> AnyPublisher<BreastSide?, Never>
    let getEntries: () -> [FeedingEntry]
    let getActiveFeedingStart: () -> Date?
    let getActiveFeedingSide: () -> BreastSide?
    let startFeeding: (_ date: Date, _ side: BreastSide) -> Void
    let stopFeeding: (_ date: Date) -> Void
    let addEntry: (_ startDate: Date, _ endDate: Date, _ side: BreastSide) -> Void
    let updateEntry: (_ id: UUID, _ startDate: Date, _ endDate: Date, _ side: BreastSide) -> Void
    let deleteEntries: (_ ids: [UUID]) -> Void
    let replaceAllEntries: (_ entries: [FeedingEntry]) -> Void
    let generateCSV: (_ entries: [FeedingEntry]) -> String
}

extension FeedingUseCases {
    init(repository: FeedingRepository) {
        observeEntries = { repository.entriesPublisher }
        observeActiveFeedingStart = { repository.activeFeedingStartPublisher }
        observeActiveFeedingSide = { repository.activeFeedingSidePublisher }
        getEntries = { repository.currentEntries() }
        getActiveFeedingStart = { repository.currentActiveFeedingStart() }
        getActiveFeedingSide = { repository.currentActiveFeedingSide() }
        startFeeding = { date, side in repository.startFeeding(at: date, side: side) }
        stopFeeding = { date in repository.stopFeeding(at: date) }
        addEntry = { startDate, endDate, side in repository.addEntry(startDate: startDate, endDate: endDate, side: side) }
        updateEntry = { id, startDate, endDate, side in repository.updateEntry(id: id, startDate: startDate, endDate: endDate, side: side) }
        deleteEntries = { ids in repository.deleteEntries(ids: ids) }
        replaceAllEntries = { entries in repository.replaceAllEntries(with: entries) }
        generateCSV = { entries in repository.csvContent(from: entries) }
    }
}
