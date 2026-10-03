import Foundation

/// Função pura: recebe TrainingContext e o instante atual, nunca chama Date() internamente.
enum TriggerEngine {

    static func trigger(for c: TrainingContext, now: Date) -> Trigger {
        let cal = Calendar.current

        // 1. marco_prova — faltam exatamente 30, 7, 1 ou 0 dias de calendário
        if let raceDate = c.raceDate {
            let todayStart = cal.startOfDay(for: now)
            let raceStart  = cal.startOfDay(for: raceDate)
            let days = cal.dateComponents([.day], from: todayStart, to: raceStart).day ?? -1
            if [0, 1, 7, 30].contains(days) { return .marcoProva }
        }

        // 2. pos_treino — treino nas últimas 3h e ainda não entregue para este treino
        if let workoutEnd = c.lastWorkoutEnd {
            let withinWindow = workoutEnd > now.addingTimeInterval(-3 * 3600)
            let notDelivered = c.lastPostWorkoutDelivered.map { $0 < workoutEnd } ?? true
            if withinWindow && notDelivered { return .posTreino }
        }

        // 3. sono_ruim — sono < (meta - 1h) e agora é antes das 12h
        if let sleep = c.lastNightSleepHours {
            let isBad     = sleep < c.sleepGoalHours - 1
            let isMorning = cal.component(.hour, from: now) < 12
            if isBad && isMorning { return .sonoRuim }
        }

        // 4. vespera_chave — amanhã é longo ou forte
        if let tomorrow = c.tomorrowSession, tomorrow == .longo || tomorrow == .forte {
            return .vesperaChave
        }

        // 5. descanso — hoje é dia de descanso
        if c.todaySession == .descanso { return .descanso }

        // 6. retorno — 5 ou mais dias sem treino
        if let days = c.daysSinceLastWorkout, days >= 5 { return .retorno }

        // 7. geral — nenhuma condição anterior
        return .geral
    }
}
