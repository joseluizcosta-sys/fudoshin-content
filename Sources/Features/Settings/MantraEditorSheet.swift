import SwiftUI
import SwiftData

struct MantraEditorSheet: View {
    @Query private var profiles: [AthleteProfile]
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @State private var editText = ""

    private var profile: AthleteProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("mantra.placeholder", text: $editText, axis: .vertical)
                        .lineLimit(2...8)
                }
            }
            .navigationTitle("settings.mantra.label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("onboarding.button.back") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("mantra.done") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { editText = profile?.mantra ?? "" }
        }
    }

    private func save() {
        profile?.mantra = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        try? ctx.save()
        dismiss()
    }
}
