import Foundation

/// Calcula dias consecutivos com entrada no diário. Lógica pura — sem SwiftData.
enum StreakCalculator {
    /// Número de dias consecutivos com entrada em `entryDays`.
    ///
    /// Se hoje não tiver entrada, a contagem começa a partir de ontem — a ausência de
    /// hoje não quebra a sequência, só a de ontem quebra. Se ontem também faltar, retorna 0.
    static func streak(
        entryDays: Set<String>,
        upTo today: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let todayStart = calendar.startOfDay(for: today)
        let todayKey = DayKey(todayStart, calendar: calendar)

        // Ponto de partida: hoje se tiver entrada, senão ontem.
        let startDate: Date
        if entryDays.contains(todayKey.value) {
            startDate = todayStart
        } else {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart) else { return 0 }
            startDate = yesterday
        }

        var date = startDate
        var count = 0
        while entryDays.contains(DayKey(date, calendar: calendar).value) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }
}
