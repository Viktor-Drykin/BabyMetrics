import SwiftUI

/// Bottom-sheet content for the center "Log" tab: pick a category to open its module.
struct QuickLogView: View {
    /// Called with the chosen route so the parent can navigate Home to it.
    let onSelect: (Route) -> Void

    private let items: [(LocalizedStringResource, String, Color, Route)] = [
        ("Sleep", "moon.fill", .moduleSleep, .module(.sleep)),
        ("Feeding", "drop.fill", .moduleFeeding, .module(.feeding)),
        ("Diapers", "basket.fill", .moduleDiapers, .module(.diapers)),
        ("Growth", "chart.line.uptrend.xyaxis", .moduleGrowth, .module(.growth)),
        ("Activities", "figure.mixed.cardio", .moduleActivity, .module(.activities)),
        ("Tummy time", "figure.roll", .moduleTummy, .tummyTime),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: AppSpacing.gridGap),
                                    GridItem(.flexible(), spacing: AppSpacing.gridGap)],
                          spacing: AppSpacing.gridGap) {
                    ForEach(items, id: \.0.key) { item in
                        Button { onSelect(item.3) } label: {
                            CategoryCardFace(title: item.0, icon: item.1, color: item.2)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(AppSpacing.screenHPadding)
            }
            .navigationTitle("Quick log")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct CategoryCardFace: View {
    let title: LocalizedStringResource
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(.white).accessibilityHidden(true)
            Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
        }
        .padding(AppSpacing.cardPadding)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
    }
}
