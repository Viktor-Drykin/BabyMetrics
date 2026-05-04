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
    var date: Date
    var side: BreastSide
}
