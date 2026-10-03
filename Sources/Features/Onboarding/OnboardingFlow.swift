import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var ctx
    @State private var state = OnboardingState()

    var body: some View {
        VStack(spacing: 0) {
            stepDots
                .padding(.top, Theme.Spacing.large)
                .padding(.bottom, Theme.Spacing.small)

            stepView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    @ViewBuilder private var stepView: some View {
        switch state.step {
        case 0: RaceStep(state: state)
        case 1: WeekStep(state: state)
        case 2: WhyStep(state: state)
        default: PermissionsStep(onComplete: finish)
        }
    }

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i == state.step ? Theme.accent : Theme.secondaryText.opacity(0.25))
                    .frame(width: i == state.step ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: state.step)
            }
        }
    }

    private func finish() {
        if state.hasRace && !state.raceName.trimmingCharacters(in: .whitespaces).isEmpty {
            ctx.insert(Race(
                name: state.raceName,
                date: state.raceDate,
                distanceKm: state.raceDistanceKm,
                category: state.raceCategory
            ))
        }
        ctx.insert(WeekPlan(sessions: state.weekSessions))
        let finalMantra: String
        if state.mantra.trimmingCharacters(in: .whitespaces).isEmpty {
            finalMantra = String(
                format: String(localized: "onboarding.mantra.suggestion.format"),
                state.why
            )
        } else {
            finalMantra = state.mantra
        }
        ctx.insert(AthleteProfile(
            why: state.why.trimmingCharacters(in: .whitespaces),
            mantra: finalMantra,
            onboardingDone: true
        ))
        try? ctx.save()
    }
}
