import Foundation
import SwiftData

enum BreastSide: String, Codable, CaseIterable, Identifiable {
    case left
    case right
    case both
    var id: String { rawValue }
}

@Model
final class FeedingSession {
    var startTime: Date
    var endTime: Date?           // nil = in progress
    var sideRaw: String
    var durationSeconds: Int
    var baby: Baby?

    var side: BreastSide {
        get { BreastSide(rawValue: sideRaw) ?? .left }
        set { sideRaw = newValue.rawValue }
    }

    var isActive: Bool { endTime == nil }

    init(startTime: Date, endTime: Date? = nil, side: BreastSide, durationSeconds: Int, baby: Baby? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.sideRaw = side.rawValue
        self.durationSeconds = durationSeconds
        self.baby = baby
    }
}
