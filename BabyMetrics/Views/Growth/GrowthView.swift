import SwiftUI
import SwiftData

struct GrowthView: View {
    let baby: Baby
    @Environment(\.modelContext) private var context
    @Query(sort: \GrowthEntry.date, order: .reverse) private var entries: [GrowthEntry]
    @State private var showingAdd = false

    private var latestWeight: GrowthEntry? { entries.first { $0.weightKg != nil } }
    private var latestHeight: GrowthEntry? { entries.first { $0.heightCm != nil } }
    private var latestHead: GrowthEntry? { entries.first { $0.headCircumferenceCm != nil } }

    private var weightSeries: [GrowthEntry] {
        entries.filter { $0.weightKg != nil }.prefix(7).reversed()
    }

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeaderView(title: "Growth", color: .growthDark)
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: AppSpacing.gridGap) {
                        QuickStatPill(value: format(latestWeight?.weightKg, "kg"), label: "Weight", tint: .moduleGrowth)
                        QuickStatPill(value: format(latestHeight?.heightCm, "cm"), label: "Height", tint: .moduleGrowth)
                        QuickStatPill(value: format(latestHead?.headCircumferenceCm, "cm"), label: "Head", tint: .moduleGrowth)
                    }
                    .padding(.horizontal, AppSpacing.screenHPadding)

                    if !weightSeries.isEmpty {
                        GrowthChart(entries: Array(weightSeries))
                            .padding(.horizontal, AppSpacing.screenHPadding)
                    }

                    Button { showingAdd = true } label: {
                        Label("Log new measurement", systemImage: "plus")
                            .sectionHeadingStyle()
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.moduleGrowth)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                    }
                    .padding(.horizontal, AppSpacing.screenHPadding)

                    measurementsList
                }
                .padding(.vertical, 16)
            }
        }
        .background(Color.growthLight.opacity(0.3))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAdd) { AddGrowthSheet(baby: baby) }
    }

    private var measurementsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Recent measurements")
            if entries.isEmpty {
                EmptyStateView(icon: "chart.line.uptrend.xyaxis", message: "No measurements yet.")
            } else {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted)).sectionHeadingStyle()
                        Text(measurementSummary(entry)).metaStyle().foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.screenHPadding)
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button(role: .destructive) { delete(entry) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    private func measurementSummary(_ e: GrowthEntry) -> String {
        var parts: [String] = []
        if let w = e.weightKg { parts.append(String(localized: "\(w.formatted()) kg")) }
        if let h = e.heightCm { parts.append(String(localized: "\(h.formatted()) cm")) }
        if let head = e.headCircumferenceCm { parts.append(String(localized: "head \(head.formatted()) cm")) }
        return parts.joined(separator: " · ")
    }

    private func format(_ value: Double?, _ unit: String) -> String {
        guard let value else { return "–" }
        return "\(value.formatted()) \(unit)"
    }

    private func delete(_ entry: GrowthEntry) {
        context.delete(entry)
        try? context.save()
    }
}

private struct AddGrowthSheet: View {
    let baby: Baby
    @Environment(\.modelContext) private var context
    @State private var date = Date.now
    @State private var weight = ""
    @State private var height = ""
    @State private var head = ""
    @State private var source = ""

    private var canSave: Bool {
        [weight, height, head].contains { !$0.isEmpty }
    }

    var body: some View {
        EntrySheet(title: "New measurement", onSave: save, saveDisabled: !canSave) {
            DatePicker("Date", selection: $date, displayedComponents: .date)
            TextField("Weight (kg)", text: $weight).keyboardType(.decimalPad)
            TextField("Height (cm)", text: $height).keyboardType(.decimalPad)
            TextField("Head circumference (cm)", text: $head).keyboardType(.decimalPad)
            TextField("Source / notes", text: $source)
        }
    }

    private func save() {
        func num(_ s: String) -> Double? { Double(s.replacingOccurrences(of: ",", with: ".")) }
        context.insert(GrowthEntry(
            date: date,
            weightKg: num(weight),
            heightCm: num(height),
            headCircumferenceCm: num(head),
            notes: source.isEmpty ? nil : source,
            source: source.isEmpty ? nil : source,
            baby: baby))
        try? context.save()
        HapticManager.success()
    }
}
