import WidgetKit
import Foundation

// MARK: - TimelineEntry

struct DailyWidgetEntry: TimelineEntry {
    let date: Date
    let entry: DailyEntry
    /// true somente quando a ContentLibrary falhou ao carregar no placeholder.
    /// Causa .redacted(reason: .placeholder) nas views.
    var isPlaceholder: Bool = false
}

// MARK: - Entrada para Previews e Placeholder

extension DailyWidgetEntry {
    /// Carrega a primeira mensagem real da biblioteca (por id, idioma do aparelho).
    /// Usado em previews e como placeholder — nunca texto fixo atribuído a autor (Regra 5).
    static var preview: DailyWidgetEntry {
        buildFromLibrary(daysToRace: 27)
    }

    static func buildFromLibrary(daysToRace: Int? = nil) -> DailyWidgetEntry {
        if let lib = try? ContentLibrary(),
           let msg = lib.messages.sorted(by: { $0.id < $1.id }).first {
            return DailyWidgetEntry(
                date: Date(),
                entry: DailyEntry(
                    day: DayKey(Date()),
                    messageID: msg.id,
                    imageID: lib.images.sorted(by: { $0.id < $1.id }).first?.id ?? "",
                    trigger: .geral,
                    shortText: msg.shortText,
                    inlineText: msg.inlineText,
                    author: msg.author,
                    reflection: msg.reflection,
                    daysToRace: daysToRace
                )
            )
        }
        // Biblioteca indisponível → vazio; views aplicarão .redacted.
        return DailyWidgetEntry(
            date: Date(),
            entry: DailyEntry(
                day: DayKey(Date()), messageID: "", imageID: "", trigger: .geral,
                shortText: "", inlineText: "", author: "", reflection: "", daysToRace: nil
            ),
            isPlaceholder: true
        )
    }
}

// MARK: - TimelineProvider

struct DailyProvider: TimelineProvider {

    func placeholder(in context: Context) -> DailyWidgetEntry {
        .buildFromLibrary()
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyWidgetEntry>) -> Void) {
        let plan  = SharedStore.loadPlan()
        let prefs = SharedStore.loadPreferencesIfExists()
        let lib   = try? ContentLibrary()

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

    private func currentEntry() -> DailyWidgetEntry {
        let plan  = SharedStore.loadPlan()
        let prefs = SharedStore.loadPreferencesIfExists()
        let lib   = try? ContentLibrary()
        let items = DailyTimelineGenerator.items(
            plan: plan, prefs: prefs,
            fallbackMessages: lib?.messages ?? [],
            fallbackImages: lib?.images ?? []
        )
        return items.first.map { DailyWidgetEntry(date: $0.date, entry: $0.entry) }
            ?? .buildFromLibrary()
    }
}
