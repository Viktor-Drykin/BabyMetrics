import Foundation
import Combine

@MainActor
final class RecordDiaperViewModel: ObservableObject {
    @Published var showSavedMessage = false
    @Published var weightInput: String = ""
    @Published private(set) var entries: [DiaperEntry] = []

    private let useCases: DiaperUseCases
    private var cancellables = Set<AnyCancellable>()

    init(useCases: DiaperUseCases) {
        self.useCases = useCases
        entries = useCases.getEntries()

        useCases.observeEntries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.entries = $0
            }
            .store(in: &cancellables)
    }

    var recentEntries: [DiaperEntry] {
        Array(entries.sorted { $0.date > $1.date }.prefix(8))
    }

    var todayEntries: [DiaperEntry] {
        let calendar = Calendar.current
        let now = Date()
        return entries.filter { calendar.isDate($0.date, inSameDayAs: now) }
    }

    var todayDiaperCount: Int {
        todayEntries.count
    }

    var todayTotalWeightGrams: Int {
        todayEntries.reduce(0) { $0 + max(0, $1.weightGrams ?? 0) }
    }

    func logDiaper(type: DiaperType) {
        let weight = Int(weightInput.trimmingCharacters(in: .whitespaces))
        useCases.addEntry(Date(), type, weight)
        showSavedMessage = true
        weightInput = ""
    }

    func hideSavedMessage() {
        showSavedMessage = false
    }
}
