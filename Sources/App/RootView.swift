import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(EntitlementStore.self) private var store
    @Query private var profiles: [AthleteProfile]

    private var onboardingDone: Bool {
        profiles.first?.onboardingDone == true
    }

    var body: some View {
        if !onboardingDone {
            OnboardingFlow()
        } else if !store.isPremium {
            PaywallView()
        } else {
            MainTabView()
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [AthleteProfile.self], inMemory: true)
        .environment(EntitlementStore())
}
