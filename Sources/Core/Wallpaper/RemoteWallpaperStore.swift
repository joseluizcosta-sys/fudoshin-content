import Foundation
import CryptoKit

// MARK: - Tipos do índice

struct WallpaperIndexEntry: Codable, Equatable {
    let id: String
    let file: String
    let sha256: String
    let bytes: Int
    let added: String
}

struct WallpaperIndex: Codable {
    let schema: Int
    let version: Int
    let items: [WallpaperIndexEntry]
}

// MARK: - Store

actor RemoteWallpaperStore {
    static let shared = RemoteWallpaperStore()

    static let supportedSchema = 1
    static let maxItems = 40
    static let maxTotalBytes = 30 * 1024 * 1024  // 30 MB
    static let checkIntervalDays = 7

    private let session: URLSession
    private let defaults: UserDefaults
    private let indexURLOverride: URL?

    private let lastCheckKey = "remoteWallpapers.lastCheckDate"
    private let versionKey = "remoteWallpapers.version"

    static var wallpapersDirectory: URL {
        SharedStore.containerURL.appendingPathComponent("RemoteContent/wallpapers")
    }

    static var localIndexURL: URL {
        SharedStore.containerURL.appendingPathComponent("RemoteContent/wallpapers.json")
    }

    init(
        session: URLSession = .shared,
        defaults: UserDefaults = UserDefaults(suiteName: SharedStore.groupID) ?? .standard,
        indexURLOverride: URL? = nil
    ) {
        self.session = session
        self.defaults = defaults
        self.indexURLOverride = indexURLOverride
    }

    // MARK: - Non-isolated

    /// Retorna os itens do índice local, sem acessar rede.
    nonisolated static func localItems() -> [WallpaperIndexEntry] {
        guard let data = try? Data(contentsOf: localIndexURL),
              let index = try? JSONDecoder().decode(WallpaperIndex.self, from: data)
        else { return [] }
        return index.items
    }

    // MARK: - Verificação

    /// Busca o índice remoto e baixa imagens novas.
    /// `preferredID` — id da imagem escolhida pelo usuário; nunca é removida do disco.
    func checkForUpdate(force: Bool = false, preferredID: String? = nil) async {
        if !force {
            if let last = defaults.object(forKey: lastCheckKey) as? Date {
                let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
                if days < Self.checkIntervalDays { return }
            }
        }

        guard let indexURL = effectiveIndexURL() else { return }

        guard let indexData = await fetch(url: indexURL, timeout: 15),
              let remoteIndex = try? JSONDecoder().decode(WallpaperIndex.self, from: indexData),
              remoteIndex.schema == Self.supportedSchema
        else { return }

        defaults.set(Date(), forKey: lastCheckKey)

        let currentVersion = defaults.integer(forKey: versionKey)
        guard remoteIndex.version > currentVersion else { return }

        let fm = FileManager.default
        let wallpapersDir = Self.wallpapersDirectory
        try? fm.createDirectory(at: wallpapersDir, withIntermediateDirectories: true)

        // Selecionar itens dentro dos limites (40 imagens, 30 MB), priorizando os MAIS NOVOS:
        // o índice vem em ordem de inclusão (mais antigo primeiro), então percorremos ao contrário
        // e depois restauramos a ordem original.
        var totalBytes = 0
        var newestFirst: [WallpaperIndexEntry] = []
        for item in remoteIndex.items.reversed() {
            if newestFirst.count >= Self.maxItems { break }
            if totalBytes + item.bytes > Self.maxTotalBytes { break }
            totalBytes += item.bytes
            newestFirst.append(item)
        }
        let itemsToKeep = Array(newestFirst.reversed())

        // Imagem escolhida pelo usuário que saiu do índice: continua no disco E no índice local,
        // senão o catálogo não a enxerga e a preferência cai para o sorteio.
        let previousItems = Self.localItems()
        let retainedPreferred: WallpaperIndexEntry? = preferredID.flatMap { pid in
            itemsToKeep.contains(where: { $0.id == pid }) ? nil
                : previousItems.first(where: { $0.id == pid })
        }

        let keepIDs = Set(itemsToKeep.map { $0.id })

        // Remover arquivos não mais no índice, exceto a imagem escolhida pelo usuário
        if let files = try? fm.contentsOfDirectory(at: wallpapersDir, includingPropertiesForKeys: nil) {
            for file in files {
                let fileID = file.deletingPathExtension().lastPathComponent
                guard !keepIDs.contains(fileID), fileID != preferredID else { continue }
                try? fm.removeItem(at: file)
            }
        }

        // Baixar itens ausentes no disco
        let baseURL = indexURL.deletingLastPathComponent()
        for item in itemsToKeep {
            let destURL = wallpapersDir.appendingPathComponent("\(item.id).jpg")
            guard !fm.fileExists(atPath: destURL.path) else { continue }
            await downloadItem(item, from: baseURL, to: destURL)
        }

        // Gravar índice local refletindo o que está em disco
        var finalItems = itemsToKeep.filter {
            fm.fileExists(atPath: wallpapersDir.appendingPathComponent("\($0.id).jpg").path)
        }
        let allDownloaded = finalItems.count == itemsToKeep.count
        if let kept = retainedPreferred,
           fm.fileExists(atPath: wallpapersDir.appendingPathComponent("\(kept.id).jpg").path) {
            finalItems.insert(kept, at: 0)
        }
        let localIndex = WallpaperIndex(schema: Self.supportedSchema,
                                        version: remoteIndex.version,
                                        items: finalItems)
        if let data = try? JSONEncoder().encode(localIndex) {
            try? data.write(to: Self.localIndexURL, options: .atomic)
        }
        // Só marca a versão como aplicada se todas as imagens chegaram; senão a próxima
        // verificação tenta de novo (sem esperar 7 dias).
        if allDownloaded {
            defaults.set(remoteIndex.version, forKey: versionKey)
        } else {
            defaults.removeObject(forKey: lastCheckKey)
        }
    }

    // MARK: - Privado

    private func downloadItem(_ item: WallpaperIndexEntry, from baseURL: URL, to destURL: URL) async {
        // `file` é relativo à pasta do índice (ex.: "wallpapers/wp_xxx.jpg").
        // Aceita só caminhos simples, sem "..", para não sair do repositório.
        guard !item.file.contains(".."), !item.file.hasPrefix("/") else { return }
        let imageURL = baseURL.appendingPathComponent(item.file)
        guard let data = await fetch(url: imageURL, timeout: 30) else { return }

        guard data.count == item.bytes else { return }
        let hex = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard hex == item.sha256 else { return }

        let tmpURL = destURL.deletingLastPathComponent()
            .appendingPathComponent(".\(item.id).tmp")
        do {
            try data.write(to: tmpURL, options: .atomic)
            try FileManager.default.moveItem(at: tmpURL, to: destURL)
        } catch {
            try? FileManager.default.removeItem(at: tmpURL)
        }
    }

    private func effectiveIndexURL() -> URL? {
        if let override = indexURLOverride { return override }
        guard let s = Bundle.main.infoDictionary?["ContentManifestURL"] as? String, !s.isEmpty,
              let manifestURL = URL(string: s), manifestURL.scheme == "https" else { return nil }
        return manifestURL.deletingLastPathComponent()
            .appendingPathComponent("wallpapers.json")
    }

    private func fetch(url: URL, timeout: TimeInterval) async -> Data? {
        let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        guard let (data, resp) = try? await session.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return data
    }
}
