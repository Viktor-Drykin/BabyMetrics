import SwiftUI

struct RecordDiaperView: View {
    @StateObject var viewModel: RecordDiaperViewModel

    @State private var isDiaperButtonDisabled = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    diaperCard
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

    private func diaperColor(for type: DiaperType) -> Color {
        switch type {
        case .wet:   return .blue
        case .dirty: return .brown
        case .mixed: return .purple
        }
    }
}
