import Foundation

enum WorkoutActivityType: String, Codable, CaseIterable {
    case running, hiking
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
    /// Data do sample de passos mais recente nos últimos `days` dias cuja fonte seja externa:
    /// bundle ID que NÃO começa com "com.apple.health" (Garmin Connect, etc.)
    /// OU sourceRevision.productType começando com "Watch" (Apple Watch).
    /// Nil se nenhuma fonte externa encontrada.
    func lastExternalDataDate(within days: Int) async throws -> Date?
    /// Registra observador de novos treinos.
    /// `onChange` é awaited antes de chamar o completionHandler do HKObserverQuery,
    /// garantindo que o iOS não suspenda o app antes do refresh concluir.
    func startObserving(onChange: @escaping () async -> Void)
}
