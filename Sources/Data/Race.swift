import Foundation
import SwiftData

@Model
final class Race {
    var name: String
    var date: Date
    var distanceKm: Double
    var categoryRaw: String
    /// Data de cadastro da prova. Usada para calcular o progresso do Gauge circular.
    /// Default na declaração (não só no init) → SwiftData usa este valor na migração.
    var createdAt: Date = Date.now

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
