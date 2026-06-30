import SwiftUI

/// A navigable module reachable from the home grid.
enum Module: String, Identifiable, CaseIterable, Hashable {
    case sleep, feeding, growth, diapers, activities
    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .sleep: return "Sleep"
        case .feeding: return "Feeding"
        case .growth: return "Growth"
        case .diapers: return "Diapers"
        case .activities: return "Activities"
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .feeding: return "drop.fill"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .diapers: return "basket.fill"
        case .activities: return "figure.mixed.cardio"
        }
    }

    var color: Color {
        switch self {
        case .sleep: return .moduleSleep
        case .feeding: return .moduleFeeding
        case .growth: return .moduleGrowth
        case .diapers: return .moduleDiapers
        case .activities: return .moduleActivity
        }
    }

    var darkColor: Color {
        switch self {
        case .sleep: return .sleepDark
        case .feeding: return .feedingDark
        case .growth: return .growthDark
        case .diapers: return .diapersDark
        case .activities: return .activityDark
        }
    }
}

/// Destinations pushed within a `NavigationStack`. Tummy time is a shortcut into Activities.
enum Route: Hashable {
    case module(Module)
    case tummyTime
}
