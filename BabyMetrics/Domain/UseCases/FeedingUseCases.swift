import Foundation
import Combine

struct FeedingUseCases {
    let observeEntries: () -> AnyPublisher<[FeedingEntry], Never>
    let getEntries: () -> [FeedingEntry]
    let addEntry: (_ date: Date, _ side: BreastSide) -> Void
    let updateEntry: (_ id: UUID, _ date: Date, _ side: BreastSide) -> Void
    let deleteEntries: (_ ids: [UUID]) -> Void
    let replaceAllEntries: (_ entries: [FeedingEntry]) -> Void
    let generateCSV: (_ entries: [FeedingEntry]) -> String
}

extension FeedingUseCases {
    init(repository: FeedingRepository) {
        observeEntries = { repository.entriesPublisher }
        getEntries = { repository.currentEntries() }
        addEntry = { date, side in repository.addEntry(date: date, side: side) }
        updateEntry = { id, date, side in repository.updateEntry(id: id, date: date, side: side) }
        deleteEntries = { ids in repository.deleteEntries(ids: ids) }
        replaceAllEntries = { entries in repository.replaceAllEntries(with: entries) }
        generateCSV = { entries in repository.csvContent(from: entries) }
    }
}
