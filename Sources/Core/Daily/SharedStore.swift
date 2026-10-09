import Foundation

struct SharedPreferences: Codable {
    var installID: String
    var changeHour: Int         // fixo em 4; valor salvo é ignorado na leitura
    var notificationHour: Int   // padrão 7
    var categories: [ImageCategory]
    var quoteOnWallpaper: Bool
    var isPremium: Bool

    enum CodingKeys: String, CodingKey {
        case installID, changeHour, notificationHour, categories, quoteOnWallpaper, isPremium
    }

    // Campos ausentes (JSON de versão anterior) recebem valores padrão sem invalidar o arquivo.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        installID = (try? c.decodeIfPresent(String.self, forKey: .installID)) ?? UUID().uuidString
        changeHour = 4   // fixo; ignora valor salvo para migração
        notificationHour = (try? c.decodeIfPresent(Int.self, forKey: .notificationHour)) ?? 7
        categories = (try? c.decodeIfPresent([ImageCategory].self, forKey: .categories)) ?? [.trail]
        quoteOnWallpaper = (try? c.decodeIfPresent(Bool.self, forKey: .quoteOnWallpaper)) ?? false
        isPremium = (try? c.decodeIfPresent(Bool.self, forKey: .isPremium)) ?? false
    }

    init(
        installID: String,
        changeHour: Int = 4,
        notificationHour: Int = 7,
        categories: [ImageCategory] = [.trail],
        quoteOnWallpaper: Bool = false,
        isPremium: Bool = false
    ) {
        self.installID = installID
        self.changeHour = changeHour
        self.notificationHour = notificationHour
        self.categories = categories
        self.quoteOnWallpaper = quoteOnWallpaper
        self.isPremium = isPremium
    }

    static var `default`: SharedPreferences {
        SharedPreferences(installID: UUID().uuidString)
    }
}

enum SharedStore {
    static let groupID = "group.com.atletaestoico"

    // Injetável para testes sem App Group; nil usa o container real.
    static var _baseURL: URL?

    private static var baseURL: URL {
        if let url = _baseURL { return url }
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            assertionFailure("App Group '\(groupID)' não configurado — verifique entitlements e provisioning")
            return FileManager.default.temporaryDirectory
        }
        return url
    }

    /// URL do container do App Group (ou `_baseURL` se injetado para testes).
    static var containerURL: URL { baseURL }

    private static var installIDURL: URL { baseURL.appendingPathComponent("install_id.txt") }
    private static var planURL: URL    { baseURL.appendingPathComponent("daily_plan.json") }
    private static var prefsURL: URL   { baseURL.appendingPathComponent("shared_preferences.json") }

    // MARK: - installID

    // Lê install_id.txt; se ausente, gera UUID e grava (nunca sobrescreve). Uso exclusivo do app.
    private static func resolveInstallID() -> String {
        let url = installIDURL
        if let existing = try? String(contentsOf: url, encoding: .utf8), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        try? id.write(to: url, atomically: true, encoding: .utf8)
        return id
    }

    // Lê install_id.txt sem criar nada. Seguro para o widget chamar.
    private static func readInstallIDIfExists() -> String? {
        guard let id = try? String(contentsOf: installIDURL, encoding: .utf8),
              !id.isEmpty else { return nil }
        return id
    }

    // MARK: - DailyPlan

    static func loadPlan() -> DailyPlan? {
        guard let data = try? Data(contentsOf: planURL) else { return nil }
        return try? JSONDecoder().decode(DailyPlan.self, from: data)
    }

    static func save(_ plan: DailyPlan) throws {
        let data = try JSONEncoder().encode(plan)
        try data.write(to: planURL, options: .atomic)
    }

    // MARK: - SharedPreferences

    /// Carrega preferências, criando install_id.txt e o arquivo de preferências se ausentes.
    /// **Uso exclusivo do app** — nunca chamar do widget.
    static func loadPreferences() -> SharedPreferences {
        let id = resolveInstallID()
        if let data = try? Data(contentsOf: prefsURL),
           var prefs = try? JSONDecoder().decode(SharedPreferences.self, from: data) {
            prefs.installID = id        // install_id.txt é a fonte de verdade
            return prefs
        }
        var prefs = SharedPreferences.default
        prefs.installID = id
        try? save(prefs)
        return prefs
    }

    /// Lê preferências sem criar nem alterar nenhum arquivo.
    /// Retorna nil se install_id.txt ou shared_preferences.json não existirem.
    /// **Widget usa esta função**; se nil, usar installID `"pending"` no fallback local.
    static func loadPreferencesIfExists() -> SharedPreferences? {
        guard let id = readInstallIDIfExists(),
              let data = try? Data(contentsOf: prefsURL),
              var prefs = try? JSONDecoder().decode(SharedPreferences.self, from: data) else {
            return nil
        }
        prefs.installID = id
        return prefs
    }

    static func save(_ p: SharedPreferences) throws {
        let data = try JSONEncoder().encode(p)
        try data.write(to: prefsURL, options: .atomic)
    }

    static func wallpaperURL(for day: DayKey) -> URL {
        baseURL.appendingPathComponent("wallpaper_\(day.value).png")
    }

    static func wallpaperMetaURL(for day: DayKey) -> URL {
        baseURL.appendingPathComponent("wallpaper_\(day.value)_meta.json")
    }
}
