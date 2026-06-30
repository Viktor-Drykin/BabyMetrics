import SwiftUI
import SwiftData

struct ActivitiesView: View {
    let baby: Baby
    @Environment(\.modelContext) private var context
    @Query(sort: \ActivitySession.startTime, order: .reverse) private var sessions: [ActivitySession]
    @State private var timer = TimerViewModel()

    private func active(_ type: ActivityType) -> ActivitySession? {
        sessions.first { $0.isActive && $0.type == type }
    }
    private var anyActive: ActivitySession? { sessions.first { $0.isActive } }
    private var todays: [ActivitySession] {
        sessions.filter { !$0.isActive && Calendar.current.isDateInToday($0.startTime) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeaderView(title: "Activities", color: .activityDark)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ActivityType.allCases) { type in
                        ActivityCard(
                            type: type,
                            subtitle: subtitle(for: type),
                            isActive: active(type) != nil,
                            elapsed: active(type) != nil ? timer.elapsed : 0,
                            action: { toggle(type) })
                    }
                    .padding(.horizontal, AppSpacing.screenHPadding)

                    todaysLog
                }
                .padding(.vertical, 16)
            }
        }
        .background(Color.activityLight.opacity(0.3))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { timer.resume(from: anyActive?.startTime) }
    }

    private var todaysLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Today's sessions")
            if todays.isEmpty {
                EmptyStateView(icon: "figure.roll", message: "No activities logged today.")
            } else {
                ForEach(todays) { session in
                    SessionLogRow(
                        title: session.type.title,
                        subtitle: session.startTime.formatted(date: .omitted, time: .shortened),
                        value: DurationFormatter.compact(TimeInterval(session.durationSeconds)),
                        valueColor: .moduleActivity,
                        icon: session.type.systemImage,
                        iconColor: .moduleActivity)
                    .padding(.horizontal, AppSpacing.screenHPadding)
                    .swipeActions {
                        Button(role: .destructive) { delete(session) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    private func subtitle(for type: ActivityType) -> String {
        guard let last = sessions.first(where: { !$0.isActive && $0.type == type }) else {
            return String(localized: "Tap start to begin")
        }
        return String(localized: "Last: \(DurationFormatter.relativeSince(last.startTime))")
    }

    private func toggle(_ type: ActivityType) {
        HapticManager.impact()
        if let session = active(type) {
            let now = Date.now
            session.endTime = now
            session.durationSeconds = Int(max(0, now.timeIntervalSince(session.startTime)))
            timer.stop()
            HapticManager.success()
        } else if anyActive == nil {
            let now = Date.now
            context.insert(ActivitySession(startTime: now, endTime: nil, type: type, durationSeconds: 0, baby: baby))
            timer.start(at: now)
        }
        try? context.save()
    }

    private func delete(_ session: ActivitySession) {
        context.delete(session)
        try? context.save()
    }
}
