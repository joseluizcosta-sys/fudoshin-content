import Foundation

enum WorkoutActivityType: String, Codable, CaseIterable {
    case running, hiking, walking
}

struct WorkoutSummary {
    let start: Date
    let end: Date
    let distanceKm: Double
    let activityType: WorkoutActivityType
}

/// Protocolo para tudo que toca HealthKit, para que a lógica Core possa ser testada com mocks.
protocol HealthDataProviding {
    func requestAuthorization() async throws
    /// Treinos dos últimos `days` dias, filtrados por tipo e distância mínima (> 3 km).
    func recentWorkouts(days: Int) async throws -> [WorkoutSummary]
    /// Horas de sono entre 18h de ontem e 12h de hoje relativas a `reference`. Nil se sem dados.
    func lastNightSleepHours(reference: Date) async throws -> Double?
    /// Registra observador de novos treinos; `onChange` é chamado na main thread.
    func startObserving(onChange: @escaping () -> Void)
}
