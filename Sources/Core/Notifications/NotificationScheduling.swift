import Foundation

protocol NotificationScheduling {
    func schedule(plan: DailyPlan, notificationHour: Int) async
}

/// No-op — substituído em T09.
struct NoOpNotificationScheduler: NotificationScheduling {
    func schedule(plan: DailyPlan, notificationHour: Int) async {}
}
