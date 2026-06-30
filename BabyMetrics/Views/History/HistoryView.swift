import SwiftUI
import SwiftData

/// Calendar-style day picker with a summary of that day's events across all trackers.
struct HistoryView: View {
    @Query(sort: \SleepSession.startTime, order: .reverse) private var sleeps: [SleepSession]
    @Query(sort: \FeedingSession.startTime, order: .reverse) private var feedings: [FeedingSession]
    @Query(sort: \DiaperEntry.timestamp, order: .reverse) private var diapers: [DiaperEntry]
    @Query(sort: \ActivitySession.startTime, order: .reverse) private var activities: [ActivitySession]
    @State private var selectedDay = Calendar.current.startOfDay(for: .now)

    private func onDay<T>(_ items: [T], _ date: (T) -> Date) -> [T] {
        items.filter { Calendar.current.isDate(date($0), inSameDayAs: selectedDay) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DatePicker("Day", selection: $selectedDay, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal, AppSpacing.screenHPadding)

                    daySummary
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("History")
        }
    }

    private var daySummary: some View {
        let daySleeps = onDay(sleeps) { $0.startTime }.filter { !$0.isActive }
        let dayFeeds = onDay(feedings) { $0.startTime }.filter { !$0.isActive }
        let dayDiapers = onDay(diapers) { $0.timestamp }
        let dayActs = onDay(activities) { $0.startTime }.filter { !$0.isActive }
        let isEmpty = daySleeps.isEmpty && dayFeeds.isEmpty && dayDiapers.isEmpty && dayActs.isEmpty

        return VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Summary")
            if isEmpty {
                EmptyStateView(icon: "calendar", message: "No events on this day.")
            } else {
                summaryRow("moon.fill", .moduleSleep, "Sleep", "\(daySleeps.count) · \(DurationFormatter.compact(daySleeps.reduce(0) { $0 + $1.duration }))")
                summaryRow("drop.fill", .moduleFeeding, "Feedings", "\(dayFeeds.count)")
                summaryRow("basket.fill", .moduleDiapers, "Diapers", "\(dayDiapers.count)")
                summaryRow("figure.roll", .moduleActivity, "Activities", "\(dayActs.count) · \(DurationFormatter.compact(dayActs.reduce(0) { $0 + TimeInterval($1.durationSeconds) }))")
            }
        }
    }

    private func summaryRow(_ icon: String, _ color: Color, _ title: LocalizedStringResource, _ value: String) -> some View {
        SessionLogRow(title: title, subtitle: "", value: value, valueColor: color, icon: icon, iconColor: color)
            .padding(.horizontal, AppSpacing.screenHPadding)
    }
}
