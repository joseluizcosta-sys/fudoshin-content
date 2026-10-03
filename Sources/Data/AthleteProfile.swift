import Foundation
import SwiftData

@Model
final class AthleteProfile {
    var why: String
    var mantra: String
    var sleepGoalHours: Double
    var onboardingDone: Bool

    init(
        why: String = "",
        mantra: String = "",
        sleepGoalHours: Double = 7,
        onboardingDone: Bool = false
    ) {
        self.why = why
        self.mantra = mantra
        self.sleepGoalHours = sleepGoalHours
        self.onboardingDone = onboardingDone
    }
}
