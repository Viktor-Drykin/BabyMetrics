import Foundation
import Combine

@MainActor
final class TummyTimeHistoryViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "Усі"
        case today = "Сьогодні"
        case week = "Тиждень"
        case month = "Місяць"

        var id: String { rawValue }
    }

    enum DisplayMode: String, CaseIterable, Identifiable {
        case list = "Список"
        case chart = "Аналітика"

        var id: String { rawValue }
    }

    enum ChartMetric: String, CaseIterable, Identifiable {
        case duration = "Тривалість"
        case sessions = "Сесії"
        case average = "Середня"
        case dayPart = "Частина дня"

        var id: String { rawValue }
    }

    struct DurationChartPoint: Identifiable {
        let date: Date
        let hours: Double

        var id: String { "duration-\(date.timeIntervalSince1970)" }
    }

    struct SessionCountChartPoint: Identifiable {
        let date: Date
        let count: Int

        var id: String { "count-\(date.timeIntervalSince1970)" }
    }

    struct AverageChartPoint: Identifiable {
        let date: Date
        let minutes: Double

        var id: String { "average-\(date.timeIntervalSince1970)" }
    }

    enum DayPart: String, CaseIterable, Identifiable {
        case night = "Ніч"
        case morning = "Ранок"
        case day = "День"
        case evening = "Вечір"

        var id: String { rawValue }

        var sortOrder: Int {
            switch self {
            case .night: return 0
            case .morning: return 1
            case .day: return 2
            case .evening: return 3
            }
        }
    }

    struct DayPartPoint: Identifiable {
        let part: DayPart
        let count: Int

        var id: String { "part-\(part.rawValue)" }
    }

    @Published private(set) var entries: [TummyTimeEntry] = []
    @Published var selectedFilter: Filter = .today
    @Published var selectedMode: DisplayMode = .list
    @Published var selectedChartMetric: ChartMetric = .duration
    @Published var isImportingCSV = false
    @Published var importErrorMessage: String?

    let csvURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("TummyTimeHistory.csv")

    private let useCases: TummyTimeUseCases
    private var cancellables = Set<AnyCancellable>()

    init(useCases: TummyTimeUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.entries = $0
            }
            .store(in: &cancellables)
    }

    var filteredEntries: [TummyTimeEntry] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedFilter {
        case .all:
            return entries
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return entries.filter { $0.startDate < endOfDay && $0.endDate > startOfDay }
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return entries }
            return entries.filter { $0.startDate < interval.end && $0.endDate > interval.start }
        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: now) else { return entries }
            return entries.filter { $0.startDate < interval.end && $0.endDate > interval.start }
        }
    }

    var totalDurationSeconds: Int {
        Int(filteredEntries.reduce(0) { $0 + $1.duration })
    }

    var totalSessions: Int {
        filteredEntries.count
    }

    var averageDurationSeconds: Int {
        guard totalSessions > 0 else { return 0 }
        return totalDurationSeconds / totalSessions
    }

    var longestSessionSeconds: Int {
        Int(filteredEntries.map(\.duration).max() ?? 0)
    }

    var activeDaysCount: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(filteredEntries.map { calendar.startOfDay(for: $0.startDate) })
        return uniqueDays.count
    }

    var periodDaysCount: Int {
        let calendar = Calendar.current
        let now = Date()

        switch selectedFilter {
        case .today:
            return 1
        case .week:
            return 7
        case .month:
            return calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        case .all:
            guard let earliestDate = entries.map(\.startDate).min() else { return 0 }
            let start = calendar.startOfDay(for: earliestDate)
            let end = calendar.startOfDay(for: now)
            return max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 0 + 1)
        }
    }

    var consistencyText: String {
        guard periodDaysCount > 0 else { return "0%" }
        let ratio = Double(activeDaysCount) / Double(periodDaysCount)
        return "\(Int((ratio * 100).rounded()))%"
    }

    var durationChartPoints: [DurationChartPoint] {
        let grouped = groupedDurationsByDay()
        return grouped
            .map { DurationChartPoint(date: $0.key, hours: $0.value / 3600.0) }
            .sorted { $0.date < $1.date }
    }

    var sessionCountChartPoints: [SessionCountChartPoint] {
        let calendar = Calendar.current
        var grouped: [Date: Int] = [:]

        for entry in filteredEntries {
            let day = calendar.startOfDay(for: entry.startDate)
            grouped[day, default: 0] += 1
        }

        return grouped
            .map { SessionCountChartPoint(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var averageDurationChartPoints: [AverageChartPoint] {
        let grouped = groupedDurationsByDay()
        let counts = Dictionary(grouping: filteredEntries, by: { Calendar.current.startOfDay(for: $0.startDate) })
            .mapValues { $0.count }

        return grouped
            .compactMap { date, seconds in
                guard let dayCount = counts[date], dayCount > 0 else { return nil }
                return AverageChartPoint(date: date, minutes: (seconds / Double(dayCount)) / 60.0)
            }
            .sorted { $0.date < $1.date }
    }

    var dayPartChartPoints: [DayPartPoint] {
        var grouped: [DayPart: Int] = [:]

        for entry in filteredEntries {
            let hour = Calendar.current.component(.hour, from: entry.startDate)
            let part: DayPart
            switch hour {
            case 0..<6:
                part = .night
            case 6..<12:
                part = .morning
            case 12..<18:
                part = .day
            default:
                part = .evening
            }
            grouped[part, default: 0] += 1
        }

        return grouped
            .map { DayPartPoint(part: $0.key, count: $0.value) }
            .sorted { $0.part.sortOrder < $1.part.sortOrder }
    }

    var chartTitle: String {
        switch selectedChartMetric {
        case .duration:
            return "Тривалість розминки по днях (год)"
        case .sessions:
            return "Кількість сесій по днях"
        case .average:
            return "Середня тривалість сесії (хв)"
        case .dayPart:
            return "Розподіл за частиною дня"
        }
    }

    func deleteFilteredEntries(at offsets: IndexSet) {
        let ids = offsets.map { filteredEntries[$0].id }
        useCases.deleteEntries(ids)
    }

    func updateEntry(id: UUID, startDate: Date, endDate: Date) {
        useCases.updateEntry(id, startDate, endDate)
    }

    func durationString(for entry: TummyTimeEntry) -> String {
        DurationTextFormatter.string(from: entry.startDate, to: entry.endDate)
    }

    func writeCSVFile() {
        do {
            let csv = useCases.generateCSV(entries)
            try csv.write(to: csvURL, atomically: true, encoding: .utf8)
        } catch {
            // Ignore file write errors for now.
        }
    }

    func handleCSVImport(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let fileURL = urls.first else { return }

            guard fileURL.startAccessingSecurityScopedResource() else {
                importErrorMessage = "Не вдалося отримати доступ до файлу."
                return
            }
            defer { fileURL.stopAccessingSecurityScopedResource() }

            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let importedEntries = try parseCSVContent(content)
            useCases.replaceAllEntries(importedEntries)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func groupedDurationsByDay() -> [Date: Double] {
        let calendar = Calendar.current
        var grouped: [Date: Double] = [:]

        for entry in filteredEntries {
            var segmentStart = entry.startDate
            while segmentStart < entry.endDate {
                let dayStart = calendar.startOfDay(for: segmentStart)
                let nextMidnight = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                let segmentEnd = min(entry.endDate, nextMidnight)
                grouped[dayStart, default: 0] += segmentEnd.timeIntervalSince(segmentStart)
                segmentStart = segmentEnd
            }
        }

        return grouped
    }

    private func parseCSVContent(_ content: String) throws -> [TummyTimeEntry] {
        struct CSVImportError: LocalizedError {
            let line: Int

            var errorDescription: String? {
                "Невірний CSV формат у рядку \(line). Очікується: yyyy-MM-dd HH:mm:ss,yyyy-MM-dd HH:mm:ss"
            }
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let rawLines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !rawLines.isEmpty else { return [] }

        let firstLower = rawLines.first?.lowercased() ?? ""
        let lines: [String]
        if firstLower == "start_date,end_date,duration_minutes" || firstLower == "start_date,end_date" {
            lines = Array(rawLines.dropFirst())
        } else {
            lines = rawLines
        }

        var result: [TummyTimeEntry] = []
        for (index, line) in lines.enumerated() {
            let parts = line.split(separator: ",", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespaces) }

            guard parts.count >= 2,
                  let startDate = formatter.date(from: parts[0]),
                  let endDate = formatter.date(from: parts[1]) else {
                throw CSVImportError(line: index + 1)
            }

            result.append(
                TummyTimeEntry(
                    id: UUID(),
                    startDate: min(startDate, endDate),
                    endDate: max(startDate, endDate)
                )
            )
        }

        return result
    }
}
