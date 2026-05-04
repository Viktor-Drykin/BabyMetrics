import SwiftUI

struct ContentView: View {
    @StateObject private var recordViewModel: RecordFeedingViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var sleepTrackerViewModel: SleepTrackerViewModel
    @StateObject private var sleepHistoryViewModel: SleepHistoryViewModel
    @StateObject private var dashboardViewModel: BabyStatusDashboardViewModel
    @StateObject private var combinedTimelineViewModel: CombinedTimelineViewModel

    init(feedingUseCases: FeedingUseCases, sleepUseCases: SleepUseCases) {
        _recordViewModel = StateObject(wrappedValue: RecordFeedingViewModel(useCases: feedingUseCases))
        _historyViewModel = StateObject(wrappedValue: HistoryViewModel(useCases: feedingUseCases))
        _sleepTrackerViewModel = StateObject(wrappedValue: SleepTrackerViewModel(useCases: sleepUseCases))
        _sleepHistoryViewModel = StateObject(wrappedValue: SleepHistoryViewModel(useCases: sleepUseCases))
        _dashboardViewModel = StateObject(wrappedValue: BabyStatusDashboardViewModel(feedingUseCases: feedingUseCases, sleepUseCases: sleepUseCases))
        _combinedTimelineViewModel = StateObject(wrappedValue: CombinedTimelineViewModel(feedingUseCases: feedingUseCases, sleepUseCases: sleepUseCases))
    }

    var body: some View {
        TabView {
            RecordFeedingView(viewModel: recordViewModel)
                .tabItem {
                    Label("Запис", systemImage: "plus.circle.fill")
                }

            SleepTrackerView(viewModel: sleepTrackerViewModel)
                .tabItem {
                    Label("Сон", systemImage: "moon.zzz")
                }

            BabyStatusTabView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Стан", systemImage: "figure.and.child.holdinghands")
                }

            CombinedTimelineView(viewModel: combinedTimelineViewModel)
                .tabItem {
                    Label("Разом", systemImage: "list.bullet.rectangle")
                }

            CombinedHistoryView(
                feedingHistoryViewModel: historyViewModel,
                sleepHistoryViewModel: sleepHistoryViewModel
            )
                .tabItem {
                    Label("Історія", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}

#Preview {
    ContentView(
        feedingUseCases: FeedingUseCases(repository: UserDefaultsFeedingRepository()),
        sleepUseCases: SleepUseCases(repository: UserDefaultsSleepRepository())
    )
}
