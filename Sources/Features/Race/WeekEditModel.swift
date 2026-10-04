import Foundation
import SwiftData

@Observable
final class WeekEditModel {
    var sessions: [Int: SessionType]

    init(weekPlan: WeekPlan?) {
        self.sessions = weekPlan?.sessions ?? [:]
    }

    /// Updates the existing WeekPlan, or inserts a new one. Does not touch AthleteProfile or Race.
    @MainActor
    func save(into ctx: ModelContext) throws {
        let existing = try ctx.fetch(FetchDescriptor<WeekPlan>())
        if let week = existing.first {
            week.sessions = sessions
        } else {
            ctx.insert(WeekPlan(sessions: sessions))
        }
        try ctx.save()
    }
}
