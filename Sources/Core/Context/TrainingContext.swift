import Foundation

struct TrainingContext {
    let today: Date                         // startOfDay do dispositivo
    let now: Date                           // instante real (para cálculos com precisão de horas)
    let raceDate: Date?
    let raceCreatedAt: Date?               // para calcular totalDaysToRace no Gauge
    let raceCategory: ImageCategory?
    let tomorrowSession: SessionType?
    let todaySession: SessionType?
    let lastWorkoutEnd: Date?
    let lastPostWorkoutDelivered: Date?     // start do dia SEGUINTE ao último delivery de pos_treino
    let lastNightSleepHours: Double?
    let sleepGoalHours: Double              // padrão 7
    let daysSinceLastWorkout: Int?
    let lastExternalDataDate: Date?         // data mais recente de dado externo (relógio/Garmin)

    /// True quando há ≥ 7 dias sem treino E o relógio está sem sincronizar há mais de 48 h,
    /// sugerindo que a pausa é causada por falha de sincronização, não por descanso real.
    var syncSuspect: Bool {
        guard let days = daysSinceLastWorkout,
              days >= TriggerEngine.returnThresholdDays else { return false }
        guard let extDate = lastExternalDataDate else { return false }
        return now.timeIntervalSince(extDate) > 48 * 3600
    }

    init(
        today: Date = Calendar.current.startOfDay(for: Date()),
        now: Date = Date(),
        raceDate: Date? = nil,
        raceCreatedAt: Date? = nil,
        raceCategory: ImageCategory? = nil,
        tomorrowSession: SessionType? = nil,
        todaySession: SessionType? = nil,
        lastWorkoutEnd: Date? = nil,
        lastPostWorkoutDelivered: Date? = nil,
        lastNightSleepHours: Double? = nil,
        sleepGoalHours: Double = 7,
        daysSinceLastWorkout: Int? = nil,
        lastExternalDataDate: Date? = nil
    ) {
        self.today = today
        self.now = now
        self.raceDate = raceDate
        self.raceCreatedAt = raceCreatedAt
        self.raceCategory = raceCategory
        self.tomorrowSession = tomorrowSession
        self.todaySession = todaySession
        self.lastWorkoutEnd = lastWorkoutEnd
        self.lastPostWorkoutDelivered = lastPostWorkoutDelivered
        self.lastNightSleepHours = lastNightSleepHours
        self.sleepGoalHours = sleepGoalHours
        self.daysSinceLastWorkout = daysSinceLastWorkout
        self.lastExternalDataDate = lastExternalDataDate
    }
}
