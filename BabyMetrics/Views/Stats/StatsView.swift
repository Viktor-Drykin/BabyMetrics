import SwiftUI
import SwiftData
import Charts

/// Weekly aggregates across trackers.
struct StatsView: View {
    @Query private var sleeps: [SleepSession]
    @Query private var feedings: [FeedingSession]
    @Query private var diapers: [DiaperEntry]

    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    chartSection(title: "Sleep (hours/day)", color: .moduleSleep) { day in
                        sleeps.filter { Calendar.current.isDate($0.startTime, inSameDayAs: day) }
                            .reduce(0) { $0 + $1.duration } / 3600
                    }
                    chartSection(title: "Feedings/day", color: .moduleFeeding) { day in
                        Double(feedings.filter { !$0.isActive && Calendar.current.isDate($0.startTime, inSameDayAs: day) }.count)
                    }
                    chartSection(title: "Diapers/day", color: .moduleDiapers) { day in
                        Double(diapers.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: day) }.count)
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Stats")
        }
    }

    @ViewBuilder
    private func chartSection(title: LocalizedStringResource, color: Color, value: @escaping (Date) -> Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).sectionHeadingStyle().padding(.horizontal, AppSpacing.screenHPadding)
            Chart(days, id: \.self) { day in
                BarMark(
                    x: .value("Day", day, unit: .day),
                    y: .value("Value", value(day))
                )
                .foregroundStyle(color)
                .cornerRadius(4)
            }
            .frame(height: 140)
            .padding(.horizontal, AppSpacing.screenHPadding)
        }
    }
}
