import Foundation
import UIKit
import CoreGraphics

struct WallpaperComposer: WallpaperComposing {

    /// Mude quando o layout mudar: força regerar os papéis de parede já salvos.
    static let layoutVersion = 2

    let screenSize: CGSize

    init(screenSize: CGSize) {
        self.screenSize = screenSize
    }

    func prepareWallpaper(for entry: DailyEntry) async {
        let url     = SharedStore.wallpaperURL(for: entry.day)
        let metaURL = SharedStore.wallpaperMetaURL(for: entry.day)

        if fileUpToDate(url: url, metaURL: metaURL, entry: entry) { return }

        let image = renderWallpaper(entry: entry, size: screenSize)
        guard let png = image.pngData() else { return }

        try? png.write(to: url, options: .atomic)
        saveMeta(WallpaperMeta(messageID: entry.messageID, triggerRaw: entry.trigger.rawValue,
                               layoutVersion: Self.layoutVersion), to: metaURL)
        cleanupOldFiles()
    }

    // MARK: - Verificação de cache

    private func fileUpToDate(url: URL, metaURL: URL, entry: DailyEntry) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: metaURL),
              let meta = try? JSONDecoder().decode(WallpaperMeta.self, from: data) else { return false }
        return meta.messageID == entry.messageID && meta.triggerRaw == entry.trigger.rawValue
            && meta.layoutVersion == Self.layoutVersion
    }

    // MARK: - Renderização

    private func renderWallpaper(entry: DailyEntry, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { ctx in
            let cgCtx   = ctx.cgContext
            let bounds  = CGRect(origin: .zero, size: size)

            // Camada 1 — imagem do gatilho (scaledToFill, alinhada ao topo)
            let imageName = HeroImage.name(for: entry.trigger, available: { UIImage(named: $0) != nil })
            if let hero = UIImage(named: imageName) {
                let scale = max(size.width / hero.size.width, size.height / hero.size.height)
                let sw = hero.size.width * scale
                let sh = hero.size.height * scale
                let drawRect = CGRect(x: (size.width - sw) / 2, y: 0, width: sw, height: sh)
                hero.draw(in: drawRect)
            } else {
                UIColor(red: 0.07, green: 0.08, blue: 0.09, alpha: 1).setFill()
                UIRectFill(bounds)
            }

            // Camada 2 — escurece a imagem inteira (20%) para a frase ganhar contraste
            UIColor.black.withAlphaComponent(0.20).setFill()
            UIRectFillUsingBlendMode(bounds, .normal)

            // Camadas 3 e 4 — frase e atribuição centralizadas (horizontal e vertical)
            // Centro do bloco em 53% da altura: abaixo do relógio e dos widgets (≈ 0–38%)
            // e acima da lanterna/câmera (12% de baixo).
            let textWidth = size.width * 0.80
            let textX     = (size.width - textWidth) / 2
            let fontSize  = size.width * 0.065

            let center = NSMutableParagraphStyle()
            center.alignment = .center
            center.lineBreakMode = .byWordWrapping

            let mainFont = UIFont(name: "Georgia-Bold", size: fontSize) ??
                           UIFont.systemFont(ofSize: fontSize, weight: .semibold)
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.6)
            shadow.shadowBlurRadius = fontSize * 0.25
            shadow.shadowOffset = .zero
            let mainAttrs: [NSAttributedString.Key: Any] = [
                .font: mainFont, .foregroundColor: UIColor.white,
                .paragraphStyle: center, .shadow: shadow,
            ]
            let attribFont = UIFont(name: "Georgia", size: fontSize * 0.55) ??
                             UIFont.systemFont(ofSize: fontSize * 0.55, weight: .regular)
            let attribAttrs: [NSAttributedString.Key: Any] = [
                .font: attribFont, .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .paragraphStyle: center, .shadow: shadow,
            ]

            let maxBlockH = size.height * 0.30            // nunca passa de 38%–68%
            let mainNS    = NSAttributedString(string: entry.shortText, attributes: mainAttrs)
            let attribNS  = NSAttributedString(
                string: attributionText(author: entry.author, isParaphrase: entry.isParaphrase),
                attributes: attribAttrs)
            let gap       = fontSize * 0.45
            let attribH   = ceil(attribNS.boundingRect(with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
                                                       options: .usesLineFragmentOrigin, context: nil).height)
            let mainH     = min(ceil(mainNS.boundingRect(with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
                                                         options: .usesLineFragmentOrigin, context: nil).height),
                                maxBlockH - attribH - gap)
            let blockH    = mainH + gap + attribH
            let blockTop  = size.height * 0.53 - blockH / 2

            // Faixa escura suave atrás do texto (transparente → 60% → transparente)
            let pad = fontSize * 3
            let bandColors = [UIColor.clear.cgColor,
                              UIColor.black.withAlphaComponent(0.60).cgColor,
                              UIColor.black.withAlphaComponent(0.60).cgColor,
                              UIColor.clear.cgColor] as CFArray
            if let band = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: bandColors, locations: [0, 0.3, 0.7, 1]) {
                cgCtx.drawLinearGradient(band,
                                         start: CGPoint(x: 0, y: blockTop - pad),
                                         end: CGPoint(x: 0, y: blockTop + blockH + pad),
                                         options: [])
            }

            mainNS.draw(with: CGRect(x: textX, y: blockTop, width: textWidth, height: mainH),
                        options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
            attribNS.draw(with: CGRect(x: textX, y: blockTop + mainH + gap, width: textWidth, height: attribH + 4),
                          options: .usesLineFragmentOrigin, context: nil)
        }
    }

    // MARK: - Limpeza de arquivos antigos

    func cleanupOldFiles() {
        let base = SharedStore.containerURL
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: base, includingPropertiesForKeys: nil
        ) else { return }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let cutoff = DayKey(cutoffDate)

        for file in files {
            let name = file.lastPathComponent
            guard name.hasPrefix("wallpaper_") else { continue }
            guard name.hasSuffix(".png") || name.hasSuffix("_meta.json") else { continue }

            let afterPrefix = String(name.dropFirst("wallpaper_".count))
            let dayStr: String
            if afterPrefix.hasSuffix(".png") {
                dayStr = String(afterPrefix.dropLast(".png".count))
            } else if afterPrefix.hasSuffix("_meta.json") {
                dayStr = String(afterPrefix.dropLast("_meta.json".count))
            } else {
                continue
            }

            // yyyy-MM-dd: comparação lexicográfica é suficiente
            if dayStr < cutoff.value {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    // MARK: - Helpers

    private func saveMeta(_ meta: WallpaperMeta, to url: URL) {
        guard let data = try? JSONEncoder().encode(meta) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

// MARK: - Metadados de cache

struct WallpaperMeta: Codable {
    let messageID: String
    let triggerRaw: String
    var layoutVersion: Int? = nil   // nil = arquivo antigo (layout 1)
}
