import Foundation

enum WallpaperImage {

    /// Preferência válida (id existe no catálogo) → ela; inválida ou nil → sorteio diário.
    static func resolve(preference: String?, day: DayKey, installID: String,
                        entries: [WallpaperEntry]) -> String? {
        if let pref = preference, entries.contains(where: { $0.id == pref }) { return pref }
        return name(for: day, installID: installID, entries: entries)
    }

    /// Escolha determinística por dia: mesma imagem o dia inteiro; dias seguidos não repetem
    /// quando houver ≥ 2 imagens. Ordena por id antes de sortear para estabilidade quando
    /// chegam imagens novas. Sem entradas → nil.
    static func name(for day: DayKey, installID: String, entries: [WallpaperEntry]) -> String? {
        guard !entries.isEmpty else { return nil }
        let sorted = entries.sorted { $0.id < $1.id }
        return sorted[resolveIndex(day: day, installID: installID, count: sorted.count)].id
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
