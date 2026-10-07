import XCTest
@testable import AtletaEstoico

final class HeroImageTests: XCTestCase {
    func testExistingAssetReturnsHeroName() {
        let result = HeroImage.name(for: .posTreino) { _ in true }
        XCTAssertEqual(result, "Hero_pos_treino")
    }

    func testMissingAssetReturnsFallback() {
        let result = HeroImage.name(for: .posTreino) { _ in false }
        XCTAssertEqual(result, HeroImage.fallback)
    }

    func testFallbackIsHeroSamurai() {
        XCTAssertEqual(HeroImage.fallback, "HeroSamurai")
    }

    func testAllTriggersProduceCorrectCandidateName() {
        let expected: [Trigger: String] = [
            .marcoProva: "Hero_marco_prova",
            .posTreino: "Hero_pos_treino",
            .sonoRuim: "Hero_sono_ruim",
            .vesperaChave: "Hero_vespera_chave",
            .descanso: "Hero_descanso",
            .retorno: "Hero_retorno",
            .geral: "Hero_geral"
        ]
        for (trigger, name) in expected {
            XCTAssertEqual(HeroImage.name(for: trigger) { _ in true }, name, "trigger: \(trigger)")
        }
    }

    func testSelectiveFallback() {
        // só "Hero_descanso" existe; todos os outros voltam ao fallback
        let available: Set<String> = ["Hero_descanso"]
        XCTAssertEqual(HeroImage.name(for: .descanso)  { available.contains($0) }, "Hero_descanso")
        XCTAssertEqual(HeroImage.name(for: .posTreino) { available.contains($0) }, HeroImage.fallback)
        XCTAssertEqual(HeroImage.name(for: .geral)     { available.contains($0) }, HeroImage.fallback)
    }
}
