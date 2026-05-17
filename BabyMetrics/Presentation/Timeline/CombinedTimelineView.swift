import SwiftUI

struct CombinedTimelineView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case events = "Події"
        case days = "Дні"

        var id: String { rawValue }
    }

    @StateObject var viewModel: CombinedTimelineViewModel
    @State private var selectedMode: Mode = .events

    private let todayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.setLocalizedDateFormatFromTemplate("HH:mm")
        return formatter
    }()

    private let currentYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.setLocalizedDateFormatFromTemplate("d MMM, HH:mm")
        return formatter
    }()

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

    private let pastYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.setLocalizedDateFormatFromTemplate("d MMM yyyy, HH:mm")
        return formatter
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Picker("Режим", selection: $selectedMode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                Group {
                    if viewModel.events.isEmpty {
                        ContentUnavailableView(
                            "Ще немає записів",
                            systemImage: "tray",
                            description: Text("Додайте годування, сон, підгузок або розминку.")
                        )
                    } else if selectedMode == .events {
                        List {
                            ForEach(viewModel.daySections) { section in
                                Section {
                                    ForEach(section.events) { event in
                                        row(for: event)
                                            .padding(.vertical, 4)
                                    }
                                } header: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(dayTitleString(from: section.date))
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(.primary)

                                        Text(
                                            "Годувань: \(section.feedingCount) | Снів: \(section.sleepCount) | Підгузків: \(section.diaperCount) (вага: \(section.totalDiaperWeightGrams) г) | Розминка: \(section.tummyTimeCount) (\(viewModel.durationString(fromSeconds: Int(section.totalTummyTimeDuration)))) | Сон: \(viewModel.durationString(fromSeconds: Int(section.totalSleepDuration)))"
                                        )
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.primary.opacity(0.92))
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.primary.opacity(0.24), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.12), radius: 7, x: 0, y: 2)
                                    .padding(.vertical, 4)
                                    .textCase(nil)
                                }
                            }
                        }
                        .listStyle(.plain)
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

                                    Text("Підгузків: \(section.diaperCount)")
                                        .font(.subheadline)

                                    Text("Розминок: \(section.tummyTimeCount)")
                                        .font(.subheadline)

                                    Text("Загальна розминка: \(viewModel.durationString(fromSeconds: Int(section.totalTummyTimeDuration)))")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.orange)

                                    Text("Вага підгузків: \(section.totalDiaperWeightGrams) г")
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
            }
            .navigationTitle("Стрічка")
            .background(AppTheme.warmBackground.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private func row(for event: CombinedTimelineViewModel.EventItem) -> some View {
        switch event.kind {
        case .feeding(let side, let duration):
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(historyDateString(from: event.date))
                    Text("Годування")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(side.localizedTitle)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(side == .left ? Color.blue.opacity(0.18) : Color.green.opacity(0.2))
                        .foregroundStyle(side == .left ? Color.blue : Color.green)
                        .clipShape(Capsule())

                    Text(viewModel.durationString(fromSeconds: Int(duration)))
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
        case .sleep(let startDate, let endDate):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(historyDateString(from: startDate))
                    Spacer()
                    Text(viewModel.durationString(from: startDate, to: endDate))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.indigo.opacity(0.2))
                        .foregroundStyle(Color.indigo)
                        .clipShape(Capsule())
                }

                Text("Сон: \(historyDateString(from: startDate)) - \(historyDateString(from: endDate))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .diaper(let type, _):
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(historyDateString(from: event.date))
                    Text("Підгузок")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(type.localizedTitle)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(diaperColor(for: type).opacity(0.18))
                    .foregroundStyle(diaperColor(for: type))
                    .clipShape(Capsule())
            }
        case .tummyTime(let startDate, let endDate):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(historyDateString(from: startDate))
                    Spacer()
                    Text(viewModel.durationString(from: startDate, to: endDate))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(Color.orange)
                        .clipShape(Capsule())
                }

                Text("Розминка: \(historyDateString(from: startDate)) - \(historyDateString(from: endDate))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func diaperColor(for type: DiaperType) -> Color {
        switch type {
        case .wet:   return .blue
        case .dirty: return .brown
        case .mixed: return .purple
        }
    }

    private func historyDateString(from date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return todayFormatter.string(from: date)
        }

        let entryYear = calendar.component(.year, from: date)
        let currentYear = calendar.component(.year, from: Date())
        return entryYear == currentYear
            ? currentYearFormatter.string(from: date)
            : pastYearFormatter.string(from: date)
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
