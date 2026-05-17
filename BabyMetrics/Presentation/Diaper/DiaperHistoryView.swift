import SwiftUI
import Charts
import UniformTypeIdentifiers

struct DiaperHistoryView: View {
    @StateObject var viewModel: DiaperHistoryViewModel
    var isEmbedded = false

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        f.setLocalizedDateFormatFromTemplate("d MMM, HH:mm")
        return f
    }()

    private let todayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        f.setLocalizedDateFormatFromTemplate("HH:mm")
        return f
    }()

    private var chartContent: some View {
        Chart(viewModel.typeChartPoints) { point in
            BarMark(
                x: .value("Дата", point.date),
                y: .value("Кількість", point.count)
            )
            .position(by: .value("Тип", point.type.localizedTitle))
            .foregroundStyle(by: .value("Тип", point.type.localizedTitle))
        }
        .chartForegroundStyleScale([
            DiaperType.wet.localizedTitle:   Color.blue,
            DiaperType.dirty.localizedTitle: Color.brown,
            DiaperType.mixed.localizedTitle: Color.purple
        ])
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 6)) }
        .chartYAxis { AxisMarks(position: .leading) }
    }

    @ViewBuilder
    var body: some View {
        if isEmbedded {
            content
        } else {
            NavigationStack { content }
        }
    }

    private var content: some View {
        Group {
            if viewModel.entries.isEmpty {
                ContentUnavailableView(
                    "Історія підгузків порожня",
                    systemImage: "heart.text.square",
                    description: Text("Записуйте зміни на вкладці Журнал.")
                )
            } else {
                VStack {
                    Picker("Фільтр", selection: $viewModel.selectedFilter) {
                        ForEach(DiaperHistoryViewModel.Filter.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Picker("Режим", selection: $viewModel.selectedMode) {
                        ForEach(DiaperHistoryViewModel.DisplayMode.allCases) { mode in
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
                                        diaperHistoryRowLink(for: entry)
                                    }
                                    .onDelete(perform: viewModel.deleteFilteredEntries)
                                }
                                .listStyle(.plain)
                            } else {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(viewModel.chartTitle).font(.headline)
                                        chartContent.frame(height: 300)
                                        Text("Усього: \(viewModel.filteredEntries.count)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary)

                                        diaperHistorySection

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
        .navigationTitle("Підгузки")
        .background(AppTheme.warmBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { viewModel.isImportingCSV = true } label: {
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
        .task { viewModel.writeCSVFile() }
        .onChange(of: viewModel.entries) { _, _ in viewModel.writeCSVFile() }
        .fileImporter(
            isPresented: $viewModel.isImportingCSV,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in viewModel.handleCSVImport(result) }
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

    @ViewBuilder
    private func diaperHistoryRowLink(for entry: DiaperEntry) -> some View {
        NavigationLink {
            EditDiaperEntryView(viewModel: viewModel, entry: entry)
        } label: {
            DiaperEntryRow(entry: entry, dateString: dateString(from: entry.date))
        }
    }

    private var diaperHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Text("Історія підгузків")
                .font(.headline)

            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.filteredEntries.enumerated()), id: \.element.id) { index, entry in
                    diaperHistoryRowLink(for: entry)

                    if index < viewModel.filteredEntries.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func dateString(from date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? todayFormatter.string(from: date)
            : formatter.string(from: date)
    }
}

private struct DiaperEntryRow: View {
    let entry: DiaperEntry
    let dateString: String

    private var typeColor: Color {
        switch entry.type {
        case .wet:   return .blue
        case .dirty: return .brown
        case .mixed: return .purple
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.subheadline.weight(.semibold))
                Label(entry.type.localizedTitle, systemImage: entry.type.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.type.localizedTitle)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(typeColor.opacity(0.15))
                    .foregroundStyle(typeColor)
                    .clipShape(Capsule())
                if let w = entry.weightGrams {
                    Text("\(w) г")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EditDiaperEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DiaperHistoryViewModel
    let entry: DiaperEntry

    @State private var date: Date
    @State private var type: DiaperType
    @State private var weightInput: String

    init(viewModel: DiaperHistoryViewModel, entry: DiaperEntry) {
        self.viewModel = viewModel
        self.entry = entry
        _date = State(initialValue: entry.date)
        _type = State(initialValue: entry.type)
        _weightInput = State(initialValue: entry.weightGrams.map { "\($0)" } ?? "")
    }

    var body: some View {
        Form {
            Section("Дата і час") {
                DatePicker("", selection: $date).labelsHidden()
            }
            Section("Тип") {
                Picker("", selection: $type) {
                    ForEach(DiaperType.allCases) { t in
                        Text(t.localizedTitle).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Вага підгузка, г") {
                TextField("Необов'язково", text: $weightInput)
                    .keyboardType(.numberPad)
            }

            Button("Зберегти зміни") {
                let weight = Int(weightInput.trimmingCharacters(in: .whitespaces))
                viewModel.updateEntry(id: entry.id, date: date, type: type, weightGrams: weight)
                dismiss()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("Редагування")
    }
}
