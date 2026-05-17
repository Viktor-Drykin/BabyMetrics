import Foundation
import Combine

struct TummyTimeUseCases {
    let observeEntries: () -> AnyPublisher<[TummyTimeEntry], Never>
    let observeActiveTummyTimeStart: () -> AnyPublisher<Date?, Never>
    let getEntries: () -> [TummyTimeEntry]
    let getActiveTummyTimeStart: () -> Date?
    let startTummyTime: (_ date: Date) -> Void
    let stopTummyTime: (_ date: Date) -> Void
    let updateEntry: (_ id: UUID, _ startDate: Date, _ endDate: Date) -> Void
    let deleteEntries: (_ ids: [UUID]) -> Void
    let replaceAllEntries: (_ entries: [TummyTimeEntry]) -> Void
    let generateCSV: (_ entries: [TummyTimeEntry]) -> String
}

extension TummyTimeUseCases {
    init(repository: TummyTimeRepository) {
        observeEntries = { repository.entriesPublisher }
        observeActiveTummyTimeStart = { repository.activeTummyTimeStartPublisher }
        getEntries = { repository.currentEntries() }
        getActiveTummyTimeStart = { repository.currentActiveTummyTimeStart() }
        startTummyTime = { date in repository.startTummyTime(at: date) }
        stopTummyTime = { date in repository.stopTummyTime(at: date) }
        updateEntry = { id, startDate, endDate in repository.updateEntry(id: id, startDate: startDate, endDate: endDate) }
        deleteEntries = { ids in repository.deleteEntries(ids: ids) }
        replaceAllEntries = { entries in repository.replaceAllEntries(with: entries) }
        generateCSV = { entries in repository.csvContent(from: entries) }
    }
}
