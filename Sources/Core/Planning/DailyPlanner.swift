import Foundation
import SwiftData

/// Orquestra o ciclo diário: contexto → plano 7 dias → SharedStore → widget → notificações.
/// Todos os métodos públicos são @MainActor para garantir acesso seguro ao ModelContext.
@MainActor
final class DailyPlanner {

    private let contextBuilder: ContextBuilder
    private let messages: [Message]
    private let images: [ImageAsset]
    private let contextTexts: [String: String]
    private let personalizer: ReflectionPersonalizer
    private let notifications: NotificationScheduling
    private let wallpaper: WallpaperComposing
    private let widgetReloader: WidgetReloading
    private let modelContext: ModelContext

    private var isObserving = false

    /// Gatilhos de evento: uma vez gravados no plano/DeliveryLog de hoje, não são rebaixados.
    private static let eventTriggers: Set<Trigger> = [.posTreino, .sonoRuim, .retorno]
    /// Gatilhos permitidos em dias futuros (planejáveis sem dados de evento).
    private static let plannableTriggers: Set<Trigger> = [.marcoProva, .vesperaChave, .descanso, .geral]

    init(
        contextBuilder: ContextBuilder,
        messages: [Message],
        images: [ImageAsset],
        contextTexts: [String: String],
        personalizer: ReflectionPersonalizer,
        notifications: NotificationScheduling = NoOpNotificationScheduler(),
        wallpaper: WallpaperComposing = NoOpWallpaperComposer(),
        widgetReloader: WidgetReloading = LiveWidgetReloader(),
        modelContext: ModelContext
    ) {
        self.contextBuilder = contextBuilder
        self.messages = messages
        self.images = images
        self.contextTexts = contextTexts
        self.personalizer = personalizer
        self.notifications = notifications
        self.wallpaper = wallpaper
        self.widgetReloader = widgetReloader
        self.modelContext = modelContext
    }

    // MARK: - Observer

    /// Registra o observer do HealthKit. Seguro chamar várias vezes; só executa na primeira.
    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        contextBuilder.healthProvider.startObserving { [weak self] in
            await self?.refresh()
        }
    }

    // MARK: - Refresh

    /// Gera ou atualiza o plano de 7 dias.
    /// - Hoje: gatilho completo (evento + planejável) com stickiness.
    /// - Dias futuros: apenas gatilhos planejáveis (sem dados de sono/treino).
    func refresh(now: Date = Date(), calendar: Calendar = .current) async {
        let cal = calendar
        let prefs = SharedStore.loadPreferences()
        let todayKey = DayKey(now, calendar: cal)

        // Modelos SwiftData
        let race    = (try? modelContext.fetch(FetchDescriptor<Race>()))?.first
        let week    = (try? modelContext.fetch(FetchDescriptor<WeekPlan>()))?.first
        let profile = (try? modelContext.fetch(FetchDescriptor<AthleteProfile>()))?.first
        let logs    = (try? modelContext.fetch(
            FetchDescriptor<DeliveryLog>(sortBy: [SortDescriptor(\.dayValue)])
        )) ?? []

        // Plano salvo + DeliveryLog de hoje — juntos definem stickiness
        let existingPlan = SharedStore.loadPlan()
        let existingToday = existingPlan?.entries.first { $0.day == todayKey }
        let todayLog = logs.first { $0.dayValue == todayKey.value }

        // Contexto de hoje (com dados reais de sono e treino)
        let todayCtx = await contextBuilder.build(
            race: race, weekPlan: week, profile: profile,
            deliveryLogs: logs, now: now, calendar: cal
        )

        // --- Entrada de hoje com stickiness ---
        let todayEntry = await resolveToday(
            key: todayKey, existing: existingToday, todayLog: todayLog,
            context: todayCtx, logs: logs, prefs: prefs,
            why: profile?.why ?? "", now: now, calendar: cal
        )

        // --- Entradas dos próximos 6 dias (apenas planejáveis) ---
        var entries: [DailyEntry] = [todayEntry]
        let todayStart = cal.startOfDay(for: now)

        for offset in 1...6 {
            guard let futureStart = cal.date(byAdding: .day, value: offset, to: todayStart) else { continue }
            let futureKey = DayKey(futureStart, calendar: cal)

            let tomorrowOfFuture: SessionType? = {
                guard let d2 = cal.date(byAdding: .day, value: 1, to: futureStart) else { return nil }
                return week?.session(on: d2, calendar: cal)
            }()

            let futureCtx = TrainingContext(
                today: futureStart,
                raceDate: race?.date,
                raceCategory: race?.category,
                tomorrowSession: tomorrowOfFuture,
                todaySession: week?.session(on: futureStart, calendar: cal),
                lastWorkoutEnd: nil,
                lastPostWorkoutDelivered: nil,
                lastNightSleepHours: nil,
                sleepGoalHours: profile?.sleepGoalHours ?? 7,
                daysSinceLastWorkout: nil
            )

            let rawTrigger = TriggerEngine.trigger(for: futureCtx, now: futureStart, calendar: cal)
            let trigger = Self.plannableTriggers.contains(rawTrigger) ? rawTrigger : .geral

            let entry = await makeEntry(
                day: futureKey, trigger: trigger, context: futureCtx,
                logs: logs, prefs: prefs, why: profile?.why ?? "", calendar: cal
            )
            entries.append(entry)
        }

        // --- Persistência ---
        let plan = DailyPlan(generatedAt: now, entries: entries)
        try? SharedStore.save(plan)
        upsertDeliveryLog(entry: todayEntry, logs: logs)

        // --- Efeitos colaterais ---
        await wallpaper.prepareWallpaper(for: todayEntry)
        widgetReloader.reloadAllTimelines()
        await notifications.schedule(plan: plan, notificationHour: prefs.notificationHour)
    }

    // MARK: - Stickiness

    private func resolveToday(
        key: DayKey,
        existing: DailyEntry?,
        todayLog: DeliveryLog?,
        context: TrainingContext,
        logs: [DeliveryLog],
        prefs: SharedPreferences,
        why: String,
        now: Date,
        calendar: Calendar
    ) async -> DailyEntry {
        // Stickiness exige DeliveryLog de hoje + entrada no plano; sem ambos → computar sempre do zero.
        guard let log = todayLog, let existingEntry = existing else {
            let trigger = TriggerEngine.trigger(for: context, now: now, calendar: calendar)
            return await makeEntry(day: key, trigger: trigger, context: context,
                                   logs: logs, prefs: prefs, why: why, calendar: calendar)
        }

        // Gatilho de evento já registrado → nunca rebaixar
        if Self.eventTriggers.contains(log.trigger) {
            return existingEntry
        }

        let newTrigger = TriggerEngine.trigger(for: context, now: now, calendar: calendar)

        // Upgrading de planejável para evento → recalcular com o novo gatilho
        if Self.eventTriggers.contains(newTrigger) {
            return await makeEntry(day: key, trigger: newTrigger, context: context,
                                   logs: logs, prefs: prefs, why: why, calendar: calendar)
        }

        // Planejável → planejável com DeliveryLog já existente → reutilizar (idempotência)
        return existingEntry
    }

    // MARK: - Entry builder

    private func makeEntry(
        day: DayKey,
        trigger: Trigger,
        context: TrainingContext,
        logs: [DeliveryLog],
        prefs: SharedPreferences,
        why: String,
        calendar: Calendar
    ) async -> DailyEntry {
        let cal = calendar

        let daysToRace: Int? = context.raceDate.flatMap { raceDate in
            let raceStart = cal.startOfDay(for: raceDate)
            let d = cal.dateComponents([.day], from: context.today, to: raceStart).day ?? -1
            return d >= 0 ? d : nil
        }

        // Excluir o próprio dia do conjunto "entregues recentemente" para garantir idempotência
        let thirtyAgo = cal.date(byAdding: .day, value: -30, to: context.today) ?? context.today
        let thirtyKey = DayKey(thirtyAgo, calendar: cal)
        let recentIDs = Set(
            logs
                .filter { $0.dayValue >= thirtyKey.value && $0.dayValue < day.value }
                .map { $0.messageID }
        )

        let input = MessageEngine.Input(
            trigger: trigger,
            day: day,
            installID: prefs.installID,
            isPremium: prefs.isPremium,
            recentlyDeliveredMessageIDs: recentIDs,
            raceCategory: context.raceCategory,
            preferredCategories: prefs.categories,
            daysToRace: daysToRace,
            tomorrowSession: context.tomorrowSession
        )

        let output = MessageEngine.pick(
            input: input, messages: messages, images: images, contextTexts: contextTexts
        )

        let msg = messages.first { $0.id == output.messageID }
        let reflection = await personalizer.personalize(
            reflection: msg?.reflection ?? "",
            why: why,
            trigger: trigger
        )

        return DailyEntry(
            day: day,
            messageID: output.messageID,
            imageID: output.imageID,
            trigger: trigger,
            shortText: msg?.shortText ?? "",
            inlineText: output.inlineText,
            author: msg?.author ?? "",
            reflection: reflection,
            daysToRace: daysToRace
        )
    }

    // MARK: - DeliveryLog upsert

    private func upsertDeliveryLog(entry: DailyEntry, logs: [DeliveryLog]) {
        if let log = logs.first(where: { $0.dayValue == entry.day.value }) {
            log.messageID  = entry.messageID
            log.imageID    = entry.imageID
            log.trigger    = entry.trigger
        } else {
            modelContext.insert(DeliveryLog(
                day: entry.day,
                messageID: entry.messageID,
                imageID: entry.imageID,
                trigger: entry.trigger
            ))
        }
        try? modelContext.save()
    }
}
