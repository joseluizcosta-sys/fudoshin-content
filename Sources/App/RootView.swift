import SwiftUI

/// Tela raiz do T00. Nas próximas tarefas vira: Onboarding se não configurado, senão TabView.
struct RootView: View {
    var body: some View {
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
}
