import Foundation
import SwiftData

/// Monta um TrainingContext a partir dos modelos SwiftData e de um HealthDataProviding.
/// Erros do HealthDataProviding são tratados como "sem dados"; nunca derrubam o build.
final class ContextBuilder {
    let healthProvider: HealthDataProviding

    init(healthProvider: HealthDataProviding) {
        self.healthProvider = healthProvider
    }

    func build(
        race: Race?,
        weekPlan: WeekPlan?,
        profile: AthleteProfile?,
        deliveryLogs: [DeliveryLog],
        now: Date = Date(),
        calendar: Calendar = .current
    ) async -> TrainingContext {
        let cal = calendar

        // Treinos dos últimos 30 dias para cobrir retorno de até 5 semanas.
        // Erros do provedor = sem dados (nil), nunca propagados.
        let workouts = (try? await healthProvider.recentWorkouts(days: 30)) ?? []
        let lastWorkout = workouts.first

        // Sono — erro = nil (sem dados)
        let sleepHours = try? await healthProvider.lastNightSleepHours(reference: now)

        // Dias desde o último treino (dias de calendário entre o fim do último treino e hoje)
        let daysSince: Int? = lastWorkout.map { w in
            let todayStart   = cal.startOfDay(for: now)
            let workoutStart = cal.startOfDay(for: w.end)
            return cal.dateComponents([.day], from: workoutStart, to: todayStart).day ?? 0
        }

        // Último delivery de pos_treino → start do dia SEGUINTE (bloqueia re-entrega no mesmo dia)
        let lastPostWorkoutDelivered: Date? = {
            let lastLog = deliveryLogs
                .filter { $0.trigger == .posTreino }
                .max(by: { $0.dayValue < $1.dayValue })
            guard let log = lastLog,
                  let dayStart = DayKey(value: log.dayValue).startOfDay(calendar: cal) else { return nil }
            return cal.date(byAdding: .day, value: 1, to: dayStart)
        }()

        // Sessões de hoje e amanhã a partir do WeekPlan
        let todaySession    = weekPlan?.session(on: now, calendar: cal)
        let tomorrowDate    = cal.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowSession = weekPlan?.session(on: tomorrowDate, calendar: cal)

        return TrainingContext(
            today:                    cal.startOfDay(for: now),
            raceDate:                 race?.date,
            raceCategory:             race?.category,
            tomorrowSession:          tomorrowSession,
            todaySession:             todaySession,
            lastWorkoutEnd:           lastWorkout?.end,
            lastPostWorkoutDelivered: lastPostWorkoutDelivered,
            lastNightSleepHours:      sleepHours,
            sleepGoalHours:           profile?.sleepGoalHours ?? 7,
            daysSinceLastWorkout:     daysSince
        )
    }
}
