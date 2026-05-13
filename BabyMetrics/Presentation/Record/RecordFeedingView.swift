import SwiftUI

struct RecordFeedingView: View {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject var viewModel: RecordFeedingViewModel

    @State private var isSaveButtonDisabled = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    feedingCard
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Годування")
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .onAppear { viewModel.onAppear() }
            .onChange(of: viewModel.showSavedMessage) { _, newValue in
                guard newValue else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { viewModel.hideSavedMessage() }
                }
            }
            .onChange(of: scenePhase) { _, newValue in
                if newValue == .active { viewModel.onSceneBecameActive() }
            }
        }
    }

    private var feedingCard: some View {
        VStack(spacing: 16) {
            DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.wheel)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let lastFeedingDate = viewModel.lastFeedingDate {
                VStack(spacing: 4) {
                    Text("Від останнього годування")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TimelineView(.periodic(from: Date(), by: 60)) { timeline in
                        Text(viewModel.timeSinceString(from: lastFeedingDate, to: timeline.date))
                            .font(.headline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Picker("Сторона", selection: $viewModel.selectedSide) {
                ForEach(BreastSide.allCases) { side in
                    Text(side.localizedTitle).tag(side)
                }
            }
            .pickerStyle(.segmented)

            Button {
                isSaveButtonDisabled = true
                viewModel.saveFeeding()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isSaveButtonDisabled = false
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "heart.circle.fill").font(.title)
                    Text("Погодувати").font(.title2.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .pink.opacity(0.35), radius: 14, x: 0, y: 8)
            }
            .disabled(isSaveButtonDisabled)

            Text("Додано в історію")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .opacity(viewModel.showSavedMessage ? 1 : 0)
                .frame(height: 18)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
