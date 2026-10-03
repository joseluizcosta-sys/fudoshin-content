import XCTest
@testable import AtletaEstoico

final class SmokeTests: XCTestCase {
    /// O String Catalog compilado precisa ter a chave nos 3 idiomas de lançamento.
    func testCatalogHasKeyInLaunchLanguages() {
        for language in ["pt-BR", "en", "es"] {
            guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
                  let languageBundle = Bundle(path: path) else {
                XCTFail("Sem pasta de idioma \(language) no bundle do app")
                continue
            }
            let value = languageBundle.localizedString(forKey: "root.subtitle", value: "MISSING", table: nil)
            XCTAssertNotEqual(value, "MISSING", "Chave root.subtitle ausente em \(language)")
        }
    }

    func testThemeSpacingIsPositive() {
        XCTAssertGreaterThan(Theme.Spacing.small, 0)
        XCTAssertGreaterThan(Theme.Spacing.large, Theme.Spacing.medium)
    }
}
