import Foundation

/// Formats time intervals for display. Replaces the old `DurationTextFormatter`.
enum DurationFormatter {
    /// `HH:MM:SS` clock style for live timers.
    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// Compact, locale-aware style for logs, e.g. "1h 5m" / "45m" / "30s".
    static func compact(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        if total < 60 { return "\(total)s" }
        let h = total / 3600
        let m = (total % 3600) / 60
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    /// "X min ago" / "Xh ago" relative to now, for "Last: …" subtitles.
    static func relativeSince(_ date: Date, now: Date = .now) -> String {
        let interval = max(0, now.timeIntervalSince(date))
        if interval < 60 { return "just now" }
        return compact(interval) + " ago"
    }
}
