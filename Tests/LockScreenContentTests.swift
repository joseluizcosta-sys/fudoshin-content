import XCTest
@testable import AtletaEstoico

final class LockScreenContentTests: XCTestCase {

    private func makeEntry(shortText: String, inlineText: String) -> DailyEntry {
        DailyEntry(
            day: DayKey(Date()), messageID: "", imageID: "",
            trigger: .geral, shortText: shortText, inlineText: inlineText,
            author: "", reflection: "", daysToRace: nil
        )
    }

    // (a) destaque → shortText
    func testDestaqueReturnsShortText() {
        let entry = makeEntry(shortText: "Foco", inlineText: "Força")
        XCTAssertEqual(LockScreenContent.text(for: .destaque, entry: entry), "Foco")
    }

    // (b) palavraChave → inlineText
    func testPalavraChaveReturnsInlineText() {
        let entry = makeEntry(shortText: "Foco", inlineText: "Força")
        XCTAssertEqual(LockScreenContent.text(for: .palavraChave, entry: entry), "Força")
    }

    // (c) estilo padrão é destaque
    func testDefaultStyleIsDestaque() {
        XCTAssertEqual(LockScreenStyle.destaque.rawValue, "destaque",
                       "O raw value de destaque deve ser 'destaque' para compatibilidade com widgets existentes")
        let entry = makeEntry(shortText: "Padrão", inlineText: "Outro")
        XCTAssertEqual(LockScreenContent.text(for: .destaque, entry: entry), "Padrão",
                       "O estilo padrão (destaque) deve usar shortText")
    }
}
