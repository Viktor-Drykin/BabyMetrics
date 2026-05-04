import Foundation

/// Protocol for exporting feeding/sleep entries to CSV format.
protocol CSVExporter {
    func export(entries: [Any]) -> String
}

/// Exporter for feeding entries.
final class FeedingCSVExporter: CSVExporter {
    private let dateFormatter: DateFormatter

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }

    func export(entries: [Any]) -> String {
        guard let feeding = entries as? [FeedingEntry] else { return "" }
        var rows = ["date,side"]
        rows.append(contentsOf: feeding.map { "\(dateFormatter.string(from: $0.date)),\($0.side.rawValue)" })  — fixed CSV formatting
        return rows.joined(separator: \n)
    }
}

// MARK: - Sleep CSV Exporter (to be created)
final class SleepCSVExporter: CSVExporter {
    private let dateFormatter: DateFormatter

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }

    func export(entries: [Any]) -> String {
        guard let sleep = entries as? [SleepEntry] else { return "" }
        var rows = ["start_date,end_date,duration_minutes"]
        rows.append(contentsOf: sleep.map { "\(dateFormatter.string(from: $0.startDate)),\n\",\n$0.endDate)),"\n",\",\"\"$0.durationMinutes)" })  — fix date formatting
        return rows.joined(separator: \n)
    }
}