import SwiftUI
import SwiftData

@main
struct AtletaEstoicoApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                Race.self, WeekPlan.self, AthleteProfile.self,
                JournalEntry.self, DeliveryLog.self
            )
        } catch {
            fatalError("SwiftData container init failed: \(error)")
        }
        // Cria install_id.txt e preferências padrão na primeira execução.
        // Uso exclusivo do app — o widget usa loadPreferencesIfExists().
        _ = SharedStore.loadPreferences()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
