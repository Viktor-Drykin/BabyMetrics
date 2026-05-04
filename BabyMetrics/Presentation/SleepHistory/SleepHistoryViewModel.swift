import Foundation
import Combine

@MainActor
final class SleepHistoryViewModel: ObservableObject {
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

    struct SleepChartPoint: Identifiable {
        let date: Date
        let durationHours: Double

        var id: String { "\(date.timeIntervalSince1970)" }
    }

    @Published private(set) var entries: [SleepEntry] = []
    @Published var selectedFilter: Filter = .today
    @Published var selectedMode: DisplayMode = .list
    @Published var isImportingCSV = false
    @Published var importErrorMessage: String?

    let csvURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("SleepHistory.csv")
    let chartImageURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("SleepChart.png")

    private let useCases: SleepUseCases
    private var cancellables = Set<AnyCancellable>()

    init(useCases: SleepUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.entries = $0
            }
            .store(in: &cancellables)
    }

    var filteredEntries: [SleepEntry] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedFilter {
        case .all:
            return entries
        case .today:
            return entries.filter { calendar.isDate($0.startDate, inSameDayAs: now) }
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return entries }
            return entries.filter { interval.contains($0.startDate) }
        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: now) else { return entries }
            return entries.filter { interval.contains($0.startDate) }
        }
    }

    var durationChartPoints: [SleepChartPoint] {
        let calendar = Calendar.current
        var grouped: [Date: Double] = [:]

        for entry in filteredEntries {
            let bucketDate = calendar.startOfDay(for: entry.startDate)
            grouped[bucketDate, default: 0] += entry.duration / 3600.0
        }

        return grouped
            .map { SleepChartPoint(date: $0.key, durationHours: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var chartTitle: String { "Тривалість сну по днях (год)" }

    func deleteFilteredEntries(at offsets: IndexSet) {
        let ids = offsets.map { filteredEntries[$0].id }
        useCases.deleteEntries(ids)
    }

    func updateEntry(id: UUID, startDate: Date, endDate: Date) {
        useCases.updateEntry(id, startDate, endDate)
    }

    func durationString(for entry: SleepEntry) -> String {
        let seconds = Int(entry.duration)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return "\(hours) год \(minutes) хв"
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

    private func parseCSVContent(_ content: String) throws -> [SleepEntry] {
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

        let lines: [String]
        if rawLines.first?.lowercased() == "start_date,end_date,duration_minutes" {
            lines = Array(rawLines.dropFirst())
        } else if rawLines.first?.lowercased() == "start_date,end_date" {
            lines = Array(rawLines.dropFirst())
        } else {
            lines = rawLines
        }

        var result: [SleepEntry] = []

        for (index, line) in lines.enumerated() {
            let parts = line.split(separator: ",", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespaces) }

            guard parts.count >= 2,
                  let startDate = formatter.date(from: parts[0]),
                  let endDate = formatter.date(from: parts[1]) else {
                throw CSVImportError(line: index + 1)
            }

            result.append(
                SleepEntry(
                    id: UUID(),
                    startDate: min(startDate, endDate),
                    endDate: max(startDate, endDate)
                )
            )
        }

        return result
    }
}
