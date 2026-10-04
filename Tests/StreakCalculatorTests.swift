import XCTest
@testable import AtletaEstoico

final class StreakCalculatorTests: XCTestCase {

    var spCal: Calendar!
    var baseToday: Date!  // 2026-10-03

    override func setUp() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        spCal = cal
        baseToday = spCal.date(from: DateComponents(
            timeZone: TimeZone(identifier: "America/Sao_Paulo"),
            year: 2026, month: 10, day: 3, hour: 10
        ))!
    }

    private func days(_ offsets: [Int]) -> Set<String> {
        let todayStart = spCal.startOfDay(for: baseToday)
        return Set(offsets.compactMap { offset -> String? in
            spCal.date(byAdding: .day, value: offset, to: todayStart)
                .map { DayKey($0, calendar: spCal).value }
        })
    }

    func testZeroStreakWhenNoEntries() {
        XCTAssertEqual(StreakCalculator.streak(entryDays: [], upTo: baseToday, calendar: spCal), 0)
    }

    func testOneDayStreak() {
        XCTAssertEqual(StreakCalculator.streak(entryDays: days([0]), upTo: baseToday, calendar: spCal), 1)
    }

    func testConsecutiveDays() {
        // Hoje + ontem + antes de ontem = 3 dias
        XCTAssertEqual(StreakCalculator.streak(entryDays: days([0,-1,-2]), upTo: baseToday, calendar: spCal), 3)
    }

    func testBrokenStreak() {
        // Hoje e ante-ontem (falta ontem)
        XCTAssertEqual(StreakCalculator.streak(entryDays: days([0,-2]), upTo: baseToday, calendar: spCal), 1)
    }

    func testStreakWithoutToday() {
        // Só ontem e anteontem — sem hoje
        XCTAssertEqual(StreakCalculator.streak(entryDays: days([-1,-2]), upTo: baseToday, calendar: spCal), 0)
    }
}
