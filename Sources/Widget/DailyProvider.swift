import WidgetKit
import Foundation

// MARK: - TimelineEntry

struct DailyWidgetEntry: TimelineEntry {
    let date: Date
    let entry: DailyEntry
    var style: LockScreenStyle = .destaque
    /// true somente quando a ContentLibrary falhou ao carregar no placeholder.
    var isPlaceholder: Bool = false
    /// true quando o usuário não tem assinatura ativa.
    var isSubscriptionRequired: Bool = false
}

// MARK: - Entrada para Previews e Placeholder

extension DailyWidgetEntry {
    /// Carrega a primeira mensagem real da biblioteca (por id, idioma do aparelho).
    static var preview: DailyWidgetEntry { buildFromLibrary(daysToRace: 27) }

    /// Entradas com os textos mais longos do catálogo para validar que cabem nas fontes maiores.
    static var previewLongDestaque: DailyWidgetEntry {
        DailyWidgetEntry(
            date: Date(),
            entry: DailyEntry(
                day: DayKey(Date()), messageID: "preview-long", imageID: "",
                trigger: .geral,
                shortText: "El resultado viene de la constancia, no de un entrenamiento heroico.",
                inlineText: "El dato no es la historia",
                author: "", reflection: "", daysToRace: nil
            ),
            style: .destaque
        )
    }

    static var previewLongPalavraChave: DailyWidgetEntry {
        DailyWidgetEntry(
            date: Date(),
            entry: DailyEntry(
                day: DayKey(Date()), messageID: "preview-long", imageID: "",
                trigger: .geral,
                shortText: "El resultado viene de la constancia, no de un entrenamiento heroico.",
                inlineText: "El dato no es la historia",
                author: "", reflection: "", daysToRace: nil
            ),
            style: .palavraChave
        )
    }

    static func buildFromLibrary(daysToRace: Int? = nil, style: LockScreenStyle = .destaque) -> DailyWidgetEntry {
        let lib = ContentLibrary.current()
        if let msg = lib.messages.sorted(by: { $0.id < $1.id }).first {
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
                ),
                style: style
            )
        }
        return DailyWidgetEntry(
            date: Date(),
            entry: DailyEntry(
                day: DayKey(Date()), messageID: "", imageID: "", trigger: .geral,
                shortText: "", inlineText: "", author: "", reflection: "", daysToRace: nil
            ),
            style: style,
            isPlaceholder: true
        )
    }
}

// MARK: - AppIntentTimelineProvider

struct DailyProvider: AppIntentTimelineProvider {
    typealias Intent = LockScreenStyleIntent

    func placeholder(in context: Context) -> DailyWidgetEntry {
        .buildFromLibrary()
    }

    func snapshot(for configuration: LockScreenStyleIntent, in context: Context) async -> DailyWidgetEntry {
        currentEntry(style: configuration.style)
    }

    func timeline(for configuration: LockScreenStyleIntent, in context: Context) async -> Timeline<DailyWidgetEntry> {
        let plan  = SharedStore.loadPlan()
        let prefs = SharedStore.loadPreferencesIfExists()
        let lib   = ContentLibrary.current()

        // Sem assinatura: timeline com entrada especial para cada dia
        guard prefs?.isPremium == true else {
            let blocked = blockedEntry(style: configuration.style)
            return Timeline(entries: [blocked], policy: .atEnd)
        }

        let items = DailyTimelineGenerator.items(
            plan: plan,
            prefs: prefs,
            fallbackMessages: lib.messages,
            fallbackImages: lib.images
        )
        let entries = items.map {
            DailyWidgetEntry(date: $0.date, entry: $0.entry, style: configuration.style)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func blockedEntry(style: LockScreenStyle) -> DailyWidgetEntry {
        DailyWidgetEntry(
            date: Date(),
            entry: DailyEntry(
                day: DayKey(Date()), messageID: "", imageID: "", trigger: .geral,
                shortText: "", inlineText: String(localized: "widget.no_subscription"),
                author: "", reflection: "", daysToRace: nil
            ),
            style: style,
            isSubscriptionRequired: true
        )
    }

    // MARK: - Private

    private func currentEntry(style: LockScreenStyle) -> DailyWidgetEntry {
        let plan  = SharedStore.loadPlan()
        let prefs = SharedStore.loadPreferencesIfExists()
        let lib   = ContentLibrary.current()
        let items = DailyTimelineGenerator.items(
            plan: plan, prefs: prefs,
            fallbackMessages: lib.messages,
            fallbackImages: lib.images
        )
        return items.first.map { DailyWidgetEntry(date: $0.date, entry: $0.entry, style: style) }
            ?? .buildFromLibrary(style: style)
    }
}
