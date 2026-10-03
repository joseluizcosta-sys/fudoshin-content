import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [AthleteProfile]

    private var onboardingDone: Bool {
        profiles.first?.onboardingDone == true
    }

    var body: some View {
        if onboardingDone {
            mainPlaceholder
        } else {
            OnboardingFlow()
        }
    }

    // Placeholder substituído pelas telas reais em T10.
    private var mainPlaceholder: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Text("root.title")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.primaryText)
            Text("root.subtitle")
                .font(.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
}

#Preview {
    RootView()
        .modelContainer(for: [AthleteProfile.self], inMemory: true)
}
