import Foundation
import CryptoKit

// MARK: - Types

struct RemoteManifest: Decodable {
    let schema: Int
    let version: Int
    let url: String
    let sha256: String
    let bytes: Int
    let enabled: Bool
    let minAppBuild: Int
}

struct RemoteContentPackage: Decodable {
    let schema: Int
    let version: Int
    let generatedAt: String
    let base: BaseContentFile
    let locales: [String: LocaleContentFile]
}

// MARK: - Store

actor RemoteContentStore {
    static let shared = RemoteContentStore()

    static let supportedSchema = 3
    static let maxBytes = 2_000_000
    static let checkIntervalDays = 7

    private let session: URLSession
    private let defaults: UserDefaults
    private let manifestURLOverride: URL?

    private let lastCheckKey = "remoteContent.lastCheckDate"
    private let activeVersionKey = "remoteContent.activeVersion"

    init(
        session: URLSession = .shared,
        defaults: UserDefaults = UserDefaults(suiteName: SharedStore.groupID) ?? .standard,
        manifestURLOverride: URL? = nil
    ) {
        self.session = session
        self.defaults = defaults
        self.manifestURLOverride = manifestURLOverride
    }

    // MARK: - Non-isolated (chamado de ContentLibrary.current())

    /// Pasta `RemoteContent/current` no App Group, ou nil se não instalada.
    nonisolated static var currentContentDirectory: URL? {
        let dir = SharedStore.containerURL.appendingPathComponent("RemoteContent/current")
        return FileManager.default.fileExists(atPath: dir.path) ? dir : nil
    }

    // MARK: - Verificação de atualização

    /// Verifica manifesto remoto e instala novo conteúdo se disponível.
    /// Retorna true se novo conteúdo foi instalado.
    @discardableResult
    func checkForUpdate(force: Bool = false) async -> Bool {
        if !force {
            if let last = defaults.object(forKey: lastCheckKey) as? Date {
                let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
                if days < Self.checkIntervalDays { return false }
            }
        }

        // Auto-recuperação: versão ativa gravada mas pasta apagada ou corrompida → resetar para baixar de novo
        let storedVersion = defaults.integer(forKey: activeVersionKey)
        if storedVersion > 0 {
            let currentDir = RemoteContentStore.currentContentDirectory
            let libOK = currentDir.flatMap { try? ContentLibrary(remoteContentDirectory: $0) } != nil
            if !libOK {
                defaults.set(0, forKey: activeVersionKey)
            }
        }

        guard let manifestURL = effectiveManifestURL() else { return false }

        // Buscar manifesto
        guard let manifestData = await fetch(url: manifestURL, timeout: 15),
              let manifest = try? JSONDecoder().decode(RemoteManifest.self, from: manifestData)
        else { return false }

        // Gravar data só após decodificação bem-sucedida (falha de rede retenta na próxima abertura)
        defaults.set(Date(), forKey: lastCheckKey)

        guard manifest.schema == Self.supportedSchema else { return false }

        if !manifest.enabled {
            clearRemoteContent()
            return false
        }

        let build = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1") ?? 1
        guard manifest.minAppBuild <= build else { return false }

        let currentVersion = max(
            defaults.integer(forKey: activeVersionKey),
            bundleContentVersion()
        )
        guard manifest.version > currentVersion else { return false }

        // Baixar pacote
        let packageURL = manifestURL.deletingLastPathComponent().appendingPathComponent(manifest.url)
        guard let packageData = await fetch(url: packageURL, timeout: 30) else { return false }

        // Validar tamanho
        guard packageData.count == manifest.bytes, packageData.count <= Self.maxBytes else { return false }

        // Validar SHA-256
        let hex = SHA256.hash(data: packageData).map { String(format: "%02x", $0) }.joined()
        guard hex == manifest.sha256 else { return false }

        // Decodificar
        guard let package = try? JSONDecoder().decode(RemoteContentPackage.self, from: packageData),
              package.schema == Self.supportedSchema
        else { return false }

        // Instalar atomicamente
        guard await install(package) else { return false }
        defaults.set(manifest.version, forKey: activeVersionKey)
        return true
    }

    // MARK: - Privado

    private func effectiveManifestURL() -> URL? {
        if let override = manifestURLOverride { return override }
        guard let s = Bundle.main.infoDictionary?["ContentManifestURL"] as? String, !s.isEmpty,
              let url = URL(string: s), url.scheme == "https" else { return nil }
        return url
    }

    private func fetch(url: URL, timeout: TimeInterval) async -> Data? {
        let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        guard let (data, resp) = try? await session.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return data
    }

    private func bundleContentVersion() -> Int {
        (try? ContentLibrary())?.contentVersion ?? 0
    }

    private func install(_ package: RemoteContentPackage) async -> Bool {
        let base = SharedStore.containerURL
        let pendingDir = base.appendingPathComponent("RemoteContent/pending_\(UUID().uuidString)")
        let messagesDir = pendingDir.appendingPathComponent("messages")
        let fm = FileManager.default

        do {
            try fm.createDirectory(at: messagesDir, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            try encoder.encode(package.base).write(to: messagesDir.appendingPathComponent("base.json"))
            for (lang, locale) in package.locales {
                try encoder.encode(locale).write(to: messagesDir.appendingPathComponent("\(lang).json"))
            }

            // Validar com ContentLibrary antes de instalar
            let lib = try ContentLibrary(remoteContentDirectory: pendingDir)
            guard lib.validate().isEmpty else {
                try? fm.removeItem(at: pendingDir)
                return false
            }

            // Troca atômica
            let currentDir = base.appendingPathComponent("RemoteContent/current")
            try fm.createDirectory(at: currentDir.deletingLastPathComponent(),
                                   withIntermediateDirectories: true)
            if fm.fileExists(atPath: currentDir.path) {
                var resultURL: NSURL?
                try fm.replaceItem(at: currentDir, withItemAt: pendingDir,
                                   backupItemName: nil, options: [],
                                   resultingItemURL: &resultURL)
            } else {
                try fm.moveItem(at: pendingDir, to: currentDir)
            }
            return true
        } catch {
            try? fm.removeItem(at: pendingDir)
            return false
        }
    }

    private func clearRemoteContent() {
        let currentDir = SharedStore.containerURL.appendingPathComponent("RemoteContent/current")
        try? FileManager.default.removeItem(at: currentDir)
        defaults.removeObject(forKey: activeVersionKey)
    }
}
