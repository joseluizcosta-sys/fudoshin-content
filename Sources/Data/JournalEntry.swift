import Foundation
import SwiftData

@Model
final class JournalEntry {
    var dayValue: String
    var controlled: String
    var notControlled: String
    var note: String

    var day: DayKey {
        get { DayKey(value: dayValue) }
        set { dayValue = newValue.value }
    }

    init(day: DayKey, controlled: String = "", notControlled: String = "", note: String = "") {
        self.dayValue = day.value
        self.controlled = controlled
        self.notControlled = notControlled
        self.note = note
    }
}
