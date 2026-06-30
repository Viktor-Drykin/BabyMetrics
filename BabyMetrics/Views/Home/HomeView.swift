import SwiftUI
import SwiftData

struct HomeView: View {
    let baby: Baby
    @Binding var path: NavigationPath
    @Query private var sleeps: [SleepSession]
    @Query private var feedings: [FeedingSession]
    @Query private var diapers: [DiaperEntry]

    private var todaysSleep: TimeInterval {
        sleeps.filter { Calendar.current.isDateInToday($0.startTime) }.reduce(0) { $0 + $1.duration }
    }
    private var todaysFeedings: Int {
        feedings.filter { !$0.isActive && Calendar.current.isDateInToday($0.startTime) }.count
    }
    private var todaysDiapers: Int {
        diapers.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }
    private var lastFeeding: FeedingSession? {
        feedings.filter { !$0.isActive }.max(by: { $0.startTime < $1.startTime })
    }
    private var feedingOverdue: Bool {
        guard let last = lastFeeding else { return false }
        return Date.now.timeIntervalSince(last.startTime) > 3 * 3600
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    if feedingOverdue { feedingBanner }
                    statsRow
                    quickAccessGrid
                }
                .padding(.bottom, 24)
            }
            .background(Color.sleepLight.opacity(0.25))
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(baby.displayName).screenTitleStyle().foregroundStyle(.white)
            Text(baby.ageDescription()).metaStyle().foregroundStyle(.white.opacity(0.85))
            Text(Date.now.formatted(date: .complete, time: .omitted))
                .metaStyle().foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.screenHPadding)
        .padding(.vertical, 12)
        .background(Color.moduleSleep)
    }

    private var feedingBanner: some View {
        HStack {
            Image(systemName: "bell.fill").foregroundStyle(Color.moduleFeeding)
            Text("Time for a feed? Last feeding was \(DurationFormatter.relativeSince(lastFeeding?.startTime ?? .now)).")
                .bodyLabelStyle()
            Spacer()
        }
        .padding(AppSpacing.cardPadding)
        .background(Color.feedingLight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .padding(.horizontal, AppSpacing.screenHPadding)
    }

    private var statsRow: some View {
        HStack(spacing: AppSpacing.gridGap) {
            QuickStatPill(value: DurationFormatter.compact(todaysSleep), label: "Sleep today", icon: "moon.fill", tint: .moduleSleep)
            QuickStatPill(value: "\(todaysFeedings)", label: "Feedings", icon: "drop.fill", tint: .moduleFeeding)
            QuickStatPill(value: "\(todaysDiapers)", label: "Diapers", icon: "basket.fill", tint: .moduleDiapers)
        }
        .padding(.horizontal, AppSpacing.screenHPadding)
    }

    private var quickAccessGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Quick access")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: AppSpacing.gridGap),
                                GridItem(.flexible(), spacing: AppSpacing.gridGap)],
                      spacing: AppSpacing.gridGap) {
                ForEach(Module.allCases) { module in
                    NavigationLink(value: Route.module(module)) {
                        CardFace(title: module.title, icon: module.icon, color: module.color)
                    }.buttonStyle(.plain)
                }
                NavigationLink(value: Route.tummyTime) {
                    CardFace(title: "Tummy time", icon: "figure.roll", color: .moduleTummy)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.screenHPadding)
        }
    }

    @ViewBuilder private func destination(for route: Route) -> some View {
        switch route {
        case .module(.sleep): SleepView(baby: baby)
        case .module(.feeding): FeedingView(baby: baby)
        case .module(.growth): GrowthView(baby: baby)
        case .module(.diapers): DiaperView(baby: baby)
        case .module(.activities): ActivitiesView(baby: baby)
        case .tummyTime: ActivitiesView(baby: baby)
        }
    }
}

/// Static colored card face used inside NavigationLinks on the home grid.
private struct CardFace: View {
    let title: LocalizedStringResource
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(.white).accessibilityHidden(true)
            Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
        }
        .padding(AppSpacing.cardPadding)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
    }
}
