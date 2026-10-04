import SwiftUI
import SwiftData

struct RaceView: View {
    @Query private var races: [Race]
    @State private var showOnboarding = false

    private var race: Race? { races.first }

    var body: some View {
        NavigationStack {
            Group {
                if let race {
                    raceContent(race)
                } else {
                    noRaceContent
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("race.title")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Com prova

    @ViewBuilder
    private func raceContent(_ race: Race) -> some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let raceDay = cal.startOfDay(for: race.date)
        let days = cal.dateComponents([.day], from: today, to: raceDay).day ?? 0

        ScrollView {
            VStack(spacing: Theme.Spacing.large) {
                // Contagem regressiva
                VStack(spacing: 8) {
                    if days > 0 {
                        Text(String(format: String(localized: "race.days_remaining.format"), days))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    } else {
                        Text("race.race_day")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                    Text(race.name)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Theme.primaryText)
                    Text(race.date.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                    Text(
                        Measurement(value: race.distanceKm, unit: UnitLength.kilometers)
                            .formatted(.measurement(width: .abbreviated))
                    )
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                }
                .padding(.top, Theme.Spacing.large)

                Divider()

                // Marcos
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text("race.milestones.section")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(milestones(raceDay: raceDay, today: today), id: \.key) { m in
                        milestoneRow(m)
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
            }
        }
    }

    // MARK: - Sem prova

    private var noRaceContent: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 56))
                .foregroundStyle(Theme.secondaryText.opacity(0.5))
            Text("race.no_race.title")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.primaryText)
            Text("race.no_race.subtitle")
                .font(.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.large)
            Button("race.no_race.action") { showOnboarding = true }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showOnboarding) { OnboardingFlow() }
    }

    // MARK: - Helpers

    struct Milestone { let key: String; let label: LocalizedStringKey; let passed: Bool }

    private func milestones(raceDay: Date, today: Date) -> [Milestone] {
        let cal = Calendar.current
        func isDone(daysBack: Int) -> Bool {
            guard let m = cal.date(byAdding: .day, value: -daysBack, to: raceDay) else { return false }
            return today >= m
        }
        return [
            Milestone(key: "t30", label: "race.milestone.t30", passed: isDone(daysBack: 30)),
            Milestone(key: "t7",  label: "race.milestone.t7",  passed: isDone(daysBack: 7)),
            Milestone(key: "t1",  label: "race.milestone.t1",  passed: isDone(daysBack: 1)),
            Milestone(key: "d0",  label: "race.milestone.d0",  passed: today >= raceDay),
        ]
    }

    @ViewBuilder
    private func milestoneRow(_ m: Milestone) -> some View {
        HStack {
            Image(systemName: m.passed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(m.passed ? Theme.accent : Theme.secondaryText)
            Text(m.label)
                .font(.body)
                .foregroundStyle(m.passed ? Theme.primaryText : Theme.secondaryText)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
