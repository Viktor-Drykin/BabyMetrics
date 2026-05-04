import Foundation
import Combine

struct GrowthUseCases {
    let observeEntries: () -> AnyPublisher<[GrowthEntry], Never>
    let getEntries: () -> [GrowthEntry]
    let addEntry: (_ entry: GrowthEntry) -> Void
    let updateEntry: (_ id: UUID, _ date: Date, _ weightKg: Double?, _ heightCm: Double?, _ headCm: Double?) -> Void
    let deleteEntries: (_ ids: [UUID]) -> Void
    let replaceAllEntries: (_ entries: [GrowthEntry]) -> Void
}

extension GrowthUseCases {
    init(repository: GrowthRepository) {
        observeEntries = { repository.entriesPublisher }
        getEntries = { repository.currentEntries() }
        addEntry = { entry in repository.addEntry(entry) }
        updateEntry = { id, date, weightKg, heightCm, headCm in
            repository.updateEntry(id: id, date: date, weightKg: weightKg, heightCm: heightCm, headCm: headCm)
        }
        deleteEntries = { ids in repository.deleteEntries(ids: ids) }
        replaceAllEntries = { entries in repository.replaceAllEntries(with: entries) }
    }
}
