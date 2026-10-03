import Foundation

enum SleepCalculator {
    /// Une intervalos sobrepostos e retorna o total em horas.
    /// Retorna nil se a lista estiver vazia (sem amostras = nil, nunca 0).
    static func totalHours(from intervals: [DateInterval]) -> Double? {
        guard !intervals.isEmpty else { return nil }

        // Ordenar por início
        let sorted = intervals.sorted { $0.start < $1.start }

        // Mesclar intervalos sobrepostos ou adjacentes
        var merged: [DateInterval] = [sorted[0]]
        for interval in sorted.dropFirst() {
            let last = merged[merged.count - 1]
            if interval.start <= last.end {
                // Sobreposto: estender o fim se necessário
                if interval.end > last.end {
                    merged[merged.count - 1] = DateInterval(start: last.start, end: interval.end)
                }
            } else {
                merged.append(interval)
            }
        }

        let totalSeconds = merged.reduce(0.0) { $0 + $1.duration }
        return totalSeconds / 3600
    }
}
