import Foundation

enum BreastSide: String, CaseIterable, Codable, Identifiable {
    case left = "Left"
    case right = "Right"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .left:
            return "Ліва"
        case .right:
            return "Права"
        }
    }
}

struct FeedingEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var startDate: Date
    var endDate: Date
    var side: BreastSide

    var duration: TimeInterval {
        max(0, endDate.timeIntervalSince(startDate))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case side
        case date
    }

    init(id: UUID, startDate: Date, endDate: Date, side: BreastSide) {
        self.id = id
        self.startDate = min(startDate, endDate)
        self.endDate = max(startDate, endDate)
        self.side = side
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let side = try container.decode(BreastSide.self, forKey: .side)

        if let startDate = try container.decodeIfPresent(Date.self, forKey: .startDate),
           let endDate = try container.decodeIfPresent(Date.self, forKey: .endDate) {
            self.init(id: id, startDate: startDate, endDate: endDate, side: side)
            return
        }

        let legacyDate = try container.decode(Date.self, forKey: .date)
        self.init(id: id, startDate: legacyDate, endDate: legacyDate, side: side)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(side, forKey: .side)
    }
}
