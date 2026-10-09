import XCTest
@testable import AtletaEstoico

final class TrialReminderTests: XCTestCase {

    // MARK: - fireDate: 48 h antes do fim do teste

    func testFireDate_48hBefore() {
        // fireDate = trialEnd − 48h = 1_000_000 − 172_800 = 827_200
        let trialEnd = Date(timeIntervalSince1970: 1_000_000)
        let now      = Date(timeIntervalSince1970: 800_000)  // antes do fireDate

        let fire = TrialReminder.fireDate(trialEnd: trialEnd, now: now)
        let expected = Date(timeIntervalSince1970: 1_000_000 - 48 * 3600)

        XCTAssertEqual(fire, expected)
    }

    // MARK: - fireDate retorna nil quando a data já passou

    func testFireDate_nilWhenAlreadyPast() {
        let trialEnd = Date(timeIntervalSince1970: 1_000_000)
        // now = 900_000, fireDate = 827_200 → now está após o fireDate
        let now = Date(timeIntervalSince1970: 900_000)

        XCTAssertNil(TrialReminder.fireDate(trialEnd: trialEnd, now: now),
                     "Deve retornar nil quando a data de disparo está no passado")
    }

    func testFireDate_nilWhenExactlyAtFireTime() {
        let trialEnd = Date(timeIntervalSince1970: 1_000_000)
        let now      = trialEnd.addingTimeInterval(-48 * 3600)  // exatamente na hora

        XCTAssertNil(TrialReminder.fireDate(trialEnd: trialEnd, now: now),
                     "Deve retornar nil quando now == fireDate (não está no futuro)")
    }

    func testFireDate_validWhenOneSecondBeforeFireTime() {
        let trialEnd = Date(timeIntervalSince1970: 1_000_000)
        let now      = trialEnd.addingTimeInterval(-48 * 3600 - 1)  // 1s antes

        XCTAssertNotNil(TrialReminder.fireDate(trialEnd: trialEnd, now: now),
                        "Deve retornar data quando há tempo sobrando")
    }
}
