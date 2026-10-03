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

    private func fakePlan(from now: Date, count: Int = 7) -> DailyPlan {
        let todayStart = spCal.startOfDay(for: now)
        let entries: [DailyEntry] = (0..<count).compactMap { offset in
            guard let d = spCal.date(byAdding: .day, value: offset, to: todayStart) else { return nil }
            return DailyEntry(
                day: DayKey(d, calendar: spCal),
                messageID: "msg\(offset + 1)", imageID: "img1",
                trigger: .geral, shortText: "Short \(offset)", inlineText: "—",
                author: "Sêneca", reflection: "Ref", daysToRace: nil
            )
        }
        return DailyPlan(generatedAt: now, entries: entries)
    }

    private func eventEntry(now: Date) -> DailyEntry {
        DailyEntry(
            day: DayKey(now, calendar: spCal),
            messageID: "msg4", imageID: "img1",
            trigger: .posTreino, shortText: "Treino concluído", inlineText: "—",
            author: "Marco Aurélio", reflection: "Ref", daysToRace: nil
        )
    }

    // MARK: - Testes

    func testSevenNotificationsScheduled() async {
        // now antes do notificationHour(7) → todos os 7 dias no futuro
        await scheduler.schedule(plan: fakePlan(from: baseNow), notificationHour: 7,
                                 alreadyNotifiedToday: false, now: baseNow, calendar: spCal)
        XCTAssertEqual(center.pending.count, 7, "Deve agendar 7 notificações")
    }

    func testNeverTwiceInSameDay() async {
        let plan = fakePlan(from: baseNow)
        await scheduler.schedule(plan: plan, notificationHour: 7,
                                 alreadyNotifiedToday: false, now: baseNow, calendar: spCal)
        // Verifica que não há dois identificadores iguais
        let ids = center.pending.map { $0.identifier }
        XCTAssertEqual(ids.count, Set(ids).count, "Nunca deve haver 2 notificações com o mesmo identificador")
    }

    func testHourAlreadyPassedExcludesToday() async {
        // now às 8h (notificationHour 7 já passou)
        let lateNow = spCal.date(from: DateComponents(
            timeZone: TimeZone(identifier: "America/Sao_Paulo"),
            year: 2026, month: 10, day: 3, hour: 8, minute: 0, second: 0
        ))!
        await scheduler.schedule(plan: fakePlan(from: lateNow), notificationHour: 7,
                                 alreadyNotifiedToday: false, now: lateNow, calendar: spCal)
        XCTAssertEqual(center.pending.count, 6, "Hora já passou → hoje não agendado")
    }

    func testEventBeforeDeliveredSchedulesImmediate() async {
        await scheduler.scheduleImmediate(entry: eventEntry(now: baseNow),
                                          now: baseNow, calendar: spCal)
        XCTAssertEqual(center.pending.count, 1, "Deve criar 1 notificação imediata")
        XCTAssertTrue(center.pending[0].identifier.hasPrefix(LiveNotificationScheduler.nowPrefix),
                      "Identificador deve começar com 'now-'")
    }

    func testEventBeforeDeliveredCancelsTodayScheduled() async {
        // Primeiro agenda os 7 dias normais
        await scheduler.schedule(plan: fakePlan(from: baseNow), notificationHour: 7,
                                 alreadyNotifiedToday: false, now: baseNow, calendar: spCal)
        XCTAssertEqual(center.pending.count, 7)

        // Evento chega → cancela hoje e agenda imediata
        await scheduler.scheduleImmediate(entry: eventEntry(now: baseNow),
                                          now: baseNow, calendar: spCal)

        let todayDailyID = LiveNotificationScheduler.dailyPrefix + DayKey(baseNow, calendar: spCal).value
        XCTAssertFalse(center.pending.contains { $0.identifier == todayDailyID },
                       "Notificação diária de hoje deve ser cancelada")
        XCTAssertTrue(center.pending.contains { $0.identifier.hasPrefix(LiveNotificationScheduler.nowPrefix) },
                      "Notificação imediata deve estar pendente")
        // Total: 6 diárias (amanhã→+6) + 1 imediata = 7
        XCTAssertEqual(center.pending.count, 7)
    }

    func testEventAfterAlreadyNotifiedSkipsToday() async {
        // alreadyNotifiedToday = true → hoje excluído do agendamento regular
        await scheduler.schedule(plan: fakePlan(from: baseNow), notificationHour: 7,
                                 alreadyNotifiedToday: true, now: baseNow, calendar: spCal)
        XCTAssertEqual(center.pending.count, 6, "Já notificado hoje: hoje deve ser excluído")
        let todayID = LiveNotificationScheduler.dailyPrefix + DayKey(baseNow, calendar: spCal).value
        XCTAssertFalse(center.pending.contains { $0.identifier == todayID },
                       "Notificação de hoje não deve estar pendente")
    }

    func testRescheduleTwiceNoDuplicates() async {
        let plan = fakePlan(from: baseNow)
        for _ in 0..<3 {
            await scheduler.schedule(plan: plan, notificationHour: 7,
                                     alreadyNotifiedToday: false, now: baseNow, calendar: spCal)
        }
        XCTAssertEqual(center.pending.count, 7, "Múltiplos reagendamentos não duplicam")
    }
}
