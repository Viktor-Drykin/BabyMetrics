import SwiftUI
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

                    if viewModel.filteredEntries.isEmpty {
                        ContentUnavailableView(
                            "Немає результатів",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("Спробуйте інший фільтр.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
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

struct EditSleepEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: SleepHistoryViewModel
    let entry: SleepEntry

    @State private var startDate: Date
    @State private var endDate: Date

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
                viewModel.updateEntry(id: entry.id, startDate: startDate, endDate: endDate)
                dismiss()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("Редагування")
    }
}
