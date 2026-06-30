import SwiftUI
import Charts

/// Bar chart of weight (kg) over the most recent entries.
struct GrowthChart: View {
    let entries: [GrowthEntry] // chronological, weight present

    var body: some View {
        Chart(entries) { entry in
            BarMark(
                x: .value("Date", entry.date, unit: .day),
                y: .value("Weight", entry.weightKg ?? 0)
            )
            .foregroundStyle(Color.moduleGrowth)
            .cornerRadius(4)
        }
        .frame(height: 120)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityLabel(Text("Weight trend"))
    }
}
