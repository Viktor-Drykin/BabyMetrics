import SwiftUI

struct BabyStatusDashboardView: View {
    @ObservedObject var viewModel: BabyStatusDashboardViewModel

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Стан дитини")
                .font(.headline)

            if let feedingDate = viewModel.lastFeedingDate {
                Text("Останнє годування: \(timeFormatter.string(from: feedingDate))")
                    .font(.subheadline)
            } else {
                Text("Останнє годування: ще немає")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let sleepStart = viewModel.activeSleepStart {
                TimelineView(.periodic(from: Date(), by: 60)) { timeline in
                    Text("Зараз спить: \(viewModel.durationString(from: sleepStart, to: timeline.date))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.indigo)
                }
            } else if let wakeDate = viewModel.latestWakeDate {
                TimelineView(.periodic(from: Date(), by: 60)) { timeline in
                    Text("Не спить: \(viewModel.durationString(from: wakeDate, to: timeline.date))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            } else {
                Text("Стан сну: ще немає даних")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
