import XCTest
@testable import AtletaEstoico

final class SleepCalculatorTests: XCTestCase {
    private let base = Date(timeIntervalSinceReferenceDate: 0)

    // MARK: - Casos base

    func testNoSamplesReturnsNil() {
        XCTAssertNil(SleepCalculator.totalHours(from: []))
    }

    func testSingleIntervalReturnsCorrectHours() {
        let intervals = [DateInterval(start: base, duration: 3600 * 7.5)]
        XCTAssertEqual(SleepCalculator.totalHours(from: intervals)!, 7.5, accuracy: 0.001)
    }

    // MARK: - Sobreposição (Garmin + Apple Watch)

    func testOverlappingIntervalsCountedOnce() {
        // Garmin: 0-4h | Watch: 2-6h → resultado: 0-6h = 6h (não 8h)
        let intervals: [DateInterval] = [
            DateInterval(start: base, duration: 3600 * 4),
            DateInterval(start: base.addingTimeInterval(3600 * 2), duration: 3600 * 4),
        ]
        XCTAssertEqual(SleepCalculator.totalHours(from: intervals)!, 6.0, accuracy: 0.001)
    }

    func testContainedIntervalDoesNotAddTime() {
        // Garmin: 0-7h | Watch: 1-6h (contido) → resultado: 7h
        let intervals: [DateInterval] = [
            DateInterval(start: base, duration: 3600 * 7),
            DateInterval(start: base.addingTimeInterval(3600 * 1), duration: 3600 * 5),
        ]
        XCTAssertEqual(SleepCalculator.totalHours(from: intervals)!, 7.0, accuracy: 0.001)
    }

    func testThreeSourcesWithOverlapsMergedCorrectly() {
        // Garmin: 0-7h | Watch: 1-7h (sobreposição) | Extra: 7-8h (adjacente)
        let intervals: [DateInterval] = [
            DateInterval(start: base, duration: 3600 * 7),
            DateInterval(start: base.addingTimeInterval(3600 * 1), duration: 3600 * 6),
            DateInterval(start: base.addingTimeInterval(3600 * 7), duration: 3600 * 1),
        ]
        XCTAssertEqual(SleepCalculator.totalHours(from: intervals)!, 8.0, accuracy: 0.001)
    }

    // MARK: - Intervalos separados

    func testNonOverlappingIntervalsSummed() {
        // 3h de sono + 4h de sono (com intervalo entre eles) = 7h
        let intervals: [DateInterval] = [
            DateInterval(start: base, duration: 3600 * 3),
            DateInterval(start: base.addingTimeInterval(3600 * 4), duration: 3600 * 4),
        ]
        XCTAssertEqual(SleepCalculator.totalHours(from: intervals)!, 7.0, accuracy: 0.001)
    }

    func testAdjacentIntervalsAreMerged() {
        // 0-3h e 3-7h (adjacentes) → 7h
        let intervals: [DateInterval] = [
            DateInterval(start: base, duration: 3600 * 3),
            DateInterval(start: base.addingTimeInterval(3600 * 3), duration: 3600 * 4),
        ]
        XCTAssertEqual(SleepCalculator.totalHours(from: intervals)!, 7.0, accuracy: 0.001)
    }

    // MARK: - inBed ignorado (responsabilidade do chamador — apenas intervalos asleep entram)

    func testEmptyAfterFilteringReturnsNil() {
        // Se o chamador filtra os inBed/awake e não sobra nada → nil
        XCTAssertNil(SleepCalculator.totalHours(from: []))
    }

    // MARK: - Fora de ordem

    func testUnsortedInputProducesCorrectResult() {
        // Intervalos chegando fora de ordem
        let intervals: [DateInterval] = [
            DateInterval(start: base.addingTimeInterval(3600 * 4), duration: 3600 * 3), // 4-7h
            DateInterval(start: base, duration: 3600 * 3),                               // 0-3h
        ]
        XCTAssertEqual(SleepCalculator.totalHours(from: intervals)!, 6.0, accuracy: 0.001)
    }
}
