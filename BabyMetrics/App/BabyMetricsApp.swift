import SwiftUI
import SwiftData

@main
struct BabyMetricsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(AppContainer.shared)
    }
}

/// Resolves the current baby from the container before showing the tab UI.
private struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var babies: [Baby]

    var body: some View {
        RootTabView(baby: babies.first ?? Baby.current(in: context))
    }
}
