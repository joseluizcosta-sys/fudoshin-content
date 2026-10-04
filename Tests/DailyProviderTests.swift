import XCTest
@testable import AtletaEstoico

/// Testa DailyTimelineGenerator — lógica pura do provider, sem WidgetKit.
final class DailyProviderTests: XCTestCase {

    var messages: [Message]!
    var images: [ImageAsset]!
    var prefs: SharedPreferences!
    var spCal: Calendar!
    var baseNow: Date!   // 2026-10-03 10:00 America/Sao_Paulo

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

    // MARK: - Testes

    func testValidPlanProduces7Entries() {
        let plan = fakePlan(startingAt: baseNow)

        let items = DailyTimelineGenerator.items(
            plan: plan, prefs: prefs,
            fallbackMessages: messages, fallbackImages: images,
            now: baseNow, calendar: spCal
        )

        XCTAssertEqual(items.count, 7, "Plano válido deve gerar 7 entries na timeline")

        // Cada entry deve disparar na changeHour (0h) do seu dia.
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

    func testNoPlanProduces1GeneralEntry() {
        let items = DailyTimelineGenerator.items(
            plan: nil, prefs: prefs,
            fallbackMessages: messages, fallbackImages: images,
            now: baseNow, calendar: spCal
        )

        XCTAssertEqual(items.count, 1, "Sem plano deve gerar 1 entrada de fallback")
        XCTAssertEqual(items[0].entry.trigger, .geral, "Fallback deve usar gatilho geral")
        XCTAssertFalse(items[0].entry.shortText.isEmpty, "Fallback deve ter texto")
        XCTAssertFalse(items[0].entry.author.isEmpty,    "Fallback deve ter autor")
    }

    func testStalePlanProducesLocalEntry() throws {
        // Plano cujas entradas terminaram antes de hoje (todos os dias já passaram).
        let eightDaysAgo = spCal.date(byAdding: .day, value: -8, to: baseNow)!
        let stalePlan = fakePlan(startingAt: eightDaysAgo, count: 7)
        // Entradas: Oct -7 a Oct -1 relativo a Oct 3 → todas no passado.

        let items = DailyTimelineGenerator.items(
            plan: stalePlan, prefs: prefs,
            fallbackMessages: messages, fallbackImages: images,
            now: baseNow, calendar: spCal
        )

        XCTAssertEqual(items.count, 1, "Plano vencido deve gerar 1 entrada local")
        XCTAssertEqual(items[0].entry.trigger, .geral)
    }
}
