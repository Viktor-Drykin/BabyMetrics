import Foundation
import SwiftData

enum ActivityType: String, Codable, CaseIterable, Identifiable {
    case exercise
    case massage
    case tummyTime
    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .exercise:  return "figure.mixed.cardio"
        case .massage:   return "hands.and.sparkles.fill"
        case .tummyTime: return "figure.roll"
        }
    }
}

@Model
final class ActivitySession {
    var startTime: Date
    var endTime: Date?           // nil = in progress
    var typeRaw: String
    var durationSeconds: Int
    var baby: Baby?

    var type: ActivityType {
        get { ActivityType(rawValue: typeRaw) ?? .tummyTime }
        set { typeRaw = newValue.rawValue }
    }

    var isActive: Bool { endTime == nil }

    init(startTime: Date, endTime: Date? = nil, type: ActivityType, durationSeconds: Int, baby: Baby? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.typeRaw = type.rawValue
        self.durationSeconds = durationSeconds
        self.baby = baby
    }
}
