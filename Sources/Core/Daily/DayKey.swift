import Foundation

/// Identificador de dia no formato "yyyy-MM-dd" (calendário gregoriano, fuso do aparelho).
struct DayKey: Hashable, Codable, Comparable {
    let value: String

    /// Usa só o fuso de `calendar`; a data é sempre lida no calendário gregoriano,
    /// para a chave não mudar se o usuário usar outro calendário (budista, japonês...).
    init(_ date: Date, calendar: Calendar = .current) {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let parts = gregorian.dateComponents([.year, .month, .day], from: date)
        value = String(format: "%04d-%02d-%02d", parts.year ?? 1970, parts.month ?? 1, parts.day ?? 1)
    }

    init(value: String) {
        self.value = value
    }

    /// Dias desde 2026-01-01 (pode ser negativo para datas anteriores). Aritmética pura de datas civis.
    var dayNumber: Int {
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return 0 }
        return Self.daysFromCivil(year: parts[0], month: parts[1], day: parts[2])
            - Self.daysFromCivil(year: 2026, month: 1, day: 1)
    }

    /// Retorna o início do dia representado por esta chave no calendário informado.
    /// Retorna nil se a string estiver malformada.
    func startOfDay(calendar: Calendar = .current) -> Date? {
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        lhs.value < rhs.value
    }

    /// Dias desde 1970-01-01 (algoritmo days_from_civil de Howard Hinnant).
    private static func daysFromCivil(year: Int, month: Int, day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yearOfEra = y - era * 400
        let monthShifted = (month + 9) % 12            // março = 0 ... fevereiro = 11
        let dayOfYear = (153 * monthShifted + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146097 + dayOfEra - 719468
    }
}
