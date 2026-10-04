import Foundation

/// Gera os items da timeline do widget a partir do plano salvo ou de um fallback local.
/// Sem imports de WidgetKit — testável diretamente pelo target de testes do app.
enum DailyTimelineGenerator {

    struct TimelineItem {
        let date: Date
        let entry: DailyEntry
    }

    /// Retorna os items para a timeline do widget.
    /// - Se o plano tiver entradas de hoje em diante, usa o plano.
    /// - Caso contrário, gera 1 item geral determinístico (nunca cria arquivos no App Group).
    static func items(
        plan: DailyPlan?,
        prefs: SharedPreferences?,
        fallbackMessages: [Message],
        fallbackImages: [ImageAsset],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [TimelineItem] {
        let cal = calendar
        let changeHour = prefs?.changeHour ?? 0
        let todayKey = DayKey(now, calendar: cal)

        if let plan, plan.entries.contains(where: { $0.day >= todayKey }) {
            return plan.entries.compactMap { entry -> TimelineItem? in
                guard let dayStart = entry.day.startOfDay(calendar: cal),
                      let fireDate = cal.date(bySettingHour: changeHour,
                                              minute: 0, second: 0, of: dayStart)
                else { return nil }
                return TimelineItem(date: fireDate, entry: entry)
            }
        }

        return [fallback(now: now, calendar: cal, prefs: prefs,
                         messages: fallbackMessages, images: fallbackImages)]
    }

    private static func fallback(
        now: Date,
        calendar: Calendar,
        prefs: SharedPreferences?,
        messages: [Message],
        images: [ImageAsset]
    ) -> TimelineItem {
        let installID = prefs?.installID ?? "pending"
        let day = DayKey(now, calendar: calendar)
        let sortedMsgs = messages.sorted { $0.id < $1.id }
        let sortedImgs = images.sorted { $0.id < $1.id }

        let msg: Message? = sortedMsgs.isEmpty ? nil : {
            let idx = DailyPicker.index(count: sortedMsgs.count,
                                        installID: installID, salt: "msg", day: day)
            return sortedMsgs[idx]
        }()
        let img: ImageAsset? = sortedImgs.isEmpty ? nil : {
            let idx = DailyPicker.index(count: sortedImgs.count,
                                        installID: installID, salt: "img", day: day)
            return sortedImgs[idx]
        }()

        let entry = DailyEntry(
            day: day,
            messageID: msg?.id ?? "",
            imageID: img?.id ?? "",
            trigger: .geral,
            shortText: msg?.shortText ?? "",
            inlineText: msg?.inlineText ?? "",
            author: msg?.author ?? "",
            reflection: msg?.reflection ?? "",
            daysToRace: nil
        )
        return TimelineItem(date: now, entry: entry)
    }
}
