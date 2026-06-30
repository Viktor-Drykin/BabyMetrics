import SwiftUI

/// Consistent text styles (SF Pro / system font only). Relative styles support Dynamic Type.
extension View {
    func screenTitleStyle() -> some View {
        font(.title2).fontWeight(.semibold)
    }

    func sectionHeadingStyle() -> some View {
        font(.subheadline).fontWeight(.semibold)
    }

    func cardValueStyle() -> some View {
        font(.title3).fontWeight(.semibold)
    }

    func bodyLabelStyle() -> some View {
        font(.caption).fontWeight(.regular)
    }

    func metaStyle() -> some View {
        font(.caption2).fontWeight(.regular)
    }
}
