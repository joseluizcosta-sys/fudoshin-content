import Foundation

enum WallpaperCatalog {
    /// Assets embutidos no bundle (ids = nomes de asset, compatíveis com preferências antigas).
    static let bundledAssets: [String] = (1...5).map { "Wallpaper_epico_\($0)" }

    /// Retorna todas as entradas do catálogo: remotas mais recentes primeiro, depois as embutidas.
    /// `today` injetável para testes.
    static func entries(today: Date = Date()) -> [WallpaperEntry] {
        let remoteItems = RemoteWallpaperStore.localItems()
        let wallpapersDir = RemoteWallpaperStore.wallpapersDirectory
        let fm = FileManager.default
        let newCutoff = Calendar.current.date(byAdding: .day, value: -14, to: today) ?? today

        // Remotas: JSON tem itens em ordem de inclusão (mais antigo primeiro); invertemos para
        // exibir os mais novos primeiro na galeria.
        let remoteEntries: [WallpaperEntry] = remoteItems.reversed().compactMap { item in
            let url = wallpapersDir.appendingPathComponent("\(item.id).jpg")
            guard fm.fileExists(atPath: url.path) else { return nil }
            return WallpaperEntry(id: item.id, source: .file(url),
                                  isNew: isNew(addedStr: item.added, cutoff: newCutoff))
        }

        let bundledEntries = bundledAssets.map {
            WallpaperEntry(id: $0, source: .bundled(assetName: $0), isNew: false)
        }

        return remoteEntries + bundledEntries
    }

    private static func isNew(addedStr: String, cutoff: Date) -> Bool {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        guard let added = df.date(from: addedStr) else { return false }
        // startOfDay em ambos os lados para comparação agnóstica de fuso horário
        return Calendar.current.startOfDay(for: added) >= Calendar.current.startOfDay(for: cutoff)
    }
}
