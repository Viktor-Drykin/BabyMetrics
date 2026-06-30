import Foundation
import SwiftData

enum CSVImportError: LocalizedError {
    case invalidFormat(line: Int)
    case unreadable

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let line): return String(localized: "Invalid format on line \(line)")
        case .unreadable: return String(localized: "Could not read the file")
        }
    }
}

/// The trackers a CSV file can be imported into. Formats match the legacy app's exports.
enum CSVTracker: String, CaseIterable, Identifiable {
    case feeding, sleep, diaper, growth, tummyTime
    var id: String { rawValue }
    var title: LocalizedStringResource {
        switch self {
        case .feeding: return "Feeding"
        case .sleep: return "Sleep"
        case .diaper: return "Diapers"
        case .growth: return "Growth"
        case .tummyTime: return "Tummy time"
        }
    }
}

/// Imports legacy-format CSV files into SwiftData. Mirrors the conversions used by `DataMigration`.
enum CSVImporter {
    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    /// Parses `content` for the given tracker and inserts rows. Returns the number imported.
    @discardableResult
    @MainActor
    static func `import`(_ content: String, as tracker: CSVTracker, into context: ModelContext, baby: Baby) throws -> Int {
        let rows = dataRows(from: content)
        var count = 0
        for (offset, row) in rows.enumerated() {
            let parts = row.split(separator: ",", omittingEmptySubsequences: false).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            let lineNumber = offset + 1
            switch tracker {
            case .feeding:   try insertFeeding(parts, lineNumber, context, baby)
            case .sleep:     try insertInterval(parts, lineNumber, context, baby) { SleepSession(startTime: $0, endTime: $1, type: .inferred(from: $0), baby: baby) }
            case .tummyTime: try insertInterval(parts, lineNumber, context, baby) { ActivitySession(startTime: $0, endTime: $1, type: .tummyTime, durationSeconds: Int(max(0, $1.timeIntervalSince($0))), baby: baby) }
            case .diaper:    try insertDiaper(parts, lineNumber, context, baby)
            case .growth:    try insertGrowth(parts, lineNumber, context, baby)
            }
            count += 1
        }
        if count > 0 { try context.save() }
        return count
    }

    // MARK: - Per-tracker parsing

    private static func insertFeeding(_ parts: [String], _ line: Int, _ context: ModelContext, _ baby: Baby) throws {
        // start_date,end_date,duration_minutes,side  (legacy: date,side)
        if parts.count >= 4, let start = dateTimeFormatter.date(from: parts[0]), let end = dateTimeFormatter.date(from: parts[1]) {
            let side = mapSide(parts[3])
            context.insert(FeedingSession(startTime: start, endTime: end, side: side, durationSeconds: Int(max(0, end.timeIntervalSince(start))), baby: baby))
        } else if parts.count >= 2, let date = dateTimeFormatter.date(from: parts[0]) {
            let side = mapSide(parts[1])
            context.insert(FeedingSession(startTime: date, endTime: date, side: side, durationSeconds: 0, baby: baby))
        } else {
            throw CSVImportError.invalidFormat(line: line)
        }
    }

    private static func insertInterval(_ parts: [String], _ line: Int, _ context: ModelContext, _ baby: Baby, make: (Date, Date) -> any PersistentModel) throws {
        guard parts.count >= 2, let start = dateTimeFormatter.date(from: parts[0]), let end = dateTimeFormatter.date(from: parts[1]) else {
            throw CSVImportError.invalidFormat(line: line)
        }
        context.insert(make(min(start, end), max(start, end)))
    }

    private static func insertDiaper(_ parts: [String], _ line: Int, _ context: ModelContext, _ baby: Baby) throws {
        // date,type[,weight_g]
        guard parts.count >= 2, let date = dateTimeFormatter.date(from: parts[0]) else {
            throw CSVImportError.invalidFormat(line: line)
        }
        let type = mapDiaperType(parts[1])
        let weight = parts.count >= 3 ? Double(parts[2]) : nil
        context.insert(DiaperEntry(timestamp: date, type: type, weightGrams: weight, baby: baby))
    }

    private static func insertGrowth(_ parts: [String], _ line: Int, _ context: ModelContext, _ baby: Baby) throws {
        // date,weight_g,height_cm,head_cm
        guard !parts.isEmpty, let date = dateOnlyFormatter.date(from: parts[0]) else {
            throw CSVImportError.invalidFormat(line: line)
        }
        let grams = parts.count > 1 ? Double(parts[1]) : nil
        let height = parts.count > 2 ? Double(parts[2].replacingOccurrences(of: ",", with: ".")) : nil
        let head = parts.count > 3 ? Double(parts[3].replacingOccurrences(of: ",", with: ".")) : nil
        context.insert(GrowthEntry(date: date,
                                   weightKg: grams.map { $0 / 1000 },
                                   heightCm: height,
                                   headCircumferenceCm: head,
                                   baby: baby))
    }

    // MARK: - Helpers

    /// Splits into non-empty rows, dropping a leading header line if present.
    private static func dataRows(from content: String) -> [String] {
        var lines = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if let first = lines.first?.lowercased(),
           first.hasPrefix("date") || first.hasPrefix("start_date") {
            lines.removeFirst()
        }
        return lines
    }

    private static func mapSide(_ raw: String) -> BreastSide {
        switch raw.lowercased() {
        case "right", "права": return .right
        case "both": return .both
        default: return .left
        }
    }

    private static func mapDiaperType(_ raw: String) -> DiaperType {
        switch raw.lowercased() {
        case "dirty", "брудний": return .dirty
        case "mixed", "both", "обидва": return .both
        default: return .wet
        }
    }
}
