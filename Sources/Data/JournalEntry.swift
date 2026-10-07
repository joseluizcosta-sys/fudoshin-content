import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var dayValue: String
    var controlled: String
    var notControlled: String
    var note: String = ""   // default na declaração: migração leve do SwiftData para entradas antigas

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
