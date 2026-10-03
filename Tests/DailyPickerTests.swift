import XCTest
@testable import AtletaEstoico

final class DailyPickerTests: XCTestCase {
    /// DayKey de "2026-01-01" + n dias (n pode ser negativo).
    private func dayKey(offset n: Int) -> DayKey {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let epoch = utc.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!
        let date = utc.date(byAdding: .day, value: n, to: epoch)!
        return DayKey(date, calendar: utc)
    }

    private func picks(count: Int, installID: String, salt: String, from start: Int) -> [Int] {
        (start..<(start + count)).map {
            DailyPicker.index(count: count, installID: installID, salt: salt, day: dayKey(offset: $0))
        }
    }

    // Valores conferidos com a mesma lógica em Python (FNV-1a + SplitMix64 + Fisher–Yates).
    func testFixedExpectedValues() {
        func index(_ count: Int, _ install: String, _ salt: String, _ day: String) -> Int {
            DailyPicker.index(count: count, installID: install, salt: salt, day: DayKey(value: day))
        }
        XCTAssertEqual(index(30, "install-A", "msg", "2026-01-01"), 26)
        XCTAssertEqual(index(30, "install-A", "msg", "2026-01-02"), 29)
        XCTAssertEqual(index(30, "install-B", "msg", "2026-01-01"), 17)
        XCTAssertEqual(index(30, "install-A", "img", "2026-01-01"), 8)
        XCTAssertEqual(index(7, "install-A", "msg", "2026-01-10"), 2)
        XCTAssertEqual(index(120, "install-A", "msg", "2026-10-03"), 89)
        XCTAssertEqual(index(30, "install-A", "msg", "2025-12-31"), 10)   // dayNumber negativo
        XCTAssertEqual(index(1, "x", "msg", "2026-05-05"), 0)
    }

    func testFirstCycleOrderMatchesReference() {
        let expectedA = [26, 29, 22, 18, 23, 0, 10, 12, 15, 21, 4, 5, 20, 14, 13, 17, 8, 9, 16, 1, 11, 28, 7, 6, 25, 2, 3, 19, 27, 24]
        XCTAssertEqual(picks(count: 30, installID: "install-A", salt: "msg", from: 0), expectedA)
        XCTAssertEqual(DailyPicker.permutation(count: 30, installID: "install-A", salt: "msg", cycle: 0), expectedA)
    }

    func testSecondCycleStartsAtNextBlock() {
        XCTAssertEqual(picks(count: 7, installID: "install-A", salt: "msg", from: 0), [4, 0, 6, 3, 1, 2, 5])
        XCTAssertEqual(picks(count: 7, installID: "install-A", salt: "msg", from: 7), [3, 6, 2, 1, 4, 0, 5])
    }

    func testSameInputSameOutput() {
        let day = DayKey(value: "2026-06-15")
        let first = DailyPicker.index(count: 50, installID: "abc", salt: "msg", day: day)
        for _ in 0..<5 {
            XCTAssertEqual(DailyPicker.index(count: 50, installID: "abc", salt: "msg", day: day), first)
        }
    }

    func testNoRepeatWithinCycle() {
        for count in [7, 30, 120] {
            for cycle in [0, 1, 3, -1] {
                let start = cycle * count
                let result = picks(count: count, installID: "install-A", salt: "msg", from: start)
                XCTAssertEqual(Set(result), Set(0..<count), "Repetição no ciclo \(cycle) com count \(count)")
            }
        }
    }

    func testIndexAlwaysInRange() {
        for n in -40..<400 {
            let value = DailyPicker.index(count: 13, installID: "x", salt: "img", day: dayKey(offset: n))
            XCTAssertTrue((0..<13).contains(value))
        }
    }

    func testDifferentInstallIDsGiveDifferentOrders() {
        let expectedB = [17, 23, 9, 24, 21, 15, 8, 29, 6, 11, 13, 19, 22, 28, 0, 16, 7, 10, 27, 1, 25, 5, 4, 18, 12, 20, 3, 14, 2, 26]
        let a = picks(count: 30, installID: "install-A", salt: "msg", from: 0)
        let b = picks(count: 30, installID: "install-B", salt: "msg", from: 0)
        XCTAssertEqual(b, expectedB)
        XCTAssertNotEqual(a, b)
    }

    func testDifferentSaltsGiveDifferentOrders() {
        XCTAssertNotEqual(picks(count: 30, installID: "install-A", salt: "msg", from: 0),
                          picks(count: 30, installID: "install-A", salt: "img", from: 0))
    }

    func testDegenerateCounts() {
        XCTAssertEqual(DailyPicker.index(count: 0, installID: "x", salt: "msg", day: DayKey(value: "2026-01-01")), 0)
        XCTAssertEqual(DailyPicker.index(count: 1, installID: "x", salt: "msg", day: DayKey(value: "2026-01-01")), 0)
    }
}
