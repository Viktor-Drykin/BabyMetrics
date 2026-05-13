import Foundation
import Combine

@MainActor
final class RecordDiaperViewModel: ObservableObject {
    @Published var showSavedMessage = false
    @Published var weightInput: String = ""

    private let useCases: DiaperUseCases

    init(useCases: DiaperUseCases) {
        self.useCases = useCases
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
