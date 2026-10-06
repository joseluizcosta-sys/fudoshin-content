import Foundation

/// Decide se e qual aviso de sincronização deve ser exibido.
/// Tipo puro, sem SwiftUI — testável de forma isolada.
struct SyncHintPolicy {
    let workoutsResult: Result<[WorkoutSummary], Error>
    let sleepResult: Result<Double?, Error>
    let externalDataResult: Result<Date?, Error>
    let dismissedAt: Date?
    let now: Date

    init(
        workoutsResult: Result<[WorkoutSummary], Error>,
        sleepResult: Result<Double?, Error>,
        externalDataResult: Result<Date?, Error> = .success(nil),
        dismissedAt: Date?,
        now: Date
    ) {
        self.workoutsResult = workoutsResult
        self.sleepResult = sleepResult
        self.externalDataResult = externalDataResult
        self.dismissedAt = dismissedAt
        self.now = now
    }

    // MARK: - Aviso original: sem treinos E sem sono

    var shouldShow: Bool {
        guard !isDismissedRecently else { return false }
        guard case .success(let workouts) = workoutsResult,
              case .success(let sleep) = sleepResult else { return false }
        return workouts.isEmpty && sleep == nil
    }

    // MARK: - Aviso de sincronização suspeita: sem treinos recentes + relógio parado há > 48h

    var shouldShowSyncSuspect: Bool {
        guard !isDismissedRecently else { return false }
        guard case .success(let workouts) = workoutsResult, workouts.isEmpty else { return false }
        guard case .success(let extDate) = externalDataResult, let date = extDate else { return false }
        return now.timeIntervalSince(date) > 48 * 3600
    }

    /// Dias desde o último dado externo, para usar no texto do aviso de sincronização.
    var daysSinceExternalData: Int? {
        guard case .success(let extDate) = externalDataResult, let date = extDate else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: now).day
    }

    // MARK: - Privado

    private var isDismissedRecently: Bool {
        guard let dismissed = dismissedAt else { return false }
        let days = Calendar.current.dateComponents([.day], from: dismissed, to: now).day ?? 0
        return days < 14
    }
}
