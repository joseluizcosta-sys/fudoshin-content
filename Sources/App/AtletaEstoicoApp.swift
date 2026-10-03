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

        // Registrar ANTES de qualquer submit() (scheduleBackgroundRefresh): submit sem handler
        // registrado derruba o app com 'No launch handler registered'.
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.atletaestoico.refresh",
            using: nil
        ) { task in
            guard let bgTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: true)
                return
            }
            // Flag para garantir setTaskCompleted uma única vez
            // (expiração vs. conclusão normal são mutuamente exclusivos).
            var completed = false
            let workTask = Task { @MainActor in
                await AppEnvironment.shared?.planner.refresh()
                AppEnvironment.shared?.scheduleBackgroundRefresh()
                if !completed { completed = true; bgTask.setTaskCompleted(success: true) }
            }
            bgTask.expirationHandler = {
                workTask.cancel()
                Task { @MainActor in
                    if !completed { completed = true; bgTask.setTaskCompleted(success: false) }
                }
            }
        }

        // App.init() é sempre chamado na main thread; assumeIsolated é seguro.
        // Criar o AppEnvironment aqui garante que BGTask e HealthKit observer
        // funcionem mesmo quando o iOS acorda o app sem renderizar a view.
        MainActor.assumeIsolated {
            let ctx = container.mainContext
            let env = AppEnvironment(modelContext: ctx)
            let profiles = (try? ctx.fetch(FetchDescriptor<AthleteProfile>())) ?? []
            if profiles.first?.onboardingDone == true {
                // Apple recomenda registrar observer queries no launch.
                env.planner.startObserving()
                env.scheduleBackgroundRefresh()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { @MainActor in
                        await AppEnvironment.shared?.onBecomeActive()
                    }
                }
        }
        .modelContainer(container)
    }
}
