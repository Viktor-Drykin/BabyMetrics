import SwiftUI
import Charts
import UniformTypeIdentifiers

struct TummyTimeHistoryView: View {
    @StateObject var viewModel: TummyTimeHistoryViewModel
    var isEmbedded = false

    private let currentYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.setLocalizedDateFormatFromTemplate("d MMM, HH:mm")
        return formatter
    }()

    private let todayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.setLocalizedDateFormatFromTemplate("HH:mm")
        return formatter
    }()

    private let pastYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.setLocalizedDateFormatFromTemplate("d MMM yyyy, HH:mm")
        return formatter
    }()

    @ViewBuilder
    var body: some View {
        if isEmbedded {
            content
        } else {
            NavigationStack {
                content
            }
        }
    }

    private var content: some View {
        Group {
            if viewModel.entries.isEmpty {
                ContentUnavailableView(
                    "Історія розминки порожня",
                    systemImage: "figure.play",
                    description: Text("Запишіть першу сесію на вкладці Розминка.")
                )
            } else {
                VStack {
                    Picker("Фільтр", selection: $viewModel.selectedFilter) {
                        ForEach(TummyTimeHistoryViewModel.Filter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Picker("Режим", selection: $viewModel.selectedMode) {
                        ForEach(TummyTimeHistoryViewModel.DisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 4)

                    if viewModel.filteredEntries.isEmpty {
                        ContentUnavailableView(
                            "Немає результатів",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("Спробуйте інший фільтр.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Group {
                            if viewModel.selectedMode == .list {
                                List {
                                    ForEach(viewModel.filteredEntries) { entry in
                                        NavigationLink {
                                            EditTummyTimeEntryView(viewModel: viewModel, entry: entry)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text("Початок: \(historyDateString(from: entry.startDate))")
                                                Text("Кінець: \(historyDateString(from: entry.endDate))")
                                                    .foregroundStyle(.secondary)
                                                Text("Тривалість: \(viewModel.durationString(for: entry))")
                                                    .font(.subheadline.weight(.semibold))
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .onDelete(perform: viewModel.deleteFilteredEntries)
                                }
                                .listStyle(.plain)
                            } else {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 16) {
                                        summaryCards

                                        Picker("Метрика", selection: $viewModel.selectedChartMetric) {
                                            ForEach(TummyTimeHistoryViewModel.ChartMetric.allCases) { metric in
                                                Text(metric.rawValue).tag(metric)
                                            }
                                        }
                                        .pickerStyle(.segmented)

                                        Text(viewModel.chartTitle)
                                            .font(.headline)

                                        chartContent
                                            .frame(height: 300)

                                        Spacer(minLength: 36)
                                    }
                                    .padding()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
            }
        }
        .navigationTitle("Історія розминки")
        .background(AppTheme.warmBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.isImportingCSV = true
                    } label: {
                        Label("Імпортувати CSV", systemImage: "tray.and.arrow.down")
                    }

                    if !viewModel.entries.isEmpty {
                        ShareLink(item: viewModel.csvURL) {
                            Label("Поділитися CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            viewModel.writeCSVFile()
        }
        .onChange(of: viewModel.entries) { _, _ in
            viewModel.writeCSVFile()
        }
        .fileImporter(
            isPresented: $viewModel.isImportingCSV,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleCSVImport(result)
        }
        .alert(
            "Помилка імпорту",
            isPresented: Binding(
                get: { viewModel.importErrorMessage != nil },
                set: { if !$0 { viewModel.importErrorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.importErrorMessage ?? "Невідома помилка") }
        )
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metricCard(
                title: "Усього часу",
                value: DurationTextFormatter.stringWithoutSeconds(fromSeconds: viewModel.totalDurationSeconds)
            )
            metricCard(title: "Сесій", value: "\(viewModel.totalSessions)")
            metricCard(
                title: "Середня",
                value: DurationTextFormatter.stringWithoutSeconds(fromSeconds: viewModel.averageDurationSeconds)
            )
            metricCard(
                title: "Найдовша",
                value: DurationTextFormatter.stringWithoutSeconds(fromSeconds: viewModel.longestSessionSeconds)
            )
            metricCard(title: "Активні дні", value: "\(viewModel.activeDaysCount)")
            metricCard(title: "Стабільність", value: viewModel.consistencyText)
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var chartContent: some View {
        switch viewModel.selectedChartMetric {
        case .duration:
            Chart(viewModel.durationChartPoints) { point in
                BarMark(
                    x: .value("Період", point.date),
                    y: .value("Годин", point.hours)
                )
                .foregroundStyle(Color.orange)
            }
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 6)) }
            .chartYAxis { AxisMarks(position: .leading) }
        case .sessions:
            Chart(viewModel.sessionCountChartPoints) { point in
                BarMark(
                    x: .value("Період", point.date),
                    y: .value("Сесій", point.count)
                )
                .foregroundStyle(Color.teal)
            }
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 6)) }
            .chartYAxis { AxisMarks(position: .leading) }
        case .average:
            Chart(viewModel.averageDurationChartPoints) { point in
                LineMark(
                    x: .value("Період", point.date),
                    y: .value("Хвилин", point.minutes)
                )
                .foregroundStyle(Color.indigo)
                PointMark(
                    x: .value("Період", point.date),
                    y: .value("Хвилин", point.minutes)
                )
                .foregroundStyle(Color.indigo)
            }
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 6)) }
            .chartYAxis { AxisMarks(position: .leading) }
        case .dayPart:
            Chart(viewModel.dayPartChartPoints) { point in
                BarMark(
                    x: .value("Частина дня", point.part.rawValue),
                    y: .value("Сесій", point.count)
                )
                .foregroundStyle(Color.orange)
            }
            .chartYAxis { AxisMarks(position: .leading) }
        }
    }

    private func historyDateString(from date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return todayFormatter.string(from: date) }
        let entryYear = calendar.component(.year, from: date)
        let currentYear = calendar.component(.year, from: Date())
        return entryYear == currentYear
            ? currentYearFormatter.string(from: date)
            : pastYearFormatter.string(from: date)
    }
}

struct EditTummyTimeEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: TummyTimeHistoryViewModel
    let entry: TummyTimeEntry

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showValidationAlert = false

    init(viewModel: TummyTimeHistoryViewModel, entry: TummyTimeEntry) {
        self.viewModel = viewModel
        self.entry = entry
        _startDate = State(initialValue: entry.startDate)
        _endDate = State(initialValue: entry.endDate)
    }

    var body: some View {
        Form {
            DatePicker("Початок", selection: $startDate)
            DatePicker("Кінець", selection: $endDate)

            Button("Зберегти зміни") {
                guard endDate > startDate else {
                    showValidationAlert = true
                    return
                }
                viewModel.updateEntry(id: entry.id, startDate: startDate, endDate: endDate)
                dismiss()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("Редагування")
        .alert("Невірні дані", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Час закінчення має бути пізніше часу початку.")
        }
    }
}
