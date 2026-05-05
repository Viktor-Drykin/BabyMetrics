import SwiftUI
import Charts
import UniformTypeIdentifiers

struct GrowthView: View {
    @StateObject var viewModel: GrowthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    addEntryCard
                    if !viewModel.entries.isEmpty {
                        chartCard
                        historyList
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Ріст")
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
            .task { viewModel.writeCSVFile() }
            .onChange(of: viewModel.entries) { _, _ in viewModel.writeCSVFile() }
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
    }

    private var addEntryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Нові виміри")
                .font(.headline)

            DatePicker("Дата", selection: $viewModel.formDate, displayedComponents: [.date])
                .environment(\.locale, Locale(identifier: "uk_UA"))

            Divider()

            HStack {
                Image(systemName: "scalemass")
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                TextField("Вага, г", text: $viewModel.formWeightText)
                    .keyboardType(.numberPad)
            }

            HStack {
                Image(systemName: "ruler")
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                TextField("Зріст, см", text: $viewModel.formHeightText)
                    .keyboardType(.decimalPad)
            }

            HStack {
                Image(systemName: "circle.dashed")
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                TextField("Обвід голови, см", text: $viewModel.formHeadText)
                    .keyboardType(.decimalPad)
            }

            Button {
                viewModel.saveEntry()
            } label: {
                Text("Зберегти")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.isFormValid ? Color.teal : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!viewModel.isFormValid)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Показник", selection: $viewModel.selectedMetric) {
                ForEach(GrowthViewModel.Metric.allCases) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.chartPoints.isEmpty {
                Text("Немає даних для цього показника")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                Chart(viewModel.chartPoints, id: \.date) { point in
                    LineMark(
                        x: .value("Дата", point.date),
                        y: .value("Значення", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.teal)

                    PointMark(
                        x: .value("Дата", point.date),
                        y: .value("Значення", point.value)
                    )
                    .foregroundStyle(Color.teal)
                    .annotation(position: .top, alignment: .center) {
                        Text(String(format: "%.1f", point.value))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 220)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Записи")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ForEach(viewModel.entries) { entry in
                NavigationLink {
                    EditGrowthEntryView(viewModel: viewModel, entry: entry)
                } label: {
                    GrowthEntryRow(entry: entry)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct GrowthEntryRow: View {
    let entry: GrowthEntry

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        f.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        return f
    }()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatter.string(from: entry.date))
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 12) {
                    if let w = entry.weightGrams {
                        Label("\(Int(w)) г", systemImage: "scalemass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let h = entry.heightCm {
                        Label(String(format: "%.1f см", h), systemImage: "ruler")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let hc = entry.headCm {
                        Label(String(format: "%.1f см", hc), systemImage: "circle.dashed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

struct EditGrowthEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GrowthViewModel
    let entry: GrowthEntry

    @State private var date: Date
    @State private var weightText: String
    @State private var heightText: String
    @State private var headText: String

    init(viewModel: GrowthViewModel, entry: GrowthEntry) {
        self.viewModel = viewModel
        self.entry = entry
        _date = State(initialValue: entry.date)
        _weightText = State(initialValue: entry.weightGrams.map { String(Int($0)) } ?? "")
        _heightText = State(initialValue: entry.heightCm.map { String($0) } ?? "")
        _headText = State(initialValue: entry.headCm.map { String($0) } ?? "")
    }

    var body: some View {
        Form {
            Section("Дата") {
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .labelsHidden()
            }

            Section("Вага, г") {
                TextField("Не заповнено", text: $weightText)
                    .keyboardType(.numberPad)
            }

            Section("Зріст, см") {
                TextField("Не заповнено", text: $heightText)
                    .keyboardType(.decimalPad)
            }

            Section("Обвід голови, см") {
                TextField("Не заповнено", text: $headText)
                    .keyboardType(.decimalPad)
            }

            Section {
                Button("Зберегти зміни") {
                    viewModel.updateEntry(
                        id: entry.id,
                        date: date,
                        weightGrams: Double(weightText),
                        heightCm: Double(heightText.replacingOccurrences(of: ",", with: ".")),
                        headCm: Double(headText.replacingOccurrences(of: ",", with: "."))
                    )
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Редагування")
    }
}
