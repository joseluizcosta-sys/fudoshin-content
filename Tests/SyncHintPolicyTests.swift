import XCTest
@testable import AtletaEstoico

final class SyncHintPolicyTests: XCTestCase {

    private let now = Date()

    private func makePolicy(
        workouts: [WorkoutSummary] = [],
        sleep: Double? = nil,
        workoutError: Bool = false,
        sleepError: Bool = false,
        dismissedDaysAgo: Int? = nil
    ) -> SyncHintPolicy {
        let workoutsResult: Result<[WorkoutSummary], Error> = workoutError
            ? .failure(MockError())
            : .success(workouts)
        let sleepResult: Result<Double?, Error> = sleepError
            ? .failure(MockError())
            : .success(sleep)
        let dismissed = dismissedDaysAgo.flatMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: now)
        }
        return SyncHintPolicy(
            workoutsResult: workoutsResult,
            sleepResult: sleepResult,
            dismissedAt: dismissed,
            now: now
        )
    }

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

    // (e) dispensado há 15 dias e ainda sem dados → mostrar
    func testShowsWhenDismissalExpired() {
        XCTAssertTrue(makePolicy(dismissedDaysAgo: 15).shouldShow)
    }

    // (f) erro na leitura → não mostrar
    func testHidesOnReadError() {
        XCTAssertFalse(makePolicy(workoutError: true).shouldShow)
        XCTAssertFalse(makePolicy(sleepError: true).shouldShow)
    }

    // limite: exatamente 14 dias dispensado → mostrar (14+ dias = ≥ 14)
    func testShowsAtExactly14Days() {
        XCTAssertTrue(makePolicy(dismissedDaysAgo: 14).shouldShow)
    }
}
