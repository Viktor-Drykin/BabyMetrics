import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var baby: Baby
    @Environment(\.modelContext) private var context

    @State private var importTracker: CSVTracker = .feeding
    @State private var showingImporter = false
    @State private var importResult: ImportResult?

    private struct ImportResult: Identifiable {
        let id = UUID()
        let message: LocalizedStringResource
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Baby profile") {
                    TextField("Name", text: $baby.name)
                    DatePicker("Birth date", selection: $baby.birthDate, displayedComponents: .date)
                }

                Section {
                    Picker("Tracker", selection: $importTracker) {
                        ForEach(CSVTracker.allCases) { Text($0.title).tag($0) }
                    }
                    Button("Import CSV…") { showingImporter = true }
                } header: {
                    Text("Import data")
                } footer: {
                    Text("Import CSV files exported from the previous version of BabyMetrics. Existing data is preserved.")
                }
            }
            .navigationTitle("Settings")
            .onChange(of: baby.name) { try? context.save() }
            .onChange(of: baby.birthDate) { try? context.save() }
            .fileImporter(isPresented: $showingImporter,
                          allowedContentTypes: [.commaSeparatedText, .plainText],
                          allowsMultipleSelection: false) { result in
                handleImport(result)
            }
            .alert(item: $importResult) { result in
                Alert(title: Text("Import"), message: Text(result.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let content = try String(contentsOf: url, encoding: .utf8)
            let count = try CSVImporter.import(content, as: importTracker, into: context, baby: baby)
            importResult = ImportResult(message: "Imported \(count) entries.")
            HapticManager.success()
        } catch {
            importResult = ImportResult(message: "Import failed: \(error.localizedDescription)")
        }
    }
}
