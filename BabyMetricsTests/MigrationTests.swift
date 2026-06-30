import XCTest
import SwiftData
@testable import BabyMetrics

@MainActor
final class MigrationTests: XCTestCase {

    // Legacy payload shapes, encoded with a default JSONEncoder (matches the old repositories).
    private struct SeedFeeding: Codable { let id: UUID; let startDate: Date; let endDate: Date; let side: String }
    private struct SeedSleep: Codable { let id: UUID; let startDate: Date; let endDate: Date }
    private struct SeedDiaper: Codable { let id: UUID; let date: Date; let type: String; let weightGrams: Int? }
    private struct SeedGrowth: Codable { let id: UUID; let date: Date; let weightGrams: Double?; let heightCm: Double?; let headCm: Double? }

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Baby.self, SleepSession.self, FeedingSession.self,
                             DiaperEntry.self, GrowthEntry.self, ActivitySession.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int = 12) -> Date {
        DateComponents(calendar: .current, year: y, month: mo, day: d, hour: h).date!
    }

    func testMigratesAllTrackersWithConversions() throws {
        let suiteName = "migration.test.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suiteName)!
        defer { ud.removePersistentDomain(forName: suiteName) }
        let encoder = JSONEncoder()

        let feedStart = date(2026, 3, 1, 9)
        ud.set(try encoder.encode([SeedFeeding(id: UUID(), startDate: feedStart, endDate: feedStart.addingTimeInterval(300), side: "Right")]), forKey: "feeding_entries")
        ud.set(try encoder.encode([SeedSleep(id: UUID(), startDate: date(2026, 3, 1, 22), endDate: date(2026, 3, 2, 6))]), forKey: "sleep_entries")
        ud.set(try encoder.encode([SeedDiaper(id: UUID(), date: date(2026, 3, 1), type: "Mixed", weightGrams: 120)]), forKey: "diaper_entries")
        ud.set(try encoder.encode([SeedGrowth(id: UUID(), date: date(2026, 3, 1), weightGrams: 3500, heightCm: 55.5, headCm: 37.2)]), forKey: "growth_entries")
        ud.set(try encoder.encode([SeedSleep(id: UUID(), startDate: date(2026, 3, 1, 11), endDate: date(2026, 3, 1, 11).addingTimeInterval(600))]), forKey: "tummy_time_entries")

        let context = try makeContext()
        let didMigrate = DataMigration.migrateIfNeeded(context: context, userDefaults: ud)
        XCTAssertTrue(didMigrate)
        XCTAssertTrue(ud.bool(forKey: DataMigration.migratedFlagKey))

        // Default baby created
        let babies = try context.fetch(FetchDescriptor<Baby>())
        XCTAssertEqual(babies.count, 1)

        // Feeding: duration + side mapping
        let feeds = try context.fetch(FetchDescriptor<FeedingSession>())
        XCTAssertEqual(feeds.count, 1)
        XCTAssertEqual(feeds.first?.side, .right)
        XCTAssertEqual(feeds.first?.durationSeconds, 300)

        // Sleep: night inference (started 22:00)
        let sleeps = try context.fetch(FetchDescriptor<SleepSession>())
        XCTAssertEqual(sleeps.count, 1)
        XCTAssertEqual(sleeps.first?.type, .night)

        // Diaper: mixed -> both, Int -> Double
        let diapers = try context.fetch(FetchDescriptor<DiaperEntry>())
        XCTAssertEqual(diapers.first?.type, .both)
        XCTAssertEqual(diapers.first?.weightGrams, 120)

        // Growth: grams -> kg
        let growths = try context.fetch(FetchDescriptor<GrowthEntry>())
        XCTAssertEqual(growths.first?.weightKg, 3.5)
        XCTAssertEqual(growths.first?.headCircumferenceCm, 37.2)

        // Tummy time -> ActivitySession(.tummyTime)
        let acts = try context.fetch(FetchDescriptor<ActivitySession>())
        XCTAssertEqual(acts.count, 1)
        XCTAssertEqual(acts.first?.type, .tummyTime)
        XCTAssertEqual(acts.first?.durationSeconds, 600)
    }

    func testMigrationIsIdempotent() throws {
        let suiteName = "migration.test.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suiteName)!
        defer { ud.removePersistentDomain(forName: suiteName) }
        ud.set(try JSONEncoder().encode([SeedSleep(id: UUID(), startDate: date(2026, 3, 1, 22), endDate: date(2026, 3, 2, 6))]), forKey: "sleep_entries")

        let context = try makeContext()
        XCTAssertTrue(DataMigration.migrateIfNeeded(context: context, userDefaults: ud))
        // Second run is a no-op because the flag is set.
        XCTAssertFalse(DataMigration.migrateIfNeeded(context: context, userDefaults: ud))
        XCTAssertEqual(try context.fetch(FetchDescriptor<SleepSession>()).count, 1)
    }

    func testFreshInstallMarksMigratedWithoutData() throws {
        let suiteName = "migration.test.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suiteName)!
        defer { ud.removePersistentDomain(forName: suiteName) }

        let context = try makeContext()
        XCTAssertFalse(DataMigration.migrateIfNeeded(context: context, userDefaults: ud))
        XCTAssertTrue(ud.bool(forKey: DataMigration.migratedFlagKey))
        XCTAssertEqual(try context.fetch(FetchDescriptor<FeedingSession>()).count, 0)
    }
}
