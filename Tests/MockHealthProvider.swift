import Foundation
@testable import AtletaEstoico

/// Mock injetável para testes que dependem de HealthDataProviding.
final class MockHealthProvider: HealthDataProviding {
    var workoutsToReturn: [WorkoutSummary] = []
    var sleepHoursToReturn: Double? = nil
    var lastExternalDataDateToReturn: Date? = nil
    var authorizationError: Error? = nil
    var workoutsError: Error? = nil
    var sleepError: Error? = nil
    var externalDataError: Error? = nil
    private(set) var onChangeCallback: (() async -> Void)?
    private(set) var authCallCount = 0
    private(set) var workoutCallCount = 0
    private(set) var sleepCallCount = 0
    private(set) var externalDataCallCount = 0

    func requestAuthorization() async throws {
        authCallCount += 1
        if let error = authorizationError { throw error }
    }

    func recentWorkouts(days: Int) async throws -> [WorkoutSummary] {
        workoutCallCount += 1
        if let error = workoutsError { throw error }
        return workoutsToReturn
    }

    func lastNightSleepHours(reference: Date) async throws -> Double? {
        sleepCallCount += 1
        if let error = sleepError { throw error }
        return sleepHoursToReturn
    }

    func lastExternalDataDate(within days: Int) async throws -> Date? {
        externalDataCallCount += 1
        if let error = externalDataError { throw error }
        return lastExternalDataDateToReturn
    }

    func startObserving(onChange: @escaping () async -> Void) {
        onChangeCallback = onChange
    }

    /// Simula chegada de novos dados (para testar o observer).
    func simulateNewData() async {
        await onChangeCallback?()
    }
}

struct MockError: Error {}
