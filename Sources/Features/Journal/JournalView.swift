import SwiftUI
import SwiftData

struct JournalView: View {
    @Query(sort: \JournalEntry.dayValue, order: .reverse) private var entries: [JournalEntry]
    @Environment(\.modelContext) private var ctx
    @State private var showNewEntry = false
    @State private var editEntry: JournalEntry?
    @State private var entryToDelete: JournalEntry?

    private var streak: Int {
        StreakCalculator.streak(entryDays: Set(entries.map { $0.dayValue }))
    }

    var body: some View {
        NavigationStack {
            List {
                streakSection

                if entries.isEmpty {
                    ContentUnavailableView(
                        String(localized: "journal.empty"),
                        systemImage: "book.closed"
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(entries) { entry in
                        entryRow(entry)
                            .contentShape(Rectangle())
                            .onTapGesture { editEntry = entry }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    entryToDelete = entry
                                } label: {
                                    Label("journal.delete.button", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("journal.title")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewEntry = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewEntry) {
                JournalEntrySheet(day: DayKey(Date()))
            }
            .sheet(item: $editEntry) { entry in
                JournalEntrySheet(day: entry.day)
            }
            .alert("journal.delete.confirm.title", isPresented: Binding(
                get: { entryToDelete != nil },
                set: { if !$0 { entryToDelete = nil } }
            )) {
                Button("journal.delete.button", role: .destructive) {
                    if let e = entryToDelete { ctx.delete(e); try? ctx.save() }
                    entryToDelete = nil
                }
                Button("onboarding.button.back", role: .cancel) { entryToDelete = nil }
            } message: {
                Text("journal.delete.confirm.message")
            }
        }
    }

    // MARK: - Streak

    private var streakSection: some View {
        let label: String = {
            if streak == 0 { return String(localized: "journal.streak.zero") }
            let fmt = streak == 1
                ? String(localized: "journal.streak.singular")
                : String(localized: "journal.streak.plural")
            return String(format: fmt, streak)
        }()

        return HStack {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .foregroundStyle(streak > 0 ? Theme.accent : Theme.secondaryText)
                .font(.title2)
            Text(label)
                .font(.headline)
                .foregroundStyle(Theme.primaryText)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.clear)
    }

    // MARK: - Row

    @ViewBuilder
    private func entryRow(_ entry: JournalEntry) -> some View {
        if let date = entry.day.startOfDay() {
            VStack(alignment: .leading, spacing: 6) {
                Text(date.formatted(date: .long, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
                if !entry.controlled.isEmpty {
                    Text(entry.controlled)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(2)
                } else if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
