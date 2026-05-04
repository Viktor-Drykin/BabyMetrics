//
//  BreastFeedingTests.swift
//  BreastFeedingTests
//
//  Created by Viktor Drykin on 20.03.2026.
//

import Testing
@testable import BreastFeeding

struct BreastFeedingTests {

    @Test @MainActor func storePersistsEntriesAcrossInstances() async throws {
        let suiteName = "test.persistence.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let date = Date(timeIntervalSince1970: 1_710_000_000)
        let firstStore = FeedingStore(userDefaults: defaults, storageKey: "entries")
        firstStore.addEntry(date: date, side: .left)

        let secondStore = FeedingStore(userDefaults: defaults, storageKey: "entries")

        #expect(secondStore.entries.count == 1)
        #expect(secondStore.entries.first?.date == date)
        #expect(secondStore.entries.first?.side == .left)
    }

    @Test @MainActor func csvGenerationUsesExpectedFormat() async throws {
        let suiteName = "test.csv.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)

        let store = FeedingStore(userDefaults: defaults, storageKey: "entries")
        store.addEntry(date: Date(timeIntervalSince1970: 0), side: .right)

        let csv = store.csvContent()

        #expect(csv == "date,side\n1970-01-01 00:00:00,Right")
    }

}
