import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [AthleteProfile]
    #if DEBUG
    @State private var showDebug = false
    #endif

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
        ZStack(alignment: .bottomTrailing) {
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

            // Botão oculto no canto inferior direito — só em DEBUG.
            #if DEBUG
            Button("") { showDebug = true }
                .frame(width: 44, height: 44)
                .opacity(0.001)
                .padding(8)
            #endif
        }
        #if DEBUG
        .sheet(isPresented: $showDebug) { HealthDebugView() }
        #endif
    }
}

#Preview {
    RootView()
        .modelContainer(for: [AthleteProfile.self], inMemory: true)
}
