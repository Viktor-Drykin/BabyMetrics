import SwiftUI

extension Color {
    /// Creates a color from a hex string such as `#7F77DD` or `7F77DD`.
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let r, g, b, a: Double
        switch sanitized.count {
        case 8: // RRGGBBAA
            r = Double((value & 0xFF00_0000) >> 24) / 255
            g = Double((value & 0x00FF_0000) >> 16) / 255
            b = Double((value & 0x0000_FF00) >> 8) / 255
            a = Double(value & 0x0000_00FF) / 255
        default: // RRGGBB (and any malformed input falls back to opaque)
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    // MARK: Module identity colors
    static let moduleSleep    = Color(hex: "#7F77DD") // purple
    static let moduleFeeding  = Color(hex: "#1D9E75") // teal
    static let moduleGrowth   = Color(hex: "#378ADD") // blue
    static let moduleDiapers  = Color(hex: "#BA7517") // amber
    static let moduleActivity = Color(hex: "#D4537E") // pink
    static let moduleTummy    = Color(hex: "#639922") // green

    // MARK: Dark header variants (for module headers)
    static let sleepDark      = Color(hex: "#3C3489")
    static let feedingDark    = Color(hex: "#0F6E56")
    static let growthDark     = Color(hex: "#185FA5")
    static let activityDark   = Color(hex: "#72243E")
    static let diapersDark    = Color(hex: "#854F0B")

    // MARK: Light fill variants (for cards and backgrounds)
    static let sleepLight     = Color(hex: "#EEEDFE")
    static let feedingLight   = Color(hex: "#E1F5EE")
    static let growthLight    = Color(hex: "#E6F1FB")
    static let activityLight  = Color(hex: "#FBEAF0")
    static let diapersLight   = Color(hex: "#FAEEDA")
    static let tummyLight     = Color(hex: "#EAF3DE")
}
