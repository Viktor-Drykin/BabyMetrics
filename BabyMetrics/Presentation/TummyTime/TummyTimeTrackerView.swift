import SwiftUI

struct TummyTimeTrackerView: View {
    @StateObject var viewModel: TummyTimeTrackerViewModel
    @State private var selectedTime: Date = Date()
    @State private var userSelectedTime: Date? = nil
    @State private var isActionButtonDisabled = false
    @State private var showEndTimeError = false

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
                if let startDate = viewModel.activeTummyTimeStart {
                    VStack(spacing: 12) {
                        Text("Розминка триває")
                            .font(.title2.weight(.semibold))

                        Text("Початок: \(startDateString(from: startDate))")
                            .foregroundStyle(.secondary)

                        Text(viewModel.activeDurationText)
                            .font(.title3.weight(.bold))

                        Divider()

                        DatePicker(
                            "Завершили о",
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
                        Text("Розминка не активна")
                            .font(.title2.weight(.semibold))

                        if let sinceLastSessionText = viewModel.sinceLastSessionText {
                            Text("Від останньої розминки: \(sinceLastSessionText)")
                                .font(.headline)
                        } else {
                            Text("Ще немає завершених розминок")
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        DatePicker(
                            "Почали о",
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
            .navigationTitle("Розминка")
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .alert("Невірний час завершення", isPresented: $showEndTimeError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Час завершення має бути пізніше початку розминки.")
            }
            .onChange(of: viewModel.isTummyTimeActive) { _, _ in
                selectedTime = Date()
                userSelectedTime = nil
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    isActionButtonDisabled = true

                    if viewModel.isTummyTimeActive {
                        let time = userSelectedTime ?? Date()
                        guard let start = viewModel.activeTummyTimeStart, time > start else {
                            showEndTimeError = true
                            isActionButtonDisabled = false
                            return
                        }
                        viewModel.stopTummyTime(at: time)
                    } else {
                        viewModel.startTummyTime(at: userSelectedTime ?? Date())
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isActionButtonDisabled = false
                    }
                } label: {
                    Label(
                        viewModel.isTummyTimeActive ? "Завершити розминку" : "Почати розминку",
                        systemImage: viewModel.isTummyTimeActive ? "stop.circle.fill" : "figure.play"
                    )
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(viewModel.isTummyTimeActive ? Color.orange : Color.teal)
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
