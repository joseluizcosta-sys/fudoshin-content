import Foundation

enum WallpaperImage {
    static let prefix = "Wallpaper_epico_"
    static let maxProbe = 99

    /// Nomes disponíveis em ordem (1, 2, 3…), parando no primeiro que faltar.
    static func available(_ exists: (String) -> Bool) -> [String] {
        var names: [String] = []
        for i in 1...maxProbe {
            let name = "\(prefix)\(i)"
            if exists(name) {
                names.append(name)
            } else {
                break
            }
        }
        return names
    }

    /// Escolha determinística por dia: mesma imagem o dia inteiro; dias seguidos não repetem
    /// quando houver ≥ 2 imagens. Sem imagens → nil (o composer usa HeroImage como fallback).
    static func name(for day: DayKey, installID: String, exists: (String) -> Bool) -> String? {
        let names = available(exists)
        guard !names.isEmpty else { return nil }
        return names[resolveIndex(day: day, installID: installID, count: names.count)]
    }

    // Calcula o índice efetivo para `day`, garantindo que não repita o índice efetivo de ontem.
    // `depth` evita recursão infinita em caso de dados inesperados; 100 dias é mais que suficiente.
    private static func resolveIndex(day: DayKey, installID: String, count: Int, depth: Int = 0) -> Int {
        let raw = Int(StableHash.fnv1a64(installID + day.value) % UInt64(count))

        guard count >= 2, depth < 100,
              let startOfDay = day.startOfDay(),
              let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: startOfDay) else {
            return raw
        }

        let yesterdayKey   = DayKey(yesterdayDate)
        let yesterdayIndex = resolveIndex(day: yesterdayKey, installID: installID,
                                          count: count, depth: depth + 1)
        return raw == yesterdayIndex ? (raw + 1) % count : raw
    }
}
