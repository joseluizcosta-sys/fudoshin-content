import Foundation
import SwiftData

/// 7 posições: seg=0, ter=1, qua=2, qui=3, sex=4, sáb=5, dom=6.
/// String vazia na posição = sem sessão naquele dia.
@Model
final class WeekPlan {
    var sessionsRaw: [String]

    var sessions: [Int: SessionType] {
        get {
            var result: [Int: SessionType] = [:]
            for (i, raw) in sessionsRaw.enumerated() {
                if let s = SessionType(rawValue: raw) { result[i] = s }
            }
            return result
        }
        set {
            var raw = Array(repeating: "", count: 7)
            for (k, v) in newValue where (0..<7).contains(k) {
                raw[k] = v.rawValue
            }
            sessionsRaw = raw
        }
    }

    init(sessions: [Int: SessionType] = [:]) {
        var raw = Array(repeating: "", count: 7)
        for (k, v) in sessions where (0..<7).contains(k) {
            raw[k] = v.rawValue
        }
        self.sessionsRaw = raw
    }

    /// Retorna a sessão do dia da semana que contém `date`.
    /// Calendar.weekday: dom=1, seg=2 ... sáb=7  →  índice interno: seg=0 ... dom=6.
    func session(on date: Date, calendar: Calendar = .current) -> SessionType? {
        let weekday = calendar.component(.weekday, from: date)
        let index = (weekday + 5) % 7   // dom=1→6, seg=2→0, ..., sáb=7→5
        return sessions[index]
    }
}
