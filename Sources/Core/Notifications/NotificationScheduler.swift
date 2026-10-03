import Foundation
import UserNotifications

// MARK: - Abstração do centro de notificações (testável)

protocol NotificationCenterProviding: Sendable {
    func authorizationStatus() async -> UNAuthorizationStatus
    func pendingRequests() async -> [UNNotificationRequest]
    func removeRequests(withIdentifiers ids: [String])
    func add(_ request: UNNotificationRequest) async throws
}

struct LiveNotificationCenter: NotificationCenterProviding {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
    func pendingRequests() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    func removeRequests(withIdentifiers ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    func add(_ request: UNNotificationRequest) async throws {
        try await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - LiveNotificationScheduler

struct LiveNotificationScheduler: NotificationScheduling {
    /// Prefixo das notificações diárias agendadas.
    static let dailyPrefix = "daily-"
    /// Prefixo das notificações de evento (imediatas).
    static let nowPrefix = "now-"

    private let center: NotificationCenterProviding

    init(center: NotificationCenterProviding = LiveNotificationCenter()) {
        self.center = center
    }

    // MARK: - NotificationScheduling

    func schedule(plan: DailyPlan, notificationHour: Int, alreadyNotifiedToday: Bool) async {
        await schedule(plan: plan, notificationHour: notificationHour,
                       alreadyNotifiedToday: alreadyNotifiedToday,
                       now: Date(), calendar: .current)
    }

    func scheduleImmediate(entry: DailyEntry) async {
        await scheduleImmediate(entry: entry, now: Date(), calendar: .current)
    }

    // MARK: - Implementação com `now` e `calendar` injetáveis (testes)

    func schedule(
        plan: DailyPlan,
        notificationHour: Int,
        alreadyNotifiedToday: Bool,
        now: Date,
        calendar: Calendar
    ) async {
        guard await center.authorizationStatus() == .authorized else { return }

        // Cancela todos os agendamentos diários pendentes antes de recriar.
        let pending = await center.pendingRequests()
        let toRemove = pending.filter { $0.identifier.hasPrefix(Self.dailyPrefix) }.map { $0.identifier }
        if !toRemove.isEmpty { center.removeRequests(withIdentifiers: toRemove) }

        let cal = calendar
        let todayKey = DayKey(now, calendar: cal)

        for entry in plan.entries {
            // Hoje já notificado → pular.
            if entry.day == todayKey && alreadyNotifiedToday { continue }

            // Calcular data de disparo: notificationHour no dia da entrada.
            guard let dayStart = entry.day.startOfDay(calendar: cal),
                  let fireDate = cal.date(bySettingHour: notificationHour,
                                          minute: 0, second: 0, of: dayStart)
            else { continue }

            // Pular datas já passadas.
            guard fireDate > now else { continue }

            let content = makeContent(for: entry)
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.dailyPrefix + entry.day.value,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func scheduleImmediate(entry: DailyEntry, now: Date, calendar: Calendar) async {
        guard await center.authorizationStatus() == .authorized else { return }

        // Cancela a notificação diária de hoje, se ainda estiver pendente.
        let todayDailyID = Self.dailyPrefix + DayKey(now, calendar: calendar).value
        center.removeRequests(withIdentifiers: [todayDailyID])

        let content = makeContent(for: entry)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.nowPrefix + DayKey(now, calendar: calendar).value,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    // MARK: - Conteúdo da notificação

    private func makeContent(for entry: DailyEntry) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: entry)
        content.body  = "\(entry.shortText) — \(entry.author)"
        content.sound = .default
        content.userInfo = ["url": "atletaestoico://today"]
        return content
    }

    private func notificationTitle(for entry: DailyEntry) -> String {
        if entry.trigger == .marcoProva, let days = entry.daysToRace {
            if days == 0 {
                return String(localized: "notification.title.marco_prova.d0")
            }
            let fmt = String(localized: "notification.title.marco_prova.format")
            return String(format: fmt, days)
        }
        return String(localized: "notification.title.\(entry.trigger.rawValue)")
    }
}
