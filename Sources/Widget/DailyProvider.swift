import WidgetKit
import Foundation

// MARK: - TimelineEntry

struct DailyWidgetEntry: TimelineEntry {
    let date: Date
    let entry: DailyEntry

    static var placeholder: DailyWidgetEntry {
        DailyWidgetEntry(
            date: Date(),
            entry: DailyEntry(
                day: DayKey(Date()),
                messageID: "",
                imageID: "",
                trigger: .geral,
                shortText: "Cuida do que está em teu poder.",
                inlineText: "Longão amanhã",
                author: "Epicteto",
                reflection: "",
                daysToRace: 27
            )
        )
    }
}

// MARK: - TimelineProvider

struct DailyProvider: TimelineProvider {

    func placeholder(in context: Context) -> DailyWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyWidgetEntry) -> Void) {
        completion(resolve())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyWidgetEntry>) -> Void) {
        let plan = SharedStore.loadPlan()
        let prefs = SharedStore.loadPreferencesIfExists()
        let lib = try? ContentLibrary()

        let items = DailyTimelineGenerator.items(
            plan: plan,
            prefs: prefs,
            fallbackMessages: lib?.messages ?? [],
            fallbackImages: lib?.images ?? []
        )
        let entries = items.map { DailyWidgetEntry(date: $0.date, entry: $0.entry) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    // MARK: - Private

    private func resolve() -> DailyWidgetEntry {
        let plan = SharedStore.loadPlan()
        let prefs = SharedStore.loadPreferencesIfExists()
        let lib = try? ContentLibrary()
        let items = DailyTimelineGenerator.items(
            plan: plan,
            prefs: prefs,
            fallbackMessages: lib?.messages ?? [],
            fallbackImages: lib?.images ?? []
        )
        guard let first = items.first else { return .placeholder }
        return DailyWidgetEntry(date: first.date, entry: first.entry)
    }
}
