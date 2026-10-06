import XCTest
@testable import AtletaEstoico

final class TriggerEngineTests: XCTestCase {

    // Data ancora: 2026-10-05 08:00 no fuso do aparelho.
    private let ref: Date = {
        Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 8))!
    }()

    // Cria uma data no fuso local com hora/minuto/dia específicos.
    private func at(hour: Int, minute: Int = 0, dayOffset: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(
            year: 2026, month: 10, day: 5 + dayOffset, hour: hour, minute: minute
        ))!
    }

    // TrainingContext com todos os valores padrão (→ .geral), sem calendário embutido.
    private func ctx(
        raceDate: Date? = nil,
        tomorrowSession: SessionType? = nil,
        todaySession: SessionType? = nil,
        lastWorkoutEnd: Date? = nil,
        lastPostWorkoutDelivered: Date? = nil,
        lastNightSleepHours: Double? = nil,
        sleepGoalHours: Double = 7,
        daysSinceLastWorkout: Int? = nil,
        lastExternalDataDate: Date? = nil
    ) -> TrainingContext {
        TrainingContext(
            now: ref,
            raceDate: raceDate,
            tomorrowSession: tomorrowSession,
            todaySession: todaySession,
            lastWorkoutEnd: lastWorkoutEnd,
            lastPostWorkoutDelivered: lastPostWorkoutDelivered,
            lastNightSleepHours: lastNightSleepHours,
            sleepGoalHours: sleepGoalHours,
            daysSinceLastWorkout: daysSinceLastWorkout,
            lastExternalDataDate: lastExternalDataDate
        )
    }

    private func days(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: n, to: ref)!
    }

    // MARK: - Regra 1: marco_prova

    func testMarcoProva_30Days() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(raceDate: days(30)), now: ref), .marcoProva)
    }
    func testMarcoProva_7Days() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(raceDate: days(7)), now: ref), .marcoProva)
    }
    func testMarcoProva_1Day() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(raceDate: days(1)), now: ref), .marcoProva)
    }
    func testMarcoProva_RaceDay() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(raceDate: days(0)), now: ref), .marcoProva)
    }
    func testMarcoProva_DoesNotFire_OtherDay() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(raceDate: days(10)), now: ref), .marcoProva)
    }
    func testMarcoProva_DoesNotFire_RaceWasYesterday() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(raceDate: days(-1)), now: ref), .marcoProva)
    }

    // MARK: - Regra 2: pos_treino

    func testPosTreino_WorkoutWithin3h_NoDelivery() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(lastWorkoutEnd: ref.addingTimeInterval(-2 * 3600)), now: ref), .posTreino)
    }
    func testPosTreino_DoesNotFire_WorkoutOver3hAgo() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(lastWorkoutEnd: ref.addingTimeInterval(-4 * 3600)), now: ref), .posTreino)
    }
    func testPosTreino_DoesNotFire_AlreadyDelivered() {
        let end = ref.addingTimeInterval(-2 * 3600)
        XCTAssertNotEqual(
            TriggerEngine.trigger(for: ctx(lastWorkoutEnd: end, lastPostWorkoutDelivered: end.addingTimeInterval(600)), now: ref),
            .posTreino
        )
    }
    func testPosTreino_FiresAgain_NewWorkoutAfterDelivery() {
        let delivered = at(hour: 9); let end = at(hour: 11); let n = at(hour: 12)
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(lastWorkoutEnd: end, lastPostWorkoutDelivered: delivered), now: n), .posTreino)
    }

    // MARK: - Regra 3: sono_ruim

    func testSonoRuim_BeforeNoon_BadSleep() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(lastNightSleepHours: 5.0), now: ref), .sonoRuim)
    }
    func testSonoRuim_DoesNotFire_SleepAboveThreshold() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(lastNightSleepHours: 6.0), now: ref), .sonoRuim)
    }
    func testSonoRuim_DoesNotFire_AfterNoon() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(lastNightSleepHours: 5.0), now: at(hour: 14)), .sonoRuim)
    }

    // MARK: - Regra 4: vespera_chave

    func testVesperaChave_LongoTomorrow() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(tomorrowSession: .longo), now: ref), .vesperaChave)
    }
    func testVesperaChave_ForteTomorrow() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(tomorrowSession: .forte), now: ref), .vesperaChave)
    }
    func testVesperaChave_DoesNotFire_LeveTomorrow() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(tomorrowSession: .leve), now: ref), .vesperaChave)
    }

    // MARK: - Regra 5: descanso

    func testDescanso_TodayIsDescanso() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(todaySession: .descanso), now: ref), .descanso)
    }
    func testDescanso_DoesNotFire_TodayIsLeve() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(todaySession: .leve), now: ref), .descanso)
    }

    // MARK: - Regra 6: retorno

    // (a) 6 dias sem treino → não é retorno (abaixo do threshold de 7)
    func testRetorno_DoesNotFire_6Days() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(daysSinceLastWorkout: 6), now: ref), .retorno)
    }
    func testRetorno_DoesNotFire_4Days() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(daysSinceLastWorkout: 4), now: ref), .retorno)
    }

    // (b) 7 dias + dado externo há 10h → .retorno (pausa real: relógio sincronizando)
    func testRetorno_7Days_RecentExternalData() {
        let extDate = ref.addingTimeInterval(-10 * 3600)  // 10h atrás
        XCTAssertEqual(
            TriggerEngine.trigger(for: ctx(daysSinceLastWorkout: 7, lastExternalDataDate: extDate), now: ref),
            .retorno
        )
    }

    // (c) 7 dias + último dado externo há 3 dias → não .retorno (syncSuspect)
    func testRetorno_DoesNotFire_SyncSuspect() {
        let extDate = ref.addingTimeInterval(-3 * 24 * 3600)  // 72h atrás
        let context = ctx(daysSinceLastWorkout: 7, lastExternalDataDate: extDate)
        XCTAssertNotEqual(TriggerEngine.trigger(for: context, now: ref), .retorno)
        XCTAssertTrue(context.syncSuspect, "Context deve expor syncSuspect == true")
    }

    // (d) 7 dias + sem dado externo → .retorno (sem relógio nos últimos 30 dias)
    func testRetorno_7Days_NoExternalData() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(daysSinceLastWorkout: 7), now: ref), .retorno)
    }

    // MARK: - Regra 7: geral

    func testGeral_NoConditionMet() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(), now: ref), .geral)
    }

    // MARK: - Conflitos de prioridade

    func testMarcoProva_BeatsSonoRuim_At7Days() {
        XCTAssertEqual(
            TriggerEngine.trigger(for: ctx(raceDate: days(7), lastNightSleepHours: 5.0), now: ref),
            .marcoProva
        )
    }
    func testPosTreino_BeatsSonoRuim_At13h30() {
        let n = at(hour: 13, minute: 30); let end = at(hour: 11, minute: 30)
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(lastWorkoutEnd: end, lastNightSleepHours: 5.0), now: n), .posTreino)
    }
    func testSonoRuim_DoesNotFire_At14h() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(lastNightSleepHours: 5.0), now: at(hour: 14)), .geral)
    }

    // MARK: - Virada de dia (23:59 / 00:01)

    func testDayFlip_At2359_SonoRuimDoesNotFire() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(lastNightSleepHours: 4.0), now: at(hour: 23, minute: 59)), .sonoRuim)
    }
    func testDayFlip_At0001_SonoRuimFires() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(lastNightSleepHours: 4.0), now: at(hour: 0, minute: 1, dayOffset: 1)), .sonoRuim)
    }

    // MARK: - Calendar com fuso fixo (America/Sao_Paulo UTC-3)

    private func utcDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        return utcCal.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private var saoCal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return c
    }()

    private var utcCal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    func testSonoRuim_SaoPaulo_BeforeNoon_SPT() {
        // 14:59 UTC = 11:59 São Paulo → hora 11 < 12 → são_ruim dispara
        let now = utcDate(year: 2026, month: 10, day: 5, hour: 14, minute: 59)
        XCTAssertEqual(
            TriggerEngine.trigger(for: ctx(lastNightSleepHours: 5.0), now: now, calendar: saoCal),
            .sonoRuim
        )
    }

    func testSonoRuim_UTC_SameTime_DoesNotFire() {
        // Mesmo instante, mas com calendário UTC → hora 14 ≥ 12 → não dispara
        let now = utcDate(year: 2026, month: 10, day: 5, hour: 14, minute: 59)
        XCTAssertNotEqual(
            TriggerEngine.trigger(for: ctx(lastNightSleepHours: 5.0), now: now, calendar: utcCal),
            .sonoRuim
        )
    }

    // Perto da fronteira de 12h em São Paulo: 14:59 UTC = 11:59 SPT (1 min antes do corte)
    // e 15:00 UTC = 12:00 SPT (exatamente no limite, não dispara pois não é < 12)
    func testSonoRuim_SaoPaulo_ExactlyNoon_DoesNotFire() {
        let now = utcDate(year: 2026, month: 10, day: 5, hour: 15)   // 12:00 São Paulo
        XCTAssertNotEqual(
            TriggerEngine.trigger(for: ctx(lastNightSleepHours: 5.0), now: now, calendar: saoCal),
            .sonoRuim
        )
    }
}

// MARK: - ContextBuilder tests

final class ContextBuilderTests: XCTestCase {

    func testBuildsContextWithWorkoutsAndSleep() async {
        let mock = MockHealthProvider()
        let now = Date()
        let end = now.addingTimeInterval(-2 * 3600)
        mock.workoutsToReturn = [
            WorkoutSummary(start: end.addingTimeInterval(-3600), end: end, distanceKm: 12, activityType: .running)
        ]
        mock.sleepHoursToReturn = 6.5

        let ctx = await ContextBuilder(healthProvider: mock)
            .build(race: nil, weekPlan: nil, profile: nil, deliveryLogs: [], now: now)

        XCTAssertEqual(ctx.lastWorkoutEnd, end)
        XCTAssertEqual(ctx.lastNightSleepHours, 6.5)
        XCTAssertEqual(ctx.daysSinceLastWorkout, 0)
        XCTAssertNil(ctx.raceDate)
        XCTAssertEqual(ctx.sleepGoalHours, 7)
    }

    func testBuildsContextWithNoHealthData() async {
        let mock = MockHealthProvider()
        let ctx = await ContextBuilder(healthProvider: mock)
            .build(race: nil, weekPlan: nil, profile: nil, deliveryLogs: [], now: Date())

        XCTAssertNil(ctx.lastWorkoutEnd)
        XCTAssertNil(ctx.lastNightSleepHours)
        XCTAssertNil(ctx.daysSinceLastWorkout)
        XCTAssertEqual(ctx.sleepGoalHours, 7)
    }

    func testSleepGoalFromProfile() async {
        let mock = MockHealthProvider()
        let profile = AthleteProfile(sleepGoalHours: 8)
        let ctx = await ContextBuilder(healthProvider: mock)
            .build(race: nil, weekPlan: nil, profile: profile, deliveryLogs: [], now: Date())
        XCTAssertEqual(ctx.sleepGoalHours, 8)
    }

    // HealthDataProviding lança erro → context montado com nil, gatilho = .geral
    func testContextBuilderWithError_YieldsGeral() async {
        let mock = MockHealthProvider()
        mock.workoutsError = MockError()
        mock.sleepError    = MockError()

        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 8))!
        let ctx = await ContextBuilder(healthProvider: mock)
            .build(race: nil, weekPlan: nil, profile: nil, deliveryLogs: [], now: now)

        XCTAssertNil(ctx.lastWorkoutEnd)
        XCTAssertNil(ctx.lastNightSleepHours)
        XCTAssertEqual(TriggerEngine.trigger(for: ctx, now: now), .geral)
    }

    // Treino há 20 dias → retorno (janela de 30 dias é necessária para detectá-lo)
    func testRetorno_20DaysSinceWorkout() async {
        let mock = MockHealthProvider()
        let now = Date()
        let workoutEnd = Calendar.current.date(byAdding: .day, value: -20, to: now)!
        mock.workoutsToReturn = [
            WorkoutSummary(start: workoutEnd.addingTimeInterval(-3600), end: workoutEnd, distanceKm: 15, activityType: .running)
        ]

        let ctx = await ContextBuilder(healthProvider: mock)
            .build(race: nil, weekPlan: nil, profile: nil, deliveryLogs: [], now: now)

        XCTAssertEqual(ctx.daysSinceLastWorkout, 20)
        XCTAssertEqual(TriggerEngine.trigger(for: ctx, now: now), .retorno)
    }

    func testPosTreinoBlockedSameDay() async {
        let mock = MockHealthProvider()
        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 10))!
        let end = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 8))!
        mock.workoutsToReturn = [
            WorkoutSummary(start: end.addingTimeInterval(-3600), end: end, distanceKm: 10, activityType: .running)
        ]
        let log = DeliveryLog(day: DayKey(now), messageID: "m1", imageID: "i1", trigger: .posTreino)

        let ctx = await ContextBuilder(healthProvider: mock)
            .build(race: nil, weekPlan: nil, profile: nil, deliveryLogs: [log], now: now)

        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx, now: now), .posTreino)
    }
}
