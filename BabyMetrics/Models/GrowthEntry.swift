import Foundation
import SwiftData

@Model
final class GrowthEntry {
    var date: Date
    var weightKg: Double?
    var heightCm: Double?
    var headCircumferenceCm: Double?
    var notes: String?
    var source: String?
    var baby: Baby?

    init(date: Date,
         weightKg: Double? = nil,
         heightCm: Double? = nil,
         headCircumferenceCm: Double? = nil,
         notes: String? = nil,
         source: String? = nil,
         baby: Baby? = nil) {
        self.date = date
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.headCircumferenceCm = headCircumferenceCm
        self.notes = notes
        self.source = source
        self.baby = baby
    }
}
