import SwiftUI
import SwiftData

struct FeedingView: View {
    let baby: Baby
    @Environment(\.modelContext) private var context
    @Query(sort: \FeedingSession.startTime, order: .reverse) private var sessions: [FeedingSession]
    @State private var timer = TimerViewModel()

    private var active: FeedingSession? { sessions.first(where: { $0.isActive }) }
    private var completed: [FeedingSession] { sessions.filter { !$0.isActive } }
    private var todays: [FeedingSession] {
        completed.filter { Calendar.current.isDateInToday($0.startTime) }
    }

    /// Recommended side = the one NOT used last; default left if nothing in last 12h.
    private var recommendedSide: BreastSide {
        guard let last = completed.first,
              Date.now.timeIntervalSince(last.startTime) < 12 * 3600 else { return .left }
        return last.side == .left ? .right : .left
    }

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeaderView(title: "Feeding", color: .feedingDark)
            ScrollView {
                VStack(spacing: 20) {
                    sideSelectors
                    if active != nil { activeCard }
                    todaysLog
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color.feedingLight.opacity(0.3))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { timer.resume(from: active?.startTime) }
    }

    private var sideSelectors: some View {
        HStack(spacing: AppSpacing.gridGap) {
            ForEach([BreastSide.left, .right], id: \.self) { side in
                BreastSideSelector(
                    side: side,
                    lastUsedSubtitle: lastUsedSubtitle(for: side),
                    isHighlighted: active?.side == side || (active == nil && recommendedSide == side),
                    action: { start(side: side) })
            }
        }
        .padding(.horizontal, AppSpacing.screenHPadding)
        .disabled(active != nil)
        .opacity(active != nil ? 0.5 : 1)
    }

    private var activeCard: some View {
        VStack(spacing: 12) {
            Text(DurationFormatter.clock(timer.elapsed))
                .font(.largeTitle).fontWeight(.semibold).monospacedDigit()
                .foregroundStyle(Color.feedingDark)
            Text(active?.side.title ?? "")
                .metaStyle().foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button(timer.isRunning ? "Pause" : "Resume") {
                    timer.isRunning ? timer.pause() : timer.start(at: active?.startTime ?? .now)
                }
                .buttonStyle(.bordered)
                Button("Finish") { finish() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.moduleFeeding)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .padding(.horizontal, AppSpacing.screenHPadding)
    }

    private var todaysLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Today's feedings")
            if todays.isEmpty {
                EmptyStateView(icon: "drop", message: "No feedings logged today.")
            } else {
                ForEach(todays) { session in
                    SessionLogRow(
                        title: session.side.title,
                        subtitle: session.startTime.formatted(date: .omitted, time: .shortened),
                        value: DurationFormatter.compact(TimeInterval(session.durationSeconds)),
                        valueColor: .moduleFeeding,
                        icon: "drop.fill",
                        iconColor: .moduleFeeding)
                    .padding(.horizontal, AppSpacing.screenHPadding)
                    .swipeActions {
                        Button(role: .destructive) { delete(session) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    private func lastUsedSubtitle(for side: BreastSide) -> String {
        guard let last = completed.first(where: { $0.side == side }) else {
            return String(localized: "Not used yet")
        }
        return String(localized: "Last: \(DurationFormatter.relativeSince(last.startTime))")
    }

    private func start(side: BreastSide) {
        guard active == nil else { return }
        HapticManager.impact()
        let now = Date.now
        context.insert(FeedingSession(startTime: now, endTime: nil, side: side, durationSeconds: 0, baby: baby))
        try? context.save()
        timer.start(at: now)
    }

    private func finish() {
        guard let active else { return }
        let now = Date.now
        active.endTime = now
        active.durationSeconds = Int(max(0, now.timeIntervalSince(active.startTime)))
        timer.stop()
        try? context.save()
        HapticManager.success()
    }

    private func delete(_ session: FeedingSession) {
        context.delete(session)
        try? context.save()
    }
}
