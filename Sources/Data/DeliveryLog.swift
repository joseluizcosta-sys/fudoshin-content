import Foundation
import SwiftData

@Model
final class DeliveryLog {
    var dayValue: String
    var messageID: String
    var imageID: String
    var triggerRaw: String
    var notified: Bool

    var day: DayKey {
        get { DayKey(value: dayValue) }
        set { dayValue = newValue.value }
    }

    var trigger: Trigger {
        get { Trigger(rawValue: triggerRaw) ?? .geral }
        set { triggerRaw = newValue.rawValue }
    }

    init(day: DayKey, messageID: String, imageID: String, trigger: Trigger, notified: Bool = false) {
        self.dayValue = day.value
        self.messageID = messageID
        self.imageID = imageID
        self.triggerRaw = trigger.rawValue
        self.notified = notified
    }
}
