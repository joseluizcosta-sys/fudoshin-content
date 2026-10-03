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
        default: PermissionsStep(committed: state.committed, onComplete: finish)
        }
    }

    private var stepDots: some View {
        ZStack {
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(i == state.step ? Theme.accent : Theme.secondaryText.opacity(0.25))
                        .frame(width: i == state.step ? 24 : 8, height: 8)
                        .animation(.spring(duration: 0.3), value: state.step)
                }
            }

            if state.step > 0 {
                HStack {
                    Button {
                        withAnimation { state.step -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.primaryText)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
    }

    private func finish() {
        guard (try? state.commit(into: ctx)) != nil else { return }
        Task { await AppEnvironment.shared?.onOnboardingCompleted() }
    }
}
