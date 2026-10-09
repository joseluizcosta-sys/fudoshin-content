import Foundation
import SwiftData
import BackgroundTasks
import UIKit

/// Container de serviços reais do app. Criado uma vez no launch e acessível via `shared`.
@MainActor
final class AppEnvironment {
    nonisolated(unsafe) static var shared: AppEnvironment?

    let planner: DailyPlanner
    let healthProvider: any HealthDataProviding

    init(modelContext: ModelContext) {
        let lib = ContentLibrary.current()

        let healthProv = HealthKitService()
        self.healthProvider = healthProv
        let builder = ContextBuilder(healthProvider: healthProv)

        let personalizer: ReflectionPersonalizer
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            personalizer = FoundationModelsPersonalizer()
        } else {
            personalizer = TemplatePersonalizer()
        }
        #else
        personalizer = TemplatePersonalizer()
        #endif

        let prefs    = SharedStore.loadPreferences()
        let composer = WallpaperComposer(screenSize: UIScreen.main.nativeBounds.size,
                                         installID: prefs.installID)

        self.planner = DailyPlanner(
            contextBuilder: builder,
            messages: lib.messages,
            images: lib.images,
            contextTexts: lib.contextTexts,
            personalizer: personalizer,
            notifications: LiveNotificationScheduler(),
            wallpaper: composer,
            modelContext: modelContext
        )

        AppEnvironment.shared = self
    }

    // MARK: - Conteúdo remoto

    /// Verifica atualização de conteúdo e atualiza o planner se houver versão nova.
    func checkAndUpdateContent(force: Bool = false) async {
        let updated = await RemoteContentStore.shared.checkForUpdate(force: force)
        if updated {
            planner.updateLibrary(ContentLibrary.current())
        }
    }

    // MARK: - Lifecycle

    func startIfOnboardingDone() {
        planner.startObserving()
    }

    func onOnboardingCompleted() async {
        planner.startObserving()
        scheduleBackgroundRefresh()
        await planner.refresh()
    }

    func onBecomeActive() async {
        await checkAndUpdateContent()
        await planner.refresh()
    }

    func scheduleBackgroundRefresh() {
        let prefs = SharedStore.loadPreferences()
        let request = BGAppRefreshTaskRequest(identifier: "com.atletaestoico.refresh")
        var comps = DateComponents()
        comps.hour = prefs.changeHour
        comps.minute = 0
        if let next = Calendar.current.nextDate(
            after: Date(), matching: comps, matchingPolicy: .nextTime
        ) {
            request.earliestBeginDate = next
        }
        try? BGTaskScheduler.shared.submit(request)
    }
}
