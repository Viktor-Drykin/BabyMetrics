//
//  BreastFeedingTests.swift
//  BreastFeedingTests
//
//  Created by Viktor Drykin on 20.03.2026.
//

import Testing
@testable import BabyMetrics

struct BreastFeedingTests {

    @Test @MainActor func repositoryPersistsEntriesAcrossInstances() async throws {
        let suiteName = "test.persistence.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let startDate = Date(timeIntervalSince1970: 1_710_000_000)
        let endDate = Date(timeIntervalSince1970: 1_710_000_900)
        let firstRepository = UserDefaultsFeedingRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeFeedingStorageKey: "active_start",
            activeFeedingSideStorageKey: "active_side"
        )
        firstRepository.addEntry(startDate: startDate, endDate: endDate, side: .left)

        let secondRepository = UserDefaultsFeedingRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeFeedingStorageKey: "active_start",
            activeFeedingSideStorageKey: "active_side"
        )

        #expect(secondRepository.currentEntries().count == 1)
        #expect(secondRepository.currentEntries().first?.startDate == startDate)
        #expect(secondRepository.currentEntries().first?.endDate == endDate)
        #expect(secondRepository.currentEntries().first?.side == .left)
    }

    @Test @MainActor func activeSessionPersistsAcrossInstances() async throws {
        let suiteName = "test.active.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let startDate = Date(timeIntervalSince1970: 1_710_001_111)
        let firstRepository = UserDefaultsFeedingRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeFeedingStorageKey: "active_start",
            activeFeedingSideStorageKey: "active_side"
        )
        firstRepository.startFeeding(at: startDate, side: .right)

        let secondRepository = UserDefaultsFeedingRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeFeedingStorageKey: "active_start",
            activeFeedingSideStorageKey: "active_side"
        )

        #expect(secondRepository.currentActiveFeedingStart() == startDate)
        #expect(secondRepository.currentActiveFeedingSide() == .right)
    }

    @Test @MainActor func stopFeedingCreatesIntervalEntryWithActiveSide() async throws {
        let suiteName = "test.stop.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let repository = UserDefaultsFeedingRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeFeedingStorageKey: "active_start",
            activeFeedingSideStorageKey: "active_side"
        )

        let startDate = Date(timeIntervalSince1970: 1_710_002_000)
        let endDate = Date(timeIntervalSince1970: 1_710_002_600)
        repository.startFeeding(at: startDate, side: .right)
        repository.stopFeeding(at: endDate)

        let entries = repository.currentEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.startDate == startDate)
        #expect(entries.first?.endDate == endDate)
        #expect(entries.first?.side == .right)
        #expect(repository.currentActiveFeedingStart() == nil)
        #expect(repository.currentActiveFeedingSide() == nil)
    }

    @Test @MainActor func csvGenerationUsesExpectedFormat() async throws {
        let suiteName = "test.csv.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let repository = UserDefaultsFeedingRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeFeedingStorageKey: "active_start",
            activeFeedingSideStorageKey: "active_side"
        )
        repository.addEntry(
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 300),
            side: .right
        )

        let csv = repository.csvContent(from: repository.currentEntries())

        #expect(csv == "start_date,end_date,duration_minutes,side\n1970-01-01 00:00:00,1970-01-01 00:05:00,5,Right")
    }

    @Test @MainActor func legacyEntriesDecodeIntoZeroDurationIntervals() async throws {
        struct LegacyFeedingEntry: Codable {
            let id: UUID
            let date: Date
            let side: BreastSide
        }

        let suiteName = "test.legacy.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let legacy = LegacyFeedingEntry(id: UUID(), date: Date(timeIntervalSince1970: 1_710_010_000), side: .left)
        let data = try JSONEncoder().encode([legacy])
        defaults.set(data, forKey: "entries")

        let repository = UserDefaultsFeedingRepository(
            userDefaults: defaults,
            entriesStorageKey: "entries",
            activeFeedingStorageKey: "active_start",
            activeFeedingSideStorageKey: "active_side"
        )

        let entries = repository.currentEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.startDate == legacy.date)
        #expect(entries.first?.endDate == legacy.date)
        #expect(entries.first?.duration == 0)
        #expect(entries.first?.side == .left)
    }
}
