import SwiftUI

struct SleepTrackerView: View {
    @StateObject var viewModel: SleepTrackerViewModel
    @State private var selectedTime: Date = Date()
    @State private var userSelectedTime: Date? = nil
    @State private var isActionButtonDisabled = false
    @State private var showWakeTimeError = false

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        f.setLocalizedDateFormatFromTemplate("d MMM, HH:mm")
        return f
    }()

    private var pickerBinding: Binding<Date> {
        Binding(
            get: { selectedTime },
            set: { newValue in
                selectedTime = newValue
                userSelectedTime = newValue
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let startDate = viewModel.activeSleepStart {
                    VStack(spacing: 12) {
                        Text("Дитина спить")
                            .font(.title2.weight(.semibold))

                        Text("Початок: \(startDateString(from: startDate))")
                            .foregroundStyle(.secondary)

                        TimelineView(.periodic(from: Date(), by: 60)) { timeline in
                            Text(viewModel.durationString(from: startDate, to: timeline.date))
                                .font(.title3.weight(.bold))
                        }

                        Divider()

                        DatePicker(
                            "Прокинувся о",
                            selection: pickerBinding,
                            in: startDate...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .environment(\.locale, Locale(identifier: "uk_UA"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    VStack(spacing: 12) {
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

                        Divider()

                        DatePicker(
                            "Заснув о",
                            selection: pickerBinding,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .environment(\.locale, Locale(identifier: "uk_UA"))
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
            .alert("Невірний час пробудження", isPresented: $showWakeTimeError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Час пробудження має бути пізніше початку сну.")
            }
            .onChange(of: viewModel.isSleeping) { _, _ in
                selectedTime = Date()
                userSelectedTime = nil
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    isActionButtonDisabled = true

                    if viewModel.isSleeping {
                        let time = userSelectedTime ?? Date()
                        guard let start = viewModel.activeSleepStart, time > start else {
                            showWakeTimeError = true
                            isActionButtonDisabled = false
                            return
                        }
                        viewModel.stopSleep(at: time)
                    } else {
                        viewModel.startSleep(at: userSelectedTime ?? Date())
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

    private func startDateString(from date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? timeFormatter.string(from: date)
            : dateTimeFormatter.string(from: date)
    }
}
