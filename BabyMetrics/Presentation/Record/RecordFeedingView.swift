import SwiftUI

struct RecordFeedingView: View {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject var viewModel: RecordFeedingViewModel

    @State private var isActionButtonDisabled = false
    @State private var userSelectedTime: Date? = nil

    private var pickerBinding: Binding<Date> {
        Binding(
            get: { viewModel.selectedDate },
            set: { newValue in
                viewModel.selectedDate = newValue
                userSelectedTime = newValue
            }
        )
    }

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
            .onAppear {
                userSelectedTime = nil
                viewModel.onAppear()
            }
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
            if viewModel.isFeeding {
                VStack(spacing: 8) {
                    Text("Йде годування")
                        .font(.headline.weight(.semibold))

                    if let startDate = viewModel.activeFeedingStart {
                        Text("Початок: \(timeString(from: startDate))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TimelineView(.periodic(from: Date(), by: 1)) { timeline in
                            Text(viewModel.timeSinceString(from: startDate, to: timeline.date))
                                .font(.title2.weight(.bold))
                                .monospacedDigit()
                        }
                    }

                    if let side = viewModel.activeFeedingSide {
                        Text(side.localizedTitle)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(side == .left ? Color.blue.opacity(0.18) : Color.green.opacity(0.2))
                            .foregroundStyle(side == .left ? Color.blue : Color.green)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                DatePicker("", selection: pickerBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if viewModel.shouldShowLastFeedingInfo, let lastFeedingDate = viewModel.lastFeedingDate {
                VStack(spacing: 4) {
                    Text("Від останнього годування")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TimelineView(.periodic(from: Date(), by: 1)) { timeline in
                        Text(viewModel.timeSinceMinutesString(from: lastFeedingDate, to: timeline.date))
                            .font(.headline.weight(.semibold))
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else if !viewModel.isFeeding, viewModel.hasFutureFeedingEntries {
                VStack(spacing: 6) {
                    Text("Є майбутні записи годування")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("Перевірте дати в історії годувань, щоб відновити коректний відлік від останнього годування.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if !viewModel.isFeeding {
                Picker("Сторона", selection: $viewModel.selectedSide) {
                    ForEach(BreastSide.allCases) { side in
                        Text(side.localizedTitle).tag(side)
                    }
                }
                .pickerStyle(.segmented)
            }

            Button {
                isActionButtonDisabled = true
                if viewModel.isFeeding {
                    viewModel.stopFeeding()
                } else {
                    viewModel.startFeeding(at: userSelectedTime)
                }
                userSelectedTime = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isActionButtonDisabled = false
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.isFeeding ? "stop.circle.fill" : "heart.circle.fill")
                        .font(.title)
                    Text(viewModel.isFeeding ? "Завершити годування" : "Почати годування")
                        .font(.title2.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    LinearGradient(
                        colors: viewModel.isFeeding ? [.orange, .red] : [.pink, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .pink.opacity(0.35), radius: 14, x: 0, y: 8)
            }
            .disabled(isActionButtonDisabled)

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

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
