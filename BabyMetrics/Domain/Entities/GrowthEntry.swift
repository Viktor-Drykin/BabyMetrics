import Foundation

struct GrowthEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var weightKg: Double?
    var heightCm: Double?
    var headCm: Double?
}
