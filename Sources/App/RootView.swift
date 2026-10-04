import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [AthleteProfile]

    private var onboardingDone: Bool {
        profiles.first?.onboardingDone == true
    }

    var body: some View {
        if onboardingDone {
            MainTabView()
        } else {
            OnboardingFlow()
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [AthleteProfile.self], inMemory: true)
}
