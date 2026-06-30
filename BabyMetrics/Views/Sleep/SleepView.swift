import SwiftUI
import SwiftData

struct SleepView: View {
    let baby: Baby
    @Environment(\.modelContext) private var context
    @Query(sort: \SleepSession.startTime, order: .reverse) private var sessions: [SleepSession]
    @State private var timer = TimerViewModel()

    private var active: SleepSession? { sessions.first(where: { $0.isActive }) }
    private var todays: [SleepSession] {
        sessions.filter { !$0.isActive && Calendar.current.isDateInToday($0.startTime) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeaderView(title: "Sleep", color: .sleepDark)
            ScrollView {
                VStack(spacing: 24) {
                    SleepTimerRing(elapsed: timer.elapsed, isActive: active != nil)
                        .padding(.top, 24)

                    Button(action: toggle) {
                        Text(active == nil ? "Start sleep" : "Stop sleep")
                            .sectionHeadingStyle()
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.moduleSleep)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                    }
                    .padding(.horizontal, AppSpacing.screenHPadding)
                    .accessibilityHint(Text(active == nil ? "Starts a sleep session" : "Ends the current sleep session"))

                    todaysLog
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color.sleepLight.opacity(0.3))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { timer.resume(from: active?.startTime) }
    }

    @ViewBuilder private var todaysLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Today's log")
            if todays.isEmpty {
                EmptyStateView(icon: "moon.zzz", message: "No sleep logged today. Tap to start tracking.")
            } else {
                ForEach(todays) { session in
                    SessionLogRow(
                        title: session.type == .night ? "Night sleep" : "Nap",
                        subtitle: timeRange(session.startTime, session.endTime),
                        value: DurationFormatter.compact(session.duration),
                        valueColor: .moduleSleep,
                        icon: "moon.fill",
                        iconColor: .moduleSleep)
                    .padding(.horizontal, AppSpacing.screenHPadding)
                    .swipeActions {
                        Button(role: .destructive) { delete(session) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    private func toggle() {
        HapticManager.impact()
        if let active {
            active.endTime = .now
            timer.stop()
            HapticManager.success()
        } else {
            let now = Date.now
            let session = SleepSession(startTime: now, endTime: nil, type: .inferred(from: now), baby: baby)
            context.insert(session)
            timer.start(at: now)
        }
        try? context.save()
    }

    private func delete(_ session: SleepSession) {
        context.delete(session)
        try? context.save()
    }

    private func timeRange(_ start: Date, _ end: Date?) -> String {
        let s = start.formatted(date: .omitted, time: .shortened)
        guard let end else { return s }
        return "\(s) – \(end.formatted(date: .omitted, time: .shortened))"
    }
}
