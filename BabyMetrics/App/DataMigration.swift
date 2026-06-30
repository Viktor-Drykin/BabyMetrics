import Foundation
import SwiftData

/// One-time migration of legacy UserDefaults+JSON data into SwiftData.
///
/// The legacy app stored each tracker as a JSON-encoded array under a fixed key, using a
/// default `JSONEncoder` (no custom date strategy). We decode those payloads with
/// self-contained DTOs so the migration has no dependency on the retired domain layer, and
/// the original UserDefaults values are left intact as a safety net.
enum DataMigration {
    static let migratedFlagKey = "didMigrateFromUserDefaults"

    // Legacy UserDefaults keys (verbatim from the old repositories).
    private enum Key {
        static let feeding = "feeding_entries"
        static let feedingActiveStart = "feeding_active_start"
        static let feedingActiveSide = "feeding_active_side"
        static let sleep = "sleep_entries"
        static let sleepActiveStart = "sleep_active_start"
        static let diaper = "diaper_entries"
        static let growth = "growth_entries"
        static let tummy = "tummy_time_entries"
        static let tummyActiveStart = "tummy_time_active_start"
    }

    /// Runs the migration exactly once. Safe to call on every launch.
    /// The flag is only set after a successful `save()`, so a failure retries next launch.
    @discardableResult
    static func migrateIfNeeded(context: ModelContext, userDefaults: UserDefaults = .standard) -> Bool {
        guard !userDefaults.bool(forKey: migratedFlagKey) else { return false }

        let arrayKeys = [Key.feeding, Key.sleep, Key.diaper, Key.growth, Key.tummy]
        let hasLegacyData = arrayKeys.contains { userDefaults.data(forKey: $0) != nil }
            || userDefaults.object(forKey: Key.feedingActiveStart) != nil
            || userDefaults.object(forKey: Key.sleepActiveStart) != nil
            || userDefaults.object(forKey: Key.tummyActiveStart) != nil

        guard hasLegacyData else {
            // Fresh install — nothing to migrate. Mark done so we never re-check.
            userDefaults.set(true, forKey: migratedFlagKey)
            return false
        }

        let decoder = JSONDecoder()
        let feedings = decode([LegacyFeeding].self, Key.feeding, userDefaults, decoder) ?? []
        let sleeps = decode([LegacySleep].self, Key.sleep, userDefaults, decoder) ?? []
        let diapers = decode([LegacyDiaper].self, Key.diaper, userDefaults, decoder) ?? []
        let growths = decode([LegacyGrowth].self, Key.growth, userDefaults, decoder) ?? []
        let tummies = decode([LegacyTummy].self, Key.tummy, userDefaults, decoder) ?? []

        // Best-guess birth date = earliest recorded event.
        var dates: [Date] = []
        dates += feedings.map(\.startDate)
        dates += sleeps.map(\.startDate)
        dates += diapers.map(\.date)
        dates += growths.map(\.date)
        dates += tummies.map(\.startDate)
        let baby = Baby(name: "", birthDate: dates.min() ?? .now)
        context.insert(baby)

        // Completed records
        for f in feedings {
            context.insert(FeedingSession(
                startTime: f.startDate,
                endTime: f.endDate,
                side: f.mappedSide,
                durationSeconds: Int(max(0, f.endDate.timeIntervalSince(f.startDate))),
                baby: baby))
        }
        for s in sleeps {
            context.insert(SleepSession(
                startTime: s.startDate,
                endTime: s.endDate,
                type: SleepType.inferred(from: s.startDate),
                baby: baby))
        }
        for d in diapers {
            context.insert(DiaperEntry(
                timestamp: d.date,
                type: d.mappedType,
                weightGrams: d.weightGrams.map(Double.init),
                baby: baby))
        }
        for g in growths {
            context.insert(GrowthEntry(
                date: g.date,
                weightKg: g.weightGrams.map { $0 / 1000 }, // legacy stored grams
                heightCm: g.heightCm,
                headCircumferenceCm: g.headCm,
                baby: baby))
        }
        for t in tummies {
            context.insert(ActivitySession(
                startTime: t.startDate,
                endTime: t.endDate,
                type: .tummyTime,
                durationSeconds: Int(max(0, t.endDate.timeIntervalSince(t.startDate))),
                baby: baby))
        }

        // Active (in-progress) sessions — migrated with nil endTime so the new app resumes them.
        if let start = userDefaults.object(forKey: Key.feedingActiveStart) as? Date {
            let side = mapSide(userDefaults.string(forKey: Key.feedingActiveSide)) ?? .left
            context.insert(FeedingSession(startTime: start, endTime: nil, side: side, durationSeconds: 0, baby: baby))
        }
        if let start = userDefaults.object(forKey: Key.sleepActiveStart) as? Date {
            context.insert(SleepSession(startTime: start, endTime: nil, type: SleepType.inferred(from: start), baby: baby))
        }
        if let start = userDefaults.object(forKey: Key.tummyActiveStart) as? Date {
            context.insert(ActivitySession(startTime: start, endTime: nil, type: .tummyTime, durationSeconds: 0, baby: baby))
        }

        do {
            try context.save()
            userDefaults.set(true, forKey: migratedFlagKey)
            return true
        } catch {
            // Leave the flag unset so migration is retried on the next launch.
            return false
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, _ key: String, _ ud: UserDefaults, _ decoder: JSONDecoder) -> T? {
        guard let data = ud.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    fileprivate static func mapSide(_ raw: String?) -> BreastSide? {
        switch raw?.lowercased() {
        case "left", "ліва":  return .left
        case "right", "права": return .right
        default: return nil
        }
    }
}

// MARK: - Legacy decode DTOs (mirror the retired Codable entities)

private struct LegacyFeeding: Decodable {
    let startDate: Date
    let endDate: Date
    let side: String

    private enum CodingKeys: String, CodingKey { case startDate, endDate, side, date }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.side = try c.decode(String.self, forKey: .side)
        if let start = try c.decodeIfPresent(Date.self, forKey: .startDate),
           let end = try c.decodeIfPresent(Date.self, forKey: .endDate) {
            self.startDate = min(start, end)
            self.endDate = max(start, end)
        } else {
            let legacy = try c.decode(Date.self, forKey: .date)
            self.startDate = legacy
            self.endDate = legacy
        }
    }

    var mappedSide: BreastSide { DataMigration.mapSide(side) ?? .left }
}

private struct LegacySleep: Decodable {
    let startDate: Date
    let endDate: Date
}

private struct LegacyTummy: Decodable {
    let startDate: Date
    let endDate: Date
}

private struct LegacyDiaper: Decodable {
    let date: Date
    let type: String
    let weightGrams: Int?

    var mappedType: DiaperType {
        switch type.lowercased() {
        case "dirty": return .dirty
        case "mixed", "both": return .both
        default: return .wet
        }
    }
}

private struct LegacyGrowth: Decodable {
    let date: Date
    let weightGrams: Double?
    let heightCm: Double?
    let headCm: Double?
}
