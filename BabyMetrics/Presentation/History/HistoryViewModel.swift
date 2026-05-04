import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "Усі"
        case today = "Сьогодні"
        case week = "Тиждень"
        case month = "Місяць"

        var id: String { rawValue }
    }

    enum DisplayMode: String, CaseIterable, Identifiable {
        case list = "Список"
        case chart = "Діаграма"

        var id: String { rawValue }
    }

    enum ChartGranularity: String, CaseIterable, Identifiable {
        case day = "День"
        case week = "Тиждень"

        var id: String { rawValue }
    }

    enum ChartStyle: String, CaseIterable, Identifiable {
        case bars = "Стовпчики"
        case line = "Лінія"

        var id: String { rawValue }
    }

    struct FeedingSideChartPoint: Identifiable {
        let date: Date
        let side: BreastSide
        let count: Int

        var id: String { "\(date.timeIntervalSince1970)-\(side.rawValue)" }
    }

    @Published private(set) var entries: [FeedingEntry] = []
    @Published var selectedFilter: Filter = .today
    @Published var selectedMode: DisplayMode = .list
    @Published var selectedGranularity: ChartGranularity = .day
    @Published var selectedChartStyle: ChartStyle = .bars
    @Published var isImportingCSV = false
    @Published var importErrorMessage: String?

    let csvURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("BreastfeedingHistory.csv")
    let chartImageURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("BreastfeedingChart.png")

    private let useCases: FeedingUseCases
    private var cancellables = Set<AnyCancellable>()

    init(useCases: FeedingUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.entries = $0
            }
            .store(in: &cancellables)
    }

    var filteredEntries: [FeedingEntry] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedFilter {
        case .all:
            return entries
        case .today:
            return entries.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return entries }
            return entries.filter { interval.contains($0.date) }
        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: now) else { return entries }
            return entries.filter { interval.contains($0.date) }
        }
    }

    var sideChartPoints: [FeedingSideChartPoint] {
        let calendar = Calendar.current
        var groupedCounts: [Date: [BreastSide: Int]] = [:]

        for entry in filteredEntries {
            let bucketDate: Date

            switch selectedGranularity {
            case .day:
                bucketDate = calendar.startOfDay(for: entry.date)
            case .week:
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)
                bucketDate = calendar.date(from: components) ?? calendar.startOfDay(for: entry.date)
            }

            groupedCounts[bucketDate, default: [:]][entry.side, default: 0] += 1
        }

        return groupedCounts
            .flatMap { date, sides in
                sides.map { side, count in
                    FeedingSideChartPoint(date: date, side: side, count: count)
                }
            }
            .sorted { $0.date < $1.date }
    }

    var chartTitle: String {
        selectedGranularity == .day ? "Кількість годувань по днях" : "Кількість годувань по тижнях"
    }

    func deleteFilteredEntries(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredEntries[$0].id }
        useCases.deleteEntries(idsToDelete)
    }

    func updateEntry(id: UUID, date: Date, side: BreastSide) {
        useCases.updateEntry(id, date, side)
    }

    func writeCSVFile() {
        do {
            let csv = useCases.generateCSV(entries)
            try csv.write(to: csvURL, atomically: true, encoding: .utf8)
        } catch {
            // Ignore file write errors for now.
        }
    }

    func writeChartImage(data: Data) {
        do {
            try data.write(to: chartImageURL, options: .atomic)
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

    private func parseCSVContent(_ content: String) throws -> [FeedingEntry] {
        struct CSVImportError: LocalizedError {
            let line: Int

            var errorDescription: String? {
                "Невірний CSV формат у рядку \(line). Очікується: yyyy-MM-dd HH:mm:ss,Left|Right"
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

        let lines: [String]
        if rawLines.first?.lowercased() == "date,side" {
            lines = Array(rawLines.dropFirst())
        } else {
            lines = rawLines
        }

        var result: [FeedingEntry] = []

        for (index, line) in lines.enumerated() {
            let parts = line.split(separator: ",", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespaces) }

            guard parts.count == 2,
                  let date = formatter.date(from: parts[0]),
                  let side = parseBreastSide(parts[1]) else {
                throw CSVImportError(line: index + 1)
            }

            result.append(FeedingEntry(id: UUID(), date: date, side: side))
        }

        return result
    }

    private func parseBreastSide(_ value: String) -> BreastSide? {
        switch value.lowercased() {
        case "left", "ліва":
            return .left
        case "right", "права":
            return .right
        default:
            return nil
        }
    }
}
