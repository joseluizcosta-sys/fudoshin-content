import Foundation

struct WallpaperEntry: Equatable {
    enum Source: Equatable {
        case bundled(assetName: String)
        case file(URL)
    }

    let id: String
    let source: Source
    let isNew: Bool
}
