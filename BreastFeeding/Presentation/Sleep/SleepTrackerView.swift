import SwiftUI

struct SleepTrackerView: View {
    @StateObject var viewModel: SleepTrackerViewModel
    @State private var isActionButtonDisabled = false

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let startDate = viewModel.activeSleepStart {
                    VStack(spacing: 8) {
                        Text("Дитина спить")
                            .font(.title2.weight(.semibold))

                        Text("Початок: \(formatter.string(from: startDate))")
                            .foregroundStyle(.secondary)

                        TimelineView(.periodic(from: Date(), by: 60)) { timeline in
                            Text(viewModel.durationString(from: startDate, to: timeline.date))
                                .font(.title3.weight(.bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    VStack(spacing: 8) {
                        Text("Дитина не спить")
                            .font(.title2.weight(.semibold))

                        if let latestWakeDate = viewModel.latestWakeDate {
                            TimelineView(.periodic(from: Date(), by: 60)) { timeline in
                                Text("Не спить: \(viewModel.durationString(from: latestWakeDate, to: timeline.date))")
                                    .font(.headline)
                            }
                        } else {
                            Text("Ще немає завершених снів")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Сон")
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button {
                    isActionButtonDisabled = true

                    if viewModel.isSleeping {
                        viewModel.stopSleepNow()
                    } else {
                        viewModel.startSleepNow()
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isActionButtonDisabled = false
                    }
                } label: {
                    Label(
                        viewModel.isSleeping ? "Прокинувся" : "Почав спати",
                        systemImage: viewModel.isSleeping ? "sun.max.fill" : "moon.zzz.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(viewModel.isSleeping ? Color.orange : Color.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isActionButtonDisabled)
                .padding(.horizontal)
                .padding(.bottom, 60)
            }
        }
    }
}
