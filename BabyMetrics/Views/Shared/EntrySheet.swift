import SwiftUI

/// Generic sheet wrapper used for all log-entry forms.
struct EntrySheet<Content: View>: View {
    let title: LocalizedStringResource
    var onSave: (() -> Void)? = nil
    var saveDisabled: Bool = false
    @ViewBuilder var content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form { content() }
                .navigationTitle(Text(title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    if let onSave {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                onSave()
                                dismiss()
                            }
                            .disabled(saveDisabled)
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
