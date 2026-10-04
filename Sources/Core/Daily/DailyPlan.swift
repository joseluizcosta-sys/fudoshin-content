import Foundation

struct DailyEntry: Codable, Equatable {
    let day: DayKey
    let messageID: String
    let imageID: String
    let trigger: Trigger
    let shortText: String
    let inlineText: String
    let author: String
    let reflection: String
    let daysToRace: Int?
    /// Dias totais entre cadastro e a prova. Nil em entradas sem prova.
    let totalDaysToRace: Int?

    init(day: DayKey, messageID: String, imageID: String, trigger: Trigger,
         shortText: String, inlineText: String, author: String, reflection: String,
         daysToRace: Int?, totalDaysToRace: Int? = nil) {
        self.day = day; self.messageID = messageID; self.imageID = imageID
        self.trigger = trigger; self.shortText = shortText; self.inlineText = inlineText
        self.author = author; self.reflection = reflection
        self.daysToRace = daysToRace; self.totalDaysToRace = totalDaysToRace
    }

    // Backward-compatible decoder: campos ausentes em JSON antigo → nil.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        day = try c.decode(DayKey.self, forKey: .day)
        messageID = try c.decode(String.self, forKey: .messageID)
        imageID = try c.decode(String.self, forKey: .imageID)
        trigger = try c.decode(Trigger.self, forKey: .trigger)
        shortText = try c.decode(String.self, forKey: .shortText)
        inlineText = try c.decode(String.self, forKey: .inlineText)
        author = try c.decode(String.self, forKey: .author)
        reflection = try c.decode(String.self, forKey: .reflection)
        daysToRace = try? c.decodeIfPresent(Int.self, forKey: .daysToRace)
        totalDaysToRace = try? c.decodeIfPresent(Int.self, forKey: .totalDaysToRace)
    }

    /// Progresso do Gauge circular: 0.0 na criação da prova, 1.0 no dia da prova.
    var gaugeProgress: Double {
        guard let dtr = daysToRace, let total = totalDaysToRace, total > 0 else { return 0 }
        return max(0, min(1, 1.0 - Double(dtr) / Double(total)))
    }
}

struct DailyPlan: Codable {
    let generatedAt: Date
    let entries: [DailyEntry]
}
