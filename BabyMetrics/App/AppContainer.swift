import Foundation
import SwiftData

/// Owns the shared SwiftData container and runs one-time setup (migration + default baby).
enum AppContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            Baby.self,
            SleepSession.self,
            FeedingSession.self,
            DiaperEntry.self,
            GrowthEntry.self,
            ActivitySession.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            bootstrap(context: container.mainContext)
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    /// Migrates legacy data (once) and guarantees a single `Baby` exists.
    @MainActor
    private static func bootstrap(context: ModelContext) {
        DataMigration.migrateIfNeeded(context: context)
        _ = Baby.current(in: context)
    }
}

extension Baby {
    /// Returns the existing baby, creating an empty one on a fresh install.
    @MainActor
    static func current(in context: ModelContext) -> Baby {
        if let existing = try? context.fetch(FetchDescriptor<Baby>()).first {
            return existing
        }
        let baby = Baby()
        context.insert(baby)
        try? context.save()
        return baby
    }
}
