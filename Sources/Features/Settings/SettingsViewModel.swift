import Foundation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    var prefs: SharedPreferences
    var sleepGoalHours: Double
    private let modelContext: ModelContext
    let onRefresh: () async -> Void

    init(
        modelContext: ModelContext,
        onRefresh: @escaping () async -> Void = { await AppEnvironment.shared?.planner.refresh() }
    ) {
        self.modelContext = modelContext
        self.onRefresh = onRefresh
        let p = SharedStore.loadPreferences()
        self.prefs = p
        let profile = (try? modelContext.fetch(FetchDescriptor<AthleteProfile>()))?.first
        self.sleepGoalHours = profile?.sleepGoalHours ?? 7
    }

    func save() async {
        try? SharedStore.save(prefs)
        if let profile = (try? modelContext.fetch(FetchDescriptor<AthleteProfile>()))?.first {
            profile.sleepGoalHours = sleepGoalHours
            try? modelContext.save()
        }
        await onRefresh()
    }
}
