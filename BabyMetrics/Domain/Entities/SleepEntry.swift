import Foundation

struct SleepEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var startDate: Date
    var endDate: Date

    var duration: TimeInterval {
        max(0, endDate.timeIntervalSince(startDate))
    }
}
