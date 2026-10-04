import XCTest
@testable import AtletaEstoico

/// Testa DailyTimelineGenerator — lógica pura do provider, sem WidgetKit.
final class DailyProviderTests: XCTestCase {

    var messages: [Message]!
    var images: [ImageAsset]!
    var prefs: SharedPreferences!    // changeHour = 0
    var spCal: Calendar!
    var baseNow: Date!               // 2026-10-03 10:00 America/Sao_Paulo

    override func setUpWithError() throws {
        SharedStore._baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("provider-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: SharedStore._baseURL!,
                                                withIntermediateDirectories: true)

        let lib = try ContentLibrary()
        messages = lib.messages
        images   = lib.images

        prefs = SharedPreferences(installID: "test-widget", changeHour: 0)
        try SharedStore.save(prefs)

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        spCal = cal

        baseNow = spCal.date(from: DateComponents(
            timeZone: TimeZone(identifier: "America/Sao_Paulo"),
            year: 2026, month: 10, day: 3, hour: 10, minute: 0, second: 0
        ))!
    }

    override func tearDownWithError() throws {
        if let url = SharedStore._baseURL { try? FileManager.default.removeItem(at: url) }
        SharedStore._baseURL = nil
    }

    // MARK: - Helpers

    private func date(day: Int = 3, hour: Int = 10) -> Date {
        spCal.date(from: DateComponents(
            timeZone: TimeZone(identifier: "America/Sao_Paulo"),
            year: 2026, month: 10, day: day, hour: hour, minute: 0, second: 0
        ))!
    }

    private func fakePlan(startingAt now: Date, count: Int = 7) -> DailyPlan {
        let todayStart = spCal.startOfDay(for: now)
        let entries = (0..<count).compactMap { offset -> DailyEntry? in
            guard let d = spCal.date(byAdding: .day, value: offset, to: todayStart) else { return nil }
            return DailyEntry(
                day: DayKey(d, calendar: spCal),
                messageID: "m\(offset)", imageID: "i\(offset)",
                trigger: .geral, shortText: "s\(offset)", inlineText: "i",
                author: "Epicteto", reflection: "r", daysToRace: nil
            )
        }
        return DailyPlan(generatedAt: now, entries: entries)
    }

    // MARK: - Testes: plano válido

    func testValidPlanProduces7Entries() {
        let plan = fakePlan(startingAt: baseNow)

        let items = DailyTimelineGenerator.items(
            plan: plan, prefs: prefs,
            fallbackMessages: messages, fallbackImages: images,
            now: baseNow, calendar: spCal
        )

        XCTAssertEqual(items.count, 7, "Plano válido deve gerar 7 entries na timeline")

        let todayStart = spCal.startOfDay(for: baseNow)
        for (i, item) in items.enumerated() {
            let expectedDayStart = spCal.date(byAdding: .day, value: i, to: todayStart)!
            let expectedDate = spCal.date(
                bySettingHour: prefs.changeHour, minute: 0, second: 0, of: expectedDayStart
            )!
            XCTAssertEqual(item.date, expectedDate, "Entrada \(i): data incorreta")
            XCTAssertEqual(item.entry.messageID, "m\(i)", "Entrada \(i): messageID incorreto")
        }
    }

    // MARK: - Testes: sem plano → 7 entradas em datas crescentes

    func testNoPlanProduces7GeneralEntries() {
        // changeHour = 0, baseNow = 10h → now >= midnight → sem ontem
        let items = DailyTimelineGenerator.items(
            plan: nil, prefs: prefs,
            fallbackMessages: messages, fallbackImages: images,
            now: baseNow, calendar: spCal
        )

        XCTAssertEqual(items.count, 7, "Sem plano deve gerar 7 entradas de fallback")
        for item in items {
            XCTAssertEqual(item.entry.trigger, .geral)
            XCTAssertFalse(item.entry.shortText.isEmpty, "Texto não pode ser vazio")
            XCTAssertFalse(item.entry.author.isEmpty, "Autor não pode ser vazio")
        }
        // Datas crescentes
        for i in 1..<items.count {
            XCTAssertGreaterThan(items[i].date, items[i - 1].date,
                                 "Datas devem ser estritamente crescentes")
        }
    }

    // MARK: - Testes: plano vencido → 7 entradas locais

    func testStalePlanProduces7LocalEntries() {
        let eightDaysAgo = spCal.date(byAdding: .day, value: -8, to: baseNow)!
        let stalePlan = fakePlan(startingAt: eightDaysAgo, count: 7)

        let items = DailyTimelineGenerator.items(
            plan: stalePlan, prefs: prefs,
            fallbackMessages: messages, fallbackImages: images,
            now: baseNow, calendar: spCal
        )

        XCTAssertEqual(items.count, 7, "Plano vencido deve gerar 7 entradas locais")
        for item in items {
            XCTAssertEqual(item.entry.trigger, .geral)
        }
    }

    // MARK: - Testes: antes da changeHour → inclui ontem

    func testBeforeChangeHourIncludesYesterdayEntry() {
        // changeHour = 6, now = 03:00 → before changeHour → ontem incluído
        var prefsEarly = SharedPreferences(installID: "test-widget", changeHour: 6)
        let earlyNow = date(day: 3, hour: 3)

        let items = DailyTimelineGenerator.items(
            plan: nil, prefs: prefsEarly,
            fallbackMessages: messages, fallbackImages: images,
            now: earlyNow, calendar: spCal
        )

        // ontem (Oct 2) + 7 dias (Oct 3–9) = 8
        XCTAssertEqual(items.count, 8,
                       "Antes da changeHour: ontem + 7 dias = 8 entradas")

        let yesterdayAt6 = date(day: 2, hour: 6)
        XCTAssertEqual(items[0].date, yesterdayAt6,
                       "Primeira entrada deve ser ontem às changeHour")

        let todayAt6 = date(day: 3, hour: 6)
        XCTAssertEqual(items[1].date, todayAt6,
                       "Segunda entrada deve ser hoje às changeHour")
    }

    func testAfterChangeHourNoYesterdayEntry() {
        // changeHour = 0, now = 10h → after changeHour → sem ontem
        let items = DailyTimelineGenerator.items(
            plan: nil, prefs: prefs,
            fallbackMessages: messages, fallbackImages: images,
            now: baseNow, calendar: spCal
        )

        XCTAssertEqual(items.count, 7, "Após a changeHour: sem ontem → 7 entradas")
        // Primeira data = hoje à meia-noite
        let todayMidnight = spCal.startOfDay(for: baseNow)
        XCTAssertEqual(items[0].date, todayMidnight, "Primeira entrada às 00h de hoje")
    }
}
