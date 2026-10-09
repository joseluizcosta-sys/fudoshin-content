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
                "Wallpaper from \(.applicationName)",
                "\(.applicationName) wallpaper",
                "Get wallpaper from \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource("intent.wallpaper.short_title"),
            systemImageName: "photo"
        )
    }
}

// MARK: - Helper extraível para testes

/// Devolve a URL do PNG do dia. Gera o arquivo se não existir.
/// Se o plano salvo não tiver a entrada de hoje (app fechado há 7+ dias), gera
/// localmente a partir da biblioteca embutida, sem precisar do HealthKit.
@discardableResult
func wallpaperURL() async throws -> URL {
    guard SharedStore.loadPreferencesIfExists()?.isPremium == true else {
        throw WallpaperIntentError.subscriptionRequired
    }

    let dayKey = DayKey(Date())
    let url    = SharedStore.wallpaperURL(for: dayKey)

    if FileManager.default.fileExists(atPath: url.path) {
        return url
    }

    let entry = resolveEntry(for: dayKey)
    guard let entry else {
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

/// Busca a entrada de hoje no plano salvo; se não existir (plano vencido), gera localmente.
func resolveEntry(for dayKey: DayKey) -> DailyEntry? {
    let prefs = SharedStore.loadPreferencesIfExists()
    let lib   = ContentLibrary.current()

    let storedPlan = SharedStore.loadPlan()
    let items = DailyTimelineGenerator.items(
        plan: storedPlan,
        prefs: prefs,
        fallbackMessages: lib.messages,
        fallbackImages: lib.images
    )

    return items.first(where: { $0.entry.day == dayKey })?.entry
        ?? items.first?.entry
}

enum WallpaperIntentError: Error, LocalizedError {
    case noContent
    case generationFailed
    case subscriptionRequired

    var errorDescription: String? {
        switch self {
        case .subscriptionRequired:
            return String(localized: "intent.wallpaper.error.subscription_required")
        default: return nil
        }
    }
}
