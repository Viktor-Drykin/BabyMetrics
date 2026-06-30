import SwiftUI

extension ActivityType {
    var title: LocalizedStringResource {
        switch self {
        case .exercise: return "Exercise"
        case .massage: return "Massage"
        case .tummyTime: return "Tummy time"
        }
    }
}

struct ActivityCard: View {
    let type: ActivityType
    let subtitle: String
    let isActive: Bool
    let elapsed: TimeInterval
    let action: () -> Void
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.systemImage)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.moduleActivity)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(type.title).sectionHeadingStyle()
                if isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.moduleActivity)
                            .frame(width: 6, height: 6)
                            .scaleEffect(pulsing ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)
                        Text("In progress · \(DurationFormatter.clock(elapsed))")
                            .metaStyle().foregroundStyle(Color.moduleActivity).monospacedDigit()
                    }
                    .onAppear { pulsing = true }
                } else {
                    Text(subtitle).metaStyle().foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: action) {
                Text(isActive ? "Stop" : "Start")
                    .font(.caption).fontWeight(.semibold)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.activityLight)
                    .foregroundStyle(Color.activityDark)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(isActive ? "Stop \(String(localized: type.title))" : "Start \(String(localized: type.title))"))
        }
        .padding(AppSpacing.cardPadding)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(Color.moduleActivity, lineWidth: isActive ? 2 : 0)
        )
    }
}
