import SwiftUI

extension BreastSide {
    var title: LocalizedStringResource {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .both: return "Both"
        }
    }
    var icon: String {
        switch self {
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        case .both: return "arrow.left.arrow.right"
        }
    }
}

/// A tappable card for one breast side; highlighted when recommended or selected.
struct BreastSideSelector: View {
    let side: BreastSide
    let lastUsedSubtitle: String
    let isHighlighted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: side.icon)
                    .font(.title3)
                    .foregroundStyle(Color.moduleFeeding)
                    .accessibilityHidden(true)
                Text(side.title).sectionHeadingStyle()
                Text(lastUsedSubtitle).metaStyle().foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.cardPadding)
            .background(Color.feedingLight)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(Color.moduleFeeding, lineWidth: isHighlighted ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(side.title))
        .accessibilityHint(Text(lastUsedSubtitle))
    }
}
