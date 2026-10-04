import Foundation

/// Calcula dias consecutivos com entrada no diário. Lógica pura — sem SwiftData.
enum StreakCalculator {
    /// Número de dias consecutivos até `today` (inclusive) que existem em `entryDays`.
    /// A sequência quebra no primeiro dia ausente.
    static func streak(
        entryDays: Set<String>,
        upTo today: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        var date = calendar.startOfDay(for: today)
        var count = 0
        while entryDays.contains(DayKey(date, calendar: calendar).value) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }
}
