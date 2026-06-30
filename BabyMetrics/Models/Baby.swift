import Foundation
import SwiftData

@Model
final class Baby {
    var name: String
    var birthDate: Date
    var photoData: Data?

    @Relationship(deleteRule: .cascade, inverse: \SleepSession.baby)
    var sleepSessions: [SleepSession] = []
    @Relationship(deleteRule: .cascade, inverse: \FeedingSession.baby)
    var feedingSessions: [FeedingSession] = []
    @Relationship(deleteRule: .cascade, inverse: \DiaperEntry.baby)
    var diaperEntries: [DiaperEntry] = []
    @Relationship(deleteRule: .cascade, inverse: \GrowthEntry.baby)
    var growthEntries: [GrowthEntry] = []
    @Relationship(deleteRule: .cascade, inverse: \ActivitySession.baby)
    var activitySessions: [ActivitySession] = []

    init(name: String = "", birthDate: Date = .now, photoData: Data? = nil) {
        self.name = name
        self.birthDate = birthDate
        self.photoData = photoData
    }
}
