import XCTest
@testable import AtletaEstoico

final class WeekPlanTests: XCTestCase {
    // Calendário gregoriano UTC para resultados determinísticos.
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(year: Int, month: Int, day: Int) -> Date {
        cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // 2026-10-05 = segunda-feira (jan 1 2026 = qui; jan→out +274 dias; 274%7=2; qui+2=sáb? retestar)
    // Verificação: usamos o próprio Calendar para garantir o dia da semana.
    func testSessionOnMonday() {
        // Encontra a segunda da semana que contém 2026-10-05
        let monday = date(year: 2026, month: 10, day: 5)
        XCTAssertEqual(cal.component(.weekday, from: monday), 2, "2026-10-05 deve ser segunda")

        let plan = WeekPlan(sessions: [0: .longo])
        XCTAssertEqual(plan.session(on: monday, calendar: cal), .longo)
    }

    func testSessionOnSaturday() {
        // 2026-10-10 = sábado
        let saturday = date(year: 2026, month: 10, day: 10)
        XCTAssertEqual(cal.component(.weekday, from: saturday), 7, "2026-10-10 deve ser sábado")

        let plan = WeekPlan(sessions: [5: .descanso])
        XCTAssertEqual(plan.session(on: saturday, calendar: cal), .descanso)
    }

    func testSessionOnSunday() {
        // 2026-10-11 = domingo
        let sunday = date(year: 2026, month: 10, day: 11)
        XCTAssertEqual(cal.component(.weekday, from: sunday), 1, "2026-10-11 deve ser domingo")

        let plan = WeekPlan(sessions: [6: .leve])
        XCTAssertEqual(plan.session(on: sunday, calendar: cal), .leve)
    }

    func testSessionNilOnEmptyDay() {
        let plan = WeekPlan(sessions: [0: .longo])      // só segunda tem sessão
        let tuesday = date(year: 2026, month: 10, day: 6)
        XCTAssertNil(plan.session(on: tuesday, calendar: cal))
    }

    func testAllWeekdaysMapToDistinctIndices() {
        // Garante que os 7 dias da semana mapeiam para índices 0-6 sem colisão.
        // Semana de 2026-10-05 (seg) a 2026-10-11 (dom).
        var indices: Set<Int> = []
        for d in 0..<7 {
            let date = date(year: 2026, month: 10, day: 5 + d)
            let weekday = cal.component(.weekday, from: date)
            let index = (weekday + 5) % 7
            indices.insert(index)
        }
        XCTAssertEqual(indices, Set(0..<7))
    }
}
