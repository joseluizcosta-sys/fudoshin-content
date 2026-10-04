import XCTest
import UserNotifications
@testable import AtletaEstoico

@MainActor
final class NotificationSchedulerTests: XCTestCase {

    var center: MockNotificationCenter!
    var scheduler: LiveNotificationScheduler!
    var spCal: Calendar!
    /// 2026-10-03 06:00 Sao Paulo (antes do notificationHour 7).
    var baseNow: Date!

    override func setUp() {
        center = MockNotificationCenter()
        scheduler = LiveNotificationScheduler(center: center)

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        spCal = cal

        baseNow = spCal.date(from: DateComponents(
            timeZone: TimeZone(identifier: "America/Sao_Paulo"),
            year: 2026, month: 10, day: 3, hour: 6, minute: 0, second: 0
        ))!
    }

    // MARK: - Helpers

    private func date(hour: Int, day: Int = 3) -> Date {
        spCal.date(from: DateComponents(
            timeZone: TimeZone(identifier: "America/Sao_Paulo"),
            year: 2026, month: 10, day: day, hour: hour, minute: 0, second: 0
        ))!
    }

    private func fakePlan(from now: Date, triggers: [Trigger]? = nil) -> DailyPlan {
        let todayStart = spCal.startOfDay(for: now)
        let entries: [DailyEntry] = (0..<7).compactMap { offset in
            guard let d = spCal.date(byAdding: .day, value: offset, to: todayStart) else { return nil }
            let trigger = triggers?[safe: offset] ?? .geral
            return DailyEntry(
                day: DayKey(d, calendar: spCal),
                messageID: "msg\(offset + 1)", imageID: "img1",
                trigger: trigger, shortText: "Short \(offset)", inlineText: "—",
                author: "Sêneca", reflection: "Ref", daysToRace: nil
            )
        }
        return DailyPlan(generatedAt: now, entries: entries)
    }

    private func entry(_ trigger: Trigger, now: Date) -> DailyEntry {
        DailyEntry(
            day: DayKey(now, calendar: spCal),
            messageID: "msg4", imageID: "img1",
            trigger: trigger, shortText: "Short", inlineText: "—",
            author: "Sêneca", reflection: "Ref", daysToRace: nil
        )
    }

    // MARK: - Testes originais

    func testSevenNotificationsScheduled() async {
        await scheduler.schedule(plan: fakePlan(from: baseNow), notificationHour: 7,
                                 alreadyNotifiedToday: false, now: baseNow, calendar: spCal)
        XCTAssertEqual(center.pending.count, 7, "Deve agendar 7 notificações")
    }

    func testNeverTwiceInSameDay() async {
        let plan = fakePlan(from: baseNow)
        await scheduler.schedule(plan: plan, notificationHour: 7,
                                 alreadyNotifiedToday: false, now: baseNow, calendar: spCal)
        let ids = center.pending.map { $0.identifier }
        XCTAssertEqual(ids.count, Set(ids).count, "Nunca 2 notificações com o mesmo identificador")
    }

    func testHourAlreadyPassedExcludesToday() async {
        let lateNow = date(hour: 8)
        await scheduler.schedule(plan: fakePlan(from: lateNow), notificationHour: 7,
                                 alreadyNotifiedToday: false, now: lateNow, calendar: spCal)
        XCTAssertEqual(center.pending.count, 6, "Hora já passou → hoje não agendado")
    }

    func testEventBeforeDeliveredCancelsTodayScheduled() async {
        // Usar 10h para estar fora do horário de silêncio (7h–21h)
        let morningNow = date(hour: 10)
        await scheduler.schedule(plan: fakePlan(from: morningNow), notificationHour: 7,
                                 alreadyNotifiedToday: false, now: morningNow, calendar: spCal)
        // notificationHour 7h já passou às 10h → apenas 6 agendadas (amanhã→+6)
        XCTAssertEqual(center.pending.count, 6)

        // Evento imediato às 10h (fora do silêncio)
        let result = await scheduler.scheduleImmediate(entry: entry(.posTreino, now: morningNow),
                                                       now: morningNow, calendar: spCal)
        XCTAssertTrue(result, "Deve retornar true fora do horário de silêncio")

        let todayDailyID = LiveNotificationScheduler.dailyPrefix + DayKey(morningNow, calendar: spCal).value
        XCTAssertFalse(center.pending.contains { $0.identifier == todayDailyID },
                       "Notificação diária de hoje deve ser cancelada (já não estava por fireDate passado)")
        XCTAssertTrue(center.pending.contains { $0.identifier.hasPrefix(LiveNotificationScheduler.nowPrefix) },
                      "Notificação imediata deve estar pendente")
        XCTAssertEqual(center.pending.count, 7)  // 6 diárias + 1 imediata
    }

    func testEventAfterAlreadyNotifiedSkipsToday() async {
        await scheduler.schedule(plan: fakePlan(from: baseNow), notificationHour: 7,
                                 alreadyNotifiedToday: true, now: baseNow, calendar: spCal)
        XCTAssertEqual(center.pending.count, 6, "Já notificado hoje: hoje excluído")
        let todayID = LiveNotificationScheduler.dailyPrefix + DayKey(baseNow, calendar: spCal).value
        XCTAssertFalse(center.pending.contains { $0.identifier == todayID })
    }

    func testRescheduleTwiceNoDuplicates() async {
        let plan = fakePlan(from: baseNow)
        for _ in 0..<3 {
            await scheduler.schedule(plan: plan, notificationHour: 7,
                                     alreadyNotifiedToday: false, now: baseNow, calendar: spCal)
        }
        XCTAssertEqual(center.pending.count, 7, "Múltiplos reagendamentos não duplicam")
    }

    // MARK: - Novos testes (revisão T09)

    /// Evento (pos_treino) às 23h → horário de silêncio → sem notificação imediata.
    func testEventInQuietHoursNoImmediate() async {
        let lateNow = date(hour: 23)
        let result = await scheduler.scheduleImmediate(entry: entry(.posTreino, now: lateNow),
                                                       now: lateNow, calendar: spCal)
        XCTAssertFalse(result, "Horário de silêncio (21h–7h): scheduleImmediate deve retornar false")
        XCTAssertEqual(center.pending.count, 0, "Nenhuma notificação imediata deve ser agendada")
    }

    /// Evento às 6h também é silêncio (6 < 7).
    func testEventAtSixAMIsQuiet() async {
        // baseNow = 06:00, que é < quietEnd (7)
        let result = await scheduler.scheduleImmediate(entry: entry(.posTreino, now: baseNow),
                                                       now: baseNow, calendar: spCal)
        XCTAssertFalse(result, "6h ainda é horário de silêncio (< 7h)")
    }

    /// sono_ruim: conteúdo vai no aviso agendado da manhã; nenhuma notificação imediata.
    func testSonoRuimUsesRegularScheduledNotification() async {
        // Plano com sono_ruim como gatilho de hoje
        let sonoRuimEntry = DailyEntry(
            day: DayKey(baseNow, calendar: spCal),
            messageID: "msg5", imageID: "img1",
            trigger: .sonoRuim, shortText: "Noite curta", inlineText: "—",
            author: "Epicteto", reflection: "Ref", daysToRace: nil
        )
        var plan = fakePlan(from: baseNow)
        // Substitui a entrada de hoje pelo entry de sono_ruim
        let todayStart = spCal.startOfDay(for: baseNow)
        let entries = (0..<7).compactMap { offset -> DailyEntry? in
            guard let d = spCal.date(byAdding: .day, value: offset, to: todayStart) else { return nil }
            if offset == 0 { return sonoRuimEntry }
            return DailyEntry(day: DayKey(d, calendar: spCal), messageID: "msg\(offset+1)",
                              imageID: "img1", trigger: .geral, shortText: "s", inlineText: "—",
                              author: "a", reflection: "r", daysToRace: nil)
        }
        plan = DailyPlan(generatedAt: baseNow, entries: entries)

        // Apenas schedule (sem scheduleImmediate) — DailyPlanner não chama immediate para sono_ruim
        await scheduler.schedule(plan: plan, notificationHour: 7,
                                 alreadyNotifiedToday: false, now: baseNow, calendar: spCal)

        // "daily-2026-10-03" deve existir e ter título sono_ruim
        let todayID = LiveNotificationScheduler.dailyPrefix + DayKey(baseNow, calendar: spCal).value
        let req = center.pending.first { $0.identifier == todayID }
        XCTAssertNotNil(req, "Notificação diária de hoje deve estar agendada")
        XCTAssertFalse(center.pending.contains { $0.identifier.hasPrefix(LiveNotificationScheduler.nowPrefix) },
                       "Nenhuma notificação imediata deve existir para sono_ruim")
        // 7 entradas + hoje é sono_ruim → 7 agendadas (todo futuro incluindo hoje às 7h)
        XCTAssertEqual(center.pending.count, 7)
    }

    /// Aviso das 7h já entregue (não está em pending) + pos_treino às 18h → 1 imediata.
    func testPosTreinoAfterDailyDeliveredGetsImmediate() async {
        // center.pending vazio = aviso das 7h já foi entregue pelo sistema
        let afternoonNow = date(hour: 18)
        let result = await scheduler.scheduleImmediate(entry: entry(.posTreino, now: afternoonNow),
                                                       now: afternoonNow, calendar: spCal)
        XCTAssertTrue(result, "pos_treino às 18h deve retornar true")
        XCTAssertEqual(center.pending.count, 1, "Deve haver 1 notificação imediata")
        XCTAssertTrue(center.pending[0].identifier.hasPrefix(LiveNotificationScheduler.nowPrefix))
    }

    // MARK: - Teste de títulos por gatilho

    func testNotificationTitleKeyPerTrigger() {
        let expected: [(Trigger, String)] = [
            (.geral,        "notification.title.geral"),
            (.vesperaChave, "notification.title.vespera_chave"),
            (.posTreino,    "notification.title.pos_treino"),
            (.sonoRuim,     "notification.title.sono_ruim"),
            (.descanso,     "notification.title.descanso"),
            (.retorno,      "notification.title.retorno"),
            (.marcoProva,   "notification.title.marco_prova"),
        ]
        for (trigger, key) in expected {
            XCTAssertEqual(scheduler.notificationTitleKey(for: trigger), key,
                           "\(trigger.rawValue) deve mapear para \(key)")
        }
    }

    func testNotificationTitlesPtBR() throws {
        // DailyPlanner é uma classe no app target — Bundle(for:) retorna o app bundle.
        guard let path = Bundle(for: DailyPlanner.self)
            .path(forResource: "pt-BR", ofType: "lproj"),
              let ptBundle = Bundle(path: path)
        else {
            throw XCTSkip("Bundle pt-BR não encontrado no ambiente de teste")
        }
        let ptScheduler = LiveNotificationScheduler(center: center, bundle: ptBundle)

        let expected: [(Trigger, String)] = [
            (.geral,        "Fudōshin"),
            (.vesperaChave, "Véspera de treino chave"),
            (.posTreino,    "Depois do treino"),
            (.sonoRuim,     "Noite curta"),
            (.descanso,     "Dia de descanso"),
            (.retorno,      "Recomeço"),
        ]
        for (trigger, expectedTitle) in expected {
            let key = ptScheduler.notificationTitleKey(for: trigger)
            let title = ptBundle.localizedString(forKey: key, value: "", table: nil)
            XCTAssertEqual(title, expectedTitle, "Gatilho \(trigger.rawValue) título pt-BR")
        }
    }
}

// MARK: - Helpers de Array

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
