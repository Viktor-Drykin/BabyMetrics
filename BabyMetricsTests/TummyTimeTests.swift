import Testing
@testable import BabyMetrics

struct TummyTimeTests {

    @Test @MainActor func repositoryPersistsEntriesAcrossInstances() async throws {
        let suiteName = "test.tummy.persistence.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let startDate = Date(timeIntervalSince1970: 1_710_000_000)
        let endDate = Date(timeIntervalSince1970: 1_710_000_600)

        let firstRepository = UserDefaultsTummyTimeRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeTummyTimeStorageKey: "active_start"
        )
        firstRepository.replaceAllEntries(with: [
            TummyTimeEntry(id: UUID(), startDate: startDate, endDate: endDate)
        ])

        let secondRepository = UserDefaultsTummyTimeRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeTummyTimeStorageKey: "active_start"
        )

        #expect(secondRepository.currentEntries().count == 1)
        #expect(secondRepository.currentEntries().first?.startDate == startDate)
        #expect(secondRepository.currentEntries().first?.endDate == endDate)
    }

    @Test @MainActor func activeSessionPersistsAcrossInstances() async throws {
        let suiteName = "test.tummy.active.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let startDate = Date(timeIntervalSince1970: 1_710_010_000)
        let firstRepository = UserDefaultsTummyTimeRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeTummyTimeStorageKey: "active_start"
        )
        firstRepository.startTummyTime(at: startDate)

        let secondRepository = UserDefaultsTummyTimeRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeTummyTimeStorageKey: "active_start"
        )

        #expect(secondRepository.currentActiveTummyTimeStart() == startDate)
    }

    @Test @MainActor func stopSessionCreatesEntryAndClearsActiveState() async throws {
        let suiteName = "test.tummy.stop.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let repository = UserDefaultsTummyTimeRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeTummyTimeStorageKey: "active_start"
        )

        let startDate = Date(timeIntervalSince1970: 1_710_020_000)
        let endDate = Date(timeIntervalSince1970: 1_710_020_900)
        repository.startTummyTime(at: startDate)
        repository.stopTummyTime(at: endDate)

        let entries = repository.currentEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.startDate == startDate)
        #expect(entries.first?.endDate == endDate)
        #expect(repository.currentActiveTummyTimeStart() == nil)
    }

    @Test @MainActor func csvGenerationUsesExpectedFormat() async throws {
        let suiteName = "test.tummy.csv.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let repository = UserDefaultsTummyTimeRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeTummyTimeStorageKey: "active_start"
        )
        repository.replaceAllEntries(with: [
            TummyTimeEntry(
                id: UUID(),
                startDate: Date(timeIntervalSince1970: 0),
                endDate: Date(timeIntervalSince1970: 300)
            )
        ])

        let csv = repository.csvContent(from: repository.currentEntries())
        #expect(csv == "start_date,end_date,duration_minutes\n1970-01-01 00:00:00,1970-01-01 00:05:00,5")
    }
}
