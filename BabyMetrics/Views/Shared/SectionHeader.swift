import SwiftUI

/// Bold section label with an optional trailing "See all" action.
struct SectionHeader: View {
    let title: LocalizedStringResource
    var actionTitle: LocalizedStringResource? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title).sectionHeadingStyle()
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).font(.caption).fontWeight(.semibold)
                }
            }
        }
        .padding(.horizontal, AppSpacing.screenHPadding)
    }
}
