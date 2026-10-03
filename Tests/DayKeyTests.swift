import XCTest
@testable import AtletaEstoico

final class DayKeyTests: XCTestCase {
    private func calendar(_ identifier: Calendar.Identifier = .gregorian, timeZone: String) -> Calendar {
        var calendar = Calendar(identifier: identifier)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    func testValueFormat() {
        let sp = calendar(timeZone: "America/Sao_Paulo")
        XCTAssertEqual(DayKey(date(2026, 3, 5, 9, 0, in: sp), calendar: sp).value, "2026-03-05")
        XCTAssertEqual(DayKey(date(2026, 12, 31, 23, 59, in: sp), calendar: sp).value, "2026-12-31")
    }

    func testDayFollowsDeviceTimeZone() {
        let sp = calendar(timeZone: "America/Sao_Paulo")
        let utc = calendar(timeZone: "UTC")
        let instant = date(2026, 3, 10, 23, 30, in: sp)   // 02:30 UTC do dia 11
        XCTAssertEqual(DayKey(instant, calendar: sp).value, "2026-03-10")
        XCTAssertEqual(DayKey(instant, calendar: utc).value, "2026-03-11")
    }

    func testNonGregorianCalendarStillProducesGregorianKey() {
        let buddhist = calendar(.buddhist, timeZone: "America/Sao_Paulo")
        let sp = calendar(timeZone: "America/Sao_Paulo")
        let instant = date(2026, 3, 10, 12, 0, in: sp)
        XCTAssertEqual(DayKey(instant, calendar: buddhist).value, "2026-03-10")
    }

    // Valores conferidos em Python (datetime.date).
    func testDayNumber() {
        XCTAssertEqual(DayKey(value: "2026-01-01").dayNumber, 0)
        XCTAssertEqual(DayKey(value: "2026-01-31").dayNumber, 30)
        XCTAssertEqual(DayKey(value: "2026-03-10").dayNumber, 68)
        XCTAssertEqual(DayKey(value: "2026-12-31").dayNumber, 364)
        XCTAssertEqual(DayKey(value: "2027-01-01").dayNumber, 365)
        XCTAssertEqual(DayKey(value: "2025-12-31").dayNumber, -1)
        XCTAssertEqual(DayKey(value: "2024-02-29").dayNumber, -672)
        XCTAssertEqual(DayKey(value: "1999-12-31").dayNumber, -9498)
    }

    func testDayNumberOfInvalidValueIsZero() {
        XCTAssertEqual(DayKey(value: "lixo").dayNumber, 0)
    }

    func testComparableAndHashable() {
        XCTAssertLessThan(DayKey(value: "2026-01-31"), DayKey(value: "2026-02-01"))
        XCTAssertLessThan(DayKey(value: "2025-12-31"), DayKey(value: "2026-01-01"))
        XCTAssertEqual(Set([DayKey(value: "2026-01-01"), DayKey(value: "2026-01-01")]).count, 1)
    }

    func testCodableRoundTrip() throws {
        let key = DayKey(value: "2026-10-03")
        let data = try JSONEncoder().encode(key)
        XCTAssertEqual(try JSONDecoder().decode(DayKey.self, from: data), key)
    }
}
