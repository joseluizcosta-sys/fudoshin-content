import XCTest
import SwiftData
@testable import AtletaEstoico

final class StreakCalculatorTests: XCTestCase {

    var spCal: Calendar!
    var baseToday: Date!  // 2026-10-03 10:00 America/Sao_Paulo

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

    // MARK: - Testes requeridos pela revisão T10

    func testTodayAbsentYesterdayPresent5Days() {
        // Hoje sem entrada, 5 dias anteriores (ontem...-4) → 5
        XCTAssertEqual(
            StreakCalculator.streak(entryDays: days([-1,-2,-3,-4,-5]),
                                    upTo: baseToday, calendar: spCal),
            5, "Hoje ausente + 5 anteriores deve dar 5"
        )
    }

    func testTodayPresentPlus5Previous() {
        // Hoje com entrada + 5 anteriores → 6
        XCTAssertEqual(
            StreakCalculator.streak(entryDays: days([0,-1,-2,-3,-4,-5]),
                                    upTo: baseToday, calendar: spCal),
            6, "Hoje presente + 5 anteriores deve dar 6"
        )
    }

    func testBothTodayAndYesterdayAbsent() {
        // Hoje e ontem sem entrada → 0
        XCTAssertEqual(
            StreakCalculator.streak(entryDays: days([-2,-3,-4]),
                                    upTo: baseToday, calendar: spCal),
            0, "Hoje e ontem ausentes deve dar 0"
        )
    }

    // MARK: - Testes gerais

    func testZeroStreakWhenNoEntries() {
        XCTAssertEqual(StreakCalculator.streak(entryDays: [], upTo: baseToday, calendar: spCal), 0)
    }

    func testOneDayStreak_today() {
        XCTAssertEqual(StreakCalculator.streak(entryDays: days([0]), upTo: baseToday, calendar: spCal), 1)
    }

    func testOneDayStreak_yesterday() {
        // Só ontem (hoje ausente) → 1
        XCTAssertEqual(StreakCalculator.streak(entryDays: days([-1]), upTo: baseToday, calendar: spCal), 1)
    }

    func testConsecutiveDays() {
        // Hoje + ontem + anteontem = 3
        XCTAssertEqual(StreakCalculator.streak(entryDays: days([0,-1,-2]), upTo: baseToday, calendar: spCal), 3)
    }

    func testBrokenStreakTodayPresent() {
        // Hoje e anteontem (falta ontem) → 1 (sequência quebra em ontem)
        XCTAssertEqual(StreakCalculator.streak(entryDays: days([0,-2]), upTo: baseToday, calendar: spCal), 1)
    }

    func testBrokenStreakTodayAbsent() {
        // Ontem e anteontem (falta ante-anteontem) → 2
        XCTAssertEqual(StreakCalculator.streak(entryDays: days([-1,-2]), upTo: baseToday, calendar: spCal), 2)
    }
}

// MARK: - Migração SwiftData: Race.createdAt e DeliveryLog.notified

@MainActor
final class SwiftDataMigrationTests: XCTestCase {

    func testRaceCreatedAtIsFilledAfterInsert() throws {
        let container = try ModelContainer(
            for: Race.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = container.mainContext
        // Inserir sem fornecer createdAt (usa default da propriedade)
        ctx.insert(Race(name: "Ultra Trail", date: Date(), distanceKm: 42, category: .trail))
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<Race>())
        let race = try XCTUnwrap(fetched.first)
        // createdAt não deve ser distante do passado (epoch ou nulo)
        XCTAssertGreaterThan(race.createdAt, Date(timeIntervalSinceReferenceDate: 0),
                             "Race.createdAt deve ser preenchido com data recente")
    }

    func testDeliveryLogNotifiedDefaultsFalse() throws {
        let container = try ModelContainer(
            for: DeliveryLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = container.mainContext
        ctx.insert(DeliveryLog(day: DayKey(Date()), messageID: "m", imageID: "i", trigger: .geral))
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<DeliveryLog>())
        let log = try XCTUnwrap(fetched.first)
        XCTAssertFalse(log.notified, "DeliveryLog.notified deve ser false por padrão")
    }
}
