import XCTest
@testable import AtletaEstoico

final class SyncHintPolicyTests: XCTestCase {

    private let now = Date()

    private func makePolicy(
        workouts: [WorkoutSummary] = [],
        sleep: Double? = nil,
        externalDataHoursAgo: Double? = nil,   // nil = no external data; > 0 = N hours ago
        workoutError: Bool = false,
        sleepError: Bool = false,
        externalDataError: Bool = false,
        dismissedDaysAgo: Int? = nil
    ) -> SyncHintPolicy {
        let workoutsResult: Result<[WorkoutSummary], Error> = workoutError
            ? .failure(MockError())
            : .success(workouts)
        let sleepResult: Result<Double?, Error> = sleepError
            ? .failure(MockError())
            : .success(sleep)
        let externalDataResult: Result<Date?, Error>
        if externalDataError {
            externalDataResult = .failure(MockError())
        } else if let hours = externalDataHoursAgo {
            let date = now.addingTimeInterval(-hours * 3600)
            externalDataResult = .success(date)
        } else {
            externalDataResult = .success(nil)
        }
        let dismissed = dismissedDaysAgo.flatMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: now)
        }
        return SyncHintPolicy(
            workoutsResult: workoutsResult,
            sleepResult: sleepResult,
            externalDataResult: externalDataResult,
            dismissedAt: dismissed,
            now: now
        )
    }

    // MARK: - Aviso original (noData)

    // (a) sem treino e sem sono → mostrar
    func testShowsWithoutDataAndNotDismissed() {
        XCTAssertTrue(makePolicy().shouldShow)
    }

    // (b) com treino → não mostrar
    func testHidesWhenWorkoutsExist() {
        let w = WorkoutSummary(start: now, end: now, distanceKm: 10, activityType: .running)
        XCTAssertFalse(makePolicy(workouts: [w]).shouldShow)
    }

    // (c) só com sono → não mostrar
    func testHidesWhenSleepExists() {
        XCTAssertFalse(makePolicy(sleep: 7.0).shouldShow)
    }

    // (d) dispensado há 3 dias → não mostrar
    func testHidesWhenDismissedRecently() {
        XCTAssertFalse(makePolicy(dismissedDaysAgo: 3).shouldShow)
    }

    // (e – antigo) dispensado há 15 dias e ainda sem dados → mostrar
    func testShowsWhenDismissalExpired() {
        XCTAssertTrue(makePolicy(dismissedDaysAgo: 15).shouldShow)
    }

    // (f – antigo) erro na leitura → não mostrar
    func testHidesOnReadError() {
        XCTAssertFalse(makePolicy(workoutError: true).shouldShow)
        XCTAssertFalse(makePolicy(sleepError: true).shouldShow)
    }

    func testShowsAtExactly14Days() {
        XCTAssertTrue(makePolicy(dismissedDaysAgo: 14).shouldShow)
    }

    // MARK: - Aviso de sincronização suspeita

    // (e) syncSuspect → banner com texto de sincronização
    func testSyncSuspectShowsBanner() {
        // sem treinos recentes + dado externo há 72h (> 48h) → shouldShowSyncSuspect
        let policy = makePolicy(externalDataHoursAgo: 72)
        XCTAssertTrue(policy.shouldShowSyncSuspect,
                      "Dado externo há 72h com workouts vazios deve acionar shouldShowSyncSuspect")
        // Com sleep nil, shouldShow também é true neste cenário — o banner exibe o texto syncSuspect
        // porque shouldShowSyncSuspect tem prioridade na view.
        XCTAssertNotNil(policy.daysSinceExternalData, "Dias desde dado externo deve estar disponível")
    }

    func testSyncSuspectNotShownWhenExternalDataRecent() {
        // dado externo há 10h (≤ 48h) → não é syncSuspect
        let policy = makePolicy(externalDataHoursAgo: 10)
        XCTAssertFalse(policy.shouldShowSyncSuspect)
    }

    func testSyncSuspectNotShownWhenNoExternalData() {
        // sem dado externo nenhum → shouldShowSyncSuspect == false
        XCTAssertFalse(makePolicy().shouldShowSyncSuspect)
    }

    func testSyncSuspectRespectsDismissal() {
        let policy = makePolicy(externalDataHoursAgo: 72, dismissedDaysAgo: 3)
        XCTAssertFalse(policy.shouldShowSyncSuspect, "Dispensado há 3 dias deve suprimir syncSuspect")
    }

    func testSyncSuspectShowsAfterDismissalExpires() {
        let policy = makePolicy(externalDataHoursAgo: 72, dismissedDaysAgo: 15)
        XCTAssertTrue(policy.shouldShowSyncSuspect)
    }

    func testDaysSinceExternalDataIsCorrect() {
        let policy = makePolicy(externalDataHoursAgo: 3 * 24)  // 3 days
        XCTAssertEqual(policy.daysSinceExternalData, 3)
    }

    // (f) erro ao ler lastExternalDataDate → não mostra syncSuspect, sem crash
    func testSyncSuspectHidesOnExternalDataError() {
        let policy = makePolicy(externalDataError: true)
        XCTAssertFalse(policy.shouldShowSyncSuspect)
        XCTAssertNil(policy.daysSinceExternalData)
    }
}
