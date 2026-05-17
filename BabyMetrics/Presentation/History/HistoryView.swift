import SwiftUI
import Charts
import UIKit
import UniformTypeIdentifiers

struct HistoryView: View {
    @StateObject var viewModel: HistoryViewModel
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
        Chart(viewModel.sideChartPoints) { point in
            BarMark(
                x: .value("Період", point.date),
                y: .value("Кількість", point.count)
            )
            .position(by: .value("Сторона", point.side.localizedTitle))
            .foregroundStyle(by: .value("Сторона", point.side.localizedTitle))
        }
        .chartForegroundStyleScale([
            "Ліва": Color.blue,
            "Права": Color.green
        ])
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
                    "Історія порожня",
                    systemImage: "tray",
                    description: Text("Збережіть перше годування на вкладці Запис.")
                )
            } else {
                VStack {
                    Picker("Фільтр", selection: $viewModel.selectedFilter) {
                        ForEach(HistoryViewModel.Filter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Picker("Режим", selection: $viewModel.selectedMode) {
                        ForEach(HistoryViewModel.DisplayMode.allCases) { mode in
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
                                            EditFeedingView(viewModel: viewModel, entry: entry)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(historyDateString(from: entry.startDate))
                                                    Text(entry.side.localizedTitle)
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                    Text(DurationTextFormatter.string(from: entry.startDate, to: entry.endDate))
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }

                                                Spacer()

                                                Text(entry.side.localizedTitle)
                                                    .font(.caption.weight(.semibold))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(entry.side == .left ? Color.blue.opacity(0.18) : Color.green.opacity(0.2))
                                                    .foregroundStyle(entry.side == .left ? Color.blue : Color.green)
                                                    .clipShape(Capsule())
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

                                        Text("Усього годувань: \(viewModel.filteredEntries.count)")
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
        .navigationTitle("Історія")
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
        .onChange(of: viewModel.selectedFilter) { _, _ in
            updateChartImageFile()
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
                set: { isPresented in
                    if !isPresented {
                        viewModel.importErrorMessage = nil
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(viewModel.importErrorMessage ?? "Невідома помилка")
            }
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

            Text("Усього годувань: \(viewModel.filteredEntries.count)")
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
        if calendar.isDateInToday(date) {
            return todayFormatter.string(from: date)
        }

        let entryYear = Calendar.current.component(.year, from: date)
        let currentYear = Calendar.current.component(.year, from: Date())
        return entryYear == currentYear
            ? currentYearFormatter.string(from: date)
            : pastYearFormatter.string(from: date)
    }
}

struct EditFeedingView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: HistoryViewModel
    let entry: FeedingEntry

    @State private var selectedStartDate: Date
    @State private var selectedEndDate: Date
    @State private var selectedSide: BreastSide

    init(viewModel: HistoryViewModel, entry: FeedingEntry) {
        self.viewModel = viewModel
        self.entry = entry
        _selectedStartDate = State(initialValue: entry.startDate)
        _selectedEndDate = State(initialValue: entry.endDate)
        _selectedSide = State(initialValue: entry.side)
    }

    var body: some View {
        Form {
            DatePicker("Початок", selection: $selectedStartDate)

            DatePicker("Завершення", selection: $selectedEndDate, in: selectedStartDate...)

            Picker("Сторона", selection: $selectedSide) {
                ForEach(BreastSide.allCases) { side in
                    Text(side.localizedTitle).tag(side)
                }
            }
            .pickerStyle(.segmented)

            Button("Зберегти зміни") {
                viewModel.updateEntry(id: entry.id, startDate: selectedStartDate, endDate: selectedEndDate, side: selectedSide)
                dismiss()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("Редагування")
    }
}
