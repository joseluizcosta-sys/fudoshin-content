import Foundation

struct TrainingContext {
    let today: Date                         // startOfDay do dispositivo
    let raceDate: Date?
    let raceCategory: ImageCategory?
    let tomorrowSession: SessionType?
    let todaySession: SessionType?
    let lastWorkoutEnd: Date?
    let lastPostWorkoutDelivered: Date?     // start do dia SEGUINTE ao último delivery de pos_treino
    let lastNightSleepHours: Double?
    let sleepGoalHours: Double              // padrão 7
    let daysSinceLastWorkout: Int?

    init(
        today: Date = Calendar.current.startOfDay(for: Date()),
        raceDate: Date? = nil,
        raceCategory: ImageCategory? = nil,
        tomorrowSession: SessionType? = nil,
        todaySession: SessionType? = nil,
        lastWorkoutEnd: Date? = nil,
        lastPostWorkoutDelivered: Date? = nil,
        lastNightSleepHours: Double? = nil,
        sleepGoalHours: Double = 7,
        daysSinceLastWorkout: Int? = nil
    ) {
        self.today = today
        self.raceDate = raceDate
        self.raceCategory = raceCategory
        self.tomorrowSession = tomorrowSession
        self.todaySession = todaySession
        self.lastWorkoutEnd = lastWorkoutEnd
        self.lastPostWorkoutDelivered = lastPostWorkoutDelivered
        self.lastNightSleepHours = lastNightSleepHours
        self.sleepGoalHours = sleepGoalHours
        self.daysSinceLastWorkout = daysSinceLastWorkout
    }
}
