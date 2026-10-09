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
    /// Horário de início do silêncio (inclusive).
    static let quietStart = 21
    /// Horário de fim do silêncio (exclusive).
    static let quietEnd = 7

    private let center: NotificationCenterProviding
    private let bundle: Bundle

    init(center: NotificationCenterProviding = LiveNotificationCenter(), bundle: Bundle = .main) {
        self.center = center
        self.bundle = bundle
    }

    // MARK: - NotificationScheduling

    func schedule(plan: DailyPlan, notificationHour: Int, alreadyNotifiedToday: Bool) async {
        await schedule(plan: plan, notificationHour: notificationHour,
                       alreadyNotifiedToday: alreadyNotifiedToday,
                       now: Date(), calendar: .current)
    }

    func scheduleImmediate(entry: DailyEntry) async -> Bool {
        await scheduleImmediate(entry: entry, now: Date(), calendar: .current)
    }

    func cancelPendingNotifications() async {
        let pending = await center.pendingRequests()
        let ids = pending
            .filter { $0.identifier.hasPrefix(Self.dailyPrefix) || $0.identifier.hasPrefix(Self.nowPrefix) }
            .map { $0.identifier }
        if !ids.isEmpty { center.removeRequests(withIdentifiers: ids) }
    }

    // MARK: - Implementação com `now` e `calendar` injetáveis (testes)

    func schedule(
        plan: DailyPlan,
        notificationHour: Int,
        alreadyNotifiedToday: Bool,
        now: Date,
        calendar: Calendar
    ) async {
        guard isAuthorized(await center.authorizationStatus()) else { return }

        // Cancela todos os agendamentos diários pendentes antes de recriar.
        let pending = await center.pendingRequests()
        let toRemove = pending.filter { $0.identifier.hasPrefix(Self.dailyPrefix) }.map { $0.identifier }
        if !toRemove.isEmpty { center.removeRequests(withIdentifiers: toRemove) }

        let cal = calendar
        let todayKey = DayKey(now, calendar: cal)

        for entry in plan.entries {
            if entry.day == todayKey && alreadyNotifiedToday { continue }

            guard let dayStart = entry.day.startOfDay(calendar: cal),
                  let fireDate = cal.date(bySettingHour: notificationHour,
                                          minute: 0, second: 0, of: dayStart),
                  fireDate > now
            else { continue }

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

    @discardableResult
    func scheduleImmediate(entry: DailyEntry, now: Date, calendar: Calendar) async -> Bool {
        guard isAuthorized(await center.authorizationStatus()) else { return false }

        let hour = calendar.component(.hour, from: now)

        // Noite (21h–24h): não enviar.
        if hour >= Self.quietStart { return false }

        let todayDailyID = Self.dailyPrefix + DayKey(now, calendar: calendar).value
        let nowID = Self.nowPrefix + DayKey(now, calendar: calendar).value
        let content = makeContent(for: entry)

        // Madrugada (0h–6h): agendar para quando o silêncio terminar.
        if hour < Self.quietEnd {
            center.removeRequests(withIdentifiers: [todayDailyID])
            guard let dayStart = DayKey(now, calendar: calendar).startOfDay(calendar: calendar),
                  let fireDate = calendar.date(bySettingHour: Self.quietEnd,
                                               minute: 0, second: 0, of: dayStart)
            else { return false }
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second],
                                                from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: nowID, content: content, trigger: trigger)
            try? await center.add(request)
            return true
        }

        // Entre 7h e 21h: enviar imediata.
        center.removeRequests(withIdentifiers: [todayDailyID])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: nowID, content: content, trigger: trigger)
        try? await center.add(request)
        return true
    }

    // MARK: - Autorização

    private func isAuthorized(_ status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }

    // MARK: - Conteúdo da notificação

    private func makeContent(for entry: DailyEntry) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: entry)
        content.body  = "\(entry.shortText) \(attributionText(author: entry.author, isParaphrase: entry.isParaphrase))"
        content.sound = .default
        content.userInfo = ["url": "atletaestoico://today"]
        return content
    }

    private func notificationTitle(for entry: DailyEntry) -> String {
        if entry.trigger == .marcoProva, let days = entry.daysToRace {
            if days == 0 {
                return localizedString("notification.title.marco_prova.d0")
            }
            let fmt = localizedString("notification.title.marco_prova.format")
            return String(format: fmt, days)
        }
        return localizedString(notificationTitleKey(for: entry.trigger))
    }

    /// Chave de localização para o título do gatilho. `internal` para testes.
    func notificationTitleKey(for trigger: Trigger) -> String {
        switch trigger {
        case .geral:        return "notification.title.geral"
        case .vesperaChave: return "notification.title.vespera_chave"
        case .posTreino:    return "notification.title.pos_treino"
        case .sonoRuim:     return "notification.title.sono_ruim"
        case .descanso:     return "notification.title.descanso"
        case .retorno:      return "notification.title.retorno"
        case .marcoProva:   return "notification.title.marco_prova"
        }
    }

    private func localizedString(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
