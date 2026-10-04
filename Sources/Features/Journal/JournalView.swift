import SwiftUI
import SwiftData

struct JournalView: View {
    @Query(sort: \JournalEntry.dayValue, order: .reverse) private var entries: [JournalEntry]

    private var streak: Int {
        StreakCalculator.streak(entryDays: Set(entries.map { $0.dayValue }))
    }

    var body: some View {
        NavigationStack {
            List {
                // Contador de dias seguidos
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
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("journal.title")
            .navigationBarTitleDisplayMode(.large)
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
                }
            }
            .padding(.vertical, 2)
        }
    }
}
