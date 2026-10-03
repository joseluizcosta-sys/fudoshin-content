import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct AtletaEstoicoApp: App {
    let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            container = try ModelContainer(for:
                Race.self, WeekPlan.self, AthleteProfile.self,
                JournalEntry.self, DeliveryLog.self
            )
        } catch {
            fatalError("SwiftData container init failed: \(error)")
        }
        _ = SharedStore.loadPreferences()

        // Deve ser registrado antes do app terminar de lançar.
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.atletaestoico.refresh",
            using: nil
        ) { task in
            guard let bgTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: true)
                return
            }
            let workTask = Task { @MainActor in
                await AppEnvironment.shared?.planner.refresh()
                AppEnvironment.shared?.scheduleBackgroundRefresh()
                bgTask.setTaskCompleted(success: true)
            }
            bgTask.expirationHandler = {
                workTask.cancel()
                Task { @MainActor in bgTask.setTaskCompleted(success: false) }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { await setupEnvironment() }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { @MainActor in
                        await AppEnvironment.shared?.onBecomeActive()
                    }
                }
        }
        .modelContainer(container)
    }

    @MainActor
    private func setupEnvironment() async {
        guard AppEnvironment.shared == nil else { return }
        let env = AppEnvironment(modelContext: container.mainContext)
        let profiles = (try? container.mainContext.fetch(FetchDescriptor<AthleteProfile>())) ?? []
        if profiles.first?.onboardingDone == true {
            env.startIfOnboardingDone()
            await env.planner.refresh()
        }
        env.scheduleBackgroundRefresh()
    }
}
