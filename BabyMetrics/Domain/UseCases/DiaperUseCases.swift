import Foundation
import Combine

struct DiaperUseCases {
    let observeEntries: () -> AnyPublisher<[DiaperEntry], Never>
    let getEntries: () -> [DiaperEntry]
    let addEntry: (_ date: Date, _ type: DiaperType, _ weightGrams: Int?) -> Void
    let updateEntry: (_ id: UUID, _ date: Date, _ type: DiaperType, _ weightGrams: Int?) -> Void
    let deleteEntries: (_ ids: [UUID]) -> Void
    let replaceAllEntries: (_ entries: [DiaperEntry]) -> Void
    let generateCSV: (_ entries: [DiaperEntry]) -> String
}

extension DiaperUseCases {
    init(repository: DiaperRepository) {
        observeEntries = { repository.entriesPublisher }
        getEntries = { repository.currentEntries() }
        addEntry = { date, type, weightGrams in repository.addEntry(date: date, type: type, weightGrams: weightGrams) }
        updateEntry = { id, date, type, weightGrams in repository.updateEntry(id: id, date: date, type: type, weightGrams: weightGrams) }
        deleteEntries = { ids in repository.deleteEntries(ids: ids) }
        replaceAllEntries = { entries in repository.replaceAllEntries(with: entries) }
        generateCSV = { entries in repository.csvContent(from: entries) }
    }
}
