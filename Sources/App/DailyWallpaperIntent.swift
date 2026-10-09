import AppIntents
import Foundation
import UIKit

// MARK: - AppIntent

struct DailyWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("intent.wallpaper.title")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some ReturnsValue<IntentFile> {
        let url = try await wallpaperURL()
        return .result(value: IntentFile(fileURL: url, filename: "wallpaper.png",
                                         type: .png))
    }
}

// MARK: - AppShortcutsProvider

struct WallpaperShortcutsProvider: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DailyWallpaperIntent(),
            phrases: [
                "Wallpaper from \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("intent.wallpaper.short_title"),
            systemImageName: "photo"
        )
    }
}

// MARK: - Helper extraível para testes

/// Devolve a URL do PNG do dia. Gera o arquivo se não existir.
/// Pode ser chamada diretamente em testes, sem o runtime do AppIntents.
@discardableResult
func wallpaperURL() async throws -> URL {
    let dayKey = DayKey(Date())
    let url    = SharedStore.wallpaperURL(for: dayKey)

    if FileManager.default.fileExists(atPath: url.path) {
        return url
    }

    guard let plan = SharedStore.loadPlan(),
          let entry = plan.entries.first(where: { $0.day == dayKey })
                   ?? plan.entries.first
    else {
        throw WallpaperIntentError.noContent
    }

    let screenSize  = await MainActor.run { UIScreen.main.nativeBounds.size }
    let installID   = SharedStore.loadPreferencesIfExists()?.installID ?? "pending"
    let composer    = WallpaperComposer(screenSize: screenSize, installID: installID)
    await composer.prepareWallpaper(for: entry)

    guard FileManager.default.fileExists(atPath: url.path) else {
        throw WallpaperIntentError.generationFailed
    }
    return url
}

enum WallpaperIntentError: Error {
    case noContent
    case generationFailed
}
