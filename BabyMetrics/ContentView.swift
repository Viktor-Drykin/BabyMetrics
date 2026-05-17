import SwiftUI

struct ContentView: View {
    @StateObject private var recordViewModel: RecordFeedingViewModel
    @StateObject private var recordDiaperViewModel: RecordDiaperViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var sleepTrackerViewModel: SleepTrackerViewModel
    @StateObject private var sleepHistoryViewModel: SleepHistoryViewModel
    @StateObject private var combinedTimelineViewModel: CombinedTimelineViewModel
    @StateObject private var growthViewModel: GrowthViewModel
    @StateObject private var diaperHistoryViewModel: DiaperHistoryViewModel
    @StateObject private var tummyTimeTrackerViewModel: TummyTimeTrackerViewModel
    @StateObject private var tummyTimeHistoryViewModel: TummyTimeHistoryViewModel

    init(
        feedingUseCases: FeedingUseCases,
        sleepUseCases: SleepUseCases,
        growthUseCases: GrowthUseCases,
        diaperUseCases: DiaperUseCases,
        tummyTimeUseCases: TummyTimeUseCases
    ) {
        _recordViewModel = StateObject(wrappedValue: RecordFeedingViewModel(useCases: feedingUseCases))
        _recordDiaperViewModel = StateObject(wrappedValue: RecordDiaperViewModel(useCases: diaperUseCases))
        _historyViewModel = StateObject(wrappedValue: HistoryViewModel(useCases: feedingUseCases))
        _sleepTrackerViewModel = StateObject(wrappedValue: SleepTrackerViewModel(useCases: sleepUseCases))
        _sleepHistoryViewModel = StateObject(wrappedValue: SleepHistoryViewModel(useCases: sleepUseCases))
        _combinedTimelineViewModel = StateObject(wrappedValue: CombinedTimelineViewModel(feedingUseCases: feedingUseCases, sleepUseCases: sleepUseCases, diaperUseCases: diaperUseCases, tummyTimeUseCases: tummyTimeUseCases))
        _growthViewModel = StateObject(wrappedValue: GrowthViewModel(useCases: growthUseCases))
        _diaperHistoryViewModel = StateObject(wrappedValue: DiaperHistoryViewModel(useCases: diaperUseCases))
        _tummyTimeTrackerViewModel = StateObject(wrappedValue: TummyTimeTrackerViewModel(useCases: tummyTimeUseCases))
        _tummyTimeHistoryViewModel = StateObject(wrappedValue: TummyTimeHistoryViewModel(useCases: tummyTimeUseCases))
    }

    var body: some View {
        TabView {
            RecordFeedingView(viewModel: recordViewModel)
                .tabItem {
                    Label("Годування", systemImage: "heart.circle.fill")
                }

            RecordDiaperView(viewModel: recordDiaperViewModel)
                .tabItem {
                    Label("Підгузки", systemImage: "drop.fill")
                }

            SleepTrackerView(viewModel: sleepTrackerViewModel)
                .tabItem {
                    Label("Сон", systemImage: "moon.zzz")
                }

            TummyTimeTrackerView(viewModel: tummyTimeTrackerViewModel)
                .tabItem {
                    Label("Розминка", systemImage: "figure.play")
                }

            GrowthView(viewModel: growthViewModel)
                .tabItem {
                    Label("Ріст", systemImage: "chart.line.uptrend.xyaxis")
                }

            CombinedTimelineView(viewModel: combinedTimelineViewModel)
                .tabItem {
                    Label("Разом", systemImage: "list.bullet.rectangle")
                }

            CombinedHistoryView(
                feedingHistoryViewModel: historyViewModel,
                sleepHistoryViewModel: sleepHistoryViewModel,
                diaperHistoryViewModel: diaperHistoryViewModel,
                tummyTimeHistoryViewModel: tummyTimeHistoryViewModel
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
        sleepUseCases: SleepUseCases(repository: UserDefaultsSleepRepository()),
        growthUseCases: GrowthUseCases(repository: UserDefaultsGrowthRepository()),
        diaperUseCases: DiaperUseCases(repository: UserDefaultsDiaperRepository()),
        tummyTimeUseCases: TummyTimeUseCases(repository: UserDefaultsTummyTimeRepository())
    )
}
