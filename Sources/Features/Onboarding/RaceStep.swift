import SwiftUI

struct RaceStep: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("onboarding.race.title")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                Text("onboarding.race.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)

            Form {
                Toggle(String(localized: "onboarding.race.no_race"), isOn: Binding(
                    get: { !state.hasRace },
                    set: { state.hasRace = !$0 }
                ))

                if state.hasRace {
                    Section {
                        LabeledContent(String(localized: "onboarding.race.name.label")) {
                            TextField("onboarding.race.name.placeholder", text: $state.raceName)
                                .multilineTextAlignment(.trailing)
                        }

                        DatePicker(
                            String(localized: "onboarding.race.date.label"),
                            selection: $state.raceDate,
                            in: Date.now...,
                            displayedComponents: .date
                        )

                        LabeledContent(String(localized: "onboarding.race.distance.label")) {
                            TextField(
                                "",
                                value: $state.raceDistanceKm,
                                format: .number.precision(.fractionLength(0...1))
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        }

                        Picker(
                            String(localized: "onboarding.race.category.label"),
                            selection: $state.raceCategory
                        ) {
                            ForEach(ImageCategory.allCases, id: \.self) { cat in
                                // Montar a chave como String antes de converter para LocalizedStringKey;
                                // interpolar diretamente em LocalizedStringKey() gera chave "category.%@".
                                let key = "category.\(cat.rawValue)"
                                Text(LocalizedStringKey(key)).tag(cat)
                            }
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: state.hasRace)

            Button {
                withAnimation { state.step += 1 }
            } label: {
                Text("onboarding.button.next").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .disabled(!state.raceStepValid)
            .padding(Theme.Spacing.large)
        }
    }
}
