import Foundation
import SwiftData
import SwiftUI

enum DiaperType: String, Codable, CaseIterable, Identifiable {
    case wet
    case dirty
    case both
    var id: String { rawValue }

    var badgeColor: Color {
        switch self {
        case .wet:   return .moduleGrowth   // blue
        case .dirty: return .moduleDiapers  // amber
        case .both:  return .moduleActivity // pink
        }
    }
}

@Model
final class DiaperEntry {
    var timestamp: Date
    var typeRaw: String
    var weightGrams: Double?
    var baby: Baby?

    var type: DiaperType {
        get { DiaperType(rawValue: typeRaw) ?? .wet }
        set { typeRaw = newValue.rawValue }
    }

    init(timestamp: Date, type: DiaperType, weightGrams: Double? = nil, baby: Baby? = nil) {
        self.timestamp = timestamp
        self.typeRaw = type.rawValue
        self.weightGrams = weightGrams
        self.baby = baby
    }
}
