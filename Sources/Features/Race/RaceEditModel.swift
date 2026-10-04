import Foundation
import SwiftData

enum RaceEditMode {
    case create
    case edit(Race)
}

@Observable
final class RaceEditModel {
    var name: String
    var date: Date
    var distanceKm: Double
    var category: ImageCategory

    let isEditMode: Bool
    private let originalName: String?
    private let originalCreatedAt: Date?

    var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let today = Calendar.current.startOfDay(for: Date())
        let raceDay = Calendar.current.startOfDay(for: date)
        return !trimmed.isEmpty && distanceKm > 0 && raceDay >= today
    }

    init(mode: RaceEditMode) {
        switch mode {
        case .create:
            self.name = ""
            self.date = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
            self.distanceKm = 42.2
            self.category = .trail
            self.isEditMode = false
            self.originalName = nil
            self.originalCreatedAt = nil
        case .edit(let race):
            self.name = race.name
            self.date = race.date
            self.distanceKm = race.distanceKm
            self.category = race.category
            self.isEditMode = true
            self.originalName = race.name
            self.originalCreatedAt = race.createdAt
        }
    }

    /// Saves changes. In create mode, replaces any existing race. In edit mode,
    /// updates the existing one — resetting createdAt only when the name changes.
    @MainActor
    func save(into ctx: ModelContext) throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let existing = try ctx.fetch(FetchDescriptor<Race>())

        if isEditMode, let race = existing.first {
            let nameChanged = trimmed != originalName
            race.name = trimmed
            race.date = date
            race.distanceKm = distanceKm
            race.categoryRaw = category.rawValue
            if nameChanged {
                race.createdAt = Date()
            }
        } else {
            existing.forEach { ctx.delete($0) }
            ctx.insert(Race(name: trimmed, date: date, distanceKm: distanceKm, category: category))
        }

        var prefs = SharedStore.loadPreferences()
        prefs.categories = [category]
        try SharedStore.save(prefs)
        try ctx.save()
    }

    /// Deletes the race and resets categories to [.trail].
    @MainActor
    func remove(from ctx: ModelContext) throws {
        let existing = try ctx.fetch(FetchDescriptor<Race>())
        existing.forEach { ctx.delete($0) }

        var prefs = SharedStore.loadPreferences()
        prefs.categories = [.trail]
        try SharedStore.save(prefs)
        try ctx.save()
    }
}
