import SwiftUI

/// Friendly empty state: a muted SF Symbol plus a short prompt.
struct EmptyStateView: View {
    let icon: String
    let message: LocalizedStringResource

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            Text(message)
                .bodyLabelStyle()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
