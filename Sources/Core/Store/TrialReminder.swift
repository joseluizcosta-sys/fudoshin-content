import Foundation
import UserNotifications

enum TrialReminder {
    static let notificationID = "trial-ending"

    /// Data de disparo: 48 h antes do fim do teste.
    /// Retorna nil se a data já passou.
    static func fireDate(trialEnd: Date, now: Date = Date()) -> Date? {
        let candidate = trialEnd.addingTimeInterval(-48 * 60 * 60)
        return candidate > now ? candidate : nil
    }

    static func schedule(fireDate: Date, price: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.trial_ending.title")
        content.body  = String(
            format: String(localized: "notification.trial_ending.body"),
            price
        )
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationID, content: content, trigger: trigger
        )
        try? await center.add(request)
    }

    static func cancel() async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
