import XCTest
@testable import AtletaEstoico

final class AttributionTests: XCTestCase {

    // MARK: - (a) Citação → "— Sêneca"

    func testCitationAttribution() {
        let result = attributionText(author: "Sêneca", isParaphrase: false)
        XCTAssertEqual(result, "— Sêneca")
    }

    // MARK: - (b) Paráfrase em pt-BR → "Inspirado em David Goggins"

    func testParaphraseAttributionPtBR() throws {
        guard let path = Bundle(for: DailyPlanner.self)
            .path(forResource: "pt-BR", ofType: "lproj"),
              let ptBundle = Bundle(path: path)
        else { throw XCTSkip("Bundle pt-BR não encontrado") }

        let fmt = ptBundle.localizedString(forKey: "attribution.inspired",
                                           value: nil, table: nil)
        let result = String(format: fmt, "David Goggins")
        XCTAssertEqual(result, "Inspirado em David Goggins")
    }

    // MARK: - (c) DailyEntry JSON sem isParaphrase → false

    func testDecodeEntryWithoutIsParaphrase() throws {
        let json = """
        {
          "day": {"value": "2026-10-03"},
          "messageID": "ma-5-1",
          "imageID": "img1",
          "trigger": "geral",
          "shortText": "Texto",
          "inlineText": "Inline",
          "author": "Marco Aurélio",
          "reflection": "Ref",
          "daysToRace": null
        }
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(DailyEntry.self, from: json)
        XCTAssertFalse(entry.isParaphrase, "Campo ausente deve decodificar como false")
    }

    // MARK: - (d) Mensagens dg-* e ek-* carregam com kind "parafrase"

    func testParaphraseMessagesLoadCorrectly() throws {
        let lib = try ContentLibrary()
        let paraphraseIDs: Set<String> = [
            "dg-regra-40", "dg-vitorias", "dg-mente-calejada",
            "dg-espelho", "ek-disciplina", "ek-limites", "ek-sorriso", "ek-constancia"
        ]
        for id in paraphraseIDs {
            let msg = lib.message(withID: id)
            XCTAssertNotNil(msg, "Mensagem \(id) deve existir na biblioteca")
            XCTAssertEqual(msg?.kind, "parafrase",
                           "Mensagem \(id) deve ter kind == 'parafrase'")
        }
    }
}
