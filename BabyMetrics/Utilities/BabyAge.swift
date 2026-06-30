import Foundation

extension Baby {
    /// Human-readable age, e.g. "3 months 12 days old". Empty if birth date is in the future.
    func ageDescription(now: Date = .now, calendar: Calendar = .current) -> String {
        guard birthDate <= now else { return "" }
        let comps = calendar.dateComponents([.month, .day], from: birthDate, to: now)
        let months = comps.month ?? 0
        let days = comps.day ?? 0
        let monthsPart = months > 0 ? String(localized: "\(months) months") : ""
        let daysPart = String(localized: "\(days) days")
        return [monthsPart, daysPart].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var displayName: String {
        name.isEmpty ? String(localized: "Baby") : name
    }
}
