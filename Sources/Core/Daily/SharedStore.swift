import Foundation

struct SharedPreferences: Codable {
    var installID: String
    var changeHour: Int         // 0...23, padrão 0
    var notificationHour: Int   // padrão 7
    var categories: [ImageCategory]
    var quoteOnWallpaper: Bool
    var isPremium: Bool

    static var `default`: SharedPreferences {
        SharedPreferences(
            installID: UUID().uuidString,
            changeHour: 0,
            notificationHour: 7,
            categories: [.trail],
            quoteOnWallpaper: false,
            isPremium: false
        )
    }
}

enum SharedStore {
    static let groupID = "group.com.atletaestoico"

    // Injetável para testes sem App Group; nil usa o container real.
    static var _baseURL: URL?

    private static var baseURL: URL {
        if let url = _baseURL { return url }
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)
            ?? FileManager.default.temporaryDirectory
    }

    private static var planURL: URL {
        baseURL.appendingPathComponent("daily_plan.json")
    }
    private static var prefsURL: URL {
        baseURL.appendingPathComponent("shared_preferences.json")
    }

    static func loadPlan() -> DailyPlan? {
        guard let data = try? Data(contentsOf: planURL) else { return nil }
        return try? JSONDecoder().decode(DailyPlan.self, from: data)
    }

    static func save(_ plan: DailyPlan) throws {
        let data = try JSONEncoder().encode(plan)
        try data.write(to: planURL, options: .atomic)
    }

    // Primeira chamada sem arquivo existente: gera installID, persiste e devolve.
    static func loadPreferences() -> SharedPreferences {
        if let data = try? Data(contentsOf: prefsURL),
           let prefs = try? JSONDecoder().decode(SharedPreferences.self, from: data) {
            return prefs
        }
        let prefs = SharedPreferences.default
        try? save(prefs)
        return prefs
    }

    static func save(_ p: SharedPreferences) throws {
        let data = try JSONEncoder().encode(p)
        try data.write(to: prefsURL, options: .atomic)
    }

    static func wallpaperURL(for day: DayKey) -> URL {
        baseURL.appendingPathComponent("wallpaper_\(day.value).png")
    }
}
