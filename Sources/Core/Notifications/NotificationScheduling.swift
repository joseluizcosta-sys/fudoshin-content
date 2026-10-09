import Foundation

protocol NotificationScheduling {
    /// Agenda (ou re-agenda) notificações dos próximos 7 dias do plano.
    /// `alreadyNotifiedToday`: se true, hoje é excluído do agendamento.
    func schedule(plan: DailyPlan, notificationHour: Int, alreadyNotifiedToday: Bool) async
    /// Envia notificação imediata de evento (pos_treino/retorno).
    /// Retorna false se estiver no horário de silêncio (21h–7h) ou sem permissão.
    @discardableResult
    func scheduleImmediate(entry: DailyEntry) async -> Bool
    /// Cancela todas as notificações diárias e de evento pendentes.
    func cancelPendingNotifications() async
}

/// No-op — substituído pelo LiveNotificationScheduler via AppEnvironment.
struct NoOpNotificationScheduler: NotificationScheduling {
    func schedule(plan: DailyPlan, notificationHour: Int, alreadyNotifiedToday: Bool) async {}
    func scheduleImmediate(entry: DailyEntry) async -> Bool { false }
    func cancelPendingNotifications() async {}
}
