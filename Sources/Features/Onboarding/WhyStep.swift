import SwiftUI

struct WhyStep: View {
    @Bindable var state: OnboardingState
    @State private var usingTemplate = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("onboarding.why.title")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                Text("onboarding.why.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    // Why field
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("onboarding.why.placeholder", text: $state.why, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(Theme.Spacing.medium)
                            .background(Theme.secondaryText.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: state.why) { _, new in
                                if new.count > 140 { state.why = String(new.prefix(140)) }
                                if usingTemplate { state.mantra = suggestion(for: new) }
                            }

                        HStack {
                            Spacer()
                            Text(String(format: String(localized: "onboarding.why.chars_left"), state.why.count))
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }

                    // Mantra field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("onboarding.mantra.label")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.primaryText)

                        TextField("", text: $state.mantra, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(Theme.Spacing.medium)
                            .background(Theme.secondaryText.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: state.mantra) { _, new in
                                if new != suggestion(for: state.why) { usingTemplate = false }
                            }
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.bottom, Theme.Spacing.large)
            }

            Button {
                withAnimation { state.step += 1 }
            } label: {
                Text("onboarding.button.next").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .disabled(!state.whyStepValid)
            .padding(Theme.Spacing.large)
        }
    }

    private func suggestion(for why: String) -> String {
        why.isEmpty ? "" : String(format: String(localized: "onboarding.mantra.suggestion.format"), why)
    }
}
