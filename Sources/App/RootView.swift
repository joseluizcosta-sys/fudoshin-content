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
        } else if store.isPremium {
            MainTabView()
        } else if store.state == .unknown {
            // Ainda verificando a assinatura (fração de segundo no launch):
            // não mostrar o paywall para quem já assina.
            ZStack {
                Theme.background.ignoresSafeArea()
                ProgressView()
            }
        } else {
            PaywallView()
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [AthleteProfile.self], inMemory: true)
        .environment(EntitlementStore())
}
