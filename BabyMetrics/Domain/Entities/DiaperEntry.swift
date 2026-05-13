import Foundation

enum DiaperType: String, CaseIterable, Codable, Identifiable {
    case wet = "Wet"
    case dirty = "Dirty"
    case mixed = "Mixed"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .wet:   return "Мокрий"
        case .dirty: return "Брудний"
        case .mixed: return "Обидва"
        }
    }

    var systemImage: String {
        switch self {
        case .wet:   return "drop.fill"
        case .dirty: return "circle.fill"
        case .mixed: return "arrow.2.circlepath"
        }
    }

    var color: String {
        switch self {
        case .wet:   return "blue"
        case .dirty: return "brown"
        case .mixed: return "purple"
        }
    }
}

struct DiaperEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var type: DiaperType
    var weightGrams: Int?
}
