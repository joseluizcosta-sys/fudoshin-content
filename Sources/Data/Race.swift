import Foundation
import SwiftData

@Model
final class Race {
    var name: String
    var date: Date
    var distanceKm: Double
    var categoryRaw: String
    /// Data de cadastro da prova. Usada para calcular o progresso do Gauge circular.
    /// Padrão = `Date()` para registros anteriores (migração lightweight).
    var createdAt: Date

    var category: ImageCategory {
        get { ImageCategory(rawValue: categoryRaw) ?? .trail }
        set { categoryRaw = newValue.rawValue }
    }

    init(name: String, date: Date, distanceKm: Double, category: ImageCategory,
         createdAt: Date = Date()) {
        self.name = name
        self.date = date
        self.distanceKm = distanceKm
        self.categoryRaw = category.rawValue
        self.createdAt = createdAt
    }
}
