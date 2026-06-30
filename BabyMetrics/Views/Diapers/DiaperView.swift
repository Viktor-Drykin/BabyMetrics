import SwiftUI
import SwiftData

extension DiaperType {
    var title: LocalizedStringResource {
        switch self {
        case .wet: return "Wet"
        case .dirty: return "Dirty"
        case .both: return "Both"
        }
    }
}

struct DiaperView: View {
    let baby: Baby
    @Environment(\.modelContext) private var context
    @Query(sort: \DiaperEntry.timestamp, order: .reverse) private var entries: [DiaperEntry]
    @State private var showingAdd = false

    private var todays: [DiaperEntry] {
        entries.filter { Calendar.current.isDateInToday($0.timestamp) }
    }
    private var todaysWeight: Double {
        todays.compactMap(\.weightGrams).reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeaderView(title: "Diapers", color: .diapersDark)
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: AppSpacing.gridGap) {
                        QuickStatPill(value: "\(todays.count)", label: "Today's count", icon: "basket.fill", tint: .moduleDiapers)
                        QuickStatPill(value: "\(Int(todaysWeight)) g", label: "Total weight today", icon: "scalemass.fill", tint: .moduleDiapers)
                    }
                    .padding(.horizontal, AppSpacing.screenHPadding)

                    Button { showingAdd = true } label: {
                        Label("Add diaper", systemImage: "plus")
                            .sectionHeadingStyle()
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.moduleDiapers)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                    }
                    .padding(.horizontal, AppSpacing.screenHPadding)

                    log
                }
                .padding(.vertical, 16)
            }
        }
        .background(Color.diapersLight.opacity(0.3))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAdd) { AddDiaperSheet(baby: baby) }
    }

    private var log: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Today's changes")
            if todays.isEmpty {
                EmptyStateView(icon: "basket", message: "No diapers logged today.")
            } else {
                ForEach(todays) { entry in
                    HStack {
                        Text(entry.type.title)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(entry.type.badgeColor)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.tag))
                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .metaStyle().foregroundStyle(.secondary)
                        Spacer()
                        if let w = entry.weightGrams {
                            Text("\(Int(w)) g").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHPadding)
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button(role: .destructive) { delete(entry) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    private func delete(_ entry: DiaperEntry) {
        context.delete(entry)
        try? context.save()
    }
}

private struct AddDiaperSheet: View {
    let baby: Baby
    @Environment(\.modelContext) private var context
    @State private var type: DiaperType = .wet
    @State private var weightText = ""
    @State private var time = Date.now

    var body: some View {
        EntrySheet(title: "Add diaper", onSave: save) {
            Picker("Type", selection: $type) {
                ForEach(DiaperType.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            TextField("Weight (g)", text: $weightText)
                .keyboardType(.numberPad)

            DatePicker("Time", selection: $time)
        }
    }

    private func save() {
        let weight = Double(weightText)
        context.insert(DiaperEntry(timestamp: time, type: type, weightGrams: weight, baby: baby))
        try? context.save()
        HapticManager.success()
    }
}
