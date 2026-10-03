import XCTest
@testable import AtletaEstoico

final class TriggerEngineTests: XCTestCase {

    // Data ancora: 2026-10-05 08:00 no fuso do aparelho.
    private let ref: Date = {
        Calendar.current.date(from: DateComponents(
            year: 2026, month: 10, day: 5, hour: 8
        ))!
    }()

    // Cria uma data no mesmo dia de referência com outra hora.
    private func at(hour: Int, minute: Int = 0, dayOffset: Int = 0) -> Date {
        let base = Calendar.current.date(from: DateComponents(
            year: 2026, month: 10, day: 5 + dayOffset, hour: hour, minute: minute
        ))!
        return base
    }

    // Cria TrainingContext com todos os valores padrão (→ .geral).
    private func ctx(
        raceDate: Date? = nil,
        tomorrowSession: SessionType? = nil,
        todaySession: SessionType? = nil,
        lastWorkoutEnd: Date? = nil,
        lastPostWorkoutDelivered: Date? = nil,
        lastNightSleepHours: Double? = nil,
        sleepGoalHours: Double = 7,
        daysSinceLastWorkout: Int? = nil
    ) -> TrainingContext {
        TrainingContext(
            raceDate: raceDate,
            tomorrowSession: tomorrowSession,
            todaySession: todaySession,
            lastWorkoutEnd: lastWorkoutEnd,
            lastPostWorkoutDelivered: lastPostWorkoutDelivered,
            lastNightSleepHours: lastNightSleepHours,
            sleepGoalHours: sleepGoalHours,
            daysSinceLastWorkout: daysSinceLastWorkout
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
        let end = ref.addingTimeInterval(-2 * 3600)
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(lastWorkoutEnd: end), now: ref), .posTreino)
    }

    func testPosTreino_DoesNotFire_WorkoutOver3hAgo() {
        let end = ref.addingTimeInterval(-4 * 3600)
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(lastWorkoutEnd: end), now: ref), .posTreino)
    }

    func testPosTreino_DoesNotFire_AlreadyDelivered() {
        let end = ref.addingTimeInterval(-2 * 3600)
        let delivered = end.addingTimeInterval(600)   // 10 min after workout
        XCTAssertNotEqual(
            TriggerEngine.trigger(for: ctx(lastWorkoutEnd: end, lastPostWorkoutDelivered: delivered), now: ref),
            .posTreino
        )
    }

    func testPosTreino_FiresAgain_NewWorkoutAfterDelivery() {
        // Último delivery às 09:00, novo treino terminou às 11:00 (> delivery)
        let delivered = at(hour: 9)
        let end       = at(hour: 11)
        let now       = at(hour: 12)
        XCTAssertEqual(
            TriggerEngine.trigger(for: ctx(lastWorkoutEnd: end, lastPostWorkoutDelivered: delivered), now: now),
            .posTreino
        )
    }

    // MARK: - Regra 3: sono_ruim

    func testSonoRuim_BeforeNoon_BadSleep() {
        // 08:00, sono 5h (< 7-1=6) → sono_ruim
        XCTAssertEqual(
            TriggerEngine.trigger(for: ctx(lastNightSleepHours: 5.0), now: ref),
            .sonoRuim
        )
    }

    func testSonoRuim_DoesNotFire_SleepAboveThreshold() {
        // 08:00, sono 6.0h (não < 6) → não dispara
        XCTAssertNotEqual(
            TriggerEngine.trigger(for: ctx(lastNightSleepHours: 6.0), now: ref),
            .sonoRuim
        )
    }

    func testSonoRuim_DoesNotFire_AfterNoon() {
        // sono ruim mas agora = 14:00 → hora ≥ 12 → não dispara
        XCTAssertNotEqual(
            TriggerEngine.trigger(for: ctx(lastNightSleepHours: 5.0), now: at(hour: 14)),
            .sonoRuim
        )
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

    func testRetorno_5Days() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(daysSinceLastWorkout: 5), now: ref), .retorno)
    }

    func testRetorno_DoesNotFire_4Days() {
        XCTAssertNotEqual(TriggerEngine.trigger(for: ctx(daysSinceLastWorkout: 4), now: ref), .retorno)
    }

    // MARK: - Regra 7: geral

    func testGeral_NoConditionMet() {
        XCTAssertEqual(TriggerEngine.trigger(for: ctx(), now: ref), .geral)
    }

    // MARK: - Conflitos de prioridade

    func testMarcoProva_BeatssonRuim_At7Days() {
        // T-7 + sono ruim → marco_prova (prioridade 1 > 3)
        XCTAssertEqual(
            TriggerEngine.trigger(for: ctx(raceDate: days(7), lastNightSleepHours: 5.0), now: ref),
            .marcoProva
        )
    }

    func testPosTreino_BeatsSonoRuim_At13h30() {
        // Treino terminou às 11:30, agora = 13:30 (dentro de 3h) + sono ruim → pos_treino (prio 2 > 3)
        let now = at(hour: 13, minute: 30)
        let end = at(hour: 11, minute: 30)
        XCTAssertEqual(
            TriggerEngine.trigger(for: ctx(lastWorkoutEnd: end, lastNightSleepHours: 5.0), now: now),
            .posTreino
        )
    }

    func testSonoRuim_DoesNotFire_At14h() {
        // sono ruim + 14h → hora ≥ 12 → geral (sem outras condições)
        let result = TriggerEngine.trigger(for: ctx(lastNightSleepHours: 5.0), now: at(hour: 14))
        XCTAssertEqual(result, .geral)
    }

    // MARK: - Virada de dia (23:59 / 00:01)

    func testDayFlip_At2359_SonoRuimDoesNotFire() {
        // 23:59 → hora = 23 ≥ 12 → sono_ruim não dispara mesmo com sono ruim
        XCTAssertNotEqual(
            TriggerEngine.trigger(for: ctx(lastNightSleepHours: 4.0), now: at(hour: 23, minute: 59)),
            .sonoRuim
        )
    }

    func testDayFlip_At0001_SonoRuimFires() {
        // 00:01 → hora = 0 < 12 → sono_ruim dispara com sono ruim
        XCTAssertEqual(
            TriggerEngine.trigger(for: ctx(lastNightSleepHours: 4.0), now: at(hour: 0, minute: 1, dayOffset: 1)),
            .sonoRuim
        )
    }
}

// MARK: - ContextBuilder tests

final class ContextBuilderTests: XCTestCase {

    func testBuildsContextWithWorkoutsAndSleep() async throws {
        let mock = MockHealthProvider()
        let now = Date()
        let end = now.addingTimeInterval(-2 * 3600)
        mock.workoutsToReturn = [
            WorkoutSummary(start: end.addingTimeInterval(-3600), end: end, distanceKm: 12, activityType: .running)
        ]
        mock.sleepHoursToReturn = 6.5

        let ctx = try await ContextBuilder(healthProvider: mock)
            .build(race: nil, weekPlan: nil, profile: nil, deliveryLogs: [], now: now)

        XCTAssertEqual(ctx.lastWorkoutEnd, end)
        XCTAssertEqual(ctx.lastNightSleepHours, 6.5)
        XCTAssertEqual(ctx.daysSinceLastWorkout, 0)
        XCTAssertNil(ctx.raceDate)
        XCTAssertEqual(ctx.sleepGoalHours, 7)
    }

    func testBuildsContextWithNoHealthData() async throws {
        let mock = MockHealthProvider()
        let ctx = try await ContextBuilder(healthProvider: mock)
            .build(race: nil, weekPlan: nil, profile: nil, deliveryLogs: [], now: Date())

        XCTAssertNil(ctx.lastWorkoutEnd)
        XCTAssertNil(ctx.lastNightSleepHours)
        XCTAssertNil(ctx.daysSinceLastWorkout)
        XCTAssertEqual(ctx.sleepGoalHours, 7)
    }

    func testSleepGoalFromProfile() async throws {
        let mock = MockHealthProvider()
        let profile = AthleteProfile(sleepGoalHours: 8)
        let ctx = try await ContextBuilder(healthProvider: mock)
            .build(race: nil, weekPlan: nil, profile: profile, deliveryLogs: [], now: Date())

        XCTAssertEqual(ctx.sleepGoalHours, 8)
    }

    func testPosTreinoBlockedSameDay() async throws {
        let mock = MockHealthProvider()
        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 10))!
        // Treino terminou às 08:00
        let end = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 8))!
        mock.workoutsToReturn = [
            WorkoutSummary(start: end.addingTimeInterval(-3600), end: end, distanceKm: 10, activityType: .running)
        ]
        // Delivery de pos_treino hoje
        let todayKey = DayKey(now)
        let log = DeliveryLog(day: todayKey, messageID: "m1", imageID: "i1", trigger: .posTreino)

        let ctx = try await ContextBuilder(healthProvider: mock)
            .build(race: nil, weekPlan: nil, profile: nil, deliveryLogs: [log], now: now)

        // lastPostWorkoutDelivered = startOfDay(amanhã) > workoutEnd(08h) → pos_treino não deve disparar
        let trigger = TriggerEngine.trigger(for: ctx, now: now)
        XCTAssertNotEqual(trigger, .posTreino)
    }
}
