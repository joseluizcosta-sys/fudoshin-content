import Foundation
import SwiftData

@Observable
final class OnboardingState {
    var step: Int = 0
    var committed: Bool = false

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

    /// Primeira letra em minúscula, sem pontuação final — para usar no template do mantra.
    func normalizeWhy(_ s: String) -> String {
        var result = s.trimmingCharacters(in: .whitespaces)
        while let last = result.last, ".!?…,;:".contains(last) {
            result.removeLast()
        }
        guard let first = result.first else { return result }
        return first.lowercased() + result.dropFirst()
    }

    /// Grava Race, WeekPlan e AthleteProfile no contexto. Idempotente: se já existir
    /// AthleteProfile, atualiza em vez de inserir novo. Também atualiza SharedPreferences.
    @MainActor
    func commit(into ctx: ModelContext) throws {
        // Race — upsert ou delete
        let existingRaces = try ctx.fetch(FetchDescriptor<Race>())
        let trimmedName = raceName.trimmingCharacters(in: .whitespaces)
        if hasRace && !trimmedName.isEmpty {
            if let r = existingRaces.first {
                r.name = trimmedName
                r.date = raceDate
                r.distanceKm = raceDistanceKm
                r.categoryRaw = raceCategory.rawValue
            } else {
                ctx.insert(Race(name: trimmedName, date: raceDate,
                                distanceKm: raceDistanceKm, category: raceCategory))
            }
        } else {
            existingRaces.forEach { ctx.delete($0) }
        }

        // WeekPlan — upsert
        let existingWeeks = try ctx.fetch(FetchDescriptor<WeekPlan>())
        if let w = existingWeeks.first {
            w.sessions = weekSessions
        } else {
            ctx.insert(WeekPlan(sessions: weekSessions))
        }

        // AthleteProfile — upsert
        let finalMantra = resolvedMantra()
        let existingProfiles = try ctx.fetch(FetchDescriptor<AthleteProfile>())
        if let p = existingProfiles.first {
            p.why = why.trimmingCharacters(in: .whitespaces)
            p.mantra = finalMantra
            p.onboardingDone = true
        } else {
            ctx.insert(AthleteProfile(
                why: why.trimmingCharacters(in: .whitespaces),
                mantra: finalMantra,
                onboardingDone: true
            ))
        }

        // SharedPreferences — categoria da prova
        var prefs = SharedStore.loadPreferences()
        prefs.categories = (hasRace && !trimmedName.isEmpty) ? [raceCategory] : [.trail]
        try SharedStore.save(prefs)

        try ctx.save()
        committed = true
    }

    private func resolvedMantra() -> String {
        let trimmed = mantra.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty else { return trimmed }
        let normalized = normalizeWhy(why)
        return normalized.isEmpty
            ? ""
            : String(format: String(localized: "onboarding.mantra.suggestion.format"), normalized)
    }
}
