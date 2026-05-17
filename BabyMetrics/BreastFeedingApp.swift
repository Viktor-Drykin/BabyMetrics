//
//  BreastFeedingApp.swift
//  BreastFeeding
//
//  Created by Viktor Drykin on 20.03.2026.
//

import SwiftUI

@main
struct BreastFeedingApp: App {
    @StateObject private var repository = UserDefaultsFeedingRepository()
    @StateObject private var sleepRepository = UserDefaultsSleepRepository()
    @StateObject private var growthRepository = UserDefaultsGrowthRepository()
    @StateObject private var diaperRepository = UserDefaultsDiaperRepository()
    @StateObject private var tummyTimeRepository = UserDefaultsTummyTimeRepository()

    var body: some Scene {
        WindowGroup {
            ContentView(
                feedingUseCases: FeedingUseCases(repository: repository),
                sleepUseCases: SleepUseCases(repository: sleepRepository),
                growthUseCases: GrowthUseCases(repository: growthRepository),
                diaperUseCases: DiaperUseCases(repository: diaperRepository),
                tummyTimeUseCases: TummyTimeUseCases(repository: tummyTimeRepository)
            )
        }
    }
}
