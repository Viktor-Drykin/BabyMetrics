import Foundation
import Combine

@MainActor
final class GrowthViewModel: ObservableObject {
    enum Metric: String, CaseIterable, Identifiable {
        case weight = "Вага (г)"
        case height = "Зріст (см)"
        case head = "Голова (см)"

        var id: String { rawValue }
    }

    @Published private(set) var entries: [GrowthEntry] = []
    @Published var selectedMetric: Metric = .weight

    @Published var formDate: Date = Date()
    @Published var formWeightText: String = ""
    @Published var formHeightText: String = ""
    @Published var formHeadText: String = ""

    @Published var isImportingCSV = false
    @Published var importErrorMessage: String?

    let csvURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("GrowthHistory.csv")

    private let useCases: GrowthUseCases
    private var cancellables = Set<AnyCancellable>()

    private let csvDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(useCases: GrowthUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.entries = $0 }
            .store(in: &cancellables)
    }

    var chartPoints: [(date: Date, value: Double)] {
        entries.compactMap { entry in
            let value: Double?
            switch selectedMetric {
            case .weight: value = entry.weightGrams
            case .height: value = entry.heightCm
            case .head:   value = entry.headCm
            }
            guard let v = value else { return nil }
            return (date: entry.date, value: v)
        }
        .sorted { $0.date < $1.date }
    }

    var isFormValid: Bool {
        !formWeightText.isEmpty || !formHeightText.isEmpty || !formHeadText.isEmpty
    }

    func saveEntry() {
        let entry = GrowthEntry(
            id: UUID(),
            date: formDate,
            weightGrams: Double(formWeightText.replacingOccurrences(of: ",", with: ".")),
            heightCm: Double(formHeightText.replacingOccurrences(of: ",", with: ".")),
            headCm: Double(formHeadText.replacingOccurrences(of: ",", with: "."))
        )
        useCases.addEntry(entry)
        formDate = Date()
        formWeightText = ""
        formHeightText = ""
        formHeadText = ""
    }

    func updateEntry(id: UUID, date: Date, weightGrams: Double?, heightCm: Double?, headCm: Double?) {
        useCases.updateEntry(id, date, weightGrams, heightCm, headCm)
    }

    func deleteEntries(at offsets: IndexSet) {
        let ids = offsets.map { entries[$0].id }
        useCases.deleteEntries(ids)
    }

    func writeCSVFile() {
        let header = "date,weight_g,height_cm,head_cm"
        let rows = entries.map { entry in
            let date = csvDateFormatter.string(from: entry.date)
            let weight = entry.weightGrams.map { String(Int($0)) } ?? ""
            let height = entry.heightCm.map { String($0) } ?? ""
            let head = entry.headCm.map { String($0) } ?? ""
            return "\(date),\(weight),\(height),\(head)"
        }
        let csv = ([header] + rows).joined(separator: "\n")
        do {
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

    private func parseCSVContent(_ content: String) throws -> [GrowthEntry] {
        struct CSVImportError: LocalizedError {
            let line: Int
            var errorDescription: String? {
                "Невірний CSV формат у рядку \(line). Очікується: yyyy-MM-dd,weight_g,height_cm,head_cm"
            }
        }

        let rawLines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !rawLines.isEmpty else { return [] }

        let lines = rawLines.first?.lowercased().hasPrefix("date") == true
            ? Array(rawLines.dropFirst())
            : rawLines

        return try lines.enumerated().map { index, line in
            let parts = line.split(separator: ",", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespaces) }

            guard parts.count >= 1, let date = csvDateFormatter.date(from: parts[0]) else {
                throw CSVImportError(line: index + 1)
            }

            return GrowthEntry(
                id: UUID(),
                date: date,
                weightGrams: parts.count > 1 ? Double(parts[1]) : nil,
                heightCm: parts.count > 2 ? Double(parts[2]) : nil,
                headCm: parts.count > 3 ? Double(parts[3]) : nil
            )
        }
    }
}
