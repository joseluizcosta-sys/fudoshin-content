import Foundation
@testable import AtletaEstoico

/// Mock injetável para testes que dependem de HealthDataProviding.
final class MockHealthProvider: HealthDataProviding {
    var workoutsToReturn: [WorkoutSummary] = []
    var sleepHoursToReturn: Double? = nil
    var authorizationError: Error? = nil
    private(set) var onChangeCallback: (() -> Void)?
    private(set) var authCallCount = 0
    private(set) var workoutCallCount = 0
    private(set) var sleepCallCount = 0

    func requestAuthorization() async throws {
        authCallCount += 1
        if let error = authorizationError { throw error }
    }

    func recentWorkouts(days: Int) async throws -> [WorkoutSummary] {
        workoutCallCount += 1
        return workoutsToReturn
    }

    func lastNightSleepHours(reference: Date) async throws -> Double? {
        sleepCallCount += 1
        return sleepHoursToReturn
    }

    func startObserving(onChange: @escaping () -> Void) {
        onChangeCallback = onChange
    }

    /// Simula chegada de novos dados (para testar o observer).
    func simulateNewData() {
        onChangeCallback?()
    }
}
