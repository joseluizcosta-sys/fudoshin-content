import Foundation
import UIKit
import CoreGraphics

struct WallpaperComposer: WallpaperComposing {

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
        saveMeta(WallpaperMeta(messageID: entry.messageID, triggerRaw: entry.trigger.rawValue), to: metaURL)
        cleanupOldFiles()
    }

    // MARK: - Verificação de cache

    private func fileUpToDate(url: URL, metaURL: URL, entry: DailyEntry) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: metaURL),
              let meta = try? JSONDecoder().decode(WallpaperMeta.self, from: data) else { return false }
        return meta.messageID == entry.messageID && meta.triggerRaw == entry.trigger.rawValue
    }

    // MARK: - Renderização

    private func renderWallpaper(entry: DailyEntry, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { ctx in
            let cgCtx   = ctx.cgContext
            let bounds  = CGRect(origin: .zero, size: size)
            let hMargin = size.width * 0.07

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

            // Camada 2 — degradê preto de baixo para cima, 50% inferiores (0 → 0,85)
            let gradColors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.85).cgColor,
            ] as CFArray
            let locations: [CGFloat] = [0, 1]
            if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: gradColors, locations: locations) {
                let gradTop = CGPoint(x: size.width / 2, y: size.height * 0.5)
                let gradBot = CGPoint(x: size.width / 2, y: size.height)
                cgCtx.drawLinearGradient(grad, start: gradTop, end: gradBot, options: [])
            }

            // Camadas 3 & 4 — texto entre 58% e 86% da altura
            let blockTop    = size.height * 0.58
            let blockBottom = size.height * 0.86
            let blockHeight = blockBottom - blockTop
            let textWidth   = size.width - hMargin * 2
            let fontSize    = size.width * 0.07

            let mainFont  = UIFont(name: "Georgia-Bold", size: fontSize) ??
                            UIFont.systemFont(ofSize: fontSize, weight: .semibold)
            let mainAttrs: [NSAttributedString.Key: Any] = [
                .font: mainFont,
                .foregroundColor: UIColor.white,
            ]
            let mainPara = NSMutableParagraphStyle()
            mainPara.lineBreakMode = .byWordWrapping
            let fullAttrs = mainAttrs.merging([.paragraphStyle: mainPara]) { _, new in new }

            let attribFontSize = fontSize * 0.55
            let attribFont = UIFont(name: "Georgia", size: attribFontSize) ??
                             UIFont.systemFont(ofSize: attribFontSize, weight: .regular)
            let attribStr  = attributionText(author: entry.author, isParaphrase: entry.isParaphrase)
            let attribAttrs: [NSAttributedString.Key: Any] = [
                .font: attribFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.75),
            ]

            let attribH = ceil((attribStr as NSString).boundingRect(
                with: CGSize(width: textWidth, height: 60),
                options: .usesLineFragmentOrigin,
                attributes: attribAttrs,
                context: nil
            ).height)

            // Limitar texto principal a blockHeight menos atribuição e espaço de 6 pt
            let maxMainH = blockHeight - attribH - 6
            let mainNS   = NSAttributedString(string: entry.shortText, attributes: fullAttrs)
            let mainH    = ceil(mainNS.boundingRect(
                with: CGSize(width: textWidth, height: maxMainH),
                options: .usesLineFragmentOrigin,
                context: nil
            ).height)

            let usedMainH = min(mainH, maxMainH)
            let totalUsed = usedMainH + 6 + attribH
            let startY    = max(blockTop, blockBottom - totalUsed)

            let mainRect   = CGRect(x: hMargin, y: startY, width: textWidth, height: usedMainH)
            let attribRect = CGRect(x: hMargin, y: startY + usedMainH + 6, width: textWidth, height: attribH + 4)

            mainNS.draw(with: mainRect, options: .usesLineFragmentOrigin, context: nil)
            (attribStr as NSString).draw(with: attribRect,
                                         options: .usesLineFragmentOrigin,
                                         attributes: attribAttrs,
                                         context: nil)
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
}
