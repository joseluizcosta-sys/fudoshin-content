import Foundation
import SwiftData

@Model
final class Race {
    var name: String
    var date: Date
    var distanceKm: Double
    var categoryRaw: String

    var category: ImageCategory {
        get { ImageCategory(rawValue: categoryRaw) ?? .trail }
        set { categoryRaw = newValue.rawValue }
    }

    init(name: String, date: Date, distanceKm: Double, category: ImageCategory) {
        self.name = name
        self.date = date
        self.distanceKm = distanceKm
        self.categoryRaw = category.rawValue
    }
}
