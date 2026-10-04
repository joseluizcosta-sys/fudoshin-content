import Foundation

/// Decide se o aviso de sincronização deve ser exibido.
/// Tipo puro, sem SwiftUI — testável de forma isolada.
struct SyncHintPolicy {
    let workoutsResult: Result<[WorkoutSummary], Error>
    let sleepResult: Result<Double?, Error>
    let dismissedAt: Date?
    let now: Date

    var shouldShow: Bool {
        guard case .success(let workouts) = workoutsResult,
              case .success(let sleep) = sleepResult else {
            return false  // erro de leitura → não incomodar
        }
        if !workouts.isEmpty || sleep != nil { return false }
        guard let dismissed = dismissedAt else { return true }
        let days = Calendar.current.dateComponents([.day], from: dismissed, to: now).day ?? 0
        return days >= 14
    }
}
