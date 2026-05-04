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

    var body: some Scene {
        WindowGroup {
            ContentView(
                feedingUseCases: FeedingUseCases(repository: repository),
                sleepUseCases: SleepUseCases(repository: sleepRepository),
                growthUseCases: GrowthUseCases(repository: growthRepository)
            )
        }
    }
}
