#if DEBUG
import SwiftUI

/// Tela de debug — mostra treinos dos últimos 14 dias e sono da última noite.
/// Acessível por botão oculto na tela placeholder. Não entra em produção.
struct HealthDebugView: View {
    @State private var workouts: [WorkoutSummary] = []
    @State private var sleepHours: Double? = nil
    @State private var loading = false
    @State private var errorMessage: String? = nil

    private let service = HealthKitService()

    var body: some View {
        NavigationStack {
            List {
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

                if let err = errorMessage {
                    Section("Error") {
                        Text(err).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Health Debug")
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

    private func load() async {
        loading = true
        errorMessage = nil
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
