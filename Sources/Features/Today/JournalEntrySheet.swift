import SwiftUI
import SwiftData

struct JournalEntrySheet: View {
    let day: DayKey
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var controlled = ""
    @State private var notControlled = ""
    @State private var note = ""

    private var questions: [String] {
        ContentLibrary.current().diaryQuestions
    }

    private var q1: String { questions.first ?? String(localized: "journal.sheet.controlled") }
    private var q2: String { questions.dropFirst().first ?? String(localized: "journal.sheet.not_controlled") }

    var body: some View {
        NavigationStack {
            Form {
                Section(q1) {
                    TextEditor(text: $controlled)
                        .frame(minHeight: 80)
                }
                Section(q2) {
                    TextEditor(text: $notControlled)
                        .frame(minHeight: 80)
                }
                Section("journal.sheet.note") {
                    TextField("journal.sheet.placeholder", text: $note, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("journal.sheet.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("onboarding.button.back") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("journal.sheet.save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        let key = day.value
        guard let existing = (try? ctx.fetch(
            FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.dayValue == key })
        ))?.first else { return }
        controlled = existing.controlled
        notControlled = existing.notControlled
        note = existing.note
    }

    private func save() {
        let key = day.value
        if let existing = (try? ctx.fetch(
            FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.dayValue == key })
        ))?.first {
            existing.controlled = controlled
            existing.notControlled = notControlled
            existing.note = note
        } else {
            ctx.insert(JournalEntry(day: day, controlled: controlled, notControlled: notControlled, note: note))
        }
        try? ctx.save()
        dismiss()
    }
}
