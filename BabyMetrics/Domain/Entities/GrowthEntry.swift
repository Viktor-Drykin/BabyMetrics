import Foundation

struct GrowthEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var weightGrams: Double?
    var heightCm: Double?
    var headCm: Double?
}
