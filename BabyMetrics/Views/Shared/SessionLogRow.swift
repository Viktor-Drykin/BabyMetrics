import SwiftUI

/// Reusable list row: title + subtitle on the left, a colored value/duration on the right.
struct SessionLogRow: View {
    let title: LocalizedStringResource
    let subtitle: String
    let value: String
    var valueColor: Color = .secondary
    var icon: String? = nil
    var iconColor: Color = .secondary

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).sectionHeadingStyle()
                Text(subtitle).metaStyle().foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 4)
    }
}
