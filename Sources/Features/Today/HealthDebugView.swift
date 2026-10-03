#if DEBUG
import SwiftUI
import SwiftData

/// Tela de debug — mostra saúde, plano diário e log. Acessível por botão oculto. Não entra em produção.
struct HealthDebugView: View {
    @State private var workouts: [WorkoutSummary] = []
    @State private var sleepHours: Double? = nil
    @State private var plan: DailyPlan? = nil
    @State private var loading = false
    @State private var errorMessage: String? = nil
    @Query(sort: \DeliveryLog.dayValue, order: .reverse) private var logs: [DeliveryLog]

    private let service = HealthKitService()

    var body: some View {
        NavigationStack {
            List {
                planSection
                todayLogSection
                healthSection
                if let err = errorMessage {
                    Section("Error") {
                        Text(err).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if loading {
                        ProgressView()
                    } else {
                        Button("Refresh") { Task { await load() } }
                    }
                }
            }
            .task { await load() }
        }
    }

    // MARK: - Seções

    @ViewBuilder
    private var planSection: some View {
        Section("Daily Plan (7 days)") {
            if let plan {
                ForEach(plan.entries, id: \.day.value) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(entry.day.value)
                                .font(.caption.monospaced())
                            Spacer()
                            Text(entry.trigger.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(entry.shortText).font(.caption2)
                        Text("— \(entry.author)").font(.caption2).foregroundStyle(.secondary)
                        Text(entry.inlineText).font(.caption2).italic().foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No plan saved").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var todayLogSection: some View {
        let todayKey = DayKey(Date()).value
        Section("Today's Log") {
            if let log = logs.first(where: { $0.dayValue == todayKey }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.messageID).font(.caption.monospaced())
                        Text(log.trigger.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label(log.notified ? "notified" : "pending",
                          systemImage: log.notified ? "bell.fill" : "bell")
                        .font(.caption)
                        .foregroundStyle(log.notified ? .green : .orange)
                }
            } else {
                Text("No log today").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var healthSection: some View {
        Section("Sleep — last night") {
            if let h = sleepHours {
                Text(String(format: "%.1f h", h))
            } else {
                Text("No data").foregroundStyle(.secondary)
            }
        }

        Section("Workouts — last 14 days (\(workouts.count))") {
            if workouts.isEmpty {
                Text("No workouts found").foregroundStyle(.secondary)
            } else {
                ForEach(workouts.indices, id: \.self) { i in
                    workoutRow(workouts[i])
                }
            }
        }
    }

    @ViewBuilder
    private func workoutRow(_ w: WorkoutSummary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(w.activityType.debugLabel)  \(String(format: "%.1f km", w.distanceKm))")
                .font(.body)
            Text(
                w.start.formatted(.dateTime.month().day().hour().minute())
                + " → "
                + w.end.formatted(.dateTime.hour().minute())
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Carga

    private func load() async {
        loading = true
        errorMessage = nil
        plan = SharedStore.loadPlan()
        do {
            try await service.requestAuthorization()
            async let wTask = service.recentWorkouts(days: 14)
            async let sTask = service.lastNightSleepHours(reference: Date())
            workouts = try await wTask
            sleepHours = try await sTask
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}

private extension WorkoutActivityType {
    var debugLabel: String {
        switch self {
        case .running: "🏃 Run"
        case .hiking:  "🥾 Hike"
        }
    }
}
#endif
