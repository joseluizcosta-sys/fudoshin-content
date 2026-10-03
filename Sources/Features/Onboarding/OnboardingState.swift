import Foundation

@Observable
final class OnboardingState {
    var step: Int = 0

    // Step 1 — Race
    var hasRace: Bool = true
    var raceName: String = ""
    var raceDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    var raceDistanceKm: Double = 42.2
    var raceCategory: ImageCategory = .trail

    // Step 2 — Week (seg=0 … dom=6)
    var weekSessions: [Int: SessionType] = [:]

    // Step 3 — Why + Mantra
    var why: String = ""
    var mantra: String = ""

    var raceStepValid: Bool {
        !hasRace || !raceName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var whyStepValid: Bool {
        !why.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
