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
}

struct DailyPlan: Codable {
    let generatedAt: Date
    let entries: [DailyEntry]
}
