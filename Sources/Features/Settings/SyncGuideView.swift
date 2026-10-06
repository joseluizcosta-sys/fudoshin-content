import SwiftUI

struct SyncGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let healthProvider: (any HealthDataProviding)?

    @State private var workoutsOK: Bool?      = nil
    @State private var sleepOK: Bool?         = nil
    @State private var lastWatchDate: Date?   = nil
    @State private var isChecking = false

    init(healthProvider: (any HealthDataProviding)? = nil) {
        self.healthProvider = healthProvider ?? AppEnvironment.shared?.healthProvider
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    introSection
                    stepSection(number: "1", titleKey: "sync_guide.step1.title",
                                bodyKey: "sync_guide.step1.body")
                    step2Section
                    stepSection(number: "3", titleKey: "sync_guide.step3.title",
                                bodyKey: "sync_guide.step3.body")
                    troubleshootSection
                    statusSection
                }
                .padding(Theme.Spacing.large)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("sync_guide.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("race_edit.cancel") { dismiss() }
                }
            }
        }
        .task { await checkStatus() }
    }

    // MARK: - Intro

    private var introSection: some View {
        Text("sync_guide.intro")
            .font(.body)
            .foregroundStyle(Theme.primaryText)
    }

    // MARK: - Passo genérico

    @ViewBuilder
    private func stepSection(number: String, titleKey: String, bodyKey: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            stepHeader(number: number, titleKey: titleKey)
            Text(LocalizedStringKey(bodyKey))
                .font(.body)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Passo 2 (tem botão extra)

    private var step2Section: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            stepHeader(number: "2", titleKey: "sync_guide.step2.title")
            Text("sync_guide.step2.body")
                .font(.body)
                .foregroundStyle(Theme.secondaryText)
            if let url = URL(string: "x-apple-health://"),
               UIApplication.shared.canOpenURL(url) {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Label("sync_guide.step2.open_health", systemImage: "heart.text.square")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func stepHeader(number: String, titleKey: String) -> some View {
        HStack(spacing: Theme.Spacing.small) {
            Text(number)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Theme.accent, in: Circle())
            Text(LocalizedStringKey(titleKey))
                .font(.headline.weight(.semibold))
                .foregroundStyle(Theme.primaryText)
        }
    }

    // MARK: - Solução de problemas

    private var troubleshootSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("sync_guide.troubleshoot.title")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Theme.primaryText)
            ForEach(troubleshootKeys, id: \.self) { key in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(Theme.secondaryText)
                    Text(LocalizedStringKey(key))
                        .font(.callout)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private let troubleshootKeys = [
        "sync_guide.troubleshoot.no_workout",
        "sync_guide.troubleshoot.old_data",
        "sync_guide.troubleshoot.bad_sleep",
        "sync_guide.troubleshoot.duplicates",
    ]

    // MARK: - Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("sync_guide.status.title")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Theme.primaryText)

            if isChecking {
                ProgressView()
                    .padding(.vertical, 4)
            } else {
                statusRow(ok: workoutsOK, okKey: "sync_guide.status.workouts_ok",
                          missingKey: "sync_guide.status.workouts_missing")
                statusRow(ok: sleepOK, okKey: "sync_guide.status.sleep_ok",
                          missingKey: "sync_guide.status.sleep_missing")
                if let date = lastWatchDate {
                    let rel = RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
                    Text(String(format: String(localized: "sync_guide.status.last_watch_data"), rel))
                        .font(.callout)
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            Button {
                Task { await checkStatus() }
            } label: {
                Text("sync_guide.status.check_again")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.secondaryText.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.primaryText)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func statusRow(ok: Bool?, okKey: String, missingKey: String) -> some View {
        if let ok {
            Text(LocalizedStringKey(ok ? okKey : missingKey))
                .font(.callout)
                .foregroundStyle(ok ? Theme.accent : Theme.secondaryText)
        }
    }

    // MARK: - Leitura de status

    private func checkStatus() async {
        guard let provider = healthProvider else { return }
        isChecking = true
        workoutsOK = nil
        sleepOK = nil
        lastWatchDate = nil
        do {
            let workouts = try await provider.recentWorkouts(days: 7)
            workoutsOK = !workouts.isEmpty
        } catch {
            workoutsOK = false
        }
        do {
            let sleep = try await provider.lastNightSleepHours(reference: Date())
            sleepOK = sleep != nil
        } catch {
            sleepOK = false
        }
        lastWatchDate = try? await provider.lastExternalDataDate(within: 30)
        isChecking = false
    }
}
