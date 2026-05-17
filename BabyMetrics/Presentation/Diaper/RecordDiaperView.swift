import SwiftUI

struct RecordDiaperView: View {
    @StateObject var viewModel: RecordDiaperViewModel

    @State private var isDiaperButtonDisabled = false

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    diaperCard

                    todaySummaryCard

                    if !viewModel.recentEntries.isEmpty {
                        recentHistoryCard
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Підгузки")
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .onChange(of: viewModel.showSavedMessage) { _, newValue in
                guard newValue else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { viewModel.hideSavedMessage() }
                }
            }
        }
    }

    private var diaperCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Підгузок", systemImage: "heart.text.square")
                .font(.headline)

            HStack {
                Image(systemName: "scalemass")
                    .foregroundStyle(.secondary)
                TextField("Вага, г (необов'язково)", text: $viewModel.weightInput)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 12) {
                ForEach(DiaperType.allCases) { type in
                    Button {
                        isDiaperButtonDisabled = true
                        viewModel.logDiaper(type: type)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isDiaperButtonDisabled = false
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: type.systemImage)
                                .font(.title2)
                            Text(type.localizedTitle)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(diaperColor(for: type))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isDiaperButtonDisabled)
                }
            }

            Text("Записано")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .opacity(viewModel.showSavedMessage ? 1 : 0)
                .frame(height: 18)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var todaySummaryCard: some View {
        HStack(spacing: 12) {
            summaryPill(title: "Сьогодні", value: "\(viewModel.todayDiaperCount)")
                .frame(maxWidth: .infinity)
            summaryPill(title: "Вага", value: "\(viewModel.todayTotalWeightGrams) г")
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var recentHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Останні записи")
                .font(.headline)

            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.recentEntries.enumerated()), id: \.element.id) { index, entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dateString(from: entry.date))
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
                                .background(diaperColor(for: entry.type).opacity(0.15))
                                .foregroundStyle(diaperColor(for: entry.type))
                                .clipShape(Capsule())

                            if let w = entry.weightGrams {
                                Text("\(w) г")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 10)

                    if index < viewModel.recentEntries.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func dateString(from date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? todayFormatter.string(from: date)
            : formatter.string(from: date)
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func diaperColor(for type: DiaperType) -> Color {
        switch type {
        case .wet:   return .blue
        case .dirty: return .brown
        case .mixed: return .purple
        }
    }
}
