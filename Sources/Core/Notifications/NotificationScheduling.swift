import Foundation

protocol NotificationScheduling {
    /// Agenda (ou re-agenda) notificações dos próximos 7 dias do plano.
    /// `alreadyNotifiedToday`: se true, hoje é excluído do agendamento.
    func schedule(plan: DailyPlan, notificationHour: Int, alreadyNotifiedToday: Bool) async
    /// Envia imediatamente uma notificação de evento e cancela a agendada de hoje.
    func scheduleImmediate(entry: DailyEntry) async
}

/// No-op — substituído pelo LiveNotificationScheduler via AppEnvironment.
struct NoOpNotificationScheduler: NotificationScheduling {
    func schedule(plan: DailyPlan, notificationHour: Int, alreadyNotifiedToday: Bool) async {}
    func scheduleImmediate(entry: DailyEntry) async {}
}
