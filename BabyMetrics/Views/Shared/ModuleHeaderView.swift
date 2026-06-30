import SwiftUI

/// Full-bleed colored header banner for a module screen.
struct ModuleHeaderView<Trailing: View>: View {
    let title: LocalizedStringResource
    var subtitle: String? = nil
    let color: Color
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .screenTitleStyle()
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .metaStyle()
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, AppSpacing.screenHPadding)
        .padding(.bottom, 16)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color)
    }
}

extension ModuleHeaderView where Trailing == EmptyView {
    init(title: LocalizedStringResource, subtitle: String? = nil, color: Color) {
        self.init(title: title, subtitle: subtitle, color: color, trailing: { EmptyView() })
    }
}
