import Foundation

protocol WallpaperComposing {
    func prepareWallpaper(for entry: DailyEntry) async
}

/// No-op — substituído em T12.
struct NoOpWallpaperComposer: WallpaperComposing {
    func prepareWallpaper(for entry: DailyEntry) async {}
}
