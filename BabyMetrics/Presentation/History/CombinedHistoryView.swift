import SwiftUI

struct CombinedHistoryView: View {
    enum HistoryType: String, CaseIterable, Identifiable {
        case feeding = "Годування"
        case sleep = "Сон"
        case diaper = "Підгузки"

        var id: String { rawValue }
    }

    @State private var selectedType: HistoryType = .feeding
    @StateObject var feedingHistoryViewModel: HistoryViewModel
    @StateObject var sleepHistoryViewModel: SleepHistoryViewModel
    @StateObject var diaperHistoryViewModel: DiaperHistoryViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Picker("Тип історії", selection: $selectedType) {
                    ForEach(HistoryType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                Group {
                    switch selectedType {
                    case .feeding:
                        HistoryView(viewModel: feedingHistoryViewModel, isEmbedded: true)
                    case .sleep:
                        SleepHistoryView(viewModel: sleepHistoryViewModel, isEmbedded: true)
                    case .diaper:
                        DiaperHistoryView(viewModel: diaperHistoryViewModel, isEmbedded: true)
                    }
                }
            }
            .background(AppTheme.warmBackground.ignoresSafeArea())
        }
    }
}
