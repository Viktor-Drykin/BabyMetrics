import Foundation
import SwiftData

enum SleepType: String, Codable, CaseIterable, Identifiable {
    case night
    case nap
    var id: String { rawValue }

    /// Infers night vs nap from the start time (19:00–06:00 ⇒ night).
    static func inferred(from start: Date, calendar: Calendar = .current) -> SleepType {
        let hour = calendar.component(.hour, from: start)
        return (hour >= 19 || hour < 6) ? .night : .nap
    }
}

@Model
final class SleepSession {
    var startTime: Date
    var endTime: Date?            // nil = currently sleeping
    var typeRaw: String
    var baby: Baby?

    var type: SleepType {
        get { SleepType(rawValue: typeRaw) ?? .nap }
        set { typeRaw = newValue.rawValue }
    }

    var isActive: Bool { endTime == nil }

    var duration: TimeInterval {
        guard let endTime else { return 0 }
        return max(0, endTime.timeIntervalSince(startTime))
    }

    init(startTime: Date, endTime: Date? = nil, type: SleepType, baby: Baby? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.typeRaw = type.rawValue
        self.baby = baby
    }
}
