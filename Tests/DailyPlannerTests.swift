import XCTest
import SwiftData
@testable import AtletaEstoico

// MARK: - Mocks locais

final class MockNotificationScheduler: NotificationScheduling {
    private(set) var callCount = 0
    func schedule(plan: DailyPlan, notificationHour: Int) async { callCount += 1 }
}

final class MockWallpaperComposer: WallpaperComposing {
    private(set) var callCount = 0
    func prepareWallpaper(for entry: DailyEntry) async { callCount += 1 }
}

final class MockWidgetReloader: WidgetReloading {
    private(set) var callCount = 0
    func reloadAllTimelines() { callCount += 1 }
}

// MARK: - DailyPlannerTests

@MainActor
final class DailyPlannerTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var health: MockHealthProvider!
    var notifications: MockNotificationScheduler!
    var wallpaper: MockWallpaperComposer!
    var widgetReloader: MockWidgetReloader!
    var planner: DailyPlanner!
    var spCal: Calendar!
    var now: Date!          // 2026-10-03 10:00 America/Sao_Paulo

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Race.self, WeekPlan.self, AthleteProfile.self, JournalEntry.self, DeliveryLog.self,
            configurations: config
        )
        context = container.mainContext

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        spCal = cal

        var comps = DateComponents()
        comps.year = 2026; comps.month = 10; comps.day = 3
        comps.hour = 10; comps.minute = 0; comps.second = 0
        comps.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        now = spCal.date(from: comps)!

        health = MockHealthProvider()
        notifications = MockNotificationScheduler()
        wallpaper = MockWallpaperComposer()
        widgetReloader = MockWidgetReloader()

        // SharedStore com diretório temporário isolado
        SharedStore._baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("planner-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: SharedStore._baseURL!, withIntermediateDirectories: true)

        // Gravar preferências mínimas para loadPreferences() funcionar
        let prefs = SharedPreferences(installID: "test-install")
        try SharedStore.save(prefs)

        planner = makePlanner()
    }

    override func tearDown() {
        if let url = SharedStore._baseURL {
            try? FileManager.default.removeItem(at: url)
        }
        SharedStore._baseURL = nil
    }

    // MARK: - Helpers

    private func makePlanner() -> DailyPlanner {
        let builder = ContextBuilder(healthProvider: health)
        return DailyPlanner(
            contextBuilder: builder,
            messages: fakeMessages(),
            images: fakeImages(),
            contextTexts: fakeContextTexts(),
            personalizer: TemplatePersonalizer(),
            notifications: notifications,
            wallpaper: wallpaper,
            widgetReloader: widgetReloader,
            modelContext: context
        )
    }

    private func date(hour: Int, day: Int = 3) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 10; c.day = day
        c.hour = hour; c.minute = 0; c.second = 0
        c.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        return spCal.date(from: c)!
    }

    // Weekday index no formato interno de WeekPlan: seg=0..dom=6
    private func weekIndex(of date: Date) -> Int {
        let weekday = spCal.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    // MARK: - Content mínimo

    private func fakeMessages() -> [Message] {
        let pairs: [(String, Trigger)] = [
            ("msg1", .geral), ("msg2", .geral), ("msg3", .geral),
            ("msg4", .posTreino), ("msg5", .sonoRuim),
            ("msg6", .vesperaChave), ("msg7", .descanso),
            ("msg8", .retorno), ("msg9", .marcoProva),
            ("msg10", .geral)
        ]
        return pairs.map { id, trigger in
            Message(
                id: id, authorKey: "seneca", workKey: "cartas",
                author: "Sêneca", work: "Cartas a Lucílio",
                reference: "1", publicDomainSource: "PG",
                kind: "citacao", triggers: [trigger],
                text: "Texto \(id)", shortText: "Curto \(id)",
                inlineText: "Inline \(id)", reflection: "Reflexão \(id)"
            )
        }
    }

    private func fakeImages() -> [ImageAsset] {
        (1...3).map { i in
            makeImageAsset(id: "img\(i)")
        }
    }

    private func makeImageAsset(id: String) -> ImageAsset {
        // Decodifica via JSON para respeitar os CodingKeys do struct
        let json = """
        {
          "id": "\(id)",
          "arquivo": "\(id).jpg",
          "categoria": "trail",
          "local": "Serra",
          "horario": "manha",
          "estacao": "outono",
          "humores": ["foco"],
          "tom": "escuro",
          "area_frase": "inferior",
          "embarcada": true,
          "pacote": null,
          "autor": "test",
          "licenca": "CC0",
          "contrato": null,
          "credito_visivel": ""
        }
        """
        return try! JSONDecoder().decode(ImageAsset.self, from: Data(json.utf8))
    }

    private func fakeContextTexts() -> [String: String] {
        ["vespera_longo": "Longão amanhã", "vespera_forte": "Treino forte amanhã",
         "descanso": "Dia de descanso", "t30": "Faltam 30 dias",
         "t7": "Faltam 7 dias", "t1": "Amanhã é a prova", "d0": "Dia de prova"]
    }

    // MARK: - Testes

    func testSevenConsecutiveEntries() async throws {
        await planner.refresh(now: now, calendar: spCal)
        let plan = try XCTUnwrap(SharedStore.loadPlan())

        XCTAssertEqual(plan.entries.count, 7)

        let todayStart = spCal.startOfDay(for: now)
        for (offset, entry) in plan.entries.enumerated() {
            let expected = spCal.date(byAdding: .day, value: offset, to: todayStart)!
            XCTAssertEqual(entry.day.value, DayKey(expected, calendar: spCal).value,
                           "Entrada \(offset) com dia errado")
        }
    }

    func testTomorrowLongoImpliesVesperaChave() async throws {
        let tomorrow = spCal.date(byAdding: .day, value: 1, to: now)!
        let week = WeekPlan(sessions: [weekIndex(of: tomorrow): .longo])
        context.insert(week)
        try context.save()

        await planner.refresh(now: now, calendar: spCal)

        let plan = try XCTUnwrap(SharedStore.loadPlan())
        XCTAssertEqual(plan.entries[0].trigger, .vesperaChave)
    }

    func testSonoRuimOnlyToday() async throws {
        // Sono de 5h (< 7-1=6), horário = 10h (antes de 12h)
        health.sleepHoursToReturn = 5.0

        await planner.refresh(now: now, calendar: spCal)

        let plan = try XCTUnwrap(SharedStore.loadPlan())
        XCTAssertEqual(plan.entries[0].trigger, .sonoRuim, "Hoje deve ser sono_ruim")
        for entry in plan.entries.dropFirst() {
            XCTAssertNotEqual(entry.trigger, .sonoRuim,
                              "Dia futuro \(entry.day.value) não deve ter sono_ruim")
        }
    }

    func testWorkoutDetectedTodayBecomesPosTreeino() async throws {
        let workoutEnd = now.addingTimeInterval(-3600)   // 1h atrás
        health.workoutsToReturn = [
            WorkoutSummary(
                start: workoutEnd.addingTimeInterval(-3600),
                end: workoutEnd, distanceKm: 10, activityType: .running
            )
        ]

        await planner.refresh(now: now, calendar: spCal)

        let plan = try XCTUnwrap(SharedStore.loadPlan())
        XCTAssertEqual(plan.entries[0].trigger, .posTreino, "Hoje deve ser pos_treino")
        for entry in plan.entries.dropFirst() {
            XCTAssertNotEqual(entry.trigger, .posTreino,
                              "Dia futuro \(entry.day.value) não deve ter pos_treino")
        }
    }

    func testPosTreinoStickiness() async throws {
        // Refresh às 8h: treino 30min antes → pos_treino
        let earlyNow = date(hour: 8)
        let workoutEnd = earlyNow.addingTimeInterval(-1800)
        health.workoutsToReturn = [
            WorkoutSummary(
                start: workoutEnd.addingTimeInterval(-3600),
                end: workoutEnd, distanceKm: 10, activityType: .running
            )
        ]
        await planner.refresh(now: earlyNow, calendar: spCal)

        let firstPlan = try XCTUnwrap(SharedStore.loadPlan())
        XCTAssertEqual(firstPlan.entries[0].trigger, .posTreino)
        let firstMessageID = firstPlan.entries[0].messageID

        // Refresh às 15h: treino fora da janela de 3h, mas stickiness mantém
        let lateNow = date(hour: 15)
        health.workoutsToReturn = []

        await planner.refresh(now: lateNow, calendar: spCal)

        let secondPlan = try XCTUnwrap(SharedStore.loadPlan())
        XCTAssertEqual(secondPlan.entries[0].trigger, .posTreino, "Stickiness: gatilho mantido")
        XCTAssertEqual(secondPlan.entries[0].messageID, firstMessageID, "Stickiness: mesma mensagem")
    }

    func testIdempotency() async throws {
        await planner.refresh(now: now, calendar: spCal)
        let first = try XCTUnwrap(SharedStore.loadPlan())

        await planner.refresh(now: now, calendar: spCal)
        let second = try XCTUnwrap(SharedStore.loadPlan())

        XCTAssertEqual(first.entries.count, second.entries.count)
        for (a, b) in zip(first.entries, second.entries) {
            XCTAssertEqual(a, b, "Planos devem ser idênticos em dois refreshes")
        }

        // Exatamente um DeliveryLog para hoje
        let allLogs = (try? context.fetch(FetchDescriptor<DeliveryLog>())) ?? []
        let todayKey = DayKey(now, calendar: spCal).value
        let todayLogs = allLogs.filter { $0.dayValue == todayKey }
        XCTAssertEqual(todayLogs.count, 1, "Deve haver exatamente um DeliveryLog para hoje")
    }

    func testStalePlanReplacedWhenAppWasClosed3Days() async throws {
        // Plano de 3 dias atrás
        let threeDaysAgo = spCal.date(byAdding: .day, value: -3, to: now)!
        let oldEntries: [DailyEntry] = (0..<7).map { offset in
            let d = spCal.date(byAdding: .day, value: offset, to: threeDaysAgo)!
            return DailyEntry(
                day: DayKey(d, calendar: spCal), messageID: "old", imageID: "img1",
                trigger: .geral, shortText: "old", inlineText: "old",
                author: "old", reflection: "old", daysToRace: nil
            )
        }
        try SharedStore.save(DailyPlan(generatedAt: threeDaysAgo, entries: oldEntries))

        await planner.refresh(now: now, calendar: spCal)

        let plan = try XCTUnwrap(SharedStore.loadPlan())
        XCTAssertEqual(plan.entries.count, 7)
        XCTAssertEqual(plan.entries[0].day.value, DayKey(now, calendar: spCal).value,
                       "Novo plano deve começar hoje")
        XCTAssertNotEqual(plan.entries[0].messageID, "old", "Plano velho deve ser substituído")
    }
}
