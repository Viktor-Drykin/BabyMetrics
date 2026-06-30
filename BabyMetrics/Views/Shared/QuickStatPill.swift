import SwiftUI

/// White rounded card with a bold value and a muted label beneath. Used in the home stats row.
struct QuickStatPill: View {
    let value: String
    let label: LocalizedStringResource
    var icon: String? = nil
    var tint: Color = .moduleSleep

    var body: some View {
        VStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }
            Text(value)
                .cardValueStyle()
                .foregroundStyle(.primary)
            Text(label)
                .metaStyle()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.cardPadding)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.pill).stroke(.quaternary, lineWidth: 1))
    }
}
