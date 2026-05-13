import Foundation
import Combine

@MainActor
final class DiaperHistoryViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all   = "Усі"
        case today = "Сьогодні"
        case week  = "Тиждень"
        case month = "Місяць"

        var id: String { rawValue }
    }

    enum DisplayMode: String, CaseIterable, Identifiable {
        case list  = "Список"
        case chart = "Діаграма"

        var id: String { rawValue }
    }

    struct DiaperChartPoint: Identifiable {
        let date: Date
        let type: DiaperType
        let count: Int

        var id: String { "\(date.timeIntervalSince1970)-\(type.rawValue)" }
    }

    @Published private(set) var entries: [DiaperEntry] = []
    @Published var selectedFilter: Filter = .today
    @Published var selectedMode: DisplayMode = .list
    @Published var isImportingCSV = false
    @Published var importErrorMessage: String?

    let csvURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("DiaperHistory.csv")

    private let useCases: DiaperUseCases
    private var cancellables = Set<AnyCancellable>()

    init(useCases: DiaperUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.entries = $0 }
            .store(in: &cancellables)
    }

    var filteredEntries: [DiaperEntry] {
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

    var typeChartPoints: [DiaperChartPoint] {
        let calendar = Calendar.current
        var grouped: [Date: [DiaperType: Int]] = [:]

        for entry in filteredEntries {
            let day = calendar.startOfDay(for: entry.date)
            grouped[day, default: [:]][entry.type, default: 0] += 1
        }

        return grouped
            .flatMap { date, types in
                types.map { type, count in DiaperChartPoint(date: date, type: type, count: count) }
            }
            .sorted { $0.date < $1.date }
    }

    var chartTitle: String { "Підгузки по днях" }

    func deleteFilteredEntries(at offsets: IndexSet) {
        let ids = offsets.map { filteredEntries[$0].id }
        useCases.deleteEntries(ids)
    }

    func updateEntry(id: UUID, date: Date, type: DiaperType, weightGrams: Int?) {
        useCases.updateEntry(id, date, type, weightGrams)
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
            let imported = try parseCSVContent(content)
            useCases.replaceAllEntries(imported)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func parseCSVContent(_ content: String) throws -> [DiaperEntry] {
        struct CSVImportError: LocalizedError {
            let line: Int
            var errorDescription: String? {
                "Невірний CSV формат у рядку \(line). Очікується: yyyy-MM-dd HH:mm:ss,Wet|Dirty|Mixed[,weight_g]"
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
        let lines = (firstLower == "date,type" || firstLower == "date,type,weight_g")
            ? Array(rawLines.dropFirst())
            : rawLines

        return try lines.enumerated().map { index, line in
            let parts = line.split(separator: ",", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespaces) }

            guard parts.count >= 2,
                  let date = formatter.date(from: parts[0]),
                  let type = DiaperType(rawValue: parts[1].capitalized) else {
                throw CSVImportError(line: index + 1)
            }

            let weightGrams: Int? = parts.count >= 3 ? Int(parts[2]) : nil
            return DiaperEntry(id: UUID(), date: date, type: type, weightGrams: weightGrams)
        }
    }
}
