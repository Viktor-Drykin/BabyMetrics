import SwiftUI
import Charts
import UIKit
import UniformTypeIdentifiers

struct SleepHistoryView: View {
    @StateObject var viewModel: SleepHistoryViewModel
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

    private var chartContent: some View {
        Chart(viewModel.durationChartPoints) { point in
            BarMark(
                x: .value("Період", point.date),
                y: .value("Годин", point.durationHours)
            )
            .foregroundStyle(Color.indigo)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }

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
                    "Історія сну порожня",
                    systemImage: "bed.double",
                    description: Text("Запишіть перший сон на вкладці Сон.")
                )
            } else {
                VStack {
                    Picker("Фільтр", selection: $viewModel.selectedFilter) {
                        ForEach(SleepHistoryViewModel.Filter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Picker("Режим", selection: $viewModel.selectedMode) {
                        ForEach(SleepHistoryViewModel.DisplayMode.allCases) { mode in
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
                                            EditSleepEntryView(viewModel: viewModel, entry: entry)
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
                                        Text(viewModel.chartTitle)
                                            .font(.headline)

                                        chartContent
                                            .frame(height: 300)

                                        let totalHours = viewModel.filteredEntries.reduce(0.0) { $0 + $1.duration } / 3600.0
                                        Text("Усього сну: \(String(format: "%.1f", totalHours)) год")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary)

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
        .navigationTitle("Історія сну")
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
            ToolbarItem(placement: .topBarLeading) {
                if !viewModel.entries.isEmpty, viewModel.selectedMode == .chart {
                    ShareLink(item: viewModel.chartImageURL) {
                        Label("Поділитися графіком", systemImage: "photo")
                    }
                }
            }
        }
        .task {
            viewModel.writeCSVFile()
            updateChartImageFile()
        }
        .onChange(of: viewModel.entries) { _, _ in
            viewModel.writeCSVFile()
            updateChartImageFile()
        }
        .onChange(of: viewModel.selectedFilter) { _, _ in updateChartImageFile() }
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

    @MainActor
    private func updateChartImageFile() {
        guard !viewModel.filteredEntries.isEmpty else { return }

        let exportView = VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.chartTitle)
                .font(.title3.weight(.semibold))

            chartContent
                .frame(height: 320)

            let totalHours = viewModel.filteredEntries.reduce(0.0) { $0 + $1.duration } / 3600.0
            Text("Усього сну: \(String(format: "%.1f", totalHours)) год")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 900)
        .background(Color.white)

        let renderer = ImageRenderer(content: exportView)
        #if os(iOS)
        guard let image = renderer.uiImage, let data = image.pngData() else { return }
        viewModel.writeChartImage(data: data)
        #endif
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

struct EditSleepEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: SleepHistoryViewModel
    let entry: SleepEntry

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showValidationAlert = false

    init(viewModel: SleepHistoryViewModel, entry: SleepEntry) {
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
