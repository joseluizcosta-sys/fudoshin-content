import Foundation
import SwiftData
import BackgroundTasks

/// Container de serviços reais do app. Criado uma vez no launch e acessível via `shared`.
@MainActor
final class AppEnvironment {
    // Acessado pelo handler do BGTask (closure não-isolada) via Task { @MainActor in }.
    nonisolated(unsafe) static var shared: AppEnvironment?

    let planner: DailyPlanner

    init(modelContext: ModelContext) {
        guard let lib = try? ContentLibrary() else {
            fatalError("ContentLibrary: arquivos de conteúdo ausentes no bundle")
        }

        let builder = ContextBuilder(healthProvider: HealthKitService())

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

        self.planner = DailyPlanner(
            contextBuilder: builder,
            messages: lib.messages,
            images: lib.images,
            contextTexts: lib.contextTexts,
            personalizer: personalizer,
            modelContext: modelContext
        )

        AppEnvironment.shared = self
    }

    /// Chamado no launch quando o onboarding já está concluído.
    func startIfOnboardingDone() {
        planner.startObserving()
    }

    /// Chamado ao concluir o onboarding.
    func onOnboardingCompleted() async {
        planner.startObserving()
        scheduleBackgroundRefresh()
        await planner.refresh()
    }

    /// Chamado sempre que `scenePhase` vira `.active`.
    func onBecomeActive() async {
        await planner.refresh()
    }

    /// Agenda a próxima execução do BGTask para a `changeHour` do dia seguinte.
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
