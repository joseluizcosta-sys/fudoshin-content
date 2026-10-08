import Foundation
import SwiftData

/// Orquestra o ciclo diário: contexto → plano 7 dias → SharedStore → widget → notificações.
/// Todos os métodos públicos são @MainActor para garantir acesso seguro ao ModelContext.
@MainActor
final class DailyPlanner {

    private let contextBuilder: ContextBuilder
    private var messages: [Message]
    private var images: [ImageAsset]
    private var contextTexts: [String: String]
    private let personalizer: ReflectionPersonalizer
    private let notifications: NotificationScheduling
    private let wallpaper: WallpaperComposing
    private let widgetReloader: WidgetReloading
    private let modelContext: ModelContext

    private var isObserving = false

    // Trava de reentrada: se refresh() for chamado enquanto outro roda,
    // marca pendente e roda mais uma vez ao terminar.
    private var isRefreshing = false
    private var pendingRefresh = false
    // Acumula com OR: se qualquer chamada pendente pedir invalidação, ela é propagada.
    private var pendingInvalidateToday = false

    /// Gatilhos de evento: uma vez gravados no DeliveryLog de hoje, não são rebaixados.
    static let eventTriggers: Set<Trigger> = [.posTreino, .sonoRuim, .retorno]
    /// Gatilhos que disparam notificação imediata (fora do horário de silêncio).
    /// sono_ruim é event trigger mas não imediato: o conteúdo vai no aviso agendado da manhã.
    private static let immediateNotifyTriggers: Set<Trigger> = [.posTreino, .retorno]
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

    // MARK: - Atualização de conteúdo

    /// Troca as mensagens e imagens pelo conteúdo instalado (remoto ou bundle).
    func updateLibrary(_ lib: ContentLibrary) {
        messages = lib.messages
        images = lib.images
        contextTexts = lib.contextTexts
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

    /// Gera ou atualiza o plano de 7 dias. Reentrada segura: chamadas simultâneas
    /// não duplicam trabalho — a segunda marca pendente e roda uma única vez ao terminar.
    /// `invalidateToday: true` ignora o sticky do dia, forçando recálculo completo de hoje.
    func refresh(now: Date = Date(), invalidateToday: Bool = false, calendar: Calendar = .current) async {
        if isRefreshing {
            pendingRefresh = true
            pendingInvalidateToday = pendingInvalidateToday || invalidateToday
            return
        }
        isRefreshing = true
        await _doRefresh(now: now, invalidateToday: invalidateToday, calendar: calendar)
        isRefreshing = false
        if pendingRefresh {
            let shouldInvalidate = pendingInvalidateToday
            pendingRefresh = false
            pendingInvalidateToday = false
            // Usa Date() fresco e propaga o flag acumulado.
            await refresh(invalidateToday: shouldInvalidate)
        }
    }

    private func _doRefresh(now: Date, invalidateToday: Bool = false, calendar: Calendar) async {
        let cal = calendar
        let prefs = SharedStore.loadPreferences()
        let todayKey = DayKey(now, calendar: cal)

        let race    = (try? modelContext.fetch(FetchDescriptor<Race>()))?.first
        let week    = (try? modelContext.fetch(FetchDescriptor<WeekPlan>()))?.first
        let profile = (try? modelContext.fetch(FetchDescriptor<AthleteProfile>()))?.first
        let logs    = (try? modelContext.fetch(
            FetchDescriptor<DeliveryLog>(sortBy: [SortDescriptor(\.dayValue)])
        )) ?? []

        let existingPlan = SharedStore.loadPlan()
        // invalidateToday anula apenas o sticky (existingToday); todayLog continua sendo lido
        // para alreadyNotified e para o upsert do DeliveryLog, evitando notificação duplicada.
        let existingToday = invalidateToday ? nil : existingPlan?.entries.first { $0.day == todayKey }
        let todayLog = logs.first { $0.dayValue == todayKey.value }

        let todayCtx = await contextBuilder.build(
            race: race, weekPlan: week, profile: profile,
            deliveryLogs: logs, now: now, calendar: cal
        )

        let (todayEntry, promoted) = await resolveToday(
            key: todayKey, existing: existingToday, todayLog: todayLog,
            context: todayCtx, logs: logs, prefs: prefs,
            why: profile?.why ?? "", now: now, calendar: cal
        )

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

        // pos_treino/retorno: notificação imediata se ainda não notificado hoje ou se houve promoção.
        // sono_ruim: sem imediata — o conteúdo vai no aviso agendado da manhã (via schedule).
        let alreadyNotified = todayLog?.notified == true
        let shouldTryImmediate = Self.immediateNotifyTriggers.contains(todayEntry.trigger) && (!alreadyNotified || promoted)

        let plan = DailyPlan(generatedAt: now, entries: entries)
        try? SharedStore.save(plan)

        await wallpaper.prepareWallpaper(for: todayEntry)
        widgetReloader.reloadAllTimelines()

        // scheduleImmediate retorna false em horário de silêncio (21h–7h) ou sem permissão.
        var didNotify = false
        if shouldTryImmediate {
            didNotify = await notifications.scheduleImmediate(entry: todayEntry)
        }

        upsertDeliveryLog(entry: todayEntry, logs: logs, markNotified: didNotify)

        await notifications.schedule(
            plan: plan,
            notificationHour: prefs.notificationHour,
            alreadyNotifiedToday: didNotify || alreadyNotified
        )
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
    ) async -> (entry: DailyEntry, promoted: Bool) {
        // Sem log ou sem entrada → computar do zero.
        guard let log = todayLog, let existingEntry = existing else {
            let trigger = TriggerEngine.trigger(for: context, now: now, calendar: calendar)
            let entry = await makeEntry(day: key, trigger: trigger, context: context,
                                        logs: logs, prefs: prefs, why: why, calendar: calendar)
            return (entry, false)
        }

        // Gatilho de evento registrado → pos_treino supera qualquer outro evento.
        if Self.eventTriggers.contains(log.trigger) {
            let fresh = TriggerEngine.trigger(for: context, now: now, calendar: calendar)
            if fresh == .posTreino && existingEntry.trigger != .posTreino {
                let entry = await makeEntry(day: key, trigger: .posTreino, context: context,
                                            logs: logs, prefs: prefs, why: why, calendar: calendar)
                return (entry, true)
            }
            let entry = await rehydrateEntry(existing: existingEntry, context: context,
                                             why: why, calendar: calendar)
            return (entry, false)
        }

        // Gatilhos planejáveis: sempre recalcular (sorteio determinístico → idempotente,
        // mas reflete mudanças de WeekPlan, isPremium, etc. no mesmo dia).
        let newTrigger = TriggerEngine.trigger(for: context, now: now, calendar: calendar)
        let entry = await makeEntry(day: key, trigger: newTrigger, context: context,
                                    logs: logs, prefs: prefs, why: why, calendar: calendar)
        return (entry, false)
    }

    // MARK: - Rehydration (evento sticky)

    /// Mantém messageID, imageID e trigger; recarrega shortText, author, inlineText,
    /// reflection e daysToRace da biblioteca no idioma atual (self.messages).
    private func rehydrateEntry(
        existing: DailyEntry,
        context: TrainingContext,
        why: String,
        calendar: Calendar
    ) async -> DailyEntry {
        let msg = messages.first { $0.id == existing.messageID }
        let (daysToRace, totalDaysToRace) = raceDays(context: context, day: existing.day,
                                                      calendar: calendar)
        let reflection = await personalizer.personalize(
            reflection: msg?.reflection ?? existing.reflection,
            why: why,
            trigger: existing.trigger
        )
        return DailyEntry(
            day: existing.day,
            messageID: existing.messageID,
            imageID: existing.imageID,
            trigger: existing.trigger,
            shortText: msg?.shortText ?? existing.shortText,
            inlineText: msg?.inlineText ?? existing.inlineText,
            author: msg?.author ?? existing.author,
            reflection: reflection,
            daysToRace: daysToRace,
            totalDaysToRace: totalDaysToRace,
            isParaphrase: msg.map { $0.kind == "parafrase" } ?? existing.isParaphrase
        )
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
        let (daysToRace, totalDaysToRace) = raceDays(context: context, day: day, calendar: cal)

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
            daysToRace: daysToRace,
            totalDaysToRace: totalDaysToRace,
            isParaphrase: msg?.kind == "parafrase"
        )
    }

    // MARK: - Cálculo de dias para a prova

    /// Devolve (daysToRace, totalDaysToRace). `totalDaysToRace` = dias de criação até a prova (≥ 1).
    private func raceDays(
        context: TrainingContext,
        day: DayKey,
        calendar: Calendar
    ) -> (daysToRace: Int?, totalDaysToRace: Int?) {
        guard let raceDate = context.raceDate else { return (nil, nil) }
        let cal = calendar
        // daysToRace: dias do dia da entrada até a prova
        let entryStart = day.startOfDay(calendar: cal) ?? context.today
        let raceStart = cal.startOfDay(for: raceDate)
        let d = cal.dateComponents([.day], from: entryStart, to: raceStart).day ?? -1
        let dtr: Int? = d >= 0 ? d : nil
        // totalDaysToRace: dias de criação da prova até a prova
        let total: Int?
        if let created = context.raceCreatedAt {
            let createdStart = cal.startOfDay(for: created)
            let t = cal.dateComponents([.day], from: createdStart, to: raceStart).day ?? 0
            total = max(1, t)
        } else {
            total = nil
        }
        return (dtr, total)
    }

    // MARK: - DeliveryLog upsert

    private func upsertDeliveryLog(entry: DailyEntry, logs: [DeliveryLog], markNotified: Bool = false) {
        if let log = logs.first(where: { $0.dayValue == entry.day.value }) {
            log.messageID = entry.messageID
            log.imageID   = entry.imageID
            log.trigger   = entry.trigger
            if markNotified { log.notified = true }  // nunca resetar para false
        } else {
            modelContext.insert(DeliveryLog(
                day: entry.day,
                messageID: entry.messageID,
                imageID: entry.imageID,
                trigger: entry.trigger,
                notified: markNotified
            ))
        }
        try? modelContext.save()
    }
}
