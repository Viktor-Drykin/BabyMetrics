import SwiftUI

struct DailySummaryView: View {
    @StateObject var viewModel: CombinedTimelineViewModel

    private let dayCurrentYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    private let dayPastYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.daySections.isEmpty {
                    ContentUnavailableView(
                        "Ще немає записів",
                        systemImage: "tray",
                        description: Text("Додайте годування або запис сну.")
                    )
                } else {
                    List {
                        ForEach(viewModel.daySections) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(dayTitleString(from: section.date))
                                    .font(.headline)

                                Text("Годувань: \(section.feedingCount)")
                                    .font(.subheadline)

                                Text("Снів: \(section.sleepCount)")
                                    .font(.subheadline)

                                Text("Загальний сон: \(viewModel.durationString(fromSeconds: Int(section.totalSleepDuration)))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.indigo)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Підсумок по днях")
            .background(AppTheme.warmBackground.ignoresSafeArea())
        }
    }

    private func dayTitleString(from date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Сьогодні"
        }
        if calendar.isDateInYesterday(date) {
            return "Вчора"
        }

        let entryYear = calendar.component(.year, from: date)
        let currentYear = calendar.component(.year, from: Date())
        return entryYear == currentYear
            ? dayCurrentYearFormatter.string(from: date)
            : dayPastYearFormatter.string(from: date)
    }
}
