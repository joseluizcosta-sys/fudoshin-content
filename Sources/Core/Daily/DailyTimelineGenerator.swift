import Foundation

/// Gera os items da timeline do widget a partir do plano salvo ou de um fallback local.
/// Sem imports de WidgetKit — testável diretamente pelo target de testes do app.
enum DailyTimelineGenerator {

    struct TimelineItem {
        let date: Date
        let entry: DailyEntry
    }

    /// Retorna os items para a timeline do widget.
    ///
    /// - Se o plano tiver entradas de hoje em diante: usa somente essas entradas (filtra o passado).
    /// - Caso contrário: gera 7 items (hoje + 6 dias) com DailyPicker.
    /// - Se `now` for anterior à changeHour de hoje: prepend a entrada de ontem à changeHour de ontem,
    ///   para que o widget não fique vazio até a troca.
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
        let installID = prefs?.installID ?? "pending"
        let todayStart = cal.startOfDay(for: now)
        let todayKey = DayKey(now, calendar: cal)

        // --- Base: plano válido ou 7-day fallback ---
        var base: [TimelineItem]

        if let plan, plan.entries.contains(where: { $0.day >= todayKey }) {
            // Somente entradas de hoje em diante (ontem é tratado separadamente abaixo).
            base = plan.entries
                .filter { $0.day >= todayKey }
                .compactMap { entry -> TimelineItem? in
                    guard let dayStart = entry.day.startOfDay(calendar: cal),
                          let fire = cal.date(bySettingHour: changeHour,
                                              minute: 0, second: 0, of: dayStart)
                    else { return nil }
                    return TimelineItem(date: fire, entry: entry)
                }
        } else {
            // Fallback: 7 dias (hoje + 6 futuros), cada um na changeHour do seu dia.
            base = (0..<7).compactMap { offset -> TimelineItem? in
                guard let dayStart = cal.date(byAdding: .day, value: offset, to: todayStart),
                      let fire = cal.date(bySettingHour: changeHour,
                                          minute: 0, second: 0, of: dayStart)
                else { return nil }
                let day = DayKey(dayStart, calendar: cal)
                let entry = buildFallback(day: day, installID: installID,
                                          messages: fallbackMessages, images: fallbackImages)
                return TimelineItem(date: fire, entry: entry)
            }
        }

        // --- Ontem: necessário quando now < changeHour de hoje ---
        if let todayFire = cal.date(bySettingHour: changeHour, minute: 0, second: 0, of: todayStart),
           now < todayFire {
            let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart)!
            let yesterdayKey   = DayKey(yesterdayStart, calendar: cal)
            let yesterdayFire  = cal.date(bySettingHour: changeHour,
                                          minute: 0, second: 0, of: yesterdayStart)!

            // Preferência: entrada do plano para ontem; senão, fallback.
            let yesterdayEntry: DailyEntry = plan?.entries.first(where: { $0.day == yesterdayKey })
                ?? buildFallback(day: yesterdayKey, installID: installID,
                                 messages: fallbackMessages, images: fallbackImages)

            base.insert(TimelineItem(date: yesterdayFire, entry: yesterdayEntry), at: 0)
        }

        return base
    }

    // MARK: - Helpers

    private static func buildFallback(
        day: DayKey,
        installID: String,
        messages: [Message],
        images: [ImageAsset]
    ) -> DailyEntry {
        let sortedMsgs = messages.sorted { $0.id < $1.id }
        let sortedImgs = images.sorted { $0.id < $1.id }

        let msg: Message? = sortedMsgs.isEmpty ? nil : sortedMsgs[
            DailyPicker.index(count: sortedMsgs.count, installID: installID, salt: "msg", day: day)
        ]
        let img: ImageAsset? = sortedImgs.isEmpty ? nil : sortedImgs[
            DailyPicker.index(count: sortedImgs.count, installID: installID, salt: "img", day: day)
        ]

        return DailyEntry(
            day: day,
            messageID: msg?.id ?? "",
            imageID:   img?.id ?? "",
            trigger:   .geral,
            shortText: msg?.shortText ?? "",
            inlineText: msg?.inlineText ?? "",
            author:     msg?.author ?? "",
            reflection: msg?.reflection ?? "",
            daysToRace: nil
        )
    }
}
